import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:robot_delivery/app/data/models/delivery_order.dart';
import 'package:robot_delivery/app/data/services/firebase_service.dart';
import 'package:robot_delivery/app/data/services/osrm_service.dart';

class MapController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  
  GoogleMapController? mapController;
  final Rx<LatLng?> currentLocation = Rx<LatLng?>(null);
  final Rx<LatLng?> selectedDestination = Rx<LatLng?>(null);
  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxSet<Polyline> polylines = <Polyline>{}.obs;
  final RxList<LatLng> routeCoordinates = <LatLng>[].obs;
  final RxBool isLoading = false.obs;

  // Robot starting position (có thể cấu hình theo vị trí thực tế)
  final LatLng robotStartPosition = const LatLng(10.762622, 106.660172); // TP.HCM

  @override
  void onInit() {
    super.onInit();
    getCurrentLocation();
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
      
      // Add robot marker
      addMarker(
        robotStartPosition,
        'robot',
        'Vị trí Robot',
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );

      // Move camera to robot position
      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(robotStartPosition, 14),
      );
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
    
    // Add destination marker
    addMarker(
      position,
      'destination',
      'Điểm giao hàng',
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    // Calculate route
    calculateRoute();
  }

  // Add marker to map
  void addMarker(LatLng position, String id, String title, BitmapDescriptor icon) {
    final marker = Marker(
      markerId: MarkerId(id),
      position: position,
      infoWindow: InfoWindow(title: title),
      icon: icon,
    );
    
    markers.removeWhere((m) => m.markerId.value == id);
    markers.add(marker);
  }

  // Calculate route from robot to destination using OSRM (Free, no API key needed)
  Future<void> calculateRoute() async {
    if (selectedDestination.value == null) return;

    try {
      isLoading.value = true;
      routeCoordinates.clear();
      polylines.clear();

      // Sử dụng OSRM - miễn phí, không cần API key
      final route = await OSRMService.getRoute(
        origin: robotStartPosition,
        destination: selectedDestination.value!,
      );

      if (route.isNotEmpty) {
        routeCoordinates.value = route;

        // Create polyline
        final polyline = Polyline(
          polylineId: const PolylineId('route'),
          color: const Color(0xFF4285F4),
          width: 5,
          points: routeCoordinates,
        );

        polylines.add(polyline);

        // Fit bounds to show entire route
        _fitBounds();
        
        // Lấy thông tin khoảng cách và thời gian
        final routeInfo = await OSRMService.getRouteInfo(
          origin: robotStartPosition,
          destination: selectedDestination.value!,
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

  // Create a straight line route as fallback
  void _createStraightRoute() {
    if (selectedDestination.value == null) return;

    // Tạo đường thẳng với 50 điểm giữa robot và đích
    routeCoordinates.clear();
    
    final latDiff = selectedDestination.value!.latitude - robotStartPosition.latitude;
    final lngDiff = selectedDestination.value!.longitude - robotStartPosition.longitude;
    
    for (int i = 0; i <= 50; i++) {
      final progress = i / 50.0;
      routeCoordinates.add(LatLng(
        robotStartPosition.latitude + (latDiff * progress),
        robotStartPosition.longitude + (lngDiff * progress),
      ));
    }

    // Create polyline
    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      color: const Color(0xFFFF9800), // Orange color for fallback route
      width: 5,
      points: routeCoordinates,
      patterns: [PatternItem.dash(20), PatternItem.gap(10)], // Dashed line
    );

    polylines.add(polyline);
    _fitBounds();
  }

  // Fit map bounds to show entire route
  void _fitBounds() {
    if (mapController == null || routeCoordinates.isEmpty) return;

    LatLngBounds bounds;
    if (routeCoordinates.length == 1) {
      bounds = LatLngBounds(
        southwest: routeCoordinates.first,
        northeast: routeCoordinates.first,
      );
    } else {
      double minLat = routeCoordinates.first.latitude;
      double maxLat = routeCoordinates.first.latitude;
      double minLng = routeCoordinates.first.longitude;
      double maxLng = routeCoordinates.first.longitude;

      for (var coord in routeCoordinates) {
        if (coord.latitude < minLat) minLat = coord.latitude;
        if (coord.latitude > maxLat) maxLat = coord.latitude;
        if (coord.longitude < minLng) minLng = coord.longitude;
        if (coord.longitude > maxLng) maxLng = coord.longitude;
      }

      bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
    }

    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
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
    markers.removeWhere((m) => m.markerId.value == 'destination');
  }

  @override
  void onClose() {
    mapController?.dispose();
    super.onClose();
  }
}
