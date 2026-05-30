# 🚀 Khởi tạo Data Lake, Metadata & Processing Engine (HDFS + Hive + Spark)

Tài liệu này hướng dẫn cách khởi động cụm lưu trữ phân tán (HDFS), hệ thống quản lý siêu dữ liệu (Hive Metastore) và động cơ tính toán (Apache Spark). Đặc biệt bao gồm bước kích hoạt tiến trình **Spark Structured Streaming** để thu thập dữ liệu từ Kafka.

## 🎯 Mục tiêu
- **HDFS (Hadoop):** Đóng vai trò là Data Lake, lưu trữ dữ liệu thô (Raw Data) dưới định dạng JSON.
- **Hive Metastore & PostgreSQL:** Đóng vai trò là Metadata Store, lưu trữ cấu trúc định nghĩa bảng (Schema) và ánh xạ (Mapping) chúng xuống các tệp vật lý tại HDFS.
- **Apache Spark:** Đóng vai trò là Compute Engine, thực hiện tiến trình thu thập dữ liệu thời gian thực (Streaming Job), đồng thời cung cấp giao thức truy vấn thông qua Spark SQL (Thrift Server) để xử lý dữ liệu.

---

## 🛠️ Hướng dẫn Khởi động & Vận hành

### Bước 1: Khởi tạo cụm Docker
Mở Terminal, di chuyển vào thư mục chứa cấu hình của Spark và HDFS và thực thi lệnh:
```bash
cd ~/bigdata_project/spark 
docker-compose up -d
```
```bash
cd ~/bigdata_project/hdfs 
docker-compose up -d
```
Xác nhận hệ thống khởi tạo đầy đủ các dịch vụ cốt lõi bằng lệnh `docker ps` (`namenode`, `datanode`, `hive-metastore`, `postgres-hive`, `spark-master`, `spark-worker`, `spark-thrift-server`).

### Bước 2: Kích hoạt tiến trình Data Ingestion (Kafka ➡️ HDFS)
Đây là bước bắt buộc để hệ thống bắt đầu quá trình thu thập dữ liệu. Chúng ta cần nạp các tệp mã nguồn Python vào Spark Master và kích hoạt Streaming Job.

1. **Sao chép mã nguồn xử lý vào container Spark Master:**
```bash
docker cp schema.py spark-master:/schema.py
docker cp streaming_functions.py spark-master:/streaming_functions.py
docker cp stream_all_events.py spark-master:/stream_all_events.py
```

2. **Submit tiến trình Spark Streaming:**
Thực thi lệnh sau để Spark bắt đầu tiêu thụ (consume) dữ liệu từ Kafka và ghi dưới định dạng tệp JSON xuống HDFS:
```bash
docker exec -it spark-master /spark/bin/spark-submit \
  --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.3.0 \
  --py-files /schema.py,/streaming_functions.py \
  --master spark://spark-master:7077 \
  --total-executor-cores 2 \
  /stream_all_events.py
```

---

## 💻 Tương tác và Kiểm tra dữ liệu (CLI Scripts)

### 1. Kiểm tra dữ liệu vật lý tại Data Lake (HDFS)
Sau khi submit job khoảng vài phút, vui lòng kiểm tra trạng thái ghi tệp tại HDFS:
- Kiểm tra tệp sự kiện nghe nhạc:
```bash
docker exec -it namenode sh -c "hdfs dfs -find /datalake/listen_events -name '*.json' | head -n 1 | xargs hdfs dfs -cat | head -n 5"
```
- Kiểm tra tệp sự kiện đăng nhập:
```bash
docker exec -it namenode sh -c "hdfs dfs -find /datalake/auth_events -name '*.json' | head -n 1 | xargs hdfs dfs -cat | head -n 5"
```
- Kiểm tra file sự kiện chuyển trang:
```bash
docker exec -it namenode sh -c "hdfs dfs -find /datalake/page_view_events -name '*.json' | head -n 1 | xargs hdfs dfs -cat | head -n 5"
```
### 2. Định hình cấu trúc dữ liệu (Schema-on-Read)
Để các công cụ định tuyến như dbt hoặc Power BI có thể thực thi truy vấn, hệ thống cần định nghĩa các tệp thô thành cấu trúc Bảng. 
*Lưu ý: Dự án sử dụng cấu trúc `CREATE EXTERNAL TABLE`. Bảng ngoại (External Table) giúp tách biệt việc quản lý siêu dữ liệu (Metadata) và dữ liệu vật lý (Physical Data). Nếu xảy ra lệnh `DROP TABLE`, hệ thống chỉ xóa siêu dữ liệu trong danh mục Hive, trong khi dữ liệu vật lý tại HDFS vẫn được bảo toàn.*

**Phương án 1: Sử dụng Spark SQL CLI (Terminal)**
```bash
docker exec -it spark-master /spark/bin/spark-sql
```

**Phương án 2: Sử dụng DBeaver (Khuyến nghị)** 

DBeaver cung cấp giao diện trực quan (GUI) để quản trị và kiểm thử chất lượng dữ liệu:
1. Khởi động DBeaver -> New Connection -> Chọn **Apache Spark** (hoặc Hive).
2. Thông số kết nối: Host: `localhost` | Port: `10000` | Username: `hive` (hoặc để trống).
3. Kết nối, mở SQL Editor và thực thi tập lệnh dưới đây:

```sql
-- 1. Khởi tạo và sử dụng Database
CREATE DATABASE IF NOT EXISTS musicify;
USE musicify;

-- 2. Ánh xạ bảng listen_events
CREATE EXTERNAL TABLE listen_events (
    artist STRING, 
    auth STRING, 
    city STRING, 
    duration DOUBLE, 
    firstName STRING, 
    gender STRING, 
    itemInSession INT, 
    lastName STRING, 
    lat DOUBLE, 
    level STRING, 
    lon DOUBLE, 
    registration BIGINT, 
    song STRING, 
    state STRING, 
    ts STRING, 
    userAgent STRING, 
    userId STRING
) USING json LOCATION 'hdfs://namenode:9000/datalake/listen_events';

-- 3. Ánh xạ bảng auth_events
CREATE EXTERNAL TABLE IF NOT EXISTS auth_events (
    ts STRING,
    sessionId BIGINT,
    level STRING,
    itemInSession BIGINT,
    city STRING,
    state STRING,
    userAgent STRING,
    lon DOUBLE,
    lat DOUBLE,
    userId BIGINT,
    lastName STRING,
    firstName STRING,
    gender STRING,
    registration BIGINT,
    success BOOLEAN
) 
USING json LOCATION 'hdfs://namenode:9000/datalake/auth_events';

-- 4. Ánh xạ bảng page_view_events
CREATE EXTERNAL TABLE page_view_events (
    artist STRING, 
    auth STRING, 
    city STRING, 
    duration DOUBLE, 
    firstName STRING, 
    gender STRING, 
    itemInSession INT, 
    lastName STRING, 
    lat DOUBLE, 
    level STRING, 
    lon DOUBLE, 
    method STRING, 
    page STRING, 
    registration BIGINT, 
    sessionId STRING, 
    song STRING, 
    state STRING, 
    status INT, 
    ts STRING, 
    userAgent STRING, 
    userId STRING
) USING json LOCATION 'hdfs://namenode:9000/datalake/page_view_events';
```

Sau khi hoàn tất quá trình ánh xạ, bạn có thể thực hiện thao tác chuột phải vào bảng trên cấu trúc cây của DBeaver -> **View Data** để hiển thị dữ liệu trực quan.

---

## 👁️‍🗨️ Giám sát hệ thống qua Giao diện Web (UI)
- **HDFS NameNode UI:** [http://localhost:9870](http://localhost:9870) (Trình duyệt cấu trúc lưu trữ phân tán `/datalake`).
- **Spark Master UI:** [http://localhost:8080](http://localhost:8080) (Giám sát tài nguyên và các Streaming Job đang thực thi).

---

## 🛑 Dừng hệ thống
Để dừng các container và giải phóng tài nguyên:
```bash
docker-compose down
# docker-compose stop
```

---
⏭️ **Bước tiếp theo:** Sau khi dữ liệu thô đã được ánh xạ thành công qua Hive, vui lòng chuyển sang [Setup dbt (Data Build Tool)](dbt.md) để tiến hành quy trình chuyển đổi và mô hình hóa (Data Transformation).