import 'package:get/get.dart';
import '../modules/map/bindings/map_binding.dart';
import '../modules/map/views/map_view.dart';
import '../modules/orders/bindings/orders_binding.dart';
import '../modules/orders/views/orders_view.dart';

class AppRoutes {
  static const String home = '/';
  static const String orders = '/orders';
}

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.home,
      page: () => const MapView(),
      binding: MapBinding(),
    ),
    GetPage(
      name: AppRoutes.orders,
      page: () => const OrdersView(),
      binding: OrdersBinding(),
    ),
  ];
}
