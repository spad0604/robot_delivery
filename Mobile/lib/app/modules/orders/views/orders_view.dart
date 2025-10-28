import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/orders_controller.dart';
import 'order_detail_view.dart';

class OrdersView extends GetView<OrdersController> {
  const OrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.blue[600],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Đơn hàng',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue[700]!, Colors.blue[400]!],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Get.back(),
            ),
          ),

          // Order count
          Obx(() {
            if (controller.orders.isNotEmpty) {
              return SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[50]!, Colors.blue[100]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[600],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shopping_bag,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tổng số đơn hàng',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${controller.orders.length} đơn',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(),
                    ],
                  ),
                ),
              );
            }
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }),

          // Orders list
          Obx(() {
            if (controller.isLoading.value && controller.orders.isEmpty) {
              return const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Đang tải dữ liệu...',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (controller.orders.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Chưa có đơn hàng nào',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tạo đơn hàng mới từ màn hình bản đồ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.map),
                        label: const Text('Về bản đồ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final order = controller.orders[index];
                    return _buildOrderCard(order, index);
                  },
                  childCount: controller.orders.length,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final pending = controller.orders.where((o) => o.status == 'pending').length;
    final inProgress = controller.orders.where((o) => o.status == 'in_progress').length;
    final completed = controller.orders.where((o) => o.status == 'completed').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (pending > 0) _buildMiniTag('Chờ', pending, Colors.orange),
        if (inProgress > 0) _buildMiniTag('Giao', inProgress, Colors.blue),
        if (completed > 0) _buildMiniTag('Xong', completed, Colors.green),
      ],
    );
  }

  Widget _buildMiniTag(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$label: $count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(order, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.to(() => OrderDetailView(order: order)),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: controller.getStatusColor(order.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.local_shipping,
                        color: controller.getStatusColor(order.status),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.receiverName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.phoneNumber,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: controller.getStatusColor(order.status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        controller.getStatusText(order.status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Details
                _buildInfoRow(Icons.inventory_2_outlined, 'Hàng hóa', order.goods),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(Icons.scale_outlined, 'Khối lượng', '${order.weight} kg'),
                    ),
                    Expanded(
                      child: _buildInfoRow(Icons.route_outlined, 'Điểm', '${order.routePoints?.length ?? 0}'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(order.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        if (value == 'delete') {
                          controller.deleteOrder(order.id!);
                        } else {
                          controller.updateOrderStatus(order.id!, value);
                        }
                      },
                      itemBuilder: (context) => [
                        _buildMenuItem(Icons.schedule, 'Chờ xử lý', 'pending', Colors.orange),
                        _buildMenuItem(Icons.local_shipping, 'Đang giao', 'in_progress', Colors.blue),
                        _buildMenuItem(Icons.check_circle, 'Hoàn thành', 'completed', Colors.green),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red[600]),
                              const SizedBox(width: 12),
                              Text(
                                'Xóa đơn hàng',
                                style: TextStyle(color: Colors.red[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(IconData icon, String text, String value, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
