# 🚀 Điều phối Tự động (Orchestration - Apache Airflow)

Tài liệu này hướng dẫn cách khởi tạo và vận hành **Apache Airflow**, đóng vai trò là hệ thống điều phối (Orchestrator) toàn bộ vòng đời của Data Pipeline một cách tự động theo lịch trình (Scheduled) hoặc kích hoạt thủ công (Trigger).

## 🎯 Mục tiêu
- **Tự động hóa (Automation):** Thay thế việc thực thi thủ công bằng các chuỗi tác vụ (DAG - Directed Acyclic Graph).
- **Quản lý phụ thuộc (Dependency Management):** Đảm bảo tính tuần tự chặt chẽ: Dữ liệu phải được Spark xử lý trước, sau đó nạp dữ liệu tham chiếu tĩnh, và cuối cùng mới gọi lần lượt các mô hình chuyển đổi của dbt.
- **Giám sát (Monitoring):** Theo dõi tiến độ chạy, ghi nhận log lỗi và thông báo trạng thái của từng tác vụ (Task).

---

## 🛠️ Hướng dẫn Khởi động & Vận hành

### Bước 1: Khắc phục lỗi Phân quyền (QUAN TRỌNG)
*Lưu ý: Khi chạy Airflow qua Docker trên môi trường Linux/WSL, các container sử dụng người dùng `airflow` để thực thi lệnh. Nếu không cấp quyền ghi (write) cho các thư mục được gắn (mount) từ máy chủ vật lý vào container, quá trình chạy DAG sẽ phát sinh lỗi `Permission Denied`.*

Mở Terminal và di chuyển vào thư mục chứa cấu hình Airflow:
```bash
cd ~/bigdata_project/airflow
```

Thực thi các lệnh sau để cấp quyền đọc/ghi toàn diện cho các thư mục làm việc của Airflow và dbt:
```bash
# Cấp quyền cho các thư mục nội bộ của Airflow
sudo chmod -R 777 dags logs plugins

# Cấp quyền cho thư mục dbt (Để Airflow BashOperator có thể ghi tệp log/target khi gọi lệnh dbt)
sudo chmod -R 777 ../dbt
```

### Bước 2: Khởi tạo hệ thống Airflow
Sau khi đã cấp quyền, tiến hành khởi động cụm Docker của Airflow:
```bash
docker-compose up -d
```
Xác nhận các container cốt lõi như `airflow-webserver`, `airflow-scheduler`, và `postgres-airflow` (cơ sở dữ liệu lưu trữ siêu dữ liệu của Airflow) đều đang hoạt động.

---

## 👁️‍🗨️ Hướng dẫn sử dụng Giao diện Web (UI) & Kích hoạt DAG

### 1. Đăng nhập hệ thống
- Mở trình duyệt web và truy cập vào: [http://localhost:8080](http://localhost:8080)
- Đăng nhập với tài khoản quản trị viên mặc định:
  - **Username:** `admin`
  - **Password:** `admin`

### 2. Kích hoạt luồng dữ liệu (Trigger DAG)
Tại màn hình chính (trang DAGs), bạn sẽ thấy danh sách các quy trình tự động đã được lập trình sẵn.

1. Tìm DAG có tên là **`musicify_dag`**.
2. **Kích hoạt (Unpause):** Ở cột ngoài cùng bên trái của tên DAG, gạt thanh trượt từ màu xám sang màu xanh dương để hệ thống nhận diện luồng.
3. **Chạy luồng (Trigger):** Ở cột *Actions* bên phải, bấm vào biểu tượng hình tam giác (▶️ Play) -> Chọn **Trigger DAG**.

### 3. Giám sát tiến trình (Monitoring)
Sau khi Trigger, hãy bấm thẳng vào tên `musicify_dag` để xem chi tiết:
- Chuyển sang tab **Graph** (Sơ đồ đồ thị) để xem các hộp tác vụ (Tasks) đang chạy theo đúng thứ tự thiết kế:
  1. **`spark_pull_kafka_to_hdfs`**: Giả lập gọi Spark xử lý dữ liệu thô từ HDFS.
  2. **`dbt_seed_reference_data`**: Nạp dữ liệu tham chiếu tĩnh (từ tệp .csv) vào hệ thống.
  3. **`dbt_build_dimensions`**: Xây dựng các Bảng Danh mục (Dim).
  4. **`dbt_build_fact_streams`**: Xây dựng Bảng Sự kiện trung tâm (Fact).
  5. **`dbt_build_wide_streams`**: Tạo Bảng phẳng (Wide table) phục vụ trực quan hóa.
  6. **`trigger_powerbi_api`**: Kích hoạt việc làm mới dữ liệu trên Power BI.

- **Trạng thái màu sắc:**
  - 🟩 Xanh lá đậm (Success): Tác vụ đã hoàn thành.
  - 🟩 Xanh lá nhạt (Running): Tác vụ đang được xử lý.
  - 🟥 Đỏ (Failed): Tác vụ bị lỗi (Click vào ô đó -> Chọn **Log** để xem chi tiết thông báo lỗi).

---

## 🛑 Dừng hệ thống
Khi muốn dừng hệ thống điều phối để giải phóng tài nguyên tính toán:
```bash
docker-compose down
```

---
🎉 **HOÀN TẤT DỰ ÁN:** Xin chúc mừng! Bạn đã vận hành thành công toàn bộ kiến trúc Data Platform từ khâu sinh dữ liệu (EventSim) cho đến khâu điều phối luồng dữ liệu tự động.