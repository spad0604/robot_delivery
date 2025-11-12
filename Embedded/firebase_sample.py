"""
Firebase Realtime Database Client
Đẩy vị trí robot và lấy dữ liệu từ Firebase Realtime Database
"""

import requests
import json
import time
import random
import math
from typing import Any, Callable, Dict, List, Optional, Tuple
from dataclasses import dataclass, asdict
from datetime import datetime


# ==================== MODELS ====================

@dataclass
class RoutePoint:
    """Điểm trên lộ trình"""
    lat: float
    lng: float
    order: int
    
    def to_dict(self) -> dict:
        return {
            "lat": self.lat,
            "lng": self.lng,
            "order": self.order
        }
    
    @classmethod
    def from_dict(cls, data: dict) -> 'RoutePoint':
        return cls(
            lat=float(data["lat"]),
            lng=float(data["lng"]),
            order=int(data["order"])
        )


@dataclass
class Order:
    """Đơn hàng giao hàng"""
    id: str
    createdAt: str
    destinationLat: float
    destinationLng: float
    goods: str
    phoneNumber: str
    receiverAge: int
    receiverName: str
    routePoints: List[RoutePoint]
    status: str  # "pending", "in_progress", "completed"
    weight: float
    
    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "createdAt": self.createdAt,
            "destinationLat": self.destinationLat,
            "destinationLng": self.destinationLng,
            "goods": self.goods,
            "phoneNumber": self.phoneNumber,
            "receiverAge": self.receiverAge,
            "receiverName": self.receiverName,
            "routePoints": [rp.to_dict() for rp in self.routePoints],
            "status": self.status,
            "weight": self.weight
        }
    
    @classmethod
    def from_dict(cls, data: dict, order_id: Optional[str] = None) -> 'Order':
        return cls(
            id=order_id or data.get("id", ""),
            createdAt=data["createdAt"],
            destinationLat=float(data["destinationLat"]),
            destinationLng=float(data["destinationLng"]),
            goods=data["goods"],
            phoneNumber=data["phoneNumber"],
            receiverAge=int(data["receiverAge"]),
            receiverName=data["receiverName"],
            routePoints=[RoutePoint.from_dict(rp) for rp in data["routePoints"]],
            status=data["status"],
            weight=float(data["weight"])
        )


@dataclass
class Robot:
    """Vị trí robot"""
    lat: float
    lon: float  # Note: trong JSON là "lon" nhưng trong model có thể dùng "lng"
    
    def to_dict(self) -> dict:
        return {
            "lat": self.lat,
            "lon": self.lon
        }
    
    @classmethod
    def from_dict(cls, data: dict) -> 'Robot':
        return cls(
            lat=float(data["lat"]),
            lon=float(data.get("lon", data.get("lng", 0.0)))
        )


@dataclass
class DatabaseData:
    """Toàn bộ dữ liệu từ Firebase"""
    orders: Dict[str, Order]
    robot: Robot
    
    @classmethod
    def from_dict(cls, data: dict) -> 'DatabaseData':
        orders = {}
        if "orders" in data and data["orders"]:
            for order_id, order_data in data["orders"].items():
                orders[order_id] = Order.from_dict(order_data, order_id)
        
        robot = Robot.from_dict(data.get("robot", {"lat": 0.0, "lon": 0.0}))
        
        return cls(orders=orders, robot=robot)


# ==================== FIREBASE CLIENT ====================

class FirebaseClient:
    """Client để tương tác với Firebase Realtime Database"""
    
    def __init__(self, database_url: str):
        """
        Khởi tạo Firebase Client
        
        Args:
            database_url: URL của Firebase Realtime Database
                         Ví dụ: https://robot-delivery-cbdcf-default-rtdb.firebaseio.com
        """
        # Đảm bảo URL không có dấu / ở cuối
        self.base_url = database_url.rstrip('/')
    
    def _make_request(self, method: str, path: str = "", data: Optional[dict] = None) -> Optional[dict]:
        """
        Thực hiện HTTP request đến Firebase
        
        Args:
            method: HTTP method (GET, PUT, PATCH, POST, DELETE)
            path: Đường dẫn trong database (ví dụ: "robot", "orders/-OdiO9pdXUIykq5vwqyL")
            data: Dữ liệu để gửi (nếu có)
        
        Returns:
            Response data dưới dạng dict hoặc None nếu có lỗi
        """
        # Tạo URL đúng định dạng Firebase: base_url/path.json hoặc base_url/.json cho root
        if path:
            url = f"{self.base_url}/{path}.json"
        else:
            url = f"{self.base_url}/.json"
        
        try:
            if method.upper() == "GET":
                response = requests.get(url, timeout=10)
            elif method.upper() == "PUT":
                response = requests.put(url, json=data, timeout=10)
            elif method.upper() == "PATCH":
                response = requests.patch(url, json=data, timeout=10)
            elif method.upper() == "POST":
                response = requests.post(url, json=data, timeout=10)
            elif method.upper() == "DELETE":
                response = requests.delete(url, timeout=10)
            else:
                raise ValueError(f"Unsupported HTTP method: {method}")
            
            response.raise_for_status()
            
            # Firebase trả về null nếu không có dữ liệu
            if response.text == "null":
                return None
            
            return response.json()
        
        except requests.exceptions.RequestException as e:
            print(f"Lỗi khi thực hiện request: {e}")
            return None
        except json.JSONDecodeError as e:
            print(f"Lỗi khi parse JSON: {e}")
            return None
    
    def update_robot_location(self, lat: float, lon: float) -> bool:
        """
        Cập nhật vị trí robot lên Firebase
        
        Args:
            lat: Vĩ độ
            lon: Kinh độ
        
        Returns:
            True nếu thành công, False nếu có lỗi
        """
        robot_data = {
            "lat": lat,
            "lon": lon
        }
        
        result = self._make_request("PUT", "robot", robot_data)
        return result is not None
    
    def get_robot_location(self) -> Optional[Robot]:
        """
        Lấy vị trí robot từ Firebase
        
        Returns:
            Robot object hoặc None nếu có lỗi
        """
        data = self._make_request("GET", "robot")
        if data is None:
            return None
        
        try:
            return Robot.from_dict(data)
        except (KeyError, ValueError) as e:
            print(f"Lỗi khi parse robot data: {e}")
            return None
    
    def get_all_orders(self) -> Dict[str, Order]:
        """
        Lấy tất cả đơn hàng từ Firebase
        
        Returns:
            Dictionary với key là order_id và value là Order object
        """
        data = self._make_request("GET", "orders")
        if data is None:
            return {}
        
        orders = {}
        try:
            for order_id, order_data in data.items():
                orders[order_id] = Order.from_dict(order_data, order_id)
        except (KeyError, ValueError) as e:
            print(f"Lỗi khi parse orders data: {e}")
        
        return orders
    
    def get_order(self, order_id: str) -> Optional[Order]:
        """
        Lấy một đơn hàng cụ thể từ Firebase
        
        Args:
            order_id: ID của đơn hàng
        
        Returns:
            Order object hoặc None nếu không tìm thấy hoặc có lỗi
        """
        data = self._make_request("GET", f"orders/{order_id}")
        if data is None:
            return None
        
        try:
            return Order.from_dict(data, order_id)
        except (KeyError, ValueError) as e:
            print(f"Lỗi khi parse order data: {e}")
            return None
    
    def get_all_data(self) -> Optional[DatabaseData]:
        """
        Lấy toàn bộ dữ liệu từ Firebase (orders + robot)
        
        Returns:
            DatabaseData object hoặc None nếu có lỗi
        """
        data = self._make_request("GET")
        if data is None:
            return None
        
        try:
            return DatabaseData.from_dict(data)
        except (KeyError, ValueError) as e:
            print(f"Lỗi khi parse database data: {e}")
            return None

    def listen_orders(
        self,
        on_change: Callable[[List[Order], Dict[str, Any], str], None],
        on_error: Optional[Callable[[Exception], None]] = None,
        retry_delay_seconds: float = 5.0,
    ) -> None:
        """
        Lắng nghe thay đổi của danh sách đơn hàng theo thời gian thực.

        Args:
            on_change: Callback khi có thay đổi. Tham số gồm:
                - danh sách Order đã được sắp xếp giảm dần theo createdAt
                - payload gốc từ Firebase (dict)
                - event_type (put, patch, keep-alive, ...)
            on_error: Callback khi có lỗi (optional). Nếu không truyền sẽ in ra console.
            retry_delay_seconds: Thời gian chờ trước khi thử kết nối lại khi gặp lỗi.

        Ví dụ:

            def handle_change(orders, payload, event_type):
                print(f\"Có {len(orders)} đơn hàng (event={event_type})\")

            firebase.listen_orders(handle_change)
        """
        url = f"{self.base_url}/orders.json"
        headers = {"Accept": "text/event-stream"}
        params = {"print": "silent"}  # Giảm dung lượng dữ liệu

        def _emit_error(exc: Exception) -> None:
            if on_error:
                on_error(exc)
            else:
                print(f"Lỗi stream orders: {exc}")

        while True:
            try:
                with requests.get(
                    url,
                    stream=True,
                    headers=headers,
                    params=params,
                    timeout=60,
                ) as response:
                    response.raise_for_status()

                    event_type: Optional[str] = None
                    data_buffer: List[str] = []

                    for raw_line in response.iter_lines(decode_unicode=True):
                        if raw_line is None:
                            continue

                        line = raw_line.strip()

                        # Dòng trống => kết thúc một event
                        if line == "":
                            if not data_buffer:
                                event_type = None
                                continue

                            try:
                                payload_str = "\n".join(data_buffer).strip()
                                payload: Dict[str, Any] = (
                                    json.loads(payload_str) if payload_str else {}
                                )
                            except json.JSONDecodeError as exc:
                                _emit_error(exc)
                                data_buffer = []
                                event_type = None
                                continue

                            # Lấy lại toàn bộ danh sách đơn hàng (đảm bảo đồng bộ)
                            orders_dict = self.get_all_orders()
                            orders_list = sorted(
                                orders_dict.values(),
                                key=lambda o: o.createdAt,
                                reverse=True,
                            )

                            try:
                                on_change(orders_list, payload, event_type or "message")
                            except Exception as callback_exc:  # pragma: no cover
                                _emit_error(callback_exc)

                            data_buffer = []
                            event_type = None
                            continue

                        if line.startswith("event:"):
                            event_type = line[len("event:") :].strip()
                        elif line.startswith("data:"):
                            data_buffer.append(line[len("data:") :].strip())
                        else:
                            # Các dòng khác (ví dụ comment bắt đầu bằng ':') bỏ qua
                            continue

            except KeyboardInterrupt:
                print("\nĐã dừng lắng nghe đơn hàng (KeyboardInterrupt)")
                break
            except requests.exceptions.RequestException as exc:
                _emit_error(exc)
            except Exception as exc:  # pragma: no cover
                _emit_error(exc)

            time.sleep(retry_delay_seconds)


# ==================== HELPER FUNCTIONS ====================

def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Tính khoảng cách giữa 2 điểm tọa độ (Haversine formula)
    Trả về khoảng cách tính bằng mét
    
    Args:
        lat1, lon1: Tọa độ điểm 1
        lat2, lon2: Tọa độ điểm 2
    
    Returns:
        Khoảng cách tính bằng mét
    """
    R = 6371000  # Bán kính Trái Đất tính bằng mét
    
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)
    
    a = math.sin(delta_phi / 2) ** 2 + \
        math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2) ** 2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    
    return R * c


def generate_next_location(current_lat: float, current_lon: float, 
                          max_distance_meters: float = 200.0) -> Tuple[float, float]:
    """
    Tạo tọa độ mới trong phạm vi Hà Nội, không quá xa điểm hiện tại
    
    Args:
        current_lat: Vĩ độ hiện tại
        current_lon: Kinh độ hiện tại
        max_distance_meters: Khoảng cách tối đa từ điểm hiện tại (mét), mặc định 200m
    
    Returns:
        Tuple (lat, lon) mới
    """
    # Phạm vi Hà Nội (trung tâm)
    # lat: 20.9 - 21.1, lon: 105.7 - 105.9
    HANOI_LAT_MIN = 20.9
    HANOI_LAT_MAX = 21.1
    HANOI_LON_MIN = 105.7
    HANOI_LON_MAX = 105.9
    
    # Chuyển đổi khoảng cách từ mét sang độ (xấp xỉ)
    # 1 độ lat ≈ 111,000 mét
    # 1 độ lon ≈ 111,000 * cos(lat) mét
    lat_degree_per_meter = 1.0 / 111000.0
    lon_degree_per_meter = 1.0 / (111000.0 * math.cos(math.radians(current_lat)))
    
    max_lat_delta = max_distance_meters * lat_degree_per_meter
    max_lon_delta = max_distance_meters * lon_degree_per_meter
    
    # Tạo tọa độ mới trong phạm vi cho phép
    attempts = 0
    while attempts < 50:  # Thử tối đa 50 lần
        # Tạo tọa độ ngẫu nhiên trong phạm vi
        new_lat = current_lat + random.uniform(-max_lat_delta, max_lat_delta)
        new_lon = current_lon + random.uniform(-max_lon_delta, max_lon_delta)
        
        # Đảm bảo trong phạm vi Hà Nội
        new_lat = max(HANOI_LAT_MIN, min(HANOI_LAT_MAX, new_lat))
        new_lon = max(HANOI_LON_MIN, min(HANOI_LON_MAX, new_lon))
        
        # Kiểm tra khoảng cách
        distance = calculate_distance(current_lat, current_lon, new_lat, new_lon)
        if distance <= max_distance_meters:
            return (new_lat, new_lon)
        
        attempts += 1
    
    # Nếu không tìm được trong phạm vi, trả về điểm gần nhất trong phạm vi
    new_lat = current_lat + random.uniform(-max_lat_delta * 0.5, max_lat_delta * 0.5)
    new_lon = current_lon + random.uniform(-max_lon_delta * 0.5, max_lon_delta * 0.5)
    new_lat = max(HANOI_LAT_MIN, min(HANOI_LAT_MAX, new_lat))
    new_lon = max(HANOI_LON_MIN, min(HANOI_LON_MAX, new_lon))
    
    return (new_lat, new_lon)


def run_periodic_location_update(firebase_client: FirebaseClient, 
                                interval_seconds: int = 10,
                                max_distance_meters: float = 200.0,
                                initial_lat: Optional[float] = None,
                                initial_lon: Optional[float] = None):
    """
    Chạy định kỳ đẩy tọa độ robot lên Firebase
    
    Args:
        firebase_client: FirebaseClient instance
        interval_seconds: Khoảng thời gian giữa các lần cập nhật (giây), mặc định 10s
        max_distance_meters: Khoảng cách tối đa giữa các điểm (mét), mặc định 200m
        initial_lat: Vĩ độ ban đầu (nếu None sẽ lấy từ Firebase)
        initial_lon: Kinh độ ban đầu (nếu None sẽ lấy từ Firebase)
    """
    print(f"=== Bắt đầu đẩy tọa độ robot định kỳ (mỗi {interval_seconds}s) ===")
    print(f"Khoảng cách tối đa giữa các điểm: {max_distance_meters}m")
    print("Nhấn Ctrl+C để dừng\n")
    
    # Lấy vị trí ban đầu
    if initial_lat is None or initial_lon is None:
        robot = firebase_client.get_robot_location()
        if robot:
            current_lat = robot.lat
            current_lon = robot.lon
            print(f"Vị trí ban đầu từ Firebase: lat={current_lat}, lon={current_lon}")
        else:
            # Vị trí mặc định ở trung tâm Hà Nội
            current_lat = 21.0285
            current_lon = 105.8542
            print(f"Không lấy được vị trí từ Firebase, dùng vị trí mặc định: lat={current_lat}, lon={current_lon}")
            firebase_client.update_robot_location(current_lat, current_lon)
    else:
        current_lat = initial_lat
        current_lon = initial_lon
        print(f"Vị trí ban đầu: lat={current_lat}, lon={current_lon}")
        firebase_client.update_robot_location(current_lat, current_lon)
    
    try:
        update_count = 0
        while True:
            # Tạo tọa độ mới
            new_lat, new_lon = generate_next_location(current_lat, current_lon, max_distance_meters)
            distance = calculate_distance(current_lat, current_lon, new_lat, new_lon)
            
            # Đẩy lên Firebase
            success = firebase_client.update_robot_location(new_lat, new_lon)
            
            if success:
                update_count += 1
                print(f"[{update_count}] ✓ Đã cập nhật: lat={new_lat:.6f}, lon={new_lon:.6f} "
                      f"(khoảng cách: {distance:.1f}m)")
            else:
                print(f"[{update_count + 1}] ✗ Lỗi khi cập nhật vị trí")
            
            # Cập nhật vị trí hiện tại
            current_lat = new_lat
            current_lon = new_lon
            
            # Đợi interval_seconds giây
            time.sleep(interval_seconds)
    
    except KeyboardInterrupt:
        print(f"\n\nĐã dừng. Tổng số lần cập nhật: {update_count}")
        print(f"Vị trí cuối cùng: lat={current_lat:.6f}, lon={current_lon:.6f}")


# ==================== EXAMPLE USAGE ====================

if __name__ == "__main__":
    # Khởi tạo Firebase Client
    firebase = FirebaseClient("https://robot-delivery-cbdcf-default-rtdb.firebaseio.com")
    
    # Ví dụ 1: Cập nhật vị trí robot
    print("=== Cập nhật vị trí robot ===")
    success = firebase.update_robot_location(lat=20.982903, lon=105.836822)
    if success:
        print("✓ Đã cập nhật vị trí robot thành công")
    else:
        print("✗ Lỗi khi cập nhật vị trí robot")
    
    print()
    
    # Ví dụ 2: Lấy vị trí robot hiện tại
    print("=== Lấy vị trí robot ===")
    robot = firebase.get_robot_location()
    if robot:
        print(f"Robot tại: lat={robot.lat}, lon={robot.lon}")
    else:
        print("Không thể lấy vị trí robot")
    
    print()
    
    # Ví dụ 3: Lấy tất cả đơn hàng
    print("=== Lấy tất cả đơn hàng ===")
    orders = firebase.get_all_orders()
    print(f"Tổng số đơn hàng: {len(orders)}")
    for order_id, order in orders.items():
        print(f"  - {order_id}: {order.receiverName} - {order.status} - {order.goods}")
    
    print()
    
    # Ví dụ 4: Lấy một đơn hàng cụ thể
    print("=== Lấy đơn hàng cụ thể ===")
    if orders:
        first_order_id = list(orders.keys())[0]
        order = firebase.get_order(first_order_id)
        if order:
            print(f"Đơn hàng {order.id}:")
            print(f"  Người nhận: {order.receiverName}")
            print(f"  Số điện thoại: {order.phoneNumber}")
            print(f"  Hàng hóa: {order.goods}")
            print(f"  Trọng lượng: {order.weight} kg")
            print(f"  Trạng thái: {order.status}")
            print(f"  Số điểm lộ trình: {len(order.routePoints)}")
    
    print()
    
    # Ví dụ 5: Lấy toàn bộ dữ liệu
    print("=== Lấy toàn bộ dữ liệu ===")
    db_data = firebase.get_all_data()
    if db_data:
        print(f"Robot: lat={db_data.robot.lat}, lon={db_data.robot.lon}")
        print(f"Số đơn hàng: {len(db_data.orders)}")
        for order_id, order in db_data.orders.items():
            print(f"  - {order_id}: {order.receiverName} ({order.status})")
    
    print()
    print("=" * 60)
    print()
    
    # Ví dụ 6: Chạy định kỳ đẩy tọa độ robot lên Firebase (mỗi 10 giây)
    # Uncomment dòng dưới để chạy chức năng này
    # run_periodic_location_update(firebase, interval_seconds=10, max_distance_meters=200.0)

    # Ví dụ 7: Lắng nghe đơn hàng theo thời gian thực
    # def handle_change(orders, payload, event_type):
    #     print(f"[{event_type}] Có {len(orders)} đơn hàng")
    # firebase.listen_orders(handle_change)

