# 🚀 Cài đặt Data Generator & Message Queue (Kafka + EventSim)

Tài liệu này hướng dẫn cách khởi động hệ thống sinh dữ liệu sự kiện giả lập (EventSim) và hệ thống Message Broker (Apache Kafka) để hứng dữ liệu theo thời gian thực (Streaming).

## 🎯 Mục tiêu
- **EventSim:** Đóng vai trò là ứng dụng nghe nhạc, liên tục sinh ra các log hành vi của hàng triệu người dùng (nghe bài gì, lúc nào, thiết bị gì...) dưới dạng JSON.
- **Apache Kafka:** Đóng vai trò là "ống nước khổng lồ" hứng toàn bộ log từ EventSim để tránh rơi rớt dữ liệu, chờ hệ thống Spark kéo về Data Lake.

---

## 🛠️ Hướng dẫn Khởi động

### Bước 1: Khởi động cụm Docker
Mở Terminal, di chuyển vào thư mục chứa dự án và chạy lệnh khởi động dưới chế độ chạy ngầm (detached):

```bash
cd ~/bigdata_project
docker-compose up -d
```
*Lưu ý: Quá trình khởi động lần đầu có thể mất từ 1-2 phút.*

### Bước 2: Kiểm tra trạng thái Container
Xác nhận hệ thống đã lên đủ các dịch vụ:

```bash
docker ps
```
Bạn cần đảm bảo các container như `broker`, `zookeeper`, `schema-registry`, `control-center` và `eventsim` đều đang ở trạng thái **Up**.

---

## 💻 Tương tác và Kiểm tra dữ liệu (CLI Scripts)
Để kiểm tra xem hệ thống sinh dữ liệu và ống nước Kafka có đang hoạt động mượt mà không, hãy chạy các lệnh tương tác trực tiếp dưới đây tại Terminal:

**1. Kiểm tra log sinh dữ liệu của EventSim**
Đảm bảo ứng dụng giả lập đang liên tục sinh data mà không bị lỗi:
```bash
docker logs eventsim -f
```
*(Bấm `Ctrl + C` để thoát chế độ xem log).*

**2. Liệt kê các Topic hiện có trong Kafka**: Xem danh sách các luồng dữ liệu (topics) đã được tự động khởi tạo
```bash
docker exec -it broker kafka-topics --bootstrap-server localhost:9092 --list
```

**3. Đọc thử dữ liệu Real-time (Consume Messages)**: Trích xuất thử 5 bản ghi đầu tiên của từng topic để kiểm tra xem cấu trúc dữ liệu JSON sinh ra có chuẩn xác không

- Đọc sự kiện nghe nhạc (`listen_events`):
```bash
docker exec -it broker kafka-console-consumer --bootstrap-server localhost:9092 --topic listen_events --from-beginning --max-messages 5
```
- Đọc sự kiện đăng nhập/đăng xuất (`auth_events`):
```bash
docker exec -it broker kafka-console-consumer --bootstrap-server localhost:9092 --topic auth_events --from-beginning --max-messages 5
```
- Đọc sự kiện chuyển trang (`page_view_events`):
```bash
docker exec -it broker kafka-console-consumer --bootstrap-server localhost:9092 --topic page_view_events --from-beginning --max-messages 5
```

**4. Kiểm tra dung lượng vật lý**: Dữ liệu streaming chạy liên tục có thể làm đầy ổ cứng. Dùng lệnh này để kiểm tra xem phân vùng lưu trữ của Kafka đang chiếm bao nhiêu dung lượng
```bash
docker exec -it broker du -sh /var/lib/kafka/data
```

---

## 👁️‍🗨️ Giám sát luồng dữ liệu qua Giao diện Web (UI)
Dự án được tích hợp sẵn **Confluent Control Center** để theo dõi trực quan luồng sự kiện.
1. Mở trình duyệt Web và truy cập vào: [http://localhost:9021](http://localhost:9021)
2. Chọn cụm **Cluster 1**.
3. Bấm vào menu **Topics** ở cột bên trái. 
4. Nếu bạn thấy biểu đồ `Production` nhảy số liên tục, hệ thống Streaming của bạn đang hoạt động hoàn hảo!

---

## 🛑 Cách tắt hệ thống
Khi muốn dừng toàn bộ cụm Kafka và EventSim để giải phóng RAM cho máy tính:

```bash
docker-compose down
# docker-compose stop
```

---
⏭️ **Bước tiếp theo:** Sau khi Kafka đã hứng được dữ liệu, hãy chuyển sang [Setup HDFS & Spark Cluster](spark_hdfs.md) để kéo dữ liệu này lưu trữ xuống Data Lake.