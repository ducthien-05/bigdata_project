# 🎲 EventSim - Music Streaming Data Generator

## 📌 Overview
Thư mục này chứa mã nguồn và cấu hình của **EventSim**, một công cụ giả lập dữ liệu hành vi người dùng (User Event Simulator). Bạn có thể tìm repo chính thức [tại đây](https://github.com/Interana/eventsim).
Trong kiến trúc của dự án Streamify, EventSim đóng vai trò là nguồn phát sinh luồng dữ liệu (Data Source), mô phỏng hàng ngàn người dùng đang nghe nhạc và tương tác trên nền tảng.

## ⚙️ How it works
EventSim sử dụng các dữ liệu gốc (seed data) trong thư mục `data/` (như danh sách bài hát, tên người, mã vùng US) để tạo ra các bản ghi sự kiện (event logs) dưới định dạng JSON một cách ngẫu nhiên nhưng có tính logic thực tế.

* **Data Generation Logic:** EventSim core engine (được viết bằng Scala) sẽ nạp các file tĩnh từ thư mục `data/`. Nó thực hiện "Cross-join" ngẫu nhiên giữa bộ dữ liệu Nhân khẩu học (`yob1990.txt`, `Top1000Surnames.csv`, `US.txt`) và bộ dữ liệu Âm nhạc (`songs_analysis.txt.gz`) dựa trên các mô hình xác suất để tạo ra hàng triệu luồng sự kiện (event streams) sát với hành vi con người thực tế.

Các loại sự kiện giả lập bao gồm:
- `Listen`: Người dùng phát một bài hát.
- `Auth`: Đăng nhập/Đăng xuất.
- `Page View`: Xem trang nghệ sĩ/bài hát.

## 📂 Folder Structure
- `data/`: Chứa các file raw data (.csv, .txt, .gz) làm nguyên liệu giả lập.
- `examples/`: Chứa các file cấu hình `.json` thiết lập tham số sinh dữ liệu.
- `Dockerfile`: Lệnh build image cho EventSim.

## 🚀 Execution via Docker Compose
Trong dự án này, EventSim không chạy đơn lẻ mà được quản lý thông qua file `docker-compose.yml` tại thư mục gốc. Nó được thiết lập để chờ Kafka (`broker`) khởi động xong trước khi bắt đầu bắn dữ liệu.

Cấu hình service được sử dụng:
```yaml
  eventsim:
    build: ./eventsim
    container_name: eventsim
    depends_on:
      - broker
    command: -c "examples/example-config.json" --start-time "2026-01-01T00:00:00" --end-time "2026-12-31T23:59:59" --nusers 1000 --kafkaBrokerList broker:29092 --continuous