import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/delivery_order.dart';
import '../../../data/services/firebase_service.dart';

class OrdersController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  
  final RxList<DeliveryOrder> orders = <DeliveryOrder>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadOrders();
  }

  void loadOrders() {
    isLoading.value = true;
    _firebaseService.getOrders().listen((ordersList) {
      orders.value = ordersList;
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      isLoading.value = false;
    }, onError: (error) {
      print('Error loading orders: $error');
      isLoading.value = false;
      // Sử dụng snackbar sau khi frame render xong
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isSnackbarOpen != true) {
          Get.snackbar('Lỗi', 'Không thể tải danh sách đơn hàng');
        }
      });
    });
  }

  Future<void> deleteOrder(String orderId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa đơn hàng này?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _firebaseService.deleteOrder(orderId);
      // Chờ dialog đóng hoàn toàn
      await Future.delayed(const Duration(milliseconds: 100));
      if (success) {
        if (Get.isSnackbarOpen != true) {
          Get.snackbar('Thành công', 'Đã xóa đơn hàng');
        }
      } else {
        if (Get.isSnackbarOpen != true) {
          Get.snackbar('Lỗi', 'Không thể xóa đơn hàng');
        }
      }
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    final success = await _firebaseService.updateOrderStatus(orderId, status);
    await Future.delayed(const Duration(milliseconds: 100));
    if (success) {
      if (Get.isSnackbarOpen != true) {
        Get.snackbar('Thành công', 'Đã cập nhật trạng thái đơn hàng');
      }
    } else {
      if (Get.isSnackbarOpen != true) {
        Get.snackbar('Lỗi', 'Không thể cập nhật trạng thái');
      }
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'in_progress':
        return 'Đang giao';
      case 'completed':
        return 'Hoàn thành';
      default:
        return status;
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFFA726);
      case 'in_progress':
        return const Color(0xFF42A5F5);
      case 'completed':
        return const Color(0xFF66BB6A);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}
