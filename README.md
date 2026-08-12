# ☎️ Dự án Phân tích Vận hành Trung tâm Cuộc gọi 📶

> **Lưu ý:** Bối cảnh doanh nghiệp trong dự án này (tên công ty, quy mô, tình huống kinh doanh) là **giả định**, được xây dựng để minh họa cách áp dụng phân tích dữ liệu vào bài toán vận hành trung tâm cuộc gọi thực tế.

SQL: Create View

---

## 📊 1. Tổng quan Dự án
Dự án phân tích dữ liệu vận hành trong 4 năm (từ 2018 đến 2021) của một trung tâm cuộc gọi (call center - bộ phận chuyên xử lý các cuộc gọi đến và đi từ khách hàng và đối tác để chăm sóc khách hàng, hỗ trợ kỹ thuật, bán hàng hoặc thu thập thông tin thị trường, *[KrispCall, 2026]*[^1]).

Phân tích được thực hiện bằng SQL Server để xử lý dữ liệu cuộc gọi ở cấp độ giao dịch, sau đó xây dựng dashboard Power BI nhằm theo dõi 3 nhóm bài toán cốt lõi:
- **Thỏa thuận chất lượng dịch vụ (Service Level Agreement - SLA):** Chỉ số đánh giá liệu một cuộc gọi có được trả lời trong ngưỡng thời gian nhất định hay không
- **Giờ vàng & Giờ chết (Workforce Planning):** Phân tích sự biến động của lượng cuộc gọi theo thời gian, xác định khung giờ quá tải và khung giờ nhàn rỗi, bố trí nhân sự
- **Hiệu suất nhân viên (Rep Performance)**: Đánh giá hiệu suất xử lý cuộc gọi của từng nhân viên

🗃️ **Quy mô dữ liệu:** 130.000+ cuộc gọi

---

## 2. Vấn đề Kinh doanh & Mục tiêu
**Bối cảnh (giả định):** Trung tâm vận hành nhiều chi nhánh (`Site`), mỗi chi nhánh có đội ngũ nhân viên (`Employee`) và quản lý (`Manager`) riêng, tiếp nhận nhiều loại cuộc gọi khác nhau (được phân loại theo `Call Type`). Ban quản lý muốn đánh giá lại hiệu quả vận hành: liệu khách hàng có đang phải chờ quá lâu không, thời điểm nào quá tải, chi nhánh/nhân viên nào cần được hỗ trợ thêm, và liệu việc mở rộng doanh nghiệp qua các năm có ảnh hưởng đến chất lượng dịch vụ (SLA) không.
 
**Câu hỏi kinh doanh cần trả lời:**
- **Thỏa thuận chất lượng dịch vụ (Service Level Agreement - SLA):** Bao nhiêu % cuộc gọi được trả lời trong ngưỡng thời gian chờ chấp nhận được?  Mối tương quan giữa loại cuộc gọi và thời gian chờ?
- **Workforce Planning:** Khung giờ nào trong ngày quá tải và khung giờ nào nhàn rỗi? Biến động cuộc gọi theo ngày và tháng như thế nào? Chi nhánh nào đang quá tải, chi nhánh nào đang nhàn rỗi? Có cần bố trí lại nhân sự không?
- **Performance Tracking:** Nhân viên/Chi nhánh nào có thời gian xử lý cuộc gọi và thời gian chờ tốt nhất và tệ nhất? Loại cuộc gọi nào chiếm tỷ trọng lớn nhất? Loại cuộc gọi nào tốn nhiều thời gian xử lý nhất?

**Mục tiêu (KPI):**
- % SLA Compliance: Tỷ lệ cuộc gọi có đạt ngưỡng SLA về thời gian chờ
   - Cuộc gọi đạt (`WaitTime` ≤ 35) được đánh giá là _**"Within SLA"**_
   - Cuộc gọi không đạt (`WaitTime` ≥ 35) được đánh giá là _**"Outside SLA"**_
- % Call Type: Tỷ trọng các loại cuộc gọi
- % Abandoned Call: Tỷ lệ cuộc gọi bị hủy bỏ
- Average Wait Time: Thời gian chờ trung bình
- Average Call Duration: Thời gian xử lý cuộc gọi trung bình
- Phân bổ khối lượng cuộc gọi theo thời gian/ theo chi nhánh/ theo loại cuộc gọi

---
## 3. Bộ Dữ liệu
 
Dataset gồm **7 bảng gốc**: 4 bảng Fact tách riêng theo năm (2018–2021) và 3 bảng Dimension, liên kết theo mô hình star schema.
 
**🔹 Fact Tables (theo năm)**
| Bảng | Mô tả |
|---|---|
| Call Center Data 2018 | Dữ liệu cuộc gọi năm 2018 |
| Call Center Data 2019 | Dữ liệu cuộc gọi năm 2019 |
| Call Center Data 2020 | Dữ liệu cuộc gọi năm 2020 |
| Call Center Data 2021 | Dữ liệu cuộc gọi năm 2021 |
 
Các bảng Fact đều có cấu trúc cột giống nhau:
| Cột | Mô tả |
|---|---|
| CallTimestamp | Ngày & giờ diễn ra cuộc gọi |
| CallTypeID | Mã loại cuộc gọi |
| EmployeeID | Mã nhân viên tiếp nhận cuộc gọi |
| CallDuration | Thời lượng cuộc gọi (giây) |
| WaitTime | Thời gian khách hàng chờ trước khi được trả lời (giây) |
| CallAbandoned | 1 = cuộc gọi bị hủy bỏ, 0 = cuộc gọi được xử lý |
 
**🔹 Employee Table**
| Cột | Mô tả |
|---|---|
| EmployeeID | Mã nhân viên (Khóa chính) |
| EmployeeName | Họ tên nhân viên |
| Site | Chi nhánh làm việc |
| ManagerName | Quản lý của nhân viên |

**🔹 Call Type ID Table**
| Cột | Mô tả |
|---|---|
| CallTypeID | Mã loại cuộc gọi (Khóa chính) |
| CallTypeDesc | Mô tả loại cuộc gọi |
 
---
 
## 4. Công cụ sử dụng
- **Excel:** kiểm tra chéo dữ liệu thô trước khi import vào SQL Server
- **SQL Server:** join các bảng Dim và Fact, tổng hợp dữ liệu cuộc gọi ở cấp độ giao dịch cho từng năm và qua 4 năm, tạo các views
- **Power BI Desktop:** xây dựng data model dạng star schema, viết DAX measures, thiết kế dashboard

---
 
## 5. Làm sạch Dữ liệu
**1️⃣ Bước 1 - Excel: Chuẩn bị file nguồn:**

- Chuyển định dạng cột `CallAbandoned` từ Text sang **Number** để khi import vào SQL Server cột này được nhận đúng kiểu dữ liệu `BIT`
- Lưu file dưới dạng **CSV** để Import Flat File ở SSMS

**2️⃣ Bước 2 - SSMS: Làm sạch các bảng Dimension:**

- Loại bỏ các dòng có khóa chính bị trống ở `Dim_CallType` và `Dim_CallCharges`, tránh lỗi khi join với bảng Fact

**3️⃣ Bước 3 - SSMS: Làm sạch bảng Fact:**
- Kiểm tra `EmployeeID` và `CallTypeID` trong Fact Table có tồn tại trong bảng Dim tương ứng không, tránh lỗi orphan record khi join
- Kiểm tra dữ liệu bất thường trước khi phân tích (`CallDuration < 0 OR WaitTime < 0`)
- Thêm cột `SLA_Compliance` (kiểu `VARCHAR(20)`) vào từng bảng Fact theo năm, gán giá trị `'Within SLA'` nếu `WaitTime < 35`, ngược lại là `'Outside SLA'`

**4️⃣ Bước 4 - SSMS: Gộp 4 bảng Fact đã làm sạch thành một view duy nhất:**
- Sau khi mỗi bảng đã có cột `SLA_Compliance`, gộp cả 4 bảng theo năm thành view `v_Fact_All` bằng `UNION ALL`

---
 
## 6. Phân Tích SQL
 
**Câu hỏi 1 (SLA Compliance): SLA compliance rate và abandon rate theo từng ngày trong tuần?**
```sql
SELECT 
    DATENAME(WEEKDAY, f.CallTimestamp) AS day_of_week,
    COUNT(*) AS total_calls,
    ROUND(AVG(CAST(f.SLA_Flag AS FLOAT)), 3) AS sla_compliance_rate,
    ROUND(AVG(CAST(f.CallAbandoned AS FLOAT)), 3) AS abandon_rate
FROM FactCalls f
GROUP BY DATENAME(WEEKDAY, f.CallTimestamp)
ORDER BY total_calls DESC;
```
*Insight: [Điền kết quả thực tế sau khi chạy query trên dữ liệu của bạn — ví dụ: ngày nào có abandon rate cao nhất, có tương quan với SLA compliance thấp không]*
 
**Câu hỏi 2 (Workforce Planning): Khung giờ nào trong ngày có lượng cuộc gọi cao nhất, theo từng site?**
```sql
SELECT 
    e.Site,
    DATEPART(HOUR, f.CallTimestamp) AS call_hour,
    COUNT(*) AS total_calls,
    ROUND(AVG(CAST(f.CallAbandoned AS FLOAT)), 3) AS abandon_rate
FROM FactCalls f
JOIN EmployeeTable e ON f.EmployeeID = e.EmployeeID
GROUP BY e.Site, DATEPART(HOUR, f.CallTimestamp)
ORDER BY e.Site, total_calls DESC;
```
*Insight: [Điền khung giờ cao điểm thực tế theo từng site — site nào có mức chênh lệch tải giữa các giờ lớn nhất, cần ưu tiên bố trí thêm nhân sự]*
 
**Câu hỏi 3 (Performance Tracking): Site/nhân viên nào có thời gian chờ và xử lý cuộc gọi tốt nhất?**
```sql
SELECT 
    e.Site,
    e.EmployeeName,
    e.ManagerName,
    COUNT(f.EmployeeID) AS total_calls_handled,
    ROUND(AVG(f.WaitTime), 1) AS avg_wait_time_sec,
    ROUND(AVG(f.CallDuration), 1) AS avg_call_duration_sec,
    ROUND(AVG(CAST(f.CallAbandoned AS FLOAT)), 3) AS abandon_rate
FROM FactCalls f
JOIN EmployeeTable e ON f.EmployeeID = e.EmployeeID
GROUP BY e.Site, e.EmployeeName, e.ManagerName
ORDER BY avg_wait_time_sec ASC;
```
*Insight: [Điền top/bottom nhân viên thực tế — nhân viên nào có avg_wait_time thấp nhưng abandon_rate cũng thấp là nhóm hiệu suất tốt nhất, cần nhân rộng quy trình]*
 
**Câu hỏi 4 (Call Type Analysis): Loại cuộc gọi nào tốn thời gian xử lý nhiều nhất?**
```sql
SELECT 
    ct.CallTypeDesc,
    COUNT(*) AS total_calls,
    ROUND(AVG(f.CallDuration), 1) AS avg_call_duration_sec,
    ROUND(AVG(f.WaitTime), 1) AS avg_wait_time_sec
FROM FactCalls f
JOIN CallTypeTable ct ON f.CallTypeID = ct.CallTypeID
GROUP BY ct.CallTypeDesc
ORDER BY avg_call_duration_sec DESC;
```
*Insight: [Điền loại cuộc gọi nào chiếm nhiều thời gian xử lý nhất — có thể là cơ sở để tách riêng đội ngũ chuyên trách cho loại cuộc gọi phức tạp]*
 
---
 
## 7. Dashboard Power BI

**1. Xây dựng bảng Dim_Date:**
Vì bảng `Fact_Call` chỉ có cột `CallTimestamp` dạng datetime, cần tạo riêng một bảng `Dim_Date` bằng DAX để hỗ trợ phân tích theo tháng, ngày, thứ, phục vụ theo dõi xu hướng theo thời gian mà không bị ảnh hưởng bởi các bộ lọc.

```dax
Dim_Date = 
 var StartDate = calculate(min(Fact_Call[Call Timestamp]), all(Fact_Call))
 var EndDate = calculate(max(Fact_Call[Call Timestamp]), all(Fact_Call))
 return calendar(StartDate, EndDate)

Year = year(Dim_Date[Date])
Quarter = year(Dim_Date[Date]) & " Q" & quarter(Dim_Date[Date])
Month = format(Dim_Date[Date],"yyyy mmm")
Day = day(Dim_Date[Date])
Weekday = format(Dim_Date[Date],"ddd")
Month_Order = year(Dim_Date[Date]) * 100 + month(Dim_Date[Date])
Weekday_Order = weekday(Dim_Date[Date], 2)
```

**2. Data Modeling:**


> *(Chèn ảnh chụp màn hình dashboard thực tế tại đây, ví dụ: `![SLA Dashboard](images/dashboard_sla.png)`)*
 
**Dashboard:**
- **Trang 1 — Tổng Quan SLA:** SLA compliance rate theo ngày/tuần, abandon rate, gauge chart so với mục tiêu SLA, xu hướng theo thời gian
- **Trang 2 — Nhân Sự & Khung Giờ:** Heatmap lượng cuộc gọi theo giờ × site, so sánh abandon rate giữa các site
- **Trang 3 — Hiệu Suất Nhân Viên & Loại Cuộc Gọi:** Bảng xếp hạng nhân viên theo wait time/call duration, phân tích theo loại cuộc gọi (`CallTypeDesc`)
**DAX Measures tiêu biểu:**
```dax
SLA Compliance Rate = 
DIVIDE(
    CALCULATE(COUNTROWS(FactCalls), FactCalls[SLA_Flag] = 1),
    COUNTROWS(FactCalls)
)
 
Abandonment Rate = 
DIVIDE(
    CALCULATE(COUNTROWS(FactCalls), FactCalls[CallAbandoned] = 1),
    COUNTROWS(FactCalls)
)
 
Average Wait Time (sec) = AVERAGE(FactCalls[WaitTime])
 
Average Call Duration (sec) = AVERAGE(FactCalls[CallDuration])
 
Total Calls = COUNTROWS(FactCalls)
```
 
---
 
## 8. Phát Hiện Chính
> Điền các phát hiện nổi bật nhất sau khi chạy đầy đủ query ở mục 6. Gợi ý các hướng phát hiện thường gặp với loại dữ liệu này:
- 🔑 [SLA compliance rate tổng thể là bao nhiêu %, so với mục tiêu đề ra]
- 🔑 [Khung giờ/ngày nào có abandon rate cao bất thường]
- 🔑 [Site nào đang có hiệu suất (wait time, abandon rate) kém hơn hẳn các site còn lại]
- 🔑 [Loại cuộc gọi nào chiếm tỷ trọng lớn và có avg_call_duration cao nhất]
---
 
## 9. Đề Xuất Giải Pháp
> Đề xuất cần bám sát vào Key Insights thực tế ở mục 8. Ví dụ mẫu:
- ✅ Bổ sung nhân sự vào khung giờ/site có abandon rate cao nhất được phát hiện ở mục 6-7
- ✅ Xây dựng quy trình chuẩn (SOP) riêng cho loại cuộc gọi có avg_call_duration cao nhất, giảm tải xử lý
- ✅ Nhân rộng quy trình làm việc của site/nhân viên có hiệu suất tốt nhất sang các site khác
- ✅ Thiết lập ngưỡng cảnh báo SLA real-time để quản lý (Manager) từng site kịp thời điều phối
---
 
## 10. Khó Khăn & Hạn Chế
- Dataset **không có cột thể hiện kết quả xử lý cuộc gọi** (resolution status), nên không thể tính First Call Resolution (FCR) — một chỉ số quan trọng khi đánh giá chất lượng dịch vụ
- Dataset không có thông tin chi phí vận hành theo site/nhân viên, nên chưa thể tính ROI cụ thể của các đề xuất bổ sung nhân sự
- Bối cảnh doanh nghiệp (tên công ty, mục tiêu SLA cụ thể) là giả định, ngưỡng SLA 35 giây được chọn theo chuẩn phổ biến của ngành, không phải số liệu nội bộ thực tế
---
 
## 11. Kết Luận
Dự án áp dụng SQL và Power BI để trả lời 3 nhóm câu hỏi cốt lõi trong vận hành call center — SLA Compliance, Workforce Planning và Performance Tracking — dựa trên bộ dữ liệu thực tế gồm Fact Table và 2 dimension table (Employee, Call Type). Qua dự án, mình thực hành xây dựng star schema, viết SQL để tính các KPI đặc thù ngành (SLA rate, Abandonment rate, Wait time), đồng thời hiểu rõ hơn về giới hạn của một bộ dữ liệu thực tế (thiếu cột FCR) và cách trình bày điều đó minh bạch thay vì suy diễn thêm dữ liệu không có.
 
---
 
## 12. Hướng Dẫn Chạy Dự Án
 
**Cấu trúc thư mục:**
```
├── data/
│   ├── FactCalls.csv
│   ├── EmployeeTable.csv
│   └── CallTypeTable.csv
├── sql/
│   ├── 01_data_cleaning.sql
│   ├── 02_sla_analysis.sql
│   ├── 03_workforce_analysis.sql
│   ├── 04_performance_analysis.sql
│   └── 05_calltype_analysis.sql
├── powerbi/
│   └── CallCenter_Dashboard.pbix
├── images/
│   ├── dashboard_sla.png
│   ├── dashboard_workforce.png
│   └── dashboard_performance.png
└── README.md
```
 
**Các bước thực hiện:**
1. Clone repository: `git clone https://github.com/username/callcenter-analytics.git`
2. Import 3 file CSV trong thư mục `data/` vào SQL Server (đặt tên bảng: `FactCalls`, `EmployeeTable`, `CallTypeTable`)
3. Chạy lần lượt các file trong `sql/` theo thứ tự
4. Mở file `CallCenter_Dashboard.pbix` bằng Power BI Desktop, trỏ lại data source về SQL Server của bạn
---
 
## 13. Liên Hệ
- 📧 Email: nguyenvana@example.com
- 💼 LinkedIn: linkedin.com/in/nguyenvana
- 🔗 Portfolio: nguyenvana-portfolio.com
 
---
[^1]: KrispCall, 2026. https://krispcall.com/call-contact-center/what-is-a-call-center/
