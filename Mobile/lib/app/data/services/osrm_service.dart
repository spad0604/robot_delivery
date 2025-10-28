import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class OSRMService {
  // OSRM public demo server (miễn phí)
  static const String baseUrl = 'https://router.project-osrm.org';
  
  // Các server OSRM công khai khác có thể dùng:
  // - https://routing.openstreetmap.de/routed-car
  // - https://router.project-osrm.org
  
  /// Lấy lộ trình giữa 2 điểm
  /// Returns: List of LatLng points forming the route
  static Future<List<LatLng>> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      // Format: /route/v1/{profile}/{coordinates}
      // coordinates: longitude,latitude;longitude,latitude
      final url = Uri.parse(
        '$baseUrl/route/v1/driving/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final coordinates = route['geometry']['coordinates'] as List;
          
          // Convert từ [lng, lat] sang LatLng
          return coordinates.map((coord) {
            return LatLng(coord[1], coord[0]); // lat, lng
          }).toList();
        } else {
          throw Exception('No route found');
        }
      } else {
        throw Exception('Failed to fetch route: ${response.statusCode}');
      }
    } catch (e) {
      print('OSRM Error: $e');
      rethrow;
    }
  }

  /// Lấy thông tin chi tiết về lộ trình (khoảng cách, thời gian)
  static Future<Map<String, dynamic>> getRouteInfo({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/route/v1/driving/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          
          return {
            'distance': route['distance'], // meters
            'duration': route['duration'], // seconds
            'distanceText': _formatDistance(route['distance']),
            'durationText': _formatDuration(route['duration']),
          };
        }
      }
      
      return {
        'distance': 0,
        'duration': 0,
        'distanceText': 'N/A',
        'durationText': 'N/A',
      };
    } catch (e) {
      print('OSRM Info Error: $e');
      return {
        'distance': 0,
        'duration': 0,
        'distanceText': 'N/A',
        'durationText': 'N/A',
      };
    }
  }

  static String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  static String _formatDuration(double seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) {
      return '$minutes phút';
    } else {
      final hours = (minutes / 60).floor();
      final remainingMinutes = minutes % 60;
      return '$hours giờ $remainingMinutes phút';
    }
  }
}
