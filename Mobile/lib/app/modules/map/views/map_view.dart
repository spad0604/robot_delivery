import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../controllers/map_controller.dart';

class MapView extends GetView<MapController> {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map - wrapped in Obx to update markers and polylines
          Obx(() {
            final markers = controller.markers;
            final polylines = controller.polylines;
            
            return GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(10.762622, 106.660172),
                zoom: 14,
              ),
              onMapCreated: (GoogleMapController mapController) {
                controller.mapController = mapController;
              },
              markers: markers,
              polylines: polylines,
              onTap: (LatLng position) {
                controller.setDestination(position);
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
            );
          }),

          // Top App Bar with gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.smart_toy, color: Colors.blue[700], size: 28),
                            const SizedBox(width: 8),
                            const Text(
                              'Robot Delivery',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      _buildActionButton(
                        icon: Icons.list_rounded,
                        onTap: () => Get.toNamed('/orders'),
                        tooltip: 'Danh sách đơn',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          Obx(() {
            if (controller.isLoading.value) {
              return Container(
                color: Colors.black26,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Đang tính toán lộ trình...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Bottom info card
          Obx(() {
            if (controller.selectedDestination.value != null) {
              return Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[600]!, Colors.blue[400]!],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Điểm giao hàng đã chọn',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: controller.clearMap,
                            ),
                          ],
                        ),
                      ),
                      
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              Icons.my_location,
                              'Vĩ độ',
                              controller.selectedDestination.value!.latitude.toStringAsFixed(6),
                              Colors.blue,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.my_location,
                              'Kinh độ',
                              controller.selectedDestination.value!.longitude.toStringAsFixed(6),
                              Colors.green,
                            ),
                            if (controller.routeCoordinates.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.route,
                                'Số điểm lộ trình',
                                '${controller.routeCoordinates.length} điểm',
                                Colors.orange,
                              ),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () => _showOrderForm(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_shopping_cart),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Tạo đơn hàng',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Floating action buttons
          Obx(() {
            final hasDestination = controller.selectedDestination.value != null;
            
            return Positioned(
              right: 16,
              bottom: hasDestination ? 280 : 100,
              child: Column(
                children: [
                  _buildFloatingButton(
                    icon: Icons.my_location,
                    onTap: () {
                      if (controller.mapController != null) {
                        controller.mapController!.animateCamera(
                          CameraUpdate.newLatLngZoom(controller.robotStartPosition, 14),
                        );
                      }
                    },
                    tooltip: 'Về vị trí Robot',
                  ),
                  const SizedBox(height: 12),
                  _buildFloatingButton(
                    icon: Icons.zoom_in,
                    onTap: () {
                      controller.mapController?.animateCamera(
                        CameraUpdate.zoomIn(),
                      );
                    },
                    tooltip: 'Phóng to',
                  ),
                  const SizedBox(height: 12),
                  _buildFloatingButton(
                    icon: Icons.zoom_out,
                    onTap: () {
                      controller.mapController?.animateCamera(
                        CameraUpdate.zoomOut(),
                      );
                    },
                    tooltip: 'Thu nhỏ',
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: Colors.blue[700]),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: Colors.blue[700], size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderForm(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final phoneController = TextEditingController();
    final goodsController = TextEditingController();
    final weightController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.shopping_bag, color: Colors.blue[700], size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thông tin đơn hàng',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Điền đầy đủ thông tin bên dưới',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Form fields
                  _buildTextField(
                    controller: nameController,
                    label: 'Tên người nhận',
                    icon: Icons.person_outline,
                    hint: 'Nhập tên người nhận',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tên người nhận';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: ageController,
                          label: 'Tuổi',
                          icon: Icons.cake_outlined,
                          hint: 'Tuổi',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nhập tuổi';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Số không hợp lệ';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _buildTextField(
                          controller: phoneController,
                          label: 'Số điện thoại',
                          icon: Icons.phone_outlined,
                          hint: '0901234567',
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nhập SĐT';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: goodsController,
                    label: 'Mô tả hàng hóa',
                    icon: Icons.inventory_2_outlined,
                    hint: 'Thực phẩm, đồ điện tử...',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mô tả hàng hóa';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: weightController,
                    label: 'Cân nặng (kg)',
                    icon: Icons.scale_outlined,
                    hint: '5.5',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập cân nặng';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Số không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          // Lấy giá trị trước khi đóng dialog
                          final name = nameController.text;
                          final age = int.parse(ageController.text);
                          final phone = phoneController.text;
                          final goods = goodsController.text;
                          final weight = double.parse(weightController.text);
                          
                          // Đóng dialog
                          Navigator.pop(context);
                          
                          // Tạo đơn hàng
                          await controller.createDeliveryOrder(
                            receiverName: name,
                            receiverAge: age,
                            phoneNumber: phone,
                            goods: goods,
                            weight: weight,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'Xác nhận tạo đơn',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      // Dispose controllers sau khi dialog đóng hoàn toàn
      nameController.dispose();
      ageController.dispose();
      phoneController.dispose();
      goodsController.dispose();
      weightController.dispose();
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue[700]),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
