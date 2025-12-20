import 'dart:convert';
import 'package:http/http.dart' as http;

class OSRMService {
  // Danh sách OSRM servers (thử lần lượt nếu server đầu bị lỗi)
  static const List<String> servers = [
    'https://router.project-osrm.org',
    'https://routing.openstreetmap.de/routed-car',
  ];
  
  static int currentServerIndex = 0;
  
  /// Lấy lộ trình giữa 2 điểm
  /// Returns: List of Map<String, double> points forming the route
  static Future<List<Map<String, double>>> getRoute({
    required dynamic origin,
    required dynamic destination,
  }) async {
    final originLat = origin.latitude ?? origin['latitude'];
    final originLng = origin.longitude ?? origin['longitude'];
    final destLat = destination.latitude ?? destination['latitude'];
    final destLng = destination.longitude ?? destination['longitude'];
    
    // Thử từng server cho đến khi thành công
    for (int attempt = 0; attempt < servers.length; attempt++) {
      final serverUrl = servers[(currentServerIndex + attempt) % servers.length];
      
      try {
        print('Trying OSRM server: $serverUrl');
        
        final url = Uri.parse(
          '$serverUrl/route/v1/driving/$originLng,$originLat;$destLng,$destLat?overview=full&geometries=geojson',
        );

        final response = await http.get(url).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Request timeout after 30s');
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
            final route = data['routes'][0];
            final coordinates = route['geometry']['coordinates'] as List;
            
            // Thành công - lưu server này cho lần sau
            currentServerIndex = (currentServerIndex + attempt) % servers.length;
            print('OSRM success with server: $serverUrl');
            
            // Convert từ [lng, lat] sang Map
            return coordinates.map<Map<String, double>>((coord) {
              return {
                'latitude': coord[1].toDouble(),
                'longitude': coord[0].toDouble(),
              };
            }).toList();
          } else {
            throw Exception('No route found');
          }
        } else if (response.statusCode == 504 || response.statusCode == 502 || response.statusCode == 503) {
          print('Server $serverUrl timeout/unavailable (${response.statusCode}), trying next...');
          // Tiếp tục thử server tiếp theo
          continue;
        } else {
          throw Exception('Failed to fetch route: ${response.statusCode}');
        }
      } catch (e) {
        print('OSRM Error with $serverUrl: $e');
        
        // Nếu còn server để thử thì tiếp tục
        if (attempt < servers.length - 1) {
          print('Trying next server...');
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }
        
        // Hết server rồi → throw error
        rethrow;
      }
    }
    
    throw Exception('All OSRM servers failed');
  }

  /// Lấy thông tin chi tiết về lộ trình (khoảng cách, thời gian)
  static Future<Map<String, dynamic>> getRouteInfo({
    required dynamic origin,
    required dynamic destination,
  }) async {
    try {
      final originLat = origin.latitude ?? origin['latitude'];
      final originLng = origin.longitude ?? origin['longitude'];
      final destLat = destination.latitude ?? destination['latitude'];
      final destLng = destination.longitude ?? destination['longitude'];
      
      // Sử dụng server hiện tại (đã được chọn từ getRoute)
      final serverUrl = servers[currentServerIndex];
      
      final url = Uri.parse(
        '$serverUrl/route/v1/driving/$originLng,$originLat;$destLng,$destLat',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
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
