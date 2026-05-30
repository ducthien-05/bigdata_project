# 🎵 Musicify - End-to-End Local Data Pipeline

Một dự án Data Engineering hoàn chỉnh xây dựng luồng xử lý dữ liệu từ Streaming đến Batch Processing, được tự động hóa hoàn toàn (Orchestration) sử dụng Kafka, Spark, HDFS, dbt, Airflow, Docker và Power BI.

## 📌 Description

### Objective
Dự án mô phỏng quá trình thu thập và xử lý luồng sự kiện (events) theo thời gian thực từ một ứng dụng nghe nhạc giả lập (tương tự Spotify). Dữ liệu bao gồm các hành vi của người dùng như: nghe nhạc, chuyển bài, đăng nhập. 

Luồng dữ liệu (Data Pipeline) sẽ bắt các sự kiện này, xử lý và lưu trữ xuống Data Lake (HDFS). Sau đó, hệ thống Transformation (dbt) sẽ nhào nặn dữ liệu thô thành cấu trúc Star Schema (Fact & Dim tables) để phục vụ cho việc trực quan hóa. Toàn bộ quy trình này được đặt dưới sự điều phối tự động của **Apache Airflow**. Cuối cùng, Power BI sẽ kết nối thông qua Spark SQL để hiển thị các chỉ số phân tích kinh doanh (Top bài hát, Nhân khẩu học, Xu hướng nghe nhạc...).

### Dataset
Dự án sử dụng [Eventsim](https://github.com/Interana/eventsim) để sinh ra dữ liệu hành vi người dùng hoàn toàn giả lập nhưng có logic tương tự dữ liệu thực tế. Eventsim sử dụng tập dữ liệu bài hát từ [Million Songs Dataset](http://millionsongdataset.com).

### 🛠️ Tools & Technologies
Kiến trúc của dự án được triển khai hoàn toàn trên môi trường Local thông qua các container (Decoupled Architecture).
- Containerization: [**Docker**](https://www.docker.com), [**Docker Compose**](https://docs.docker.com/compose/)
- Data Generation: **Eventsim** (Scala)
- Stream Processing / Message Broker: [**Apache Kafka**](https://kafka.apache.org)
- Data Lake (Storage): **Hadoop Distributed File System (HDFS)**
- Metadata Management: **Apache Hive Metastore** & **PostgreSQL**
- Compute Engine: [**Apache Spark & Spark SQL**](https://spark.apache.org/) (Spark Thrift Server)
- Data Transformation: [**dbt** (Data Build Tool)](https://www.getdbt.com)
- Orchestration: [**Apache Airflow**](https://airflow.apache.org/)
- Developer Tools / Ad-hoc Query: **DBeaver**
- Data Visualization: **Microsoft Power BI**

### 💻 Development Environment
Dự án được tối ưu để chạy trên môi trường Linux. Hệ thống được thiết lập và vận hành thông qua:
- **OS:** Windows 10/11 với **WSL 2 (Windows Subsystem for Linux)** - Bản phân phối **Ubuntu**.
- **IDE:** **Visual Studio Code** kết hợp với extension **WSL** để lập trình, gỡ lỗi và thực thi lệnh trực tiếp bên trong môi trường Linux.

### 🏗️ Data Architecture
Kiến trúc hệ thống được chia làm các phân hệ độc lập, tách biệt rõ ràng giữa Lưu trữ (Storage), Cấu trúc (Metadata) và Tính toán (Compute):
<p align="center">
  <img src="images/Data_Architecture.jpg" alt="Data Architecture" width="100%">
</p>

### 📊 Dashboard
<p align="center">
  <img src="images/dashboard.png" alt="Power BI Dashboard" width="100%">
</p>

---

## 🚀 Setup & Execution Guide

Dự án được chia thành các module độc lập nhưng liên kết chặt chẽ với nhau thông qua Docker Network. Để chạy dự án trên máy local của bạn, vui lòng làm theo thứ tự các tài liệu hướng dẫn cấu hình chi tiết dưới đây:

1. **Khởi tạo Data Generator & Message Queue:**
   - [Setup Kafka & EventSim](setup/kafka.md)
2. **Khởi tạo Data Lake, Metadata & Processing Engine:**
   - [Setup HDFS, Hive Metastore & Spark Cluster](setup/spark.md)
3. **Chuyển đổi dữ liệu (Data Transformation):**
   - [Setup dbt (Data Build Tool)](setup/dbt.md)
4. **Trực quan hóa (Data Visualization):**
   - [Kết nối Power BI với Spark Thrift Server qua cổng 10000](setup/powerbi.md)
5. **Điều phối tự động (Orchestration):**
   - [Setup Apache Airflow & Trigger DAG](setup/airflow.md)

---

## 💡 Future Improvements
- Triển khai (Migration) toàn bộ hạ tầng Local lên nền tảng Cloud (ví dụ: Amazon Web Services - AWS EC2, S3, EMR).
- Tích hợp kiểm thử chất lượng dữ liệu (Data Quality Checks) vào pipeline bằng Great Expectations hoặc dbt tests.
- Thiết lập luồng CI/CD (Continuous Integration / Continuous Deployment) sử dụng GitHub Actions.