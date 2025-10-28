# Robot Delivery App

Ứng dụng quản lý giao hàng bằng Robot sử dụng Google Maps và Firebase Realtime Database.

## Tính năng

- 🗺️ **Google Maps Integration**: Chọn điểm giao hàng trên bản đồ
- 📍 **Route Planning**: Tự động tính toán lộ trình từ vị trí Robot đến điểm giao hàng
- 📦 **Order Management**: Quản lý đơn hàng với thông tin chi tiết
- 🔥 **Firebase Realtime Database**: Lưu trữ đơn hàng và lộ trình theo thời gian thực
- 📊 **Route Segmentation**: Chia nhỏ lộ trình thành các điểm JSON để điều khiển Robot
- 🎯 **GetX Architecture**: Quản lý state hiệu quả với GetX

## Cấu trúc dự án (GetX Architecture)

```
lib/
├── app/
│   ├── data/
│   │   ├── models/
│   │   │   └── delivery_order.dart      # Model đơn hàng và lộ trình
│   │   └── services/
│   │       └── firebase_service.dart     # Service tương tác Firebase
│   ├── modules/
│   │   ├── map/
│   │   │   ├── bindings/
│   │   │   │   └── map_binding.dart      # Dependency injection
│   │   │   ├── controllers/
│   │   │   │   └── map_controller.dart   # Logic bản đồ
│   │   │   └── views/
│   │   │       └── map_view.dart         # UI bản đồ
│   │   └── orders/
│   │       ├── bindings/
│   │       │   └── orders_binding.dart
│   │       ├── controllers/
│   │       │   └── orders_controller.dart # Logic quản lý đơn
│   │       └── views/
│   │           ├── orders_view.dart       # Danh sách đơn hàng
│   │           └── order_detail_view.dart # Chi tiết đơn hàng
│   └── routes/
│       └── app_pages.dart                 # Định nghĩa routes
├── firebase_options.dart                   # Cấu hình Firebase
└── main.dart                              # Entry point

```

## Cài đặt

### 1. Clone repository

```bash
git clone <your-repo-url>
cd Robot_delivery
```

### 2. Cài đặt dependencies

```bash
flutter pub get
```

### 3. Cấu hình Firebase

File `google-services.json` đã được thêm sẵn trong `android/app/`. Đảm bảo Firebase Realtime Database đã được kích hoạt tại:
```
https://robot-delivery-cbdcf-default-rtdb.firebaseio.com/
```

### 4. Cấu hình Google Maps API

Google Maps API key đã được cấu hình trong:
- `assets/.env` - cho Flutter
- `android/app/src/main/AndroidManifest.xml` - cho Android

**Lưu ý**: Đảm bảo API key có quyền truy cập:
- Maps SDK for Android
- Directions API (để tính toán lộ trình)

### 5. Chạy ứng dụng

```bash
flutter run
```

## Sử dụng

### 1. Tạo đơn hàng mới

1. Mở ứng dụng, bạn sẽ thấy bản đồ với marker màu xanh (vị trí Robot)
2. Nhấn vào bản đồ để chọn điểm giao hàng
3. Hệ thống sẽ tự động tính toán lộ trình và hiển thị đường đi màu xanh
4. Nhấn nút "Tạo đơn hàng" và điền thông tin:
   - Tên người nhận
   - Tuổi
   - Số điện thoại
   - Mô tả hàng hóa
   - Cân nặng (kg)
5. Nhấn "Xác nhận tạo đơn"

### 2. Xem danh sách đơn hàng

1. Nhấn icon danh sách ở góc trên bên phải
2. Xem tất cả đơn hàng với trạng thái:
   - 🟠 **Chờ xử lý** (pending)
   - 🔵 **Đang giao** (in_progress)
   - 🟢 **Hoàn thành** (completed)

### 3. Quản lý đơn hàng

- **Xem chi tiết**: Nhấn vào đơn hàng để xem thông tin đầy đủ và bản đồ
- **Cập nhật trạng thái**: Nhấn icon 3 chấm và chọn trạng thái mới
- **Xóa đơn hàng**: Nhấn icon 3 chấm và chọn "Xóa đơn hàng"

## Dữ liệu trong Firebase

### Cấu trúc dữ liệu đơn hàng:

```json
{
  "orders": {
    "-NxxxxxxxxxxxxX": {
      "id": "-NxxxxxxxxxxxxX",
      "receiverName": "Nguyễn Văn A",
      "receiverAge": 25,
      "phoneNumber": "0901234567",
      "goods": "Thực phẩm",
      "weight": 5.5,
      "destinationLat": 10.7626,
      "destinationLng": 106.6602,
      "status": "pending",
      "createdAt": "2025-10-28T10:30:00.000Z",
      "routePoints": [
        {
          "lat": 10.7626,
          "lng": 106.6602,
          "order": 0
        },
        {
          "lat": 10.7627,
          "lng": 106.6603,
          "order": 1
        }
        // ... 48 điểm khác (tổng 50 điểm)
      ]
    }
  }
}
```

## Tính năng nâng cao

### Route Segmentation

Lộ trình từ Google Maps Directions API được chia nhỏ thành 50 điểm đều nhau để:
- Robot có thể di chuyển theo từng điểm
- Dễ dàng tracking và cập nhật vị trí
- Lưu trữ hiệu quả trên Firebase

### Kiến trúc GetX

- **Controllers**: Xử lý business logic và state management
- **Views**: UI components, lắng nghe thay đổi từ controllers
- **Bindings**: Dependency injection, khởi tạo controllers khi cần
- **Services**: Tương tác với external services (Firebase, API)
- **Routes**: Quản lý navigation giữa các màn hình

## Dependencies chính

```yaml
dependencies:
  get: ^4.7.2                          # State management & routing
  google_maps_flutter: ^2.13.1        # Google Maps widget
  flutter_polyline_points: ^2.1.0     # Vẽ route trên map
  geolocator: ^13.0.2                 # Lấy vị trí GPS
  geocoding: ^3.0.0                   # Chuyển đổi tọa độ <-> địa chỉ
  firebase_core: ^3.8.1               # Firebase core
  firebase_database: ^11.4.0          # Firebase Realtime Database
  flutter_dotenv: ^5.2.1              # Load environment variables
```

## Troubleshooting

### Lỗi Google Maps không hiển thị
- Kiểm tra API key trong `AndroidManifest.xml`
- Đảm bảo Maps SDK for Android đã được enable
- Kiểm tra quyền Internet và Location

### Lỗi Firebase connection
- Kiểm tra `google-services.json` đã được thêm đúng
- Xác nhận Firebase Realtime Database đã được enable
- Kiểm tra database URL trong `main.dart`

### Lỗi không tính được route
- Đảm bảo Directions API đã được enable
- Kiểm tra API key có đủ quyền
- Xem console log để debug

## Liên hệ

Nếu có vấn đề hoặc câu hỏi, vui lòng tạo issue trên GitHub.

## License

MIT License
