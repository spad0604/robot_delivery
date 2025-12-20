"""
Demo script - Tạo đơn hàng nhanh với tọa độ có sẵn
Không cần Google Maps link, chỉ cần chạy trực tiếp

Chạy: python Embedded/demo_create_order.py
"""

from auto_create_order import (
    create_order_on_firebase,
    FirebaseClient
)

# Một số địa điểm nổi tiếng ở Hà Nội để test
DEMO_LOCATIONS = [
    {
        "name": "Hồ Hoàn Kiếm",
        "lat": 21.0285,
        "lng": 105.8542
    },
    {
        "name": "Văn Miếu Quốc Tử Giám",
        "lat": 21.0277,
        "lng": 105.8355
    },
    {
        "name": "Nhà Hát Lớn Hà Nội",
        "lat": 21.0240,
        "lng": 105.8570
    },
    {
        "name": "Chợ Đồng Xuân",
        "lat": 21.0358,
        "lng": 105.8483
    },
    {
        "name": "Hoàng Thành Thăng Long",
        "lat": 21.0344,
        "lng": 105.8345
    },
]


def main():
    print("\n" + "=" * 60)
    print("DEMO: TẠO ĐƠN HÀNG VỚI ĐỊA ĐIỂM CÓ SẴN")
    print("=" * 60)
    
    print("\nCác địa điểm có sẵn:")
    for i, loc in enumerate(DEMO_LOCATIONS, 1):
        print(f"  {i}. {loc['name']}")
    
    print(f"\n  0. Thoát")
    
    try:
        choice = input("\nChọn địa điểm đích (1-5): ").strip()
        
        if choice == "0":
            print("Đã hủy.")
            return
        
        choice_idx = int(choice) - 1
        
        if choice_idx < 0 or choice_idx >= len(DEMO_LOCATIONS):
            print("Lựa chọn không hợp lệ!")
            return
        
        location = DEMO_LOCATIONS[choice_idx]
        
        print(f"\n✓ Đã chọn: {location['name']}")
        print(f"  Tọa độ: {location['lat']}, {location['lng']}")
        
        # Khởi tạo Firebase
        firebase = FirebaseClient("https://robot-delivery-cbdcf-default-rtdb.firebaseio.com")
        
        # Tạo đơn hàng
        order_id = create_order_on_firebase(
            firebase,
            location['lat'],
            location['lng']
        )
        
        # Kết quả
        print("\n" + "=" * 60)
        if order_id:
            print(f"✓ Tạo đơn hàng đến {location['name']} thành công!")
            print(f"  Order ID: {order_id}")
        else:
            print("✗ Tạo đơn hàng thất bại!")
        print("=" * 60 + "\n")
        
    except ValueError:
        print("Lựa chọn không hợp lệ!")
    except KeyboardInterrupt:
        print("\n\nĐã hủy.")


if __name__ == "__main__":
    main()
