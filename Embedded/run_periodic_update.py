"""
Script để chạy định kỳ đẩy tọa độ robot lên Firebase
Chạy: python Embedded/run_periodic_update.py
"""

from firebase_sample import FirebaseClient, run_periodic_location_update

if __name__ == "__main__":
    # Khởi tạo Firebase Client
    firebase = FirebaseClient("https://robot-delivery-cbdcf-default-rtdb.firebaseio.com")
    
    # Chạy định kỳ đẩy tọa độ robot lên Firebase
    # - interval_seconds=10: Cập nhật mỗi 10 giây
    # - max_distance_meters=200.0: Khoảng cách tối đa giữa các điểm là 200 mét
    # - initial_lat, initial_lon: Có thể chỉ định vị trí ban đầu (None = lấy từ Firebase)
    run_periodic_location_update(
        firebase_client=firebase,
        interval_seconds=10,
        max_distance_meters=200.0,
        initial_lat=None,  # None = lấy từ Firebase, hoặc chỉ định ví dụ: 21.0285
        initial_lon=None  # None = lấy từ Firebase, hoặc chỉ định ví dụ: 105.8542
    )

