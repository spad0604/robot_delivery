# CHANGELOG - Embedded Tools

## [1.0.0] - 2025-12-20

### ✨ Added - Auto Order Creation Tools

#### New Files:
- `auto_create_order.py` - Main tool tự động tạo đơn hàng
- `demo_create_order.py` - Demo với địa điểm có sẵn
- `batch_create_orders.py` - Tạo nhiều đơn hàng cùng lúc
- `examples_usage.py` - Ví dụ sử dụng các functions
- `README_AUTO_ORDER.md` - Hướng dẫn chi tiết
- `README.md` - Tổng quan tất cả tools

#### Features:
✅ **Tự động generate thông tin đơn hàng:**
  - Tên người Việt Nam (45 tên + 20 họ)
  - Số điện thoại Việt Nam
  - Tuổi (18-65)
  - Hàng hóa (20 loại)
  - Trọng lượng (0.5-20kg)

✅ **Parse Google Maps link:**
  - Hỗ trợ 3 format link phổ biến
  - Tự động extract lat/lng
  - Error handling tốt

✅ **OSRM Route Integration:**
  - Call OSRM API để tính lộ trình
  - Multiple servers fallback
  - Auto retry với timeout
  - Fallback sang route thẳng nếu OSRM fail

✅ **Firebase Integration:**
  - Auto lấy robot location làm pickup
  - Push đơn hàng mới với route points
  - Realtime sync với mobile app

#### Usage Examples:

```bash
# Tạo 1 đơn từ Google Maps link
python Embedded/auto_create_order.py "https://maps.google.com/..."

# Demo với địa điểm có sẵn
python Embedded/demo_create_order.py

# Tạo nhiều đơn (batch)
python Embedded/batch_create_orders.py 5

# Chạy examples
python Embedded/examples_usage.py
```

### 📚 Documentation
- Thêm hướng dẫn chi tiết trong README_AUTO_ORDER.md
- Thêm comments đầy đủ trong code
- Thêm docstrings cho tất cả functions

### 🎯 Benefits
- ✅ Người code robot test được mà không cần điện thoại
- ✅ Tạo test data nhanh chóng
- ✅ CI/CD friendly
- ✅ Dễ customize và mở rộng

---

## [0.1.0] - Before 2025-12-20

### Existing Files:
- `firebase_sample.py` - Firebase client cơ bản
- `listen_orders.py` - Theo dõi đơn hàng realtime
- `run_periodic_update.py` - Giả lập robot di chuyển
- `requirements.txt` - Dependencies

### Features:
- ✅ Firebase Realtime Database client
- ✅ Order listening với SSE
- ✅ Robot location simulation
- ✅ Data models (Order, RoutePoint, Robot)
