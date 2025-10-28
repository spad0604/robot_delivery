class DeliveryOrder {
  final String? id;
  final String receiverName;
  final int receiverAge;
  final String phoneNumber;
  final String goods;
  final double weight;
  final double destinationLat;
  final double destinationLng;
  final List<RoutePoint>? routePoints;
  final String status; // pending, in_progress, completed
  final DateTime createdAt;

  DeliveryOrder({
    this.id,
    required this.receiverName,
    required this.receiverAge,
    required this.phoneNumber,
    required this.goods,
    required this.weight,
    required this.destinationLat,
    required this.destinationLng,
    this.routePoints,
    this.status = 'pending',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receiverName': receiverName,
      'receiverAge': receiverAge,
      'phoneNumber': phoneNumber,
      'goods': goods,
      'weight': weight,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'routePoints': routePoints?.map((point) => point.toJson()).toList(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DeliveryOrder.fromJson(Map<String, dynamic> json, String key) {
    return DeliveryOrder(
      id: key,
      receiverName: json['receiverName'] ?? '',
      receiverAge: json['receiverAge'] ?? 0,
      phoneNumber: json['phoneNumber'] ?? '',
      goods: json['goods'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      destinationLat: (json['destinationLat'] ?? 0).toDouble(),
      destinationLng: (json['destinationLng'] ?? 0).toDouble(),
      routePoints: json['routePoints'] != null
          ? (json['routePoints'] as List)
              .map((point) => RoutePoint.fromJson(point))
              .toList()
          : null,
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  DeliveryOrder copyWith({
    String? id,
    String? receiverName,
    int? receiverAge,
    String? phoneNumber,
    String? goods,
    double? weight,
    double? destinationLat,
    double? destinationLng,
    List<RoutePoint>? routePoints,
    String? status,
    DateTime? createdAt,
  }) {
    return DeliveryOrder(
      id: id ?? this.id,
      receiverName: receiverName ?? this.receiverName,
      receiverAge: receiverAge ?? this.receiverAge,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      goods: goods ?? this.goods,
      weight: weight ?? this.weight,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      routePoints: routePoints ?? this.routePoints,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class RoutePoint {
  final double lat;
  final double lng;
  final int order;

  RoutePoint({
    required this.lat,
    required this.lng,
    required this.order,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'order': order,
    };
  }

  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    return RoutePoint(
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      order: json['order'] ?? 0,
    );
  }
}
