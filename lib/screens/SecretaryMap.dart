import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:bus_tracker/utils/marker_helper.dart';
import 'package:bus_tracker/widgets/CustomBottomNav.dart';
import 'package:bus_tracker/widgets/CustomBackButton.dart';

class SecretaryMap extends StatefulWidget {
  final String userId;
  const SecretaryMap({super.key, required this.userId});

  @override
  State<SecretaryMap> createState() => _SecretaryMapState();
}

class _SecretaryMapState extends State<SecretaryMap> {
  StreamSubscription<QuerySnapshot>? _busesSubscription;
  Set<Marker> _busMarkers = {};
  GoogleMapController? _mapController;
  LatLng? _initialCenter;
  BitmapDescriptor? _busIconGreen;
  BitmapDescriptor? _busIconOrange;
  BitmapDescriptor? _busIconRed;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    _initBusesListener();
  }

  Future<void> _loadCustomMarker() async {
    try {
      _busIconGreen = await getMarkerIconFromData(
        Icons.directions_bus,
        Colors.green,
      );
      _busIconOrange = await getMarkerIconFromData(
        Icons.directions_bus,
        Colors.orange,
      );
      _busIconRed = await getMarkerIconFromData(
        Icons.directions_bus,
        Colors.red,
      );
      if (mounted) setState(() {});
    } catch (e) {
      print("Error loading custom marker: $e");
    }
  }

  void _initBusesListener() {
    _busesSubscription = FirebaseFirestore.instance
        .collection('Buses')
        .snapshots()
        .listen((snap) {
          if (!mounted) return;
          Set<Marker> newMarkers = {};
          LatLng? firstLoc;

          for (var bus in snap.docs) {
            final data = bus.data() as Map<String, dynamic>;
            if (data['latitude'] != null && data['longitude'] != null) {
              final lat = (data['latitude'] as num).toDouble();
              final lng = (data['longitude'] as num).toDouble();
              final pt = LatLng(lat, lng);
              if (firstLoc == null) firstLoc = pt;

              double markerHue = BitmapDescriptor.hueGreen;
              BitmapDescriptor? customIcon = _busIconGreen;

              if (data['status'] == 'DELAYED') {
                markerHue = BitmapDescriptor.hueOrange;
                customIcon = _busIconOrange;
              }
              if (data['status'] == 'BREAKDOWN') {
                markerHue = BitmapDescriptor.hueRed;
                customIcon = _busIconRed;
              }

              newMarkers.add(
                Marker(
                  markerId: MarkerId(bus.id),
                  position: pt,
                  icon:
                      customIcon ??
                      BitmapDescriptor.defaultMarkerWithHue(markerHue),
                ),
              );
            }
          }

          setState(() {
            _busMarkers = newMarkers;
            if (_initialCenter == null && firstLoc != null) {
              _initialCenter = firstLoc;
            }
          });
        });
  }

  @override
  void dispose() {
    _busesSubscription?.cancel();
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
                      _initialCenter ??
                      const LatLng(9.847694, 76.942194), // GEC Idukki
                  zoom: 13.0,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                zoomControlsEnabled: false,
                myLocationEnabled: true,
                markers: _initialCenter == null
                    ? {
                        Marker(
                          markerId: const MarkerId('schoolPosition'),
                          position: const LatLng(9.847694, 76.942194),
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                        ),
                      }
                    : _busMarkers,
              ),
            ),

            // TOP BAR
            Positioned(
              top: 8,
              left: 8,
              child: const CustomBackButton(),
            ),

            // BUS CARDS OVERLAY (Using Opacity to show map behind it)
            Positioned(
              top: 90,
              left: 16,
              right: 16,
              bottom: 100,
              child: _allBusCards(),
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

  // ================= ALL BUS CARDS =================

  Widget _allBusCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Buses').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final buses = snap.data!.docs;

        if (buses.isEmpty) {
          return const Center(
            child: Text(
              "No buses available",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          );
        }

        return GridView.builder(
          itemCount: buses.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // side by side
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            final bus = buses[index];
            return _busCard(bus.id);
          },
        );
      },
    );
  }

  // ================= SINGLE BUS CARD =================

  Widget _busCard(String busId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Buses')
          .doc(busId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return const SizedBox();
        }

        final data = snap.data!.data() as Map<String, dynamic>;
        final busName = data['busName'] ?? "Unknown Bus";
        final status = data['status'] ?? "ON_THE_WAY";
        final delayMinutes = data['delayMinutes'];
        final delayReason = data['delayReason'];

        Color statusColor;

        switch (status) {
          case "DELAYED":
            statusColor = Colors.orange;
            break;
          case "BREAKDOWN":
            statusColor = Colors.red;
            break;
          default:
            statusColor = Colors.green;
        }

        return GestureDetector(
          onTap: () {
            if (data['latitude'] != null && data['longitude'] != null) {
              final pt = LatLng(
                (data['latitude'] as num).toDouble(),
                (data['longitude'] as num).toDouble(),
              );
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(pt, 16.0),
              ); // Focus on this bus when card clicked
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(
                  0.92,
                ), // Slight transparency to show map
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(2, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // 🔹 FULL HEIGHT COLOR STRIP
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 6, color: statusColor),
                  ),

                  // 🔹 CONTENT
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.directions_bus,
                              size: 20,
                              color: Colors.black87,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                busName,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _statusLabel(status),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),

                        if (status == "DELAYED" && delayMinutes != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              "$delayMinutes min late${delayReason != null ? " • $delayReason" : ""}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),

                        if (status == "BREAKDOWN")
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              "Please wait for updates",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case "DELAYED":
        return "Delayed";
      case "BREAKDOWN":
        return "Breakdown";
      default:
        return "On the Way";
    }
  }

}
