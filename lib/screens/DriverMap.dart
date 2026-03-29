import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bus_tracker/services/notification_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bus_tracker/utils/marker_helper.dart';
import 'package:bus_tracker/services/directions_service.dart';
import 'package:bus_tracker/widgets/CustomBottomNav.dart';
import 'package:bus_tracker/widgets/CustomBackButton.dart';

class DriverMap extends StatefulWidget {
  final String userId;

  const DriverMap({super.key, required this.userId});

  @override
  State<DriverMap> createState() => _DriverMapState();
}

class _DriverMapState extends State<DriverMap> {
  String? _busId;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentPosition;
  GoogleMapController? _mapController;
  String _loadingMessage = "Acquiring GPS location...";
  BitmapDescriptor? _busIcon;

  List<LatLng> _polylineCoordinates = [];
  String _distance = "";
  String _duration = "";
  bool _isFetchingRoute = false;
  bool _isTripStarted = false;
  DateTime? _lastRouteFetchTime;
  String? _assignedRouteId;
  bool _isSpecialTrip = false;
  Set<Marker> _markers = {};
  BitmapDescriptor? _stopIcon;
  BitmapDescriptor? _destinationIcon;

  // Next Stop Tracking
  List<Map<String, dynamic>> _routeStops = [];
  int _nextStopIndex = 0;
  BitmapDescriptor? _nextStopIcon;
  BitmapDescriptor? _passedStopIcon;

  // Simulation variables
  bool _isSimulating = false;
  Timer? _simulationTimer;
  int _simulationIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    _initDriverLocation();
  }

  Future<void> _loadCustomMarker() async {
    try {
      _busIcon = await getMarkerIconFromData(Icons.directions_bus, Colors.blue);
      _stopIcon = await getMarkerIconFromData(
        Icons.location_on,
        Colors.orange,
        size: 100,
      );
      _destinationIcon = await getMarkerIconFromData(
        Icons.location_on,
        Colors.red,
        size: 120,
      );
      _nextStopIcon = await getMarkerIconFromData(
        Icons.location_on,
        Colors.green,
        size: 120,
      );
      _passedStopIcon = await getMarkerIconFromData(
        Icons.location_on,
        Colors.grey,
        size: 80,
      );
      if (mounted) setState(() {});
    } catch (e) {
      print("Error loading custom marker: $e");
    }
  }

  Future<void> _initDriverLocation() async {
    // 1. Get User's Bus ID
    _userSubscription = FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.userId)
        .snapshots()
        .listen((snap) {
          if (snap.exists) {
            final data = snap.data() as Map<String, dynamic>;
            if (mounted) {
              setState(() {
                _busId = data['AssignedBusId'];
                _assignedRouteId = data['AssignedRouteId'];
                _isSpecialTrip = data['isSpecialTrip'] == true;
              });
              if (_busId != null) {
                _fetchRoutePath(_busId!);
              }
            }
          }
        });

    // 2. Request Location Permission
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted)
        setState(
          () => _loadingMessage =
              "Location services are disabled.\nPlease enable GPS.",
        );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted)
          setState(() => _loadingMessage = "Location permissions are denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted)
        setState(
          () =>
              _loadingMessage = "Location permissions are permanently denied.",
        );
      return;
    }

    try {
      Position initialPosition = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 10),
      );
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(
            initialPosition.latitude,
            initialPosition.longitude,
          );
        });
      }
    } catch (e) {
      if (mounted)
        setState(
          () => _loadingMessage =
              "Waiting for GPS signal...\n(If on emulator, set a mock location)",
        );
    }

    // 3. Start Tracking Location
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5, // update every 5 meters
          ),
        ).listen((Position position) {
          if (mounted) {
            bool isFirst = _currentPosition == null;
            setState(() {
              _currentPosition = LatLng(position.latitude, position.longitude);

              if (_isTripStarted && !_isSimulating && _polylineCoordinates.isNotEmpty) {
                double minDistance = double.infinity;
                int closestIndex = 0;
                int checkLimit = _polylineCoordinates.length < 50 ? _polylineCoordinates.length : 50;

                for (int i = 0; i < checkLimit; i++) {
                  double lat1 = _currentPosition!.latitude;
                  double lon1 = _currentPosition!.longitude;
                  double lat2 = _polylineCoordinates[i].latitude;
                  double lon2 = _polylineCoordinates[i].longitude;
                  
                  var p = 0.017453292519943295; // Math.PI / 180
                  var a = 0.5 - math.cos((lat2 - lat1) * p)/2 + 
                          math.cos(lat1 * p) * math.cos(lat2 * p) * 
                          (1 - math.cos((lon2 - lon1) * p))/2;
                  var dist = 12742 * math.asin(math.sqrt(a));
                  
                  if (dist < minDistance) {
                    minDistance = dist;
                    closestIndex = i;
                  }
                }
                
                if (closestIndex > 0) {
                  _polylineCoordinates.removeRange(0, closestIndex);
                }
                _polylineCoordinates[0] = _currentPosition!;
              }
            });
            _checkNextStopReached(_currentPosition!);
            if (!isFirst) {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(_currentPosition!, 16.0),
              ); // Center map
            }
          }

          if (_busId != null) {
            // Update Firestore only if trip is started
            if (_isTripStarted) {
              FirebaseFirestore.instance
                  .collection('Buses')
                  .doc(_busId)
                  .update({
                    'latitude': position.latitude,
                    'longitude': position.longitude,
                    'lastLocationUpdate': FieldValue.serverTimestamp(),
                  });
            }

            // Periodic route update (every 30 seconds)
            if (_lastRouteFetchTime == null ||
                DateTime.now().difference(_lastRouteFetchTime!).inSeconds >
                    30) {
              _fetchRoutePath(_busId!);
            }
          }
        });
  }

  Future<void> _fetchRoutePath(String busId) async {
    if (_isFetchingRoute) return;
    setState(() => _isFetchingRoute = true);

    try {
      final busDoc = await FirebaseFirestore.instance
          .collection('Buses')
          .doc(busId)
          .get();

      String? routeId;
      if (_isSpecialTrip) {
        routeId = _assignedRouteId;
      } else {
        if (busDoc.exists) {
          routeId = busDoc.data()?['routeId'];
        }
        routeId ??= _assignedRouteId;
      }

      if (routeId == null) {
        print(
          "DEBUG: No route ID found for bus $busId or driver ${widget.userId}",
        );
        return;
      }

      final collectionName = _isSpecialTrip ? 'SpecialTrips' : 'Routes';
      final routeDoc = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(routeId)
          .get();
          
      if (!routeDoc.exists) {
        print("DEBUG: Route doc $routeId NOT FOUND in $collectionName");
        return;
      }

      List<dynamic>? stops;
      if (_isSpecialTrip) {
        stops = routeDoc.data()?['waypoints'] as List<dynamic>?;
        final destName = routeDoc.data()?['destinationName'];
        final destLat = routeDoc.data()?['destinationLat'];
        final destLng = routeDoc.data()?['destinationLng'];
        if (destName != null && destLat != null && destLng != null) {
          stops = [
            ...(stops ?? []),
            {'name': destName, 'lat': destLat, 'lng': destLng, 'order': (stops?.length ?? 0) + 1}
          ];
        }
      } else {
        stops = routeDoc.data()?['Stops'] as List<dynamic>?;
      }
      if (stops == null || stops.isEmpty) return;

      List<dynamic> waypoints = [];
      dynamic destination;

      print(
        "DEBUG: Processing ${stops.length} stops in order: ${stops.map((dynamic s) => (s as Map)['name']).toList()}",
      );

      for (int i = 0; i < stops.length; i++) {
        final stop = stops[i];
        LatLng? pos;

        if (stop['lat'] != null && stop['lng'] != null) {
          pos = LatLng(
            (stop['lat'] as num).toDouble(),
            (stop['lng'] as num).toDouble(),
          );
        }

        final isDestination = i == stops.length - 1;

        if (isDestination) {
          destination = pos ?? stop['name'].toString();
        } else {
          waypoints.add(pos ?? stop['name'].toString());
        }
      }

      if (mounted) {
        setState(() {
          _routeStops = stops!
              .map((s) => Map<String, dynamic>.from(s as Map))
              .toList();
        });
        _calculateInitialNextStop();
      }

      // If trip hasn't started, we only show markers, no polyline/ETA
      if (!_isTripStarted) {
        return;
      }

      while (_currentPosition == null) {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
      }

      final dirData = await DirectionsService.getDirections(
        origin: _currentPosition!,
        destination: destination,
        waypoints: waypoints,
      );

      if (dirData != null && mounted) {
        setState(() {
          _distance = dirData['distance'];
          _duration = dirData['duration'];
          _polylineCoordinates = List<LatLng>.from(dirData['polylineCoordinates']);
          _lastRouteFetchTime = DateTime.now();
        });
        print(
          "DEBUG: Route fetched successfully. Polylines: ${_polylineCoordinates.length}",
        );
      } else {
        print("DEBUG: DirectionsService returned NULL for routeId: $routeId");
      }
    } catch (e) {
      print("DEBUG: Error fetching route path: $e");
    } finally {
      if (mounted) setState(() => _isFetchingRoute = false);
    }
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _userSubscription?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // ACTUAL MAP
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target:
                      _currentPosition ??
                      const LatLng(9.847694, 76.942194), // GEC Idukki
                  zoom: 16.0,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                zoomControlsEnabled: false,
                myLocationEnabled: false,
                markers: {
                  if (_currentPosition != null)
                    Marker(
                      markerId: const MarkerId('busPosition'),
                      position: _currentPosition!,
                      icon:
                          _busIcon ??
                          BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueBlue,
                          ),
                    )
                  else
                    Marker(
                      markerId: const MarkerId('schoolPosition'),
                      position: const LatLng(9.847694, 76.942194),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                    ),
                  ..._markers,
                },
                polylines: {
                  if (_isTripStarted && _polylineCoordinates.isNotEmpty)
                    Polyline(
                      polylineId: const PolylineId('route_path'),
                      color: Colors.blueAccent,
                      width: 10,
                      points: _isSimulating
                          ? _polylineCoordinates.sublist(
                              _simulationIndex > 0 ? _simulationIndex - 1 : 0,
                            )
                          : _polylineCoordinates,
                    ),
                },
              ),
            ),

            // ETA INFO CARD (Top right)
            if (_distance.isNotEmpty && _duration.isNotEmpty)
              Positioned(
                top: 80,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _distance,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _duration,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // LOADING MESSAGE OVERLAY (Top center if loading)
            if (_currentPosition == null)
              Positioned(
                top: 130,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _loadingMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),

            // TOP BAR
            Positioned(
              top: 8,
              left: 8,
              child: const CustomBackButton(),
            ),

            // BUS STATUS UPDATE CHIP
            Positioned(
              top: 90,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _showStatusPicker(context),
                  child: _busStatusText(),
                ),
              ),
            ),

            // UPCOMING STOP BANNER
            if (_isTripStarted &&
                _routeStops.isNotEmpty &&
                _nextStopIndex < _routeStops.length)
              Positioned(
                bottom: 180,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "UPCOMING STOP",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _routeStops[_nextStopIndex]['name'].toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // BOTTOM NAV
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CustomBottomNav(userId: widget.userId, activeTab: NavTab.map),
            ),

            // TRIP CONTROL BUTTONS
            Positioned(
              bottom: 100,
              left: 24,
              right: 24,
              child: _isTripStarted
                  ? Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 6,
                            ),
                            onPressed: _toggleTrip,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.stop_circle, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  "END TRIP",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isSimulating
                                  ? Colors.orange
                                  : Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 6,
                            ),
                            onPressed: _toggleSimulation,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isSimulating
                                      ? Icons.pause_circle
                                      : Icons.directions_bus,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isSimulating ? "STOP SIM" : "SIMULATE",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF095C42),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 6,
                      ),
                      onPressed: _toggleTrip,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_circle_fill, size: 28),
                          SizedBox(width: 10),
                          Text(
                            "START TRIP",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            // BOTTOM NAV
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CustomBottomNav(userId: widget.userId, activeTab: NavTab.map),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- TRIP TOGGLE ----------------
  void _toggleTrip() {
    setState(() {
      _isTripStarted = !_isTripStarted;

      if (_isTripStarted) {
        // Start Trip
        if (_busId != null) {
          _fetchRoutePath(_busId!);
        }
      } else {
        // End Trip
        _stopSimulation();
        _polylineCoordinates.clear();
        _distance = "";
        _duration = "";
      }
    });

    if (_busId != null) {
      if (_isTripStarted && _currentPosition != null) {
        // Immediately push first coordinate to wake up student apps
        FirebaseFirestore.instance.collection('Buses').doc(_busId).update({
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
          'lastLocationUpdate': FieldValue.serverTimestamp(),
          'tripActive': true,
          'passedStops': [],
        });
      } else if (!_isTripStarted) {
        FirebaseFirestore.instance.collection('Buses').doc(_busId).update({
          'tripActive': false,
        });
      }
    }
  }

  // ---------------- SIMULATION LOGIC ----------------
  void _toggleSimulation() {
    if (_isSimulating) {
      _stopSimulation();
    } else {
      _startSimulation();
    }
  }

  void _startSimulation() {
    if (_polylineCoordinates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Route path not fetched yet. Please wait."),
        ),
      );
      return;
    }

    setState(() {
      _isSimulating = true;
      _simulationIndex = 0;
    });

    _positionStream?.pause();

    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_simulationIndex >= _polylineCoordinates.length) {
        _stopSimulation();
        return;
      }

      final nextPos = _polylineCoordinates[_simulationIndex];
      setState(() {
        _currentPosition = nextPos;
        _updateSimulationETA();
      });
      _checkNextStopReached(nextPos);

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(nextPos, 16.0));

      if (_busId != null && _isTripStarted) {
        FirebaseFirestore.instance.collection('Buses').doc(_busId).update({
          'latitude': nextPos.latitude,
          'longitude': nextPos.longitude,
          'lastLocationUpdate': FieldValue.serverTimestamp(),
        });
      }

      _simulationIndex++;
    });
  }

  void _stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    if (mounted) {
      setState(() {
        _isSimulating = false;
      });
    }
    _positionStream?.resume();
  }

  void _updateSimulationETA() {
    if (_simulationIndex >= _polylineCoordinates.length - 1) {
      _distance = "0 m";
      _duration = "0 mins";
      return;
    }

    double totalRemainingDistanceMeters = 0;
    for (int i = _simulationIndex; i < _polylineCoordinates.length - 1; i++) {
      totalRemainingDistanceMeters += Geolocator.distanceBetween(
        _polylineCoordinates[i].latitude,
        _polylineCoordinates[i].longitude,
        _polylineCoordinates[i + 1].latitude,
        _polylineCoordinates[i + 1].longitude,
      );
    }

    if (totalRemainingDistanceMeters > 1000) {
      _distance =
          "${(totalRemainingDistanceMeters / 1000).toStringAsFixed(1)} km";
    } else {
      _distance = "${totalRemainingDistanceMeters.round()} m";
    }

    double mins = totalRemainingDistanceMeters / 667;
    _duration = "${mins.round()} mins";
  }

  // ---------------- NEXT STOP TRACKING ----------------

  void _updateMarkersHighlight() {
    Set<Marker> updatedMarkers = {};
    for (int i = 0; i < _routeStops.length; i++) {
      final stop = _routeStops[i];
      if (stop['lat'] == null || stop['lng'] == null) continue;

      LatLng pos = LatLng(
        (stop['lat'] as num).toDouble(),
        (stop['lng'] as num).toDouble(),
      );

      final isDestination = i == _routeStops.length - 1;
      BitmapDescriptor icon;

      if (i < _nextStopIndex) {
        icon =
            _passedStopIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      } else if (i == _nextStopIndex) {
        icon =
            _nextStopIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      } else {
        icon = isDestination
            ? (_destinationIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ))
            : (_stopIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange,
                  ));
      }

      updatedMarkers.add(
        Marker(
          markerId: MarkerId('stop_${i}_${stop['name']}'),
          position: pos,
          infoWindow: InfoWindow(title: stop['name']),
          icon: icon,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = updatedMarkers;
      });
    }
  }

  void _calculateInitialNextStop() {
    if (_routeStops.isEmpty) return;
    if (_currentPosition == null) {
      _nextStopIndex = 0;
      _updateMarkersHighlight();
      return;
    }

    double minDist = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < _routeStops.length; i++) {
      final stop = _routeStops[i];
      if (stop['lat'] != null && stop['lng'] != null) {
        double d = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          (stop['lat'] as num).toDouble(),
          (stop['lng'] as num).toDouble(),
        );
        if (d < minDist) {
          minDist = d;
          closestIndex = i;
        }
      }
    }

    if (minDist < 100.0 && closestIndex < _routeStops.length - 1) {
      _nextStopIndex = closestIndex + 1;
    } else {
      _nextStopIndex = closestIndex;
    }
    _updateMarkersHighlight();
  }

  void _checkNextStopReached(LatLng pos) {
    if (_routeStops.isEmpty || _nextStopIndex >= _routeStops.length) return;
    final nextStop = _routeStops[_nextStopIndex];
    if (nextStop['lat'] != null && nextStop['lng'] != null) {
      double dist = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        (nextStop['lat'] as num).toDouble(),
        (nextStop['lng'] as num).toDouble(),
      );
      if (dist < 100.0) {
        if (_busId != null && _isTripStarted) {
          FirebaseFirestore.instance.collection('Buses').doc(_busId).update({
            'passedStops': FieldValue.arrayUnion([nextStop['name']])
          });
        }
        if (_nextStopIndex < _routeStops.length - 1) {
          if (mounted) {
            setState(() {
              _nextStopIndex++;
            });
          }
          _updateMarkersHighlight();
        }
      }
    }
  }

  // ---------------- STATUS DISPLAY ----------------

  Widget _busStatusText() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const SizedBox();
        }

        final userData = userSnap.data!.data() as Map<String, dynamic>?;
        final busId = userData?['AssignedBusId'];

        if (busId == null) {
          return _statusChip(label: "No bus assigned", color: Colors.grey);
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Buses')
              .doc(busId)
              .snapshots(),
          builder: (context, busSnap) {
            if (!busSnap.hasData || !busSnap.data!.exists) {
              return _statusChip(label: "Bus not found", color: Colors.grey);
            }

            final busData = busSnap.data!.data() as Map<String, dynamic>;

            final status = busData['status'] ?? "ON_THE_WAY";
            final delayMinutes = busData['delayMinutes'];

            final color = _statusColor(status);

            final label = status == "DELAYED" && delayMinutes != null
                ? "Delayed • $delayMinutes min"
                : _statusLabel(status);

            return _statusChip(label: label, color: color);
          },
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case "DELAYED":
        return Colors.orange;
      case "BREAKDOWN":
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  Widget _statusChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- STATUS PICKER ----------------

  void _showStatusPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statusOption(context, "ON_THE_WAY", "On the way"),
            _statusOption(context, "DELAYED", "Delayed"),
            _statusOption(context, "BREAKDOWN", "Breakdown"),
          ],
        );
      },
    );
  }

  Widget _statusOption(BuildContext context, String value, String label) {
    return ListTile(
      title: Text(label),
      onTap: () async {
        Navigator.pop(context);
        await _updateBusStatusWithLogic(context, value);
      },
    );
  }

  // ---------------- STATUS UPDATE LOGIC ----------------

  Future<void> _updateBusStatusWithLogic(
    BuildContext context,
    String status,
  ) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.userId)
        .get();

    final busId = userDoc.data()?['AssignedBusId'];
    if (busId == null) return;

    if (status == "DELAYED") {
      _showDelayDialog(context, busId);
      return;
    }

    await FirebaseFirestore.instance.collection('Buses').doc(busId).update({
      'status': status,
      'delayMinutes': null,
      'delayReason': null,
      'statusUpdatedBy': widget.userId,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
    });

    // 🔔 Send notification to all students of this bus
    final students = await FirebaseFirestore.instance
        .collection('Users')
        .where('Role', isEqualTo: 'Student')
        .where('AssignedBusId', isEqualTo: busId)
        .get();

    final busDoc = await FirebaseFirestore.instance
        .collection('Buses')
        .doc(busId)
        .get();

    final busName = busDoc.data()?['busName'] ?? "Your Bus";
    for (var student in students.docs) {
      await NotificationService.sendNotification(
        toUserId: student.id,
        title: "$busName Status Updated",
        message: "Status changed to ${_statusLabel(status)}",
        busId: busId,
        busName: busName,
      );
    }
  }

  // ---------------- DELAY POPUP ----------------

  void _showDelayDialog(BuildContext context, String busId) {
    final TextEditingController delayController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Delay Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: delayController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Delay time (minutes)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Reason for delay",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (delayController.text.isEmpty ||
                  reasonController.text.isEmpty) {
                return;
              }

              await FirebaseFirestore.instance
                  .collection('Buses')
                  .doc(busId)
                  .update({
                    'status': "DELAYED",
                    'delayMinutes': int.parse(delayController.text),
                    'delayReason': reasonController.text.trim(),
                    'statusUpdatedBy': widget.userId,
                    'statusUpdatedAt': FieldValue.serverTimestamp(),
                  });

              // 🔔 Notify students about delay
              final students = await FirebaseFirestore.instance
                  .collection('Users')
                  .where('Role', isEqualTo: 'Student')
                  .where('AssignedBusId', isEqualTo: busId)
                  .get();

              final busDoc = await FirebaseFirestore.instance
                  .collection('Buses')
                  .doc(busId)
                  .get();

              final busName = busDoc.data()?['busName'] ?? "Your Bus";

              for (var student in students.docs) {
                await NotificationService.sendNotification(
                  toUserId: student.id,
                  title: "$busName Delayed",
                  message: "Delayed by ${delayController.text} minutes",
                  busId: busId,
                  busName: busName,
                );
              }

              Navigator.pop(context);
            },
            child: const Text("UPDATE"),
          ),
        ],
      ),
    );
  }

  // ---------------- HELPERS ----------------

  String _statusLabel(String status) {
    switch (status) {
      case 'DELAYED':
        return "Delayed";
      case 'BREAKDOWN':
        return "Breakdown";
      default:
        return "On the way";
    }
  }

}
