import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import '../models/delivery_order.dart';

class FirebaseService extends GetxService {
  late DatabaseReference _database;

  Future<FirebaseService> init() async {
    _database = FirebaseDatabase.instance.ref();
    return this;
  }

  // Create a new delivery order
  Future<String?> createDeliveryOrder(DeliveryOrder order) async {
    try {
      final newOrderRef = _database.child('orders').push();
      final orderWithId = order.copyWith(id: newOrderRef.key);
      await newOrderRef.set(orderWithId.toJson());
      return newOrderRef.key;
    } catch (e) {
      print('Error creating order: $e');
      return null;
    }
  }

  // Update delivery order
  Future<bool> updateDeliveryOrder(DeliveryOrder order) async {
    try {
      if (order.id == null) return false;
      await _database.child('orders/${order.id}').update(order.toJson());
      return true;
    } catch (e) {
      print('Error updating order: $e');
      return false;
    }
  }

  // Get all orders
  Stream<List<DeliveryOrder>> getOrders() {
    return _database.child('orders').onValue.map((event) {
      final List<DeliveryOrder> orders = [];
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          try {
            // Convert nested maps recursively
            final orderMap = _convertMap(value as Map<dynamic, dynamic>);
            orders.add(DeliveryOrder.fromJson(orderMap, key));
          } catch (e) {
            print('Error parsing order $key: $e');
          }
        });
      }
      // Sort by created date, newest first
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  // Helper method to convert Map<dynamic, dynamic> to Map<String, dynamic> recursively
  Map<String, dynamic> _convertMap(Map<dynamic, dynamic> map) {
    final result = <String, dynamic>{};
    map.forEach((key, value) {
      if (value is Map) {
        result[key.toString()] = _convertMap(value);
      } else if (value is List) {
        result[key.toString()] = value.map((item) {
          if (item is Map) {
            return _convertMap(item);
          }
          return item;
        }).toList();
      } else {
        result[key.toString()] = value;
      }
    });
    return result;
  }

  // Get order by ID
  Future<DeliveryOrder?> getOrderById(String orderId) async {
    try {
      final snapshot = await _database.child('orders/$orderId').get();
      if (snapshot.exists) {
        final orderMap = _convertMap(snapshot.value as Map<dynamic, dynamic>);
        return DeliveryOrder.fromJson(orderMap, orderId);
      }
      return null;
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  // Delete order
  Future<bool> deleteOrder(String orderId) async {
    try {
      await _database.child('orders/$orderId').remove();
      return true;
    } catch (e) {
      print('Error deleting order: $e');
      return false;
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _database.child('orders/$orderId').update({'status': status});
      return true;
    } catch (e) {
      print('Error updating status: $e');
      return false;
    }
  }

  // Save route points for an order
  Future<bool> saveRoutePoints(String orderId, List<RoutePoint> points) async {
    try {
      await _database.child('orders/$orderId/routePoints').set(
        points.map((point) => point.toJson()).toList(),
      );
      return true;
    } catch (e) {
      print('Error saving route points: $e');
      return false;
    }
  }

  // Get robot position from Firebase (one-time fetch)
  // Returns Map if found, null if not found (will use default Hanoi coordinates)
  Future<Map<String, double>?> getRobotPosition() async {
    try {
      final snapshot = await _database.child('robot').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        
        // Xử lý cả trường hợp String và num
        double? lat;
        double? lon;
        
        if (data['lat'] != null) {
          if (data['lat'] is num) {
            lat = (data['lat'] as num).toDouble();
          } else if (data['lat'] is String) {
            lat = double.tryParse(data['lat'] as String);
          }
        }
        
        if (data['lon'] != null) {
          if (data['lon'] is num) {
            lon = (data['lon'] as num).toDouble();
          } else if (data['lon'] is String) {
            lon = double.tryParse(data['lon'] as String);
          }
        }
        
        if (lat != null && lon != null) {
          print('Robot position from Firebase: lat=$lat, lon=$lon');
          return {
            'latitude': lat,
            'longitude': lon,
          };
        } else {
          print('Invalid robot position data: lat=$lat, lon=$lon');
        }
      } else {
        print('No robot data found in Firebase');
      }
      // Nếu không có dữ liệu hoặc dữ liệu không hợp lệ, trả về null để dùng tọa độ mặc định Hà Nội
      return null;
    } catch (e) {
      print('Error getting robot position: $e');
      return null;
    }
  }

  // Listen to robot position changes in real-time (Stream)
  Stream<Map<String, double>?> getRobotPositionStream() {
    return _database.child('robot').onValue.map((event) {
      try {
        if (event.snapshot.exists) {
          final data = event.snapshot.value as Map<dynamic, dynamic>;
          
          // Xử lý cả trường hợp String và num
          double? lat;
          double? lon;
          
          if (data['lat'] != null) {
            if (data['lat'] is num) {
              lat = (data['lat'] as num).toDouble();
            } else if (data['lat'] is String) {
              lat = double.tryParse(data['lat'] as String);
            }
          }
          
          if (data['lon'] != null) {
            if (data['lon'] is num) {
              lon = (data['lon'] as num).toDouble();
            } else if (data['lon'] is String) {
              lon = double.tryParse(data['lon'] as String);
            }
          }
          
          if (lat != null && lon != null) {
            print('🤖 Robot position updated (real-time): lat=$lat, lon=$lon');
            return {
              'latitude': lat,
              'longitude': lon,
            };
          } else {
            print('Invalid robot position data in stream: lat=$lat, lon=$lon');
          }
        } else {
          print('No robot data in stream');
        }
        return null;
      } catch (e) {
        print('Error parsing robot position stream: $e');
        return null;
      }
    });
  }
}
