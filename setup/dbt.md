# 🚀 Chuyển đổi và Mô hình hóa Dữ liệu (dbt - Data Build Tool)

Tài liệu này hướng dẫn cách cấu hình và vận hành **dbt**, công cụ chịu trách nhiệm nhào nặn, làm sạch và chuyển đổi dữ liệu thô (Raw Data) thành cấu trúc kho dữ liệu (Data Warehouse) chuẩn mực để phục vụ phân tích.

## 🎯 Mục tiêu
- **Mô hình hóa (Data Modeling):** Xây dựng cấu trúc Star Schema bao gồm các Bảng Danh mục (Dimension Tables) và Bảng Sự kiện (Fact Tables).
- **Tối ưu hóa (Incremental Processing):** Áp dụng chiến lược tải dữ liệu tăng dần (Incremental Load) cho bảng Fact để tiết kiệm tối đa tài nguyên tính toán của Spark.
- **Tự động hóa SQL:** dbt đóng vai trò biên dịch mã sang SQL chuẩn và gửi lệnh tới Spark SQL (Compute Engine) để thực thi.

---

## 📂 Kiến trúc Thư mục và Cấu hình (Project Structure)
Dự án được phân chia chặt chẽ thành các tầng xử lý dữ liệu thông qua file `dbt_project.yml`. Dưới đây là cấu trúc các tệp và thư mục cốt lõi:

### 1. Các tệp cấu hình gốc (.yml)
- `profiles.yml`: Khai báo kết nối đến Spark Thrift Server (Port 10000).
- `dbt_project.yml`: File cấu hình lõi của toàn bộ dự án. Định nghĩa chiến lược vật lý hóa (materialization) cho từng tầng dữ liệu.
- `packages.yml`: Chứa danh sách các thư viện mở rộng (dbt packages) được cài đặt thêm để hỗ trợ các hàm biến đổi dữ liệu phức tạp.

### 2. Phân tầng Mô hình Dữ liệu (Models)
- **`models/staging/` (Silver Layer):** Tầng làm sạch dữ liệu bước đầu.
  - Được cấu hình mặc định là `+materialized: view`.
  - Chứa tệp `schema.yml` để định nghĩa cấu trúc, test và document cho các bảng.
  - Chứa các file tiền xử lý: `stg_auth_events.sql`, `stg_listen_events.sql`, `stg_page_view_events.sql`, `stg_songs.sql`.
- **`models/cores/` (Gold Layer):** Tầng nghiệp vụ.
  - Được cấu hình mặc định là `+materialized: table`.
  - Chứa các Bảng Danh mục (Dim): `dim_artists.sql`, `dim_datetime.sql`, `dim_location.sql`, `dim_songs.sql`, `dim_users.sql`.
  - Chứa Bảng Sự kiện trung tâm (Fact): `fact_streams.sql` (Cấu hình chạy `incremental`).
- **`models/marts/` (Serving Layer):** Tầng trực quan hóa.
  - Chứa tệp `wide_streams.sql` (Bảng phẳng đã JOIN sẵn Dim và Fact) để tối ưu hóa tốc độ truy vấn cho Power BI.

---

## 🛠️ Hướng dẫn Cấu hình Môi trường

**Bước 1: Cài đặt Adapter và Thư viện mở rộng**
Di chuyển vào thư mục dự án dbt và cài đặt các thành phần cần thiết:
```bash
cd ~/bigdata_project/dbt/musicify

# Cài đặt adapter kết nối Spark
pip install dbt-spark[PyHive]

# Tải các thư viện mở rộng đã khai báo trong packages.yml
dbt deps
```

**Bước 2: Cấu hình kết nối Spark SQL**
Mở hoặc tạo tệp `~/.dbt/profiles.yml` và cấu hình chính xác như sau:
```yaml
musicify:
  outputs:
    dev:
      type: spark
      method: thrift
      host: localhost
      port: 10000
      user: hive
      schema: musicify
      threads: 4
  target: dev
```
*(Nếu chạy dbt bằng Docker container, thay `localhost` bằng `host.docker.internal`).*

---

## 💻 Tương tác và Vận hành (CLI Scripts)

Dưới đây là các câu lệnh thực thi quy trình nhào nặn dữ liệu, từ cơ bản đến nâng cao:

**1. Kiểm tra kết nối hệ thống**
```bash
dbt debug
```

**2. Nạp dữ liệu Tham chiếu (Seed Data)**
Nạp các file tĩnh (như `state_code.csv`) vào hệ thống:
```bash
dbt seed
```

**3. Chạy độc lập tầng Staging (Làm sạch)**
Chỉ thực thi việc tạo View cho các file `stg_*.sql` để kiểm thử logic làm sạch:
```bash
dbt run --select staging
```

**4. Khởi chạy toàn bộ luồng chuyển đổi**
Thực thi toàn bộ các models từ Staging, Cores đến Marts:
```bash
dbt run
```

**5. (Troubleshooting) Xử lý lỗi chạy lại Fact Table**

Trong trường hợp bạn thay đổi cấu trúc bảng Fact và dbt báo lỗi xung đột schema, hoặc bạn muốn xóa sạch dữ liệu cũ để chạy lại từ đầu (`--full-refresh`), hãy dùng lệnh thao tác trực tiếp xuống HDFS để xóa thư mục bảng Fact:
```bash
docker exec -it namenode hdfs dfs -rm -r /user/hive/warehouse/musicify.db/fact_streams
```

---
⏭️ **Bước tiếp theo:** Khi dbt chạy thành công toàn bộ mô hình, kho dữ liệu của bạn đã được tổ chức hoàn hảo. Vui lòng chuyển sang [Trực quan hóa với Power BI](powerbi.md) để khai thác các biểu đồ phân tích.