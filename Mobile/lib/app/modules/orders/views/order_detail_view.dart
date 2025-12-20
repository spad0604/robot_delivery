import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import '../../../data/models/delivery_order.dart';
import '../../../data/services/firebase_service.dart';

class OrderDetailView extends StatefulWidget {
  final DeliveryOrder order;

  const OrderDetailView({super.key, required this.order});

  @override
  State<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<OrderDetailView> {
  final fm.MapController mapController = fm.MapController();
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  LatLng? robotPosition;
  List<fm.Marker> markers = [];
  List<fm.Polyline> polylines = [];

  @override
  void initState() {
    super.initState();
    _setupMapData();
  }

  Future<void> _setupMapData() async {
    // Lấy vị trí robot từ Firebase
    final position = await _firebaseService.getRobotPosition();
    if (position != null) {
      robotPosition = LatLng(position['latitude']!, position['longitude']!);
    } else {
      // Vị trí mặc định nếu không lấy được
      robotPosition = const LatLng(21.028511, 105.804817);
    }

    // Tạo markers
    _createMarkers();
    
    // Tạo polyline nếu có route points
    _createPolyline();
    
    setState(() {});
    
    // Fit bounds sau khi map render
    Future.delayed(const Duration(milliseconds: 500), () {
      _fitBounds();
    });
  }

  void _createMarkers() {
    markers.clear();

    // Robot marker
    if (robotPosition != null) {
      markers.add(
        fm.Marker(
          width: 80,
          height: 80,
          point: robotPosition!,
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
                    color: Colors.blue,
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
    }

    // Destination marker
    markers.add(
      fm.Marker(
        width: 80,
        height: 80,
        point: LatLng(widget.order.destinationLat, widget.order.destinationLng),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.order.receiverName,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
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

  void _createPolyline() {
    polylines.clear();
    
    if (widget.order.routePoints != null && widget.order.routePoints!.isNotEmpty) {
      List<LatLng> routeCoords = widget.order.routePoints!
          .map((point) => LatLng(point.lat, point.lng))
          .toList();

      polylines.add(
        fm.Polyline(
          points: routeCoords,
          color: const Color(0xFF4285F4),
          strokeWidth: 4,
        ),
      );
    }
  }

  void _fitBounds() {
    if (robotPosition == null) return;
    
    List<LatLng> points = [
      robotPosition!,
      LatLng(widget.order.destinationLat, widget.order.destinationLng),
    ];

    final bounds = fm.LatLngBounds.fromPoints(points);
    mapController.fitCamera(
      fm.CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Map section - OpenStreetMap
          SizedBox(
            height: 300,
            child: robotPosition == null
                ? Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : fm.FlutterMap(
                    mapController: mapController,
                    options: fm.MapOptions(
                      initialCenter: LatLng(
                        widget.order.destinationLat,
                        widget.order.destinationLng,
                      ),
                      initialZoom: 13,
                      minZoom: 5,
                      maxZoom: 18,
                    ),
                    children: [
                      // Tile Layer - OpenStreetMap
                      fm.TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.robot_delivery',
                        maxZoom: 19,
                        tileProvider: fm.NetworkTileProvider(),
                      ),
                      
                      // Polyline Layer
                      if (polylines.isNotEmpty)
                        fm.PolylineLayer(
                          polylines: polylines,
                        ),
                      
                      // Marker Layer
                      fm.MarkerLayer(
                        markers: markers,
                      ),
                    ],
                  ),
          ),

          // Order details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Thông tin người nhận'),
                  _buildInfoCard([
                    _buildInfoRow(Icons.person, 'Tên', widget.order.receiverName),
                    _buildInfoRow(Icons.cake, 'Tuổi', '${widget.order.receiverAge}'),
                    _buildInfoRow(Icons.phone, 'Số điện thoại', widget.order.phoneNumber),
                  ]),
                  const SizedBox(height: 16),
                  
                  _buildSectionTitle('Thông tin hàng hóa'),
                  _buildInfoCard([
                    _buildInfoRow(Icons.inventory_2, 'Hàng hóa', widget.order.goods),
                    _buildInfoRow(Icons.scale, 'Cân nặng', '${widget.order.weight} kg'),
                  ]),
                  const SizedBox(height: 16),
                  
                  _buildSectionTitle('Thông tin giao hàng'),
                  _buildInfoCard([
                    _buildInfoRow(
                      Icons.location_on,
                      'Điểm giao',
                      '${widget.order.destinationLat.toStringAsFixed(6)}, ${widget.order.destinationLng.toStringAsFixed(6)}',
                    ),
                    _buildInfoRow(
                      Icons.route,
                      'Số điểm lộ trình',
                      '${widget.order.routePoints?.length ?? 0} điểm',
                    ),
                    _buildInfoRow(
                      Icons.access_time,
                      'Thời gian tạo',
                      _formatDate(widget.order.createdAt),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
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
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getRouteJson() {
    if (widget.order.routePoints == null) return '[]';
    
    final points = widget.order.routePoints!
        .map((p) => '{"lat": ${p.lat}, "lng": ${p.lng}, "order": ${p.order}}')
        .join(',\n  ');
    
    return '[\n  $points\n]';
  }
}
