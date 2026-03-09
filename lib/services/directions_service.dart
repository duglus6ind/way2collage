import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class DirectionsService {
  static const String _apiKey = "AIzaSyDVmBGjnUI7FQWXE3oAi1KwaIYWg1FVoQ8";

  static Future<Map<String, dynamic>?> getDirections({
    required LatLng origin,
    required dynamic destination, // String or LatLng
    List<dynamic>? waypoints,
  }) async {
    try {
      String originStr = "${origin.latitude},${origin.longitude}";

      String destStr;
      if (destination is LatLng) {
        destStr = "${destination.latitude},${destination.longitude}";
      } else {
        destStr = Uri.encodeComponent(destination.toString());
      }

      String waypointsStr = "";
      if (waypoints != null && waypoints.isNotEmpty) {
        waypointsStr =
            "&waypoints=optimize:true|" +
            waypoints
                .map((wp) {
                  if (wp is LatLng) return "${wp.latitude},${wp.longitude}";
                  return Uri.encodeComponent(wp.toString());
                })
                .join('|');
      }

      final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/directions/json?origin=$originStr&destination=$destStr$waypointsStr&key=$_apiKey",
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if ((data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];

          int totalDistanceMeters = 0;
          int totalDurationSeconds = 0;

          for (var leg in route['legs']) {
            totalDistanceMeters += (leg['distance']['value'] as num).toInt();
            totalDurationSeconds += (leg['duration']['value'] as num).toInt();
          }

          final distance =
              (totalDistanceMeters / 1000).toStringAsFixed(1) + " km";
          final duration =
              (totalDurationSeconds / 60).round().toString() + " mins";

          final polylineString = route['overview_polyline']['points'];
          final polylineCoordinates = _decodePolyline(polylineString);

          return {
            'distance': distance,
            'duration': duration,
            'polylineCoordinates': polylineCoordinates,
          };
        }
      }
    } catch (e) {
      print("Directions fetch error: $e");
    }
    return null;
  }

  // Fast polyline decoding algorithm natively via Dart
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }
}
