# 🚀 Trực quan hóa Dữ liệu (Data Visualization - Power BI)

Tài liệu này hướng dẫn cách kết nối Microsoft Power BI Desktop trực tiếp với kho dữ liệu Spark SQL, đồng thời sử dụng các công cụ nâng cao như Power Query, Bravo và DAX để xây dựng một Dashboard phân tích nghiệp vụ hoàn chỉnh.

## 🎯 Mục tiêu
- **Trích xuất dữ liệu:** Lấy bảng dữ liệu phẳng (`wide_streams`) từ tầng Serving (Marts layer).
- **Tiền xử lý (Power Query):** Chuẩn hóa kiểu dữ liệu trước khi đưa vào mô hình.
- **Mô hình hóa (Data Modeling):** Sử dụng **Bravo for Power BI** để tạo bảng `Date` tự động phục vụ cho các phép phân tích theo thời gian (Time Intelligence).
- **Tính toán (DAX):** Viết các hàm DAX (Data Analysis Expressions) để linh hoạt tính toán các chỉ số (Metrics) kinh doanh.

---

## 🛠️ Bước 1: Kết nối và Trích xuất Dữ liệu

1. Mở ứng dụng **Power BI Desktop**.
2. Tại màn hình chính, chọn **Get Data** (Lấy dữ liệu) -> Chọn **More...** (Thêm...).
3. Trong ô tìm kiếm, gõ **Spark** -> Chọn **Spark** từ danh sách kết quả -> Bấm **Connect**.
4. Điền các thông số mạng của hệ thống Spark Thrift Server:
   - **Server:** `localhost:10000`
   - **Protocol:** `HTTP`
   - **Data Connectivity mode:** Chọn **Import** (Nhập bản sao dữ liệu vào RAM để tối ưu tốc độ tính toán DAX và tương tác biểu đồ).
5. Tại cửa sổ xác thực, điền **Username:** `hive` (Mật khẩu bỏ trống) -> Bấm **Connect**.
6. Cửa sổ Navigator hiện ra, mở rộng thư mục `musicify` -> Tích chọn bảng **`wide_streams`**.
7. Thay vì bấm Load ngay, hãy bấm **Transform Data** (Chuyển đổi dữ liệu) để mở cửa sổ Power Query.

---

## 🧹 Bước 2: Chuẩn hóa bằng Power Query

Tại màn hình **Power Query Editor**, chúng ta thực hiện một số bước kiểm tra cuối cùng:
1. **Kiểm tra Data Types (Kiểu dữ liệu):** Đảm bảo cột thời gian (`ts`) được định dạng đúng là `Date/Time`, các cột kinh độ/vĩ độ là `Decimal Number`, các cột đếm (như `duration`) là số thực.
2. Đổi tên các cột (nếu cần) để thân thiện hơn với người dùng cuối (Ví dụ: `ts` -> `Stream_Time`).
3. Sau khi hoàn tất, bấm **Close & Apply** (Đóng và Áp dụng) để hệ thống kéo dữ liệu từ HDFS vào mô hình Power BI.

---

## 📅 Bước 3: Tạo Bảng Thời gian với Bravo for Power BI

Để phân tích xu hướng nghe nhạc theo tháng, quý hoặc thứ trong tuần, hệ thống bắt buộc phải có một Bảng Thời gian (Date Table) chuẩn mực. Thay vì viết code phức tạp, chúng ta sử dụng công cụ bên thứ 3 là Bravo.

1. Tải và cài đặt phần mềm **Bravo for Power BI** (công cụ miễn phí từ SQLBI).
2. Mở **Bravo for Power BI** lên. 
3. Vào tab **Attach to Power BI Desktop** -> Bấm vào project **Musicify**.
4. Trong giao diện Bravo, chọn tab **Dates** (Bảng thời gian) ở cột bên trái.
5. Cấu hình định dạng ngày tháng theo khu vực (Region) và năm tài chính (nếu cần).
6. Bấm **Apply Changes**. Bravo sẽ tự động đẩy một bảng `Date` hoàn chỉnh vào mô hình Power BI của bạn.
7. Quay lại Power BI, vào chế độ **Model view** (Khung nhìn mô hình hóa), nối (Relationship) cột `Date` của bảng Date vừa tạo với cột `Stream_Time` của bảng `wide_streams` (Quan hệ 1-Nhiều).

---

## 🧮 Bước 4: Xây dựng các Chỉ số bằng DAX

Khuyến nghị tạo một bảng rỗng chuyên chứa các Measure (Ví dụ: tên là `_Key_Measures`) để quản lý các công thức DAX gọn gàng. Dưới đây là một số DAX cơ bản cần có:

```dax
// 1. Tổng số lượt nghe nhạc
Total_Streams = COUNTROWS('wide_streams')

// 2. Tổng số người dùng duy nhất (Active Users)
Total_Users = DISTINCTCOUNT('wide_streams'[userId])

// 3. Tổng thời lượng nghe (Quy đổi ra giờ)
Total_Listening_Hours = SUM('wide_streams'[duration]) / 3600

// 4. Số lượt nghe của tháng trước (Ứng dụng Time Intelligence từ bảng Date)
Streams_Last_Month = CALCULATE([Total_Streams], PREVIOUSMONTH('Date'[Date]))
```

---

## 📊 Bước 5: Thiết kế Biểu đồ (Dashboarding)

Với dữ liệu đã được mô hình hóa và các DAX Measures có sẵn, bạn có thể thiết kế Dashboard gồm các biểu đồ sau để lột tả toàn bộ giá trị của Data Pipeline:

1. **KPI Cards:** Đặt ở trên cùng, hiển thị các chỉ số `Total_Streams`, `Total_Users`, `Total_Listening_Hours`.
2. **Line Chart (Biểu đồ đường):** Thể hiện xu hướng (Trend) lượt nghe nhạc theo thời gian (kéo thứ, ngày, tháng từ bảng Date vào trục X, `Total_Streams` vào trục Y).
3. **Donut Chart (Biểu đồ bánh Donut):** Thể hiện sự phân bổ. Ví dụ: Tỷ lệ tài khoản Free vs Paid (Cột `level`), hoặc tỷ lệ giới tính (Cột `gender`).
4. **Bar/Column Chart:** Top 10 Bài hát (Cột `song`) hoặc Top 10 Nghệ sĩ (Cột `artist`) có nhiều lượt stream nhất.
5. **Map (Bản đồ):** Sử dụng cột `lat`, `lon` hoặc mã vùng `state` để theo dõi mật độ người dùng nghe nhạc trực quan trên bản đồ.

⏭️ **Bước tiếp theo:** Sau khi Dashboard đã lên hình đẹp đẽ, hãy chuyển sang mảnh ghép cuối cùng: [Setup Apache Airflow](airflow.md) để tự động hóa (Orchestration) toàn bộ các quy trình trên bằng một nút bấm!