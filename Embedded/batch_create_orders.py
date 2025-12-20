"""
Batch Create Orders - Tạo nhiều đơn hàng cùng lúc để test

Chạy: python Embedded/batch_create_orders.py <số_lượng>
Ví dụ: python Embedded/batch_create_orders.py 5
"""

import sys
import time
import random
from auto_create_order import (
    create_order_on_firebase,
    FirebaseClient
)

# Địa điểm random trong Hà Nội
HANOI_LOCATIONS = [
    {"name": "Hồ Hoàn Kiếm", "lat": 21.0285, "lng": 105.8542},
    {"name": "Văn Miếu", "lat": 21.0277, "lng": 105.8355},
    {"name": "Nhà Hát Lớn", "lat": 21.0240, "lng": 105.8570},
    {"name": "Chợ Đồng Xuân", "lat": 21.0358, "lng": 105.8483},
    {"name": "Hoàng Thành Thăng Long", "lat": 21.0344, "lng": 105.8345},
    {"name": "Cầu Thê Húc", "lat": 21.0293, "lng": 105.8523},
    {"name": "Nhà Thờ Lớn Hà Nội", "lat": 21.0289, "lng": 105.8490},
    {"name": "Bảo Tàng Hồ Chí Minh", "lat": 21.0362, "lng": 105.8345},
    {"name": "Lăng Bác", "lat": 21.0377, "lng": 105.8347},
    {"name": "Bảo Tàng Mỹ Thuật", "lat": 21.0332, "lng": 105.8357},
    {"name": "Chợ Hôm", "lat": 21.0176, "lng": 105.8267},
    {"name": "Trung tâm Thương mại Vincom", "lat": 21.0313, "lng": 105.8516},
    {"name": "Đại học Quốc Gia", "lat": 21.0379, "lng": 105.7830},
    {"name": "Sân bay Nội Bài", "lat": 21.2212, "lng": 105.8076},
    {"name": "Bến xe Mỹ Đình", "lat": 21.0283, "lng": 105.7794},
]


def batch_create(count: int, delay_seconds: float = 2.0):
    """
    Tạo nhiều đơn hàng cùng lúc
    
    Args:
        count: Số lượng đơn hàng cần tạo
        delay_seconds: Thời gian đợi giữa mỗi đơn (giây)
    """
    print("\n" + "=" * 60)
    print(f"BATCH CREATE: TẠO {count} ĐƠN HÀNG")
    print("=" * 60)
    
    # Khởi tạo Firebase
    print("\nKết nối Firebase...")
    firebase = FirebaseClient("https://robot-delivery-cbdcf-default-rtdb.firebaseio.com")
    print("✓ Connected\n")
    
    success_count = 0
    fail_count = 0
    order_ids = []
    
    for i in range(count):
        print(f"\n{'=' * 60}")
        print(f"ĐƠN HÀNG {i + 1}/{count}")
        print(f"{'=' * 60}")
        
        # Random location
        location = random.choice(HANOI_LOCATIONS)
        print(f"Đích đến: {location['name']}")
        
        # Tạo đơn hàng
        order_id = create_order_on_firebase(
            firebase,
            location['lat'],
            location['lng']
        )
        
        if order_id:
            success_count += 1
            order_ids.append(order_id)
            print(f"\n✓ Đơn {i + 1}: THÀNH CÔNG (ID: {order_id})")
        else:
            fail_count += 1
            print(f"\n✗ Đơn {i + 1}: THẤT BẠI")
        
        # Đợi trước khi tạo đơn tiếp theo (trừ đơn cuối)
        if i < count - 1:
            print(f"\nĐợi {delay_seconds}s trước khi tạo đơn tiếp theo...")
            time.sleep(delay_seconds)
    
    # Tổng kết
    print("\n" + "=" * 60)
    print("TỔNG KẾT")
    print("=" * 60)
    print(f"Tổng số đơn: {count}")
    print(f"✓ Thành công: {success_count}")
    print(f"✗ Thất bại: {fail_count}")
    
    if order_ids:
        print(f"\nDanh sách Order IDs:")
        for idx, oid in enumerate(order_ids, 1):
            print(f"  {idx}. {oid}")
    
    print("=" * 60 + "\n")


def main():
    if len(sys.argv) < 2:
        print("\nCách sử dụng:")
        print("  python Embedded/batch_create_orders.py <số_lượng> [delay_seconds]")
        print("\nVí dụ:")
        print("  python Embedded/batch_create_orders.py 5")
        print("  python Embedded/batch_create_orders.py 10 3.0")
        print("\nTham số:")
        print("  số_lượng: Số đơn hàng cần tạo")
        print("  delay_seconds: Thời gian đợi giữa mỗi đơn (mặc định: 2.0s)")
        return
    
    try:
        count = int(sys.argv[1])
        
        if count <= 0:
            print("Số lượng phải > 0")
            return
        
        if count > 100:
            print("⚠️  Cảnh báo: Tạo quá nhiều đơn có thể làm quá tải Firebase")
            confirm = input(f"Bạn có chắc muốn tạo {count} đơn? (y/n): ").strip().lower()
            if confirm != 'y':
                print("Đã hủy.")
                return
        
        # Lấy delay (nếu có)
        delay = 2.0
        if len(sys.argv) >= 3:
            delay = float(sys.argv[2])
        
        # Bắt đầu batch create
        batch_create(count, delay)
        
    except ValueError as e:
        print(f"Lỗi: Tham số không hợp lệ - {e}")
    except KeyboardInterrupt:
        print("\n\nĐã dừng batch create (Ctrl+C)")


if __name__ == "__main__":
    main()
