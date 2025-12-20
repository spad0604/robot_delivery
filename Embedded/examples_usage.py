"""
Example Usage - Hướng dẫn sử dụng các tools tạo đơn hàng

File này chứa các ví dụ về cách sử dụng các function và tools
"""

from auto_create_order import (
    parse_google_maps_link,
    get_route_from_osrm,
    generate_random_name,
    generate_random_phone,
    generate_random_goods,
    create_order_on_firebase,
    FirebaseClient
)


def example_1_parse_link():
    """Ví dụ 1: Parse Google Maps link"""
    print("\n" + "=" * 60)
    print("VÍ DỤ 1: PARSE GOOGLE MAPS LINK")
    print("=" * 60)
    
    test_links = [
        "https://www.google.com/maps/place/21%C2%B002'03.5%22N+105%C2%B047'44.9%22E/@21.034317,105.7932251,17z/",
        "https://www.google.com/maps/@21.0285,105.8542,17z",
        "https://www.google.com/maps/place/H%E1%BB%93+Ho%C3%A0n+Ki%E1%BA%BFm/@21.0285,105.8542",
    ]
    
    for link in test_links:
        print(f"\nLink: {link[:60]}...")
        coords = parse_google_maps_link(link)
        if coords:
            print(f"  ✓ Lat: {coords[0]}, Lng: {coords[1]}")
        else:
            print(f"  ✗ Không parse được")


def example_2_generate_info():
    """Ví dụ 2: Generate thông tin đơn hàng"""
    print("\n" + "=" * 60)
    print("VÍ DỤ 2: GENERATE THÔNG TIN ĐƠN HÀNG")
    print("=" * 60)
    
    for i in range(5):
        print(f"\nĐơn hàng {i + 1}:")
        print(f"  Tên: {generate_random_name()}")
        print(f"  SĐT: {generate_random_phone()}")
        print(f"  Hàng: {generate_random_goods()}")


def example_3_osrm_route():
    """Ví dụ 3: Lấy route từ OSRM"""
    print("\n" + "=" * 60)
    print("VÍ DỤ 3: LẤY ROUTE TỪ OSRM API")
    print("=" * 60)
    
    # Từ Hồ Hoàn Kiếm đến Văn Miếu
    origin_lat = 21.0285
    origin_lng = 105.8542
    dest_lat = 21.0277
    dest_lng = 105.8355
    
    print(f"\nTừ: Hồ Hoàn Kiếm ({origin_lat}, {origin_lng})")
    print(f"Đến: Văn Miếu ({dest_lat}, {dest_lng})")
    
    route = get_route_from_osrm(origin_lat, origin_lng, dest_lat, dest_lng)
    
    if route:
        print(f"\n✓ Thành công!")
        print(f"  Số điểm route: {len(route)}")
        print(f"  Điểm đầu: {route[0]}")
        print(f"  Điểm cuối: {route[-1]}")
    else:
        print(f"\n✗ Không lấy được route")


def example_4_create_order_full():
    """Ví dụ 4: Tạo đơn hàng hoàn chỉnh (cần Firebase)"""
    print("\n" + "=" * 60)
    print("VÍ DỤ 4: TẠO ĐƠN HÀNG HOÀN CHỈNH")
    print("=" * 60)
    
    # Destination: Hồ Hoàn Kiếm
    dest_lat = 21.0285
    dest_lng = 105.8542
    
    print(f"\nĐích đến: Hồ Hoàn Kiếm")
    print(f"Tọa độ: {dest_lat}, {dest_lng}")
    
    try:
        firebase = FirebaseClient("https://robot-delivery-cbdcf-default-rtdb.firebaseio.com")
        order_id = create_order_on_firebase(firebase, dest_lat, dest_lng)
        
        if order_id:
            print(f"\n✓ Đơn hàng đã được tạo với ID: {order_id}")
        else:
            print(f"\n✗ Không tạo được đơn hàng")
    except Exception as e:
        print(f"\n✗ Lỗi: {e}")


def example_5_firebase_operations():
    """Ví dụ 5: Các thao tác với Firebase"""
    print("\n" + "=" * 60)
    print("VÍ DỤ 5: THAO TÁC VỚI FIREBASE")
    print("=" * 60)
    
    try:
        firebase = FirebaseClient("https://robot-delivery-cbdcf-default-rtdb.firebaseio.com")
        
        # Lấy vị trí robot
        print("\n1. Lấy vị trí robot:")
        robot = firebase.get_robot_location()
        if robot:
            print(f"  ✓ Robot tại: ({robot.lat}, {robot.lon})")
        else:
            print(f"  ✗ Không lấy được vị trí robot")
        
        # Lấy tất cả đơn hàng
        print("\n2. Lấy tất cả đơn hàng:")
        orders = firebase.get_all_orders()
        print(f"  ✓ Có {len(orders)} đơn hàng")
        
        # In ra 3 đơn đầu tiên
        for i, (order_id, order) in enumerate(list(orders.items())[:3]):
            print(f"  - {order.receiverName}: {order.goods} ({order.status})")
        
        if len(orders) > 3:
            print(f"  ... và {len(orders) - 3} đơn nữa")
            
    except Exception as e:
        print(f"\n✗ Lỗi: {e}")


def run_all_examples():
    """Chạy tất cả ví dụ"""
    print("\n" + "=" * 60)
    print("CHẠY TẤT CẢ VÍ DỤ")
    print("=" * 60)
    
    examples = [
        ("Parse Google Maps Link", example_1_parse_link),
        ("Generate Thông Tin", example_2_generate_info),
        ("OSRM Route", example_3_osrm_route),
        ("Firebase Operations", example_5_firebase_operations),
    ]
    
    for name, func in examples:
        try:
            func()
        except Exception as e:
            print(f"\n✗ Lỗi khi chạy {name}: {e}")
    
    print("\n" + "=" * 60)
    print("Lưu ý: Ví dụ 4 (Tạo đơn hàng) cần chạy riêng để tránh spam Firebase")
    print("Chạy: python -c 'from examples_usage import example_4_create_order_full; example_4_create_order_full()'")
    print("=" * 60 + "\n")


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1:
        example_num = sys.argv[1]
        
        examples_map = {
            "1": example_1_parse_link,
            "2": example_2_generate_info,
            "3": example_3_osrm_route,
            "4": example_4_create_order_full,
            "5": example_5_firebase_operations,
        }
        
        if example_num in examples_map:
            examples_map[example_num]()
        else:
            print(f"Ví dụ {example_num} không tồn tại")
            print("Các ví dụ có sẵn: 1, 2, 3, 4, 5")
    else:
        # Chạy tất cả (trừ ví dụ 4 - tạo đơn thật)
        run_all_examples()
