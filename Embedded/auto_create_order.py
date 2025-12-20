"""
Tool tự động tạo đơn hàng cho Robot Delivery
- Tên, tuổi, số điện thoại, hàng hóa: tự động generate
- Tọa độ đầu (pickup): lấy từ robot location trên Firebase
- Tọa độ đích (destination): parse từ Google Maps link
- Route points: call OSRM API để lấy lộ trình chi tiết
- Tạo đơn hàng mới trên Firebase

Chạy: python Embedded/auto_create_order.py "https://www.google.com/maps/place/..."
"""

import requests
import re
import sys
import random
from datetime import datetime
from typing import List, Optional, Tuple
from firebase_sample import FirebaseClient, Order, RoutePoint


# ==================== CONFIGURATION ====================

OSRM_SERVERS = [
    'https://router.project-osrm.org',
    'https://routing.openstreetmap.de/routed-car',
]

# Danh sách tên Việt Nam để random
FIRST_NAMES = [
    "Anh", "Bảo", "Chi", "Dũng", "Đức", "Giang", "Hà", "Hải", "Hằng", "Hiếu",
    "Hoa", "Hùng", "Hương", "Khang", "Khánh", "Khoa", "Lan", "Linh", "Long", "Mai",
    "Minh", "Nam", "Nga", "Ngọc", "Nhung", "Phong", "Phương", "Quân", "Quang", "Quyên",
    "Sơn", "Thành", "Thảo", "Thu", "Thủy", "Trang", "Trinh", "Trung", "Tú", "Tùng",
    "Tuyết", "Uyên", "Vân", "Việt", "Yến"
]

LAST_NAMES = [
    "Nguyễn", "Trần", "Lê", "Phạm", "Hoàng", "Huỳnh", "Phan", "Vũ", "Võ", "Đặng",
    "Bùi", "Đỗ", "Hồ", "Ngô", "Dương", "Lý", "Đinh", "Trịnh", "Mai", "Tô"
]

GOODS_LIST = [
    "Điện thoại iPhone 15",
    "Laptop Dell XPS 13",
    "Tai nghe AirPods Pro",
    "Đồng hồ Apple Watch",
    "Máy tính bảng iPad Air",
    "Quần áo thời trang",
    "Giày sneaker Nike",
    "Túi xách Gucci",
    "Sách kỹ năng mềm",
    "Đồ ăn nhanh",
    "Bánh kem sinh nhật",
    "Hoa tươi",
    "Thuốc men",
    "Mỹ phẩm Lancôme",
    "Đồ chơi trẻ em",
    "Văn phòng phẩm",
    "Thực phẩm organic",
    "Đồ điện tử",
    "Phụ kiện xe máy",
    "Đồ gia dụng"
]


# ==================== HELPER FUNCTIONS ====================

def parse_google_maps_link(url: str) -> Optional[Tuple[float, float]]:
    """
    Parse Google Maps link để lấy tọa độ
    
    Ví dụ link:
    https://www.google.com/maps/place/21%C2%B002'03.5%22N+105%C2%B047'44.9%22E/@21.034317,105.7932251,17z/...
    
    Returns:
        Tuple (lat, lng) hoặc None nếu không parse được
    """
    # Pattern 1: Tìm /@lat,lng trong URL
    pattern1 = r'/@(-?\d+\.\d+),(-?\d+\.\d+)'
    match1 = re.search(pattern1, url)
    if match1:
        lat = float(match1.group(1))
        lng = float(match1.group(2))
        print(f"✓ Parsed coordinates from URL: lat={lat}, lng={lng}")
        return (lat, lng)
    
    # Pattern 2: Tìm /place/.../@lat,lng
    pattern2 = r'/place/[^/]+/@(-?\d+\.\d+),(-?\d+\.\d+)'
    match2 = re.search(pattern2, url)
    if match2:
        lat = float(match2.group(1))
        lng = float(match2.group(2))
        print(f"✓ Parsed coordinates from URL: lat={lat}, lng={lng}")
        return (lat, lng)
    
    # Pattern 3: Tìm query params !3d (lat) và !4d (lng)
    pattern3_lat = r'!3d(-?\d+\.\d+)'
    pattern3_lng = r'!4d(-?\d+\.\d+)'
    match3_lat = re.search(pattern3_lat, url)
    match3_lng = re.search(pattern3_lng, url)
    if match3_lat and match3_lng:
        lat = float(match3_lat.group(1))
        lng = float(match3_lng.group(1))
        print(f"✓ Parsed coordinates from query params: lat={lat}, lng={lng}")
        return (lat, lng)
    
    print(f"✗ Could not parse coordinates from URL: {url}")
    return None


def generate_random_name() -> str:
    """Generate tên người Việt Nam ngẫu nhiên"""
    last_name = random.choice(LAST_NAMES)
    first_name = random.choice(FIRST_NAMES)
    return f"{last_name} {first_name}"


def generate_random_phone() -> str:
    """Generate số điện thoại Việt Nam ngẫu nhiên"""
    # Đầu số phổ biến của Việt Nam
    prefixes = ["084", "085", "086", "088", "089", "090", "091", "093", "094", "096", "097", "098"]
    prefix = random.choice(prefixes)
    # 7 số còn lại
    suffix = ''.join([str(random.randint(0, 9)) for _ in range(7)])
    return f"{prefix}{suffix}"


def generate_random_age() -> int:
    """Generate tuổi ngẫu nhiên (18-65)"""
    return random.randint(18, 65)


def generate_random_goods() -> str:
    """Generate hàng hóa ngẫu nhiên"""
    return random.choice(GOODS_LIST)


def generate_random_weight() -> float:
    """Generate trọng lượng ngẫu nhiên (0.5 - 20 kg)"""
    return round(random.uniform(0.5, 20.0), 1)


def downsample_route_points(route_coords: List[Tuple[float, float]], max_points: int = 100) -> List[Tuple[float, float]]:
    """
    Downsample route points về tối đa max_points điểm, phân bố đều
    
    Args:
        route_coords: List of (lat, lng) tuples
        max_points: Số điểm tối đa (mặc định 100)
    
    Returns:
        List of (lat, lng) tuples với tối đa max_points điểm
    """
    if len(route_coords) <= max_points:
        return route_coords
    
    # Downsample: chọn đều max_points điểm từ route
    # Luôn giữ điểm đầu và điểm cuối
    indices = [int(i * (len(route_coords) - 1) / (max_points - 1)) for i in range(max_points)]
    downsampled = [route_coords[i] for i in indices]
    
    print(f"  ⚠ Downsampled route từ {len(route_coords)} điểm xuống {len(downsampled)} điểm")
    
    return downsampled


def get_route_from_osrm(origin_lat: float, origin_lng: float, 
                        dest_lat: float, dest_lng: float) -> Optional[List[Tuple[float, float]]]:
    """
    Gọi OSRM API để lấy lộ trình chi tiết
    
    Args:
        origin_lat, origin_lng: Tọa độ điểm đầu
        dest_lat, dest_lng: Tọa độ điểm cuối
    
    Returns:
        List of (lat, lng) tuples hoặc None nếu có lỗi
    """
    for server_url in OSRM_SERVERS:
        try:
            print(f"  Trying OSRM server: {server_url}")
            
            url = f"{server_url}/route/v1/driving/{origin_lng},{origin_lat};{dest_lng},{dest_lat}?overview=full&geometries=geojson"
            
            response = requests.get(url, timeout=30)
            
            if response.status_code == 200:
                data = response.json()
                
                if data.get('code') == 'Ok' and data.get('routes'):
                    route = data['routes'][0]
                    coordinates = route['geometry']['coordinates']
                    
                    # Convert từ [lng, lat] sang (lat, lng)
                    route_points = [(coord[1], coord[0]) for coord in coordinates]
                    
                    distance = route.get('distance', 0)  # meters
                    duration = route.get('duration', 0)  # seconds
                    
                    print(f"  ✓ OSRM success: {len(route_points)} points, "
                          f"{distance/1000:.2f} km, {duration/60:.1f} minutes")
                    
                    return route_points
                else:
                    print(f"  ✗ No route found from OSRM")
            else:
                print(f"  ✗ OSRM server returned status {response.status_code}")
                
        except Exception as e:
            print(f"  ✗ OSRM Error with {server_url}: {e}")
    
    print(f"  ✗ All OSRM servers failed")
    return None


def create_order_on_firebase(firebase: FirebaseClient, 
                            destination_lat: float, 
                            destination_lng: float) -> Optional[str]:
    """
    Tạo đơn hàng mới trên Firebase
    
    Args:
        firebase: FirebaseClient instance
        destination_lat: Vĩ độ điểm đích
        destination_lng: Kinh độ điểm đích
    
    Returns:
        Order ID nếu thành công, None nếu có lỗi
    """
    print("\n" + "=" * 60)
    print("TẠO ĐỜN HÀNG MỚI")
    print("=" * 60)
    
    # 1. Lấy vị trí robot (pickup location)
    print("\n1. Lấy vị trí robot (pickup location)...")
    robot = firebase.get_robot_location()
    if not robot:
        print("  ✗ Không thể lấy vị trí robot từ Firebase")
        return None
    
    origin_lat = robot.lat
    origin_lng = robot.lon
    print(f"  ✓ Robot location: lat={origin_lat}, lng={origin_lng}")
    
    # 2. Gọi OSRM để lấy route points
    print(f"\n2. Gọi OSRM API để lấy route...")
    print(f"  From: ({origin_lat}, {origin_lng})")
    print(f"  To: ({destination_lat}, {destination_lng})")
    
    route_coords = get_route_from_osrm(origin_lat, origin_lng, destination_lat, destination_lng)
    
    if not route_coords:
        print("  ⚠ OSRM failed, tạo route thẳng đơn giản thay thế")
        # Fallback: tạo route thẳng với 2 điểm
        route_coords = [(origin_lat, origin_lng), (destination_lat, destination_lng)]
    
    # Giới hạn số điểm route về tối đa 100
    route_coords = downsample_route_points(route_coords, max_points=100)
    
    # Convert sang RoutePoint objects
    route_points = [
        RoutePoint(lat=lat, lng=lng, order=i)
        for i, (lat, lng) in enumerate(route_coords)
    ]
    
    # 3. Generate thông tin đơn hàng
    print(f"\n3. Generate thông tin đơn hàng...")
    receiver_name = generate_random_name()
    phone_number = generate_random_phone()
    age = generate_random_age()
    goods = generate_random_goods()
    weight = generate_random_weight()
    created_at = datetime.now().isoformat()
    
    print(f"  Người nhận: {receiver_name}")
    print(f"  Tuổi: {age}")
    print(f"  Số điện thoại: {phone_number}")
    print(f"  Hàng hóa: {goods}")
    print(f"  Trọng lượng: {weight} kg")
    print(f"  Số điểm route: {len(route_points)}")
    
    # 4. Tạo Order object
    order = Order(
        id="",  # Firebase sẽ tự tạo ID
        createdAt=created_at,
        destinationLat=destination_lat,
        destinationLng=destination_lng,
        goods=goods,
        phoneNumber=phone_number,
        receiverAge=age,
        receiverName=receiver_name,
        routePoints=route_points,
        status="pending",
        weight=weight
    )
    
    # 5. Push lên Firebase
    print(f"\n4. Đẩy đơn hàng lên Firebase...")
    order_dict = order.to_dict()
    # Remove id field vì Firebase sẽ tự tạo
    order_dict.pop('id', None)
    
    result = firebase._make_request("POST", "orders", order_dict)
    
    if result and 'name' in result:
        order_id = result['name']
        print(f"  ✓ Tạo đơn hàng thành công!")
        print(f"  Order ID: {order_id}")
        return order_id
    else:
        print(f"  ✗ Lỗi khi tạo đơn hàng trên Firebase")
        return None


# ==================== MAIN ====================

def main():
    """Main function"""
    print("\n" + "=" * 60)
    print("TOOL TỰ ĐỘNG TẠO ĐƠN HÀNG - ROBOT DELIVERY")
    print("=" * 60)
    
    # 1. Parse command line arguments
    if len(sys.argv) < 2:
        print("\nCách sử dụng:")
        print('  python Embedded/auto_create_order.py "https://www.google.com/maps/place/..."')
        print("\nVí dụ:")
        print('  python Embedded/auto_create_order.py "https://www.google.com/maps/place/21%C2%B002\'03.5%22N+105%C2%B047\'44.9%22E/@21.034317,105.7932251,17z/..."')
        return
    
    google_maps_url = sys.argv[1]
    
    # 2. Parse destination coordinates từ Google Maps link
    print(f"\n1. Parse tọa độ đích từ Google Maps link...")
    coords = parse_google_maps_link(google_maps_url)
    
    if not coords:
        print("\n✗ Không thể parse tọa độ từ link Google Maps")
        print("Vui lòng kiểm tra lại link")
        return
    
    dest_lat, dest_lng = coords
    
    # 3. Khởi tạo Firebase Client
    print(f"\n2. Kết nối Firebase...")
    firebase = FirebaseClient("https://robot-delivery-cbdcf-default-rtdb.firebaseio.com")
    print(f"  ✓ Connected to Firebase")
    
    # 4. Tạo đơn hàng
    order_id = create_order_on_firebase(firebase, dest_lat, dest_lng)
    
    # 5. Kết quả
    print("\n" + "=" * 60)
    if order_id:
        print("✓ THÀNH CÔNG!")
        print(f"Đơn hàng đã được tạo với ID: {order_id}")
        print("\nBạn có thể kiểm tra trên app mobile hoặc Firebase Console")
    else:
        print("✗ THẤT BẠI!")
        print("Không thể tạo đơn hàng, vui lòng thử lại")
    print("=" * 60 + "\n")


if __name__ == "__main__":
    main()
