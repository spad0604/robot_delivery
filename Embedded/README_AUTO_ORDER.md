# Auto Create Order Tool

Tool tự động tạo đơn hàng cho hệ thống Robot Delivery.

## Tính năng

✅ **Tự động generate thông tin đơn hàng:**
- Tên người nhận (random từ danh sách tên Việt Nam)
- Số điện thoại (random số Việt Nam)
- Tuổi (18-65)
- Hàng hóa (random từ danh sách)
- Trọng lượng (0.5 - 20 kg)

✅ **Tọa độ thông minh:**
- Điểm đầu (pickup): Lấy tự động từ vị trí robot trên Firebase
- Điểm đích (destination): Parse từ link Google Maps bạn cung cấp

✅ **Route points chi tiết:**
- Gọi OSRM API (OpenStreetMap) để tính lộ trình tối ưu
- Tự động retry nếu server OSRM bị lỗi
- Fallback sang route thẳng nếu OSRM không khả dụng

✅ **Push trực tiếp lên Firebase:**
- Đơn hàng xuất hiện ngay trên app mobile
- Người code robot có thể test mà không cần điện thoại

## Cài đặt

```bash
# Cài đặt dependencies
pip install -r requirements.txt
```

## Cách sử dụng

### Bước 1: Lấy link Google Maps

1. Mở Google Maps
2. Chọn điểm đích bạn muốn giao hàng đến
3. Click "Share" hoặc copy URL từ thanh địa chỉ

Ví dụ link:
```
https://www.google.com/maps/place/21%C2%B002'03.5%22N+105%C2%B047'44.9%22E/@21.034317,105.7932251,17z/data=!3m1!4b1!4m4!3m3!8m2!3d21.034312!4d105.7958
```

### Bước 2: Chạy tool

**Linux/Mac (Bash):**
```bash
python Embedded/auto_create_order.py "https://www.google.com/maps/place/..."
```

**Windows (PowerShell):**
```powershell
python Embedded/auto_create_order.py "https://www.google.com/maps/place/..."
```

⚠️ **LƯU Ý QUAN TRỌNG cho Windows PowerShell:**
- **BẮT BUỘC** phải thêm dấu ngoặc kép `"..."` quanh URL
- Nếu không có dấu ngoặc kép, PowerShell sẽ báo lỗi `The ampersand (&) character is not allowed`

**Ví dụ đầy đủ:**

```powershell
# ✅ ĐÚNG - Có dấu ngoặc kép
python Embedded/auto_create_order.py "https://www.google.com/maps/place/21%C2%B002'03.5%22N+105%C2%B047'44.9%22E/@21.034317,105.7932251,17z/data=!3m1!4b1!4m4!3m3!8m2!3d21.034312!4d105.7958?entry=ttu&g_ep=EgoyMDI1MTIwOS4wIKXMDSoKLDEwMDc5MjA2OUgBUAM%3D"

# ✅ Hoặc dùng dấu nháy đơn
python Embedded/auto_create_order.py 'https://www.google.com/maps/place/...'

# ❌ SAI - Không có dấu ngoặc kép (sẽ bị lỗi)
python Embedded/auto_create_order.py https://www.google.com/maps/place/...&...
```

### Bước 3: Kiểm tra kết quả

Sau khi chạy thành công, bạn sẽ thấy:

```
============================================================
✓ THÀNH CÔNG!
Đơn hàng đã được tạo với ID: -OdiO9pdXUIykq5vwqyL
Bạn có thể kiểm tra trên app mobile hoặc Firebase Console
============================================================
```

Đơn hàng sẽ xuất hiện ngay lập tức trên:
- ✅ App mobile Flutter
- ✅ Firebase Realtime Database Console
- ✅ Script `listen_orders.py` (nếu đang chạy)

## Output mẫu

```
============================================================
TOOL TỰ ĐỘNG TẠO ĐƠN HÀNG - ROBOT DELIVERY
============================================================

1. Parse tọa độ đích từ Google Maps link...
✓ Parsed coordinates from URL: lat=21.034317, lng=105.7932251

2. Kết nối Firebase...
  ✓ Connected to Firebase

============================================================
TẠO ĐƠN HÀNG MỚI
============================================================

1. Lấy vị trí robot (pickup location)...
  ✓ Robot location: lat=20.982903, lng=105.836822

2. Gọi OSRM API để lấy route...
  From: (20.982903, 105.836822)
  To: (21.034317, 105.7932251)
  Trying OSRM server: https://router.project-osrm.org
  ✓ OSRM success: 186 points, 9.23 km, 15.4 minutes

3. Generate thông tin đơn hàng...
  Người nhận: Nguyễn Minh Anh
  Tuổi: 34
  Số điện thoại: 0843567892
  Hàng hóa: Laptop Dell XPS 13
  Trọng lượng: 5.2 kg
  Số điểm route: 186

4. Đẩy đơn hàng lên Firebase...
  ✓ Tạo đơn hàng thành công!
  Order ID: -OdiO9pdXUIykq5vwqyL

============================================================
✓ THÀNH CÔNG!
Đơn hàng đã được tạo với ID: -OdiO9pdXUIykq5vwqyL
Bạn có thể kiểm tra trên app mobile hoặc Firebase Console
============================================================
```

## Lợi ích

### Cho người code robot:
- 🚀 **Không cần điện thoại**: Tự tạo đơn test mà không cần app mobile
- 🤖 **Tự động hóa testing**: Tạo nhiều đơn hàng test nhanh chóng
- 🎯 **Tọa độ chính xác**: Parse trực tiếp từ Google Maps
- 🗺️ **Route thực tế**: Dùng OSRM như app mobile

### Cho team:
- ⚡ **Tăng tốc development**: Không phụ thuộc vào app mobile
- 🧪 **Test dễ dàng**: Tạo test cases đa dạng
- 🔄 **CI/CD friendly**: Có thể tích hợp vào automated tests

## Các file liên quan

- `auto_create_order.py` - Tool chính
- `firebase_sample.py` - Firebase client & data models
- `listen_orders.py` - Script để theo dõi đơn hàng realtime
- `requirements.txt` - Python dependencies

## Troubleshooting

### Lỗi: "Không thể parse tọa độ từ link"
- ✅ Kiểm tra link Google Maps có đúng format không
- ✅ Link phải chứa tọa độ (có chữ số lat, lng)
- ✅ Thử copy lại link từ Google Maps

### Lỗi: "Không thể lấy vị trí robot"
- ✅ Kiểm tra Firebase có sẵn dữ liệu robot location chưa
- ✅ Chạy `run_periodic_update.py` để tạo vị trí robot ban đầu

### Lỗi: "All OSRM servers failed"
- ✅ Kiểm tra kết nối internet
- ✅ Tool sẽ tự động fallback sang route thẳng
- ✅ Đơn hàng vẫn được tạo thành công

## Mở rộng

Bạn có thể customize:
- Thêm danh sách tên, hàng hóa trong code
- Điều chỉnh trọng số random (weight, age)
- Thêm OSRM servers khác
- Thêm validation logic

## License

MIT License - Free to use and modify
