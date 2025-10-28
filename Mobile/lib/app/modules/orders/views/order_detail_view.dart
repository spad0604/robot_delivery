import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/models/delivery_order.dart';

class OrderDetailView extends StatefulWidget {
  final DeliveryOrder order;

  const OrderDetailView({super.key, required this.order});

  @override
  State<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<OrderDetailView> {
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    _setupMapData();
  }

  void _setupMapData() {
    // Add destination marker
    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(widget.order.destinationLat, widget.order.destinationLng),
        infoWindow: InfoWindow(title: widget.order.receiverName),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    // Add robot start marker
    markers.add(
      Marker(
        markerId: const MarkerId('robot'),
        position: const LatLng(10.762622, 106.660172),
        infoWindow: const InfoWindow(title: 'Vị trí Robot'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    // Add route polyline if available
    if (widget.order.routePoints != null && widget.order.routePoints!.isNotEmpty) {
      List<LatLng> routeCoords = widget.order.routePoints!
          .map((point) => LatLng(point.lat, point.lng))
          .toList();

      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          color: const Color(0xFF4285F4),
          width: 5,
          points: routeCoords,
        ),
      );
    }
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
          // Map section
          SizedBox(
            height: 300,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.order.destinationLat, widget.order.destinationLng),
                zoom: 13,
              ),
              markers: markers,
              polylines: polylines,
              onMapCreated: (controller) {
                mapController = controller;
                _fitBounds();
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
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
                  const SizedBox(height: 16),
                  
                  if (widget.order.routePoints != null && widget.order.routePoints!.isNotEmpty) ...[
                    _buildSectionTitle('Dữ liệu lộ trình (JSON)'),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          _getRouteJson(),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
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

  void _fitBounds() {
    if (mapController == null) return;
    if (widget.order.routePoints == null || widget.order.routePoints!.isEmpty) return;

    final coords = widget.order.routePoints!
        .map((point) => LatLng(point.lat, point.lng))
        .toList();

    if (coords.isEmpty) return;

    double minLat = coords.first.latitude;
    double maxLat = coords.first.latitude;
    double minLng = coords.first.longitude;
    double maxLng = coords.first.longitude;

    for (var coord in coords) {
      if (coord.latitude < minLat) minLat = coord.latitude;
      if (coord.latitude > maxLat) maxLat = coord.latitude;
      if (coord.longitude < minLng) minLng = coord.longitude;
      if (coord.longitude > maxLng) maxLng = coord.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }
}
