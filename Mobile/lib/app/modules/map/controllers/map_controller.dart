import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geolocator/geolocator.dart';
import 'package:robot_delivery/app/data/models/delivery_order.dart';
import 'package:robot_delivery/app/data/services/firebase_service.dart';
import 'package:robot_delivery/app/data/services/osrm_service.dart';

class MapController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  
  final fm.MapController mapController = fm.MapController();
  final Rx<LatLng?> currentLocation = Rx<LatLng?>(null);
  final Rx<LatLng?> selectedDestination = Rx<LatLng?>(null);
  final RxList<fm.Marker> markers = <fm.Marker>[].obs;
  final RxList<fm.Polyline> polylines = <fm.Polyline>[].obs;
  final RxList<LatLng> routeCoordinates = <LatLng>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isMapReady = false.obs; // Track if map is ready

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
    _startRobotPositionUpdates();
    // Don't call getCurrentLocation here - wait for map to be ready
  }

  @override
  void onClose() {
    _robotPositionSubscription?.cancel();
    super.onClose();
  }

  // Call this when map is ready
  void onMapReady() {
    isMapReady.value = true;
    // Focus vào vị trí robot ngay khi map sẵn sàng
    _focusOnRobot();
  }
  
  // Focus map về vị trí robot
  void _focusOnRobot() {
    if (isMapReady.value) {
      mapController.move(robotPosition.value, 15.0);
      _updateMarkers(); // Cập nhật markers để hiển thị robot
    }
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
          if (autoFollowRobot.value && isMapReady.value) {
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

      // Move camera to robot position - only if map is ready
      if (isMapReady.value) {
        try {
          mapController.move(robotPosition.value, 14);
        } catch (e) {
          print('Map controller error: $e');
        }
      }
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

      // Sử dụng OSRM - miễn phí, không cần API key
      final route = await OSRMService.getRoute(
        origin: robotPosition.value,
        destination: selectedDestination.value!,
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
          origin: robotPosition.value,
          destination: selectedDestination.value!,
        );
        
        await Future.delayed(const Duration(milliseconds: 100));
        if (Get.isSnackbarOpen != true) {
          Get.rawSnackbar(
            title: 'Thành công',
            message: 'Lộ trình: ${routeInfo['distanceText']} - ${routeInfo['durationText']}\n${routeCoordinates.length} điểm',
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green.shade100,
          );
        }
      } else {
        // Nếu không có kết quả, tạo đường thẳng
        _createStraightRoute();
        
        await Future.delayed(const Duration(milliseconds: 100));
        if (Get.isSnackbarOpen != true) {
          Get.rawSnackbar(
            title: 'Cảnh báo',
            message: 'Không thể tính lộ trình.\\nSử dụng đường thẳng thay thế.',
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.orange.shade100,
          );
        }
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
      
      await Future.delayed(const Duration(milliseconds: 100));
      if (Get.isSnackbarOpen != true) {
        Get.rawSnackbar(
          title: 'Lỗi',
          message: errorMessage,
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.orange.shade100,
        );
      }
    } finally {
      isLoading.value = false;
    }
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
      borderStrokeWidth: 2,
      borderColor: Colors.white,
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

  // Convert route coordinates to RoutePoint list
  // Nếu < 100 điểm: gửi tất cả
  // Nếu > 100 điểm: lấy mẫu đều đặn để chỉ còn 100 điểm
  List<RoutePoint> convertRouteToPoints() {
    if (routeCoordinates.isEmpty) return [];

    List<RoutePoint> points = [];
    final totalPoints = routeCoordinates.length;
    
    if (totalPoints <= 100) {
      // Ít hơn 100 điểm → gửi tất cả
      for (int i = 0; i < totalPoints; i++) {
        points.add(RoutePoint(
          lat: routeCoordinates[i].latitude,
          lng: routeCoordinates[i].longitude,
          order: i,
        ));
      }
    } else {
      // Nhiều hơn 100 điểm → lấy mẫu đều đặn chỉ 100 điểm
      final step = totalPoints / 100.0;
      for (int i = 0; i < 100; i++) {
        final index = (i * step).floor();
        final actualIndex = index >= totalPoints ? totalPoints - 1 : index;
        points.add(RoutePoint(
          lat: routeCoordinates[actualIndex].latitude,
          lng: routeCoordinates[actualIndex].longitude,
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

      // Chuyển điểm từ OSRM thành RoutePoint
      // Nếu > 100 điểm sẽ tự động lấy mẫu còn 100
      final routePoints = convertRouteToPoints();
      
      print('OSRM trả về ${routeCoordinates.length} điểm');
      print('Uploading ${routePoints.length} điểm lên Firebase');

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
          'Đơn hàng đã được tạo với ID: $orderId\n${routePoints.length} điểm lộ trình đã được lưu',
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
