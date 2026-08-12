# ☎️ Dự án Phân tích Vận hành Trung tâm Cuộc gọi 📶

> **Lưu ý:** Bối cảnh doanh nghiệp trong dự án này (tên công ty, quy mô, tình huống kinh doanh) là **giả định**, được xây dựng để minh họa cách áp dụng phân tích dữ liệu vào bài toán vận hành trung tâm cuộc gọi thực tế.

SQL: Create View

## 📊 1. Tổng quan Dự án
Dự án phân tích dữ liệu vận hành của một trung tâm chăm sóc khách hàng (Call Center) đa chi nhánh (site), sử dụng SQL Server để xử lý dữ liệu cuộc gọi ở cấp độ giao dịch, sau đó xây dựng dashboard Power BI nhằm theo dõi 3 nhóm bài toán cốt lõi: **SLA Compliance** (tỷ lệ trả lời đúng hạn), **Workforce Planning** (bố trí nhân sự theo khung giờ) và **Performance Tracking** (hiệu suất nhân viên theo từng site).
 
---
 
## 2. Vấn đề Kinh doanh
**Bối cảnh (giả định):** Trung tâm vận hành nhiều site/chi nhánh, mỗi site có đội ngũ nhân viên (agent) và quản lý (manager) riêng, tiếp nhận nhiều loại cuộc gọi khác nhau (được phân loại theo `Call Type`). Ban quản lý muốn đánh giá lại hiệu quả vận hành: liệu khách hàng có đang phải chờ quá lâu không, thời điểm nào quá tải, và site/nhân viên nào cần được hỗ trợ thêm.
 
**Câu hỏi kinh doanh cần trả lời:**
- **SLA Compliance:** Bao nhiêu % cuộc gọi được trả lời trong ngưỡng thời gian chờ chấp nhận được? Tỷ lệ cuộc gọi bị bỏ dở (abandoned) là bao nhiêu, và có liên quan đến thời gian chờ không?
- **Workforce Planning:** Khung giờ nào trong ngày lượng cuộc gọi tăng đột biến (peak hours)? Site nào đang quá tải so với các site khác?
- **Performance Tracking:** Nhân viên/site nào có thời gian xử lý cuộc gọi (`CallDuration`) và thời gian chờ (`WaitTime`) tốt nhất? Loại cuộc gọi nào (`CallType`) tốn nhiều thời gian xử lý nhất?

**Mục tiêu (KPI):**
- SLA Compliance Rate (% cuộc gọi có `WaitTime` dưới ngưỡng SLA đặt ra, ví dụ 35 giây)
- Call Abandonment Rate (dựa trên cột `CallAbandoned`)
- Average Wait Time & Average Call Duration
- Phân bổ khối lượng cuộc gọi theo giờ / theo site / theo loại cuộc gọi
---
## 3. Mục tiêu

---
## 3. Bộ Dữ liệu
 
Dataset gồm 3 bảng, liên kết theo mô hình star schema: `Fact Table` (bảng sự kiện, mỗi dòng là 1 cuộc gọi) liên kết với 2 bảng dimension là `Employee Table` và `Call Type ID Table`.
 
**🔹 Fact Table**
| Cột | Mô tả |
|---|---|
| CallTimestamp | Ngày & giờ diễn ra cuộc gọi |
| CallTypeID | Mã loại cuộc gọi (liên kết với Call Type ID Table) |
| EmployeeID | Mã nhân viên tiếp nhận cuộc gọi (liên kết với Employee Table) |
| CallDuration | Thời lượng cuộc gọi (giây) |
| WaitTime | Thời gian khách hàng chờ trước khi được trả lời (giây) |
| CallAbandoned | 1 = cuộc gọi bị bỏ dở, 0 = cuộc gọi được xử lý |
 
**🔹 Employee Table**
| Cột | Mô tả |
|---|---|
| EmployeeID | Mã nhân viên (khóa chính) |
| EmployeeName | Họ tên nhân viên |
| Site | Chi nhánh/địa điểm làm việc |
| ManagerName | Quản lý trực tiếp của nhân viên |
 
**🔹 Call Type ID Table**
| Cột | Mô tả |
|---|---|
| CallTypeID | Mã loại cuộc gọi (khóa chính) |
| CallTypeDesc | Mô tả loại cuộc gọi |
 
> **Ghi chú:** Dataset này không có cột thể hiện kết quả xử lý cuộc gọi (VD: "đã giải quyết xong hay chưa"), nên dự án **không tính được chỉ số First Call Resolution (FCR)** như một số dự án call center khác. Đây là điểm được nêu rõ trong phần [Khó Khăn & Hạn Chế](#10-khó-khăn--hạn-chế).
 
---
 
## 4. Công Cụ Sử Dụng
- **SQL Server** — xử lý, join 3 bảng, tổng hợp dữ liệu cuộc gọi ở cấp độ giao dịch
- **Power BI Desktop** — xây dựng data model dạng star schema, viết DAX measures, thiết kế dashboard
- **Excel** — kiểm tra chéo dữ liệu thô trước khi import vào SQL Server
---
 
## 5. Làm Sạch Dữ Liệu
Các bước xử lý dữ liệu thực hiện trên Fact Table:
- Kiểm tra giá trị `NULL` hoặc âm ở `CallDuration` và `WaitTime`
- Kiểm tra `EmployeeID` và `CallTypeID` trong Fact Table có tồn tại trong bảng dimension tương ứng không (tránh lỗi orphan record khi join)
- Tạo cột tính toán `SLA_Flag`: đánh dấu `1` nếu `WaitTime <= 35` giây, ngược lại `0`
- Tách `CallTimestamp` thành các cột phụ trợ: `CallDate`, `CallHour`, `DayOfWeek` để phục vụ phân tích theo khung giờ
```sql
-- Kiểm tra dữ liệu bất thường trước khi phân tích
SELECT COUNT(*) AS invalid_rows
FROM FactCalls
WHERE CallDuration < 0 OR WaitTime < 0;
 
-- Kiểm tra orphan record (EmployeeID không tồn tại trong Employee Table)
SELECT f.EmployeeID
FROM FactCalls f
LEFT JOIN EmployeeTable e ON f.EmployeeID = e.EmployeeID
WHERE e.EmployeeID IS NULL;
 
-- Tạo cột SLA flag
ALTER TABLE FactCalls ADD SLA_Flag AS (CASE WHEN WaitTime <= 35 THEN 1 ELSE 0 END);
```
 
**Mô hình dữ liệu (Data Model):** `Fact Table` liên kết với `Employee Table` qua `EmployeeID`, và với `Call Type ID Table` qua `CallTypeID` — đúng chuẩn star schema với 1 fact table và 2 dimension table.
 
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
> *(Chèn ảnh chụp màn hình dashboard thực tế tại đây, ví dụ: `![SLA Dashboard](images/dashboard_sla.png)`)*
 
**Cấu trúc dashboard — 3 trang:**
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
 
