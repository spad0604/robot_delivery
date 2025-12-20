# Embedded Scripts - Robot Delivery

Các script Python để tương tác với Firebase và hỗ trợ testing cho hệ thống Robot Delivery.

## 📁 Danh sách Files

### Core Files

#### `firebase_sample.py`
Firebase Realtime Database Client chính với các tính năng:
- ✅ Đẩy vị trí robot lên Firebase
- ✅ Lấy vị trí robot từ Firebase
- ✅ Lấy danh sách đơn hàng
- ✅ Lắng nghe đơn hàng realtime (SSE)
- ✅ Data models: `Order`, `RoutePoint`, `Robot`

#### `requirements.txt`
Python dependencies cần thiết:
```
requests>=2.31.0
```

### Monitoring Tools

#### `listen_orders.py`
Script để theo dõi danh sách đơn hàng theo thời gian thực.

**Chạy:**
```bash
python Embedded/listen_orders.py
```

**Tính năng:**
- 📡 Lắng nghe thay đổi từ Firebase realtime
- 📊 In ra thông tin đơn hàng mỗi khi có update
- 🔄 Tự động retry khi mất kết nối

#### `run_periodic_update.py`
Script định kỳ đẩy tọa độ robot lên Firebase (simulation).

**Chạy:**
```bash
python Embedded/run_periodic_update.py
```

**Tính năng:**
- 🤖 Tự động cập nhật vị trí robot mỗi 10 giây
- 🗺️ Tạo vị trí random trong phạm vi Hà Nội
- 📍 Giới hạn khoảng cách di chuyển (200m mỗi lần)

### 🆕 Order Creation Tools

#### `auto_create_order.py` ⭐ NEW!
Tool tự động tạo đơn hàng từ Google Maps link.

**Chạy:**
```bash
# Linux/Mac
python Embedded/auto_create_order.py "https://www.google.com/maps/place/..."

# Windows PowerShell (BẮT BUỘC có dấu ngoặc kép!)
python Embedded/auto_create_order.py "https://www.google.com/maps/place/..."
```

⚠️ **Windows users:** Nhớ thêm dấu ngoặc kép `"..."` quanh URL!

**Tính năng:**
- 🎯 Parse tọa độ từ Google Maps link
- 👤 Tự động generate tên, SĐT, hàng hóa
- 📍 Lấy tọa độ pickup từ robot location
- 🗺️ Call OSRM API để tính route points
- 📤 Push đơn hàng lên Firebase

**Xem chi tiết:** [README_AUTO_ORDER.md](README_AUTO_ORDER.md)

#### `demo_create_order.py` ⭐ NEW!
Demo tạo đơn nhanh với địa điểm có sẵn (không cần Google Maps link).

**Chạy:**
```bash
python Embedded/demo_create_order.py
```

**Tính năng:**
- 📋 Menu chọn địa điểm có sẵn (Hồ Hoàn Kiếm, Văn Miếu, ...)
- ⚡ Tạo đơn nhanh chóng
- 🎓 Phù hợp cho demo và học tập

#### `batch_create_orders.py` ⭐ NEW!
Tạo nhiều đơn hàng cùng lúc để test.

**Chạy:**
```bash
python Embedded/batch_create_orders.py <số_lượng> [delay_seconds]
```

**Ví dụ:**
```bash
# Tạo 5 đơn hàng, đợi 2s giữa mỗi đơn
python Embedded/batch_create_orders.py 5

# Tạo 10 đơn hàng, đợi 3s giữa mỗi đơn
python Embedded/batch_create_orders.py 10 3.0
```

**Tính năng:**
- 🚀 Tạo hàng loạt đơn hàng tự động
- 🎲 Random địa điểm trong Hà Nội
- ⏱️ Tùy chỉnh delay giữa các đơn
- 📊 Báo cáo thống kê cuối cùng

## 🚀 Quick Start

### 1. Cài đặt

```bash
# Clone repo và cd vào thư mục Embedded
cd Embedded

# Cài đặt dependencies
pip install -r requirements.txt
```

### 2. Test Firebase Connection

```bash
# Chạy script mẫu để test kết nối
python firebase_sample.py
```

### 3. Theo dõi đơn hàng

```bash
# Mở terminal thứ nhất
python listen_orders.py
```

### 4. Tạo đơn hàng mới

```bash
# Mở terminal thứ hai
python demo_create_order.py

# Hoặc dùng Google Maps link
python auto_create_order.py "https://www.google.com/maps/place/..."
```

## 📚 Use Cases

### Use Case 1: Testing Robot Code (Không cần điện thoại)

```bash
# Terminal 1: Giả lập robot di chuyển
python run_periodic_update.py

# Terminal 2: Theo dõi đơn hàng
python listen_orders.py

# Terminal 3: Tạo đơn test
python demo_create_order.py
# hoặc
python batch_create_orders.py 3
```

### Use Case 2: Tạo đơn với địa điểm thực

```bash
# 1. Mở Google Maps, chọn địa điểm
# 2. Copy link
# 3. Chạy:
python auto_create_order.py "https://www.google.com/maps/place/21.034317,105.7932251"
```

### Use Case 3: Load Testing

```bash
# Tạo 20 đơn hàng cùng lúc để test hiệu năng
python batch_create_orders.py 20 1.0
```

## 🔧 Configuration

### Firebase URL

Các script sử dụng Firebase URL:
```
https://robot-delivery-cbdcf-default-rtdb.firebaseio.com
```

Nếu cần thay đổi, sửa trong từng script hoặc tạo biến môi trường.

### OSRM Servers

Tool tự động thử các OSRM servers:
1. `https://router.project-osrm.org` (official)
2. `https://routing.openstreetmap.de/routed-car` (backup)

## 🎯 Workflow Đề Xuất

### Cho Robot Developer:

```bash
# 1. Start robot simulation
python run_periodic_update.py

# 2. Create test orders
python batch_create_orders.py 5

# 3. Watch orders in another terminal
python listen_orders.py

# 4. Viết code robot xử lý đơn hàng
# Robot sẽ nhận được đơn từ Firebase và xử lý
```

### Cho Mobile Developer:

```bash
# 1. Tạo đơn test
python demo_create_order.py

# 2. Mở app mobile để xem đơn xuất hiện
# 3. Test UI/UX trên app
```

## 📖 Documentation

- [README_AUTO_ORDER.md](README_AUTO_ORDER.md) - Chi tiết tool tạo đơn tự động
- [firebase_sample.py](firebase_sample.py) - Xem docstrings trong code

## 🐛 Troubleshooting

### Lỗi: No module named 'requests'
```bash
pip install requests
```

### Lỗi: Firebase timeout
- Kiểm tra kết nối internet
- Kiểm tra Firebase URL có đúng không
- Thử lại sau vài giây

### Lỗi: OSRM failed
- Tool tự động fallback sang route thẳng
- Đơn hàng vẫn được tạo thành công

## 🤝 Contributing

Feel free to:
- Thêm địa điểm mới vào `HANOI_LOCATIONS`
- Thêm tên Việt Nam vào `FIRST_NAMES`, `LAST_NAMES`
- Thêm hàng hóa mới vào `GOODS_LIST`
- Cải thiện OSRM error handling

## 📝 License

MIT License
