# Hướng Dẫn Chuyển Đổi từ Google Maps sang OpenStreetMap

## 🎯 Tổng Quan

Dự án hiện tại đang dùng **Google Maps** nhưng gặp vấn đề hỗ trợ ở Việt Nam. 
Tôi đã tạo sẵn giải pháp thay thế bằng **flutter_map + OpenStreetMap** - hoàn toàn **MIỄN PHÍ** và **hỗ trợ tốt cho Việt Nam**.

## ✅ Những gì đã làm

### 1. Cập nhật `pubspec.yaml`
- ✅ Thay `google_maps_flutter` bằng `flutter_map` và `latlong2`
- ✅ Dependencies mới đã được thêm vào

### 2. Tạo Controller mới
- ✅ File mới: `lib/app/modules/map/controllers/map_controller_osm.dart`
- ✅ Sử dụng `flutter_map` thay vì Google Maps
- ✅ Tương thích với OSRM service hiện có

### 3. Tạo View mới  
- ✅ File mới: `lib/app/modules/map/views/map_view_osm.dart`
- ✅ UI giống y hệt phiên bản Google Maps
- ✅ Sử dụng OpenStreetMap tile layer (miễn phí)

## 🚀 Cách Sử Dụng

### Bước 1: Cài đặt dependencies

\`\`\`bash
flutter pub get
\`\`\`

### Bước 2: Chạy thử phiên bản OSM

Có 2 cách:

#### Cách 1: Thay đổi hoàn toàn (Khuyến nghị)

Backup file cũ và đổi tên file mới:

\`\`\`bash
# Backup file cũ
mv lib/app/modules/map/controllers/map_controller.dart lib/app/modules/map/controllers/map_controller_google.dart
mv lib/app/modules/map/views/map_view.dart lib/app/modules/map/views/map_view_google.dart

# Đổi tên file mới
mv lib/app/modules/map/controllers/map_controller_osm.dart lib/app/modules/map/controllers/map_controller.dart
mv lib/app/modules/map/views/map_view_osm.dart lib/app/modules/map/views/map_view.dart
\`\`\`

Sau đó sửa import trong `map_view.dart`:
\`\`\`dart
// Từ:
import '../controllers/map_controller_osm.dart';
class MapViewOSM extends GetView<MapControllerOSM> {

// Thành:
import '../controllers/map_controller.dart';
class MapView extends GetView<MapController> {
\`\`\`

#### Cách 2: Chạy song song để test

Cập nhật routes để test cả 2 phiên bản:

\`\`\`dart
// Trong file routes
GetPage(
  name: '/map-osm',
  page: () => MapViewOSM(),
  binding: BindingsBuilder(() {
    Get.lazyPut<MapControllerOSM>(() => MapControllerOSM());
  }),
),
\`\`\`

Sau đó navigate đến `/map-osm` để test.

### Bước 3: Sửa nhỏ để tương thích

Có 2 vấn đề nhỏ cần sửa:

#### 1. OSRM Service cần hỗ trợ cả 2 loại LatLng

Sửa file `lib/app/data/services/osrm_service.dart`:

\`\`\`dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class OSRMService {
  static const String baseUrl = 'https://router.project-osrm.org';
  
  /// Lấy lộ trình giữa 2 điểm
  /// Accepts dynamic type to work with both google_maps_flutter and latlong2
  static Future<List<Map<String, double>>> getRoute({
    required dynamic origin,  // Changed from LatLng
    required dynamic destination,  // Changed from LatLng
  }) async {
    try {
      // Extract lat/lng from either type
      final originLat = origin.latitude;
      final originLng = origin.longitude;
      final destLat = destination.latitude;
      final destLng = destination.longitude;

      final url = Uri.parse(
        '\$baseUrl/route/v1/driving/\$originLng,\$originLat;\$destLng,\$destLat?overview=full&geometries=geojson',
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
          
          // Return as List<Map> để có thể convert sang bất kỳ type nào
          return coordinates.map<Map<String, double>>((coord) {
            return {
              'latitude': coord[1].toDouble(),
              'longitude': coord[0].toDouble(),
            };
          }).toList();
        } else {
          throw Exception('No route found');
        }
      } else {
        throw Exception('Failed to fetch route: \${response.statusCode}');
      }
    } catch (e) {
      print('OSRM Error: \$e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getRouteInfo({
    required dynamic origin,
    required dynamic destination,
  }) async {
    try {
      final originLat = origin.latitude;
      final originLng = origin.longitude;
      final destLat = destination.latitude;
      final destLng = destination.longitude;

      final url = Uri.parse(
        '\$baseUrl/route/v1/driving/\$originLng,\$originLat;\$destLng,\$destLat',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          
          return {
            'distance': route['distance'],
            'duration': route['duration'],
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
      print('OSRM Info Error: \$e');
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
      return '\${meters.toStringAsFixed(0)} m';
    } else {
      return '\${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  static String _formatDuration(double seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) {
      return '\$minutes phút';
    } else {
      final hours = (minutes / 60).floor();
      final remainingMinutes = minutes % 60;
      return '\$hours giờ \$remainingMinutes phút';
    }
  }
}
\`\`\`

#### 2. Firebase Service cần trả về dynamic type

Sửa file `lib/app/data/services/firebase_service.dart`:

Thay đổi method `getRobotPosition()` từ:
\`\`\`dart
Future<LatLng?> getRobotPosition() async {
  // ...
}
\`\`\`

Thành:
\`\`\`dart
Future<Map<String, double>?> getRobotPosition() async {
  try {
    final snapshot = await _database.child('robot/position').get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      return {
        'latitude': (data['latitude'] ?? 21.028511).toDouble(),
        'longitude': (data['longitude'] ?? 105.804817).toDouble(),
      };
    }
  } catch (e) {
    print('Error getting robot position: \$e');
  }
  return null;
}
\`\`\`

## 🌐 Tile Server Options

OpenStreetMap có nhiều tile server miễn phí:

### Standard OSM (Đang dùng)
\`\`\`dart
urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
\`\`\`

### Humanitarian (HOT) - Bright colors
\`\`\`dart
urlTemplate: 'https://tile.openstreetmap.fr/hot/{z}/{x}/{y}.png'
\`\`\`

### CartoDB Voyager - Clean design
\`\`\`dart
urlTemplate: 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/rastertiles/voyager/{z}/{x}/{y}.png'
subdomains: ['a', 'b', 'c', 'd']
\`\`\`

### OpenTopoMap - Topographic style
\`\`\`dart
urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png'
subdomains: ['a', 'b', 'c']
\`\`\`

## ⚠️ Lưu Ý Quan Trọng

### 1. Xóa Google Maps config khỏi Android
Nếu chuyển hoàn toàn sang OSM, xóa API key trong:
- `android/app/src/main/AndroidManifest.xml`
- Tìm và xóa dòng có `com.google.android.geo.API_KEY`

### 2. Usage Policy
OpenStreetMap tile servers có usage policy:
- ✅ Miễn phí cho ứng dụng nhỏ/vừa
- ⚠️ Nên có User-Agent header (đã thêm: `userAgentPackageName: 'com.example.robot_delivery'`)
- 📊 Nếu traffic lớn, nên tự host tile server hoặc dùng paid service

### 3. Offline Map Support
flutter_map hỗ trợ offline maps - có thể thêm sau:
\`\`\`yaml
dependencies:
  flutter_map_cache: ^latest_version
\`\`\`

## 🎨 Customization

### Thay đổi màu đường đi
Trong `map_controller_osm.dart`:
\`\`\`dart
final polyline = fm.Polyline(
  points: routeCoordinates,
  color: Colors.blue,  // Đổi màu tùy ý
  strokeWidth: 5,
);
\`\`\`

### Thay đổi marker style
Markers có thể dùng bất kỳ widget nào:
\`\`\`dart
fm.Marker(
  point: position,
  child: Icon(
    Icons.location_pin,
    size: 50,
    color: Colors.red,
  ),
);
\`\`\`

## 📦 Các Package Hữu Ích

Có thể thêm vào sau:
- `flutter_map_marker_cluster`: Cluster markers khi zoom out
- `flutter_map_location_marker`: Show current location đẹp hơn
- `flutter_map_dragmarker`: Drag & drop markers

## 🆘 Nếu Gặp Lỗi

### Lỗi: "Failed to load tile"
- Kiểm tra internet connection
- Thử đổi tile server khác (xem phần Tile Server Options)

### Lỗi compile
- Chạy: `flutter clean && flutter pub get`
- Restart IDE

### Map không hiển thị
- Kiểm tra `flutter pub get` đã chạy chưa
- Xem log để biết error cụ thể

## ✨ Tính Năng Đã Có

✅ Hiển thị bản đồ OpenStreetMap  
✅ Đánh dấu vị trí Robot  
✅ Chọn điểm đích trên bản đồ  
✅ Vẽ đường đi với OSRM  
✅ Zoom in/out  
✅ Move camera  
✅ Marker với custom widget  
✅ Tạo đơn hàng với lộ trình  

## 🚀 Next Steps

1. Test phiên bản OSM
2. So sánh hiệu năng với Google Maps
3. Quyết định có dùng hoàn toàn OSM không
4. Nếu OK, xóa dependencies Google Maps

## 📞 Support

Nếu cần customize thêm:
- Đổi màu route
- Custom marker design
- Thêm chức năng mới
- Optimize performance

Cứ hỏi tôi nhé! 😊
