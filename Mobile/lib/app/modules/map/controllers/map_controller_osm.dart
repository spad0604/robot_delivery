import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geolocator/geolocator.dart';
import 'package:robot_delivery/app/data/models/delivery_order.dart';
import 'package:robot_delivery/app/data/services/firebase_service.dart';
import 'package:robot_delivery/app/data/services/osrm_service.dart';

class MapControllerOSM extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  
  final fm.MapController mapController = fm.MapController();
  final Rx<LatLng?> currentLocation = Rx<LatLng?>(null);
  final Rx<LatLng?> selectedDestination = Rx<LatLng?>(null);
  final RxList<fm.Marker> markers = <fm.Marker>[].obs;
  final RxList<fm.Polyline> polylines = <fm.Polyline>[].obs;
  final RxList<LatLng> routeCoordinates = <LatLng>[].obs;
  final RxBool isLoading = false.obs;

  // Robot position from Firebase (reactive)
  final Rx<LatLng> robotPosition = const LatLng(21.028511, 105.804817).obs; // Tọa độ mặc định Hà Nội
  
  // Stream subscription để lắng nghe vị trí robot real-time
  StreamSubscription<Map<String, double>?>? _robotPositionSubscription;

  // Robot starting position (có thể cấu hình theo vị trí thực tế)
  final LatLng robotStartPosition = const LatLng(10.762622, 106.660172); // TP.HCM
  
  // Auto-follow robot on map
  final RxBool autoFollowRobot = true.obs;

  @override
  void onInit() {
    super.onInit();
    getCurrentLocation();
    _startRobotPositionUpdates();
  }

  @override
  void onClose() {
    _robotPositionSubscription?.cancel();
    super.onClose();
  }

  // Bắt đầu lắng nghe vị trí robot từ Firebase theo thời gian thực
  void _startRobotPositionUpdates() {
    // Lắng nghe thay đổi vị trí robot real-time
    _robotPositionSubscription = _firebaseService.getRobotPositionStream().listen(
      (position) {
        if (position != null) {
          final newPosition = LatLng(position['latitude']!, position['longitude']!);
          robotPosition.value = newPosition;
          
          // Cập nhật marker robot
          _updateMarkers();
          
          // Tự động di chuyển bản đồ theo robot nếu bật auto-follow
          if (autoFollowRobot.value) {
            try {
              mapController.move(newPosition, mapController.camera.zoom);
            } catch (e) {
              print('Error moving map: $e');
            }
          }
          
          print('🤖 Robot position updated (real-time): ${position['latitude']}, ${position['longitude']}');
        } else {
          print('Using default Hanoi position');
        }
      },
      onError: (error) {
        print('❌ Error listening to robot position: $error');
      },
    );
  }

  // Get current location
  Future<void> getCurrentLocation() async {
    try {
      isLoading.value = true;
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar('Lỗi', 'Vui lòng bật GPS');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar('Lỗi', 'Quyền truy cập vị trí bị từ chối');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentLocation.value = LatLng(position.latitude, position.longitude);
      
      // Update markers
      _updateMarkers();

      // Move camera to robot position
      mapController.move(robotPosition.value, 14);
    } catch (e) {
      print('Error getting location: $e');
      Get.snackbar('Lỗi', 'Không thể lấy vị trí hiện tại');
    } finally {
      isLoading.value = false;
    }
  }

  // Set destination when user taps on map
  void setDestination(LatLng position) {
    selectedDestination.value = position;
    
    // Update markers
    _updateMarkers();

    // Calculate route
    calculateRoute();
  }

  // Update all markers on map
  void _updateMarkers() {
    List<fm.Marker> newMarkers = [];

    // Add robot marker
    newMarkers.add(
      fm.Marker(
        width: 80,
        height: 80,
        point: robotPosition.value,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Robot',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(
              Icons.smart_toy,
              color: Colors.blue,
              size: 40,
            ),
          ],
        ),
      ),
    );

    // Add destination marker if exists
    if (selectedDestination.value != null) {
      newMarkers.add(
        fm.Marker(
          width: 80,
          height: 80,
          point: selectedDestination.value!,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Đích đến',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
            ],
          ),
        ),
      );
    }

    markers.value = newMarkers;
  }

  // Calculate route from robot to destination using OSRM
  Future<void> calculateRoute() async {
    if (selectedDestination.value == null) return;

    try {
      isLoading.value = true;
      routeCoordinates.clear();
      polylines.clear();

      // Convert flutter_map LatLng to Google Maps LatLng for OSRM service
      final originGM = _toGoogleMapsLatLng(robotPosition.value);
      final destGM = _toGoogleMapsLatLng(selectedDestination.value!);

      // Sử dụng OSRM - miễn phí, không cần API key
      final route = await OSRMService.getRoute(
        origin: originGM,
        destination: destGM,
      );

      if (route.isNotEmpty) {
        // Convert Map to LatLng
        routeCoordinates.value = route.map((point) => 
          LatLng(point['latitude']!, point['longitude']!)
        ).toList();

        // Create polyline
        final polyline = fm.Polyline(
          points: routeCoordinates,
          color: const Color(0xFF4285F4),
          strokeWidth: 5,
        );

        polylines.add(polyline);

        // Fit bounds to show entire route
        _fitBounds();
        
        // Lấy thông tin khoảng cách và thời gian
        final routeInfo = await OSRMService.getRouteInfo(
          origin: originGM,
          destination: destGM,
        );
        
        Get.snackbar(
          'Thành công',
          'Lộ trình: ${routeInfo['distanceText']} - ${routeInfo['durationText']}\n${routeCoordinates.length} điểm',
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green[100],
        );
      } else {
        // Nếu không có kết quả, tạo đường thẳng
        _createStraightRoute();
        
        Get.snackbar(
          'Cảnh báo',
          'Không thể tính lộ trình.\nSử dụng đường thẳng thay thế.',
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.orange[100],
        );
      }
    } catch (e) {
      print('Error calculating route: $e');
      
      // Tạo đường thẳng như fallback
      _createStraightRoute();
      
      String errorMessage = 'Lỗi khi tính toán lộ trình';
      if (e.toString().contains('timeout')) {
        errorMessage = 'Timeout khi kết nối OSRM server.\nSử dụng đường thẳng thay thế.';
      } else if (e.toString().contains('No route found')) {
        errorMessage = 'Không tìm thấy lộ trình giữa 2 điểm.\nSử dụng đường thẳng thay thế.';
      } else {
        errorMessage = 'Lỗi: ${e.toString()}\nSử dụng đường thẳng thay thế.';
      }
      
      Get.snackbar(
        'Lỗi',
        errorMessage,
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.orange[100],
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Convert flutter_map LatLng to Google Maps LatLng
  dynamic _toGoogleMapsLatLng(LatLng point) {
    // Return a simple object that OSRM service can use
    return _LatLngAdapter(point.latitude, point.longitude);
  }

  // Create a straight line route as fallback
  void _createStraightRoute() {
    if (selectedDestination.value == null) return;

    // Tạo đường thẳng với 50 điểm giữa robot và đích
    routeCoordinates.clear();
    
    final latDiff = selectedDestination.value!.latitude - robotPosition.value.latitude;
    final lngDiff = selectedDestination.value!.longitude - robotPosition.value.longitude;
    
    for (int i = 0; i <= 50; i++) {
      final progress = i / 50.0;
      routeCoordinates.add(LatLng(
        robotPosition.value.latitude + (latDiff * progress),
        robotPosition.value.longitude + (lngDiff * progress),
      ));
    }

    // Create polyline
    final polyline = fm.Polyline(
      points: routeCoordinates,
      color: const Color(0xFFFF9800), // Orange color for fallback route
      strokeWidth: 5,
    );

    polylines.add(polyline);
    _fitBounds();
  }

  // Fit map bounds to show entire route
  void _fitBounds() {
    if (routeCoordinates.isEmpty) return;

    final bounds = fm.LatLngBounds.fromPoints(routeCoordinates);
    mapController.fitCamera(
      fm.CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  // Divide route into smaller segments
  List<RoutePoint> divideRouteIntoPoints({int segmentCount = 50}) {
    if (routeCoordinates.isEmpty) return [];

    List<RoutePoint> points = [];
    
    // If route has fewer points than desired segments, use all points
    if (routeCoordinates.length <= segmentCount) {
      for (int i = 0; i < routeCoordinates.length; i++) {
        points.add(RoutePoint(
          lat: routeCoordinates[i].latitude,
          lng: routeCoordinates[i].longitude,
          order: i,
        ));
      }
    } else {
      // Sample points evenly along the route
      double step = routeCoordinates.length / segmentCount;
      for (int i = 0; i < segmentCount; i++) {
        int index = (i * step).floor();
        if (index >= routeCoordinates.length) {
          index = routeCoordinates.length - 1;
        }
        points.add(RoutePoint(
          lat: routeCoordinates[index].latitude,
          lng: routeCoordinates[index].longitude,
          order: i,
        ));
      }
    }

    return points;
  }

  // Create delivery order with route
  Future<bool> createDeliveryOrder({
    required String receiverName,
    required int receiverAge,
    required String phoneNumber,
    required String goods,
    required double weight,
  }) async {
    if (selectedDestination.value == null) {
      Get.snackbar('Lỗi', 'Vui lòng chọn điểm giao hàng trên bản đồ');
      return false;
    }

    if (routeCoordinates.isEmpty) {
      Get.snackbar('Lỗi', 'Chưa có lộ trình. Vui lòng tính toán lộ trình trước');
      return false;
    }

    try {
      isLoading.value = true;

      // Divide route into points
      final routePoints = divideRouteIntoPoints(segmentCount: 50);

      // Create order
      final order = DeliveryOrder(
        receiverName: receiverName,
        receiverAge: receiverAge,
        phoneNumber: phoneNumber,
        goods: goods,
        weight: weight,
        destinationLat: selectedDestination.value!.latitude,
        destinationLng: selectedDestination.value!.longitude,
        routePoints: routePoints,
        status: 'pending',
      );

      final orderId = await _firebaseService.createDeliveryOrder(order);

      if (orderId != null) {
        Get.snackbar(
          'Thành công',
          'Đơn hàng đã được tạo với ID: $orderId',
          duration: const Duration(seconds: 3),
        );
        
        // Reset map
        clearMap();
        return true;
      } else {
        Get.snackbar('Lỗi', 'Không thể tạo đơn hàng');
        return false;
      }
    } catch (e) {
      print('Error creating delivery order: $e');
      Get.snackbar('Lỗi', 'Lỗi khi tạo đơn hàng: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Clear map
  void clearMap() {
    selectedDestination.value = null;
    routeCoordinates.clear();
    polylines.clear();
    _updateMarkers();
  }
}

// Adapter class for LatLng compatibility
class _LatLngAdapter {
  final double latitude;
  final double longitude;

  _LatLngAdapter(this.latitude, this.longitude);
}
