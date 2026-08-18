# ☎️ Dự án Phân tích Vận hành Trung tâm Cuộc gọi 📶

---

## 📊 1. Tổng quan Dự án
Dự án phân tích dữ liệu vận hành trong 4 năm (từ 2018 đến 2021) của trung tâm cuộc gọi **Happy Call** (call center - bộ phận chuyên xử lý các cuộc gọi đến và đi từ khách hàng và đối tác để chăm sóc khách hàng, hỗ trợ kỹ thuật, bán hàng hoặc thu thập thông tin thị trường, *[KrispCall, 2026]*[^1]).

Phân tích được thực hiện bằng SQL Server để xử lý dữ liệu cuộc gọi ở cấp độ giao dịch, sau đó xây dựng dashboard Power BI nhằm theo dõi 3 nhóm bài toán cốt lõi:
- **Thỏa thuận chất lượng dịch vụ (Service Level Agreement - SLA):** Chỉ số đánh giá liệu một cuộc gọi có được trả lời trong ngưỡng thời gian nhất định hay không
- **Giờ vàng & Giờ chết (Workforce Planning):** Phân tích sự biến động của lượng cuộc gọi theo thời gian, xác định khung giờ quá tải và khung giờ nhàn rỗi, bố trí nhân sự
- **Hiệu suất nhân viên (Rep Performance)**: Đánh giá hiệu suất xử lý cuộc gọi của từng nhân viên

🗃️ **Quy mô dữ liệu:** 130.000+ cuộc gọi

---

## 2. Vấn đề Kinh doanh & Mục tiêu
**📍 Bối cảnh:** Trung tâm cuộc gọi tại Mỹ vận hành nhiều chi nhánh (`Site`), mỗi chi nhánh có đội ngũ nhân viên (`Employee`) và quản lý (`Manager`) riêng, tiếp nhận nhiều loại cuộc gọi khác nhau (được phân loại theo `Call Type`). Ban quản lý muốn đánh giá lại hiệu quả vận hành: liệu khách hàng có đang phải chờ quá lâu không, thời điểm nào quá tải, chi nhánh/nhân viên nào cần được hỗ trợ thêm, và liệu việc mở rộng doanh nghiệp qua các năm có ảnh hưởng đến chất lượng dịch vụ (SLA) không.
 
**❓ Câu hỏi cần trả lời:**
- **Thỏa thuận chất lượng dịch vụ (Service Level Agreement - SLA):**
  - Bao nhiêu % cuộc gọi được trả lời trong ngưỡng thời gian chờ chấp nhận được?
  - Mối tương quan giữa loại cuộc gọi và thời gian chờ?
- **Personnel Performance:**
  - Nhân viên nào có tỷ lệ cuộc gọi đạt chất lượng tốt nhất và tệ nhất?
  - Nhân viên nào có thời gian chờ ngắn nhất và dài nhất?
- **Call Breakdown:**
  - Khung giờ nào trong ngày quá tải và khung giờ nào nhàn rỗi?
  - Biến động cuộc gọi theo ngày và tháng như thế nào?
  - Chi nhánh nào đang quá tải, chi nhánh nào đang nhàn rỗi?
  - Có cần bố trí lại nhân sự không?

**🎯 Mục tiêu (KPI):**
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
 
**🔹 4 Fact Tables (2018 - 2021)**
 
Mỗi bảng Fact đều có cấu trúc cột như sau:
| Cột | Mô tả |
|---|---|
| CallTimestamp | Ngày & giờ diễn ra cuộc gọi |
| CallTypeID | Mã loại cuộc gọi |
| EmployeeID | Mã nhân viên tiếp nhận cuộc gọi |
| CallDuration | Thời lượng cuộc gọi (giây) |
| WaitTime | Thời gian khách hàng chờ trước khi được trả lời (giây) |
| CallAbandoned | 1 = cuộc gọi bị hủy bỏ, 0 = cuộc gọi được xử lý |
 
**🔹 Dim_Employee Table**
| Cột | Mô tả |
|---|---|
| EmployeeID | Mã nhân viên (Khóa chính) |
| EmployeeName | Họ tên nhân viên |
| Site | Chi nhánh làm việc |
| ManagerName | Quản lý của nhân viên |

**🔹 Dim_CallType Table**
| Cột | Mô tả |
|---|---|
| CallTypeID | Mã loại cuộc gọi (Khóa chính) |
| CallTypeDesc | Tên loại cuộc gọi |

**🔹 Dim_CallCharges Table**
| Cột | Mô tả |
|---|---|
| Call Type Key | Mã loại cuộc gọi (Khóa chính) |
| Call Type | Tên loại cuộc gọi |
| Call Charges 2018 (Min) | Giá cước năm 2018 (theo phút) |
| Call Charges 2019 (Min) | Giá cước năm 2019 (theo phút) |
| Call Charges 2020 (Min) | Giá cước năm 2020 (theo phút) |
| Call Charges 2021 (Min) | Giá cước năm 2021 (theo phút) |

---
 
## 4. Công cụ sử dụng
- **Excel:** kiểm tra chéo dữ liệu thô trước khi import vào SQL Server
- **SQL Server:** join các bảng Dim và Fact, tổng hợp dữ liệu cuộc gọi ở cấp độ giao dịch cho từng năm và qua 4 năm, tạo các views
- **Power BI Desktop:** xây dựng data model dạng star schema, viết DAX measures, thiết kế dashboard

---
 
## 5. Làm sạch Dữ liệu
**1️⃣ Bước 1 - Excel: Chuẩn bị file nguồn:**
- Kiểm tra các dòng và ô bị trống và xử lý nếu có (dữ liệu này không có)
- Chuyển định dạng cột `CallAbandoned` từ Text sang **Number** để khi import vào SQL Server cột này được nhận đúng kiểu dữ liệu `BIT`
- Lưu file dưới dạng **CSV** để Import Flat File ở SSMS

**2️⃣ Bước 2 - SSMS: Làm sạch các bảng Dimension:**
- Loại bỏ các dòng có khóa chính bị trống ở `Dim_CallType` và `Dim_CallCharges`, tránh lỗi khi join với bảng Fact

**3️⃣ Bước 3 - SSMS: Làm sạch bảng Fact:**
- Kiểm tra `EmployeeID` và `CallTypeID` trong Fact Table có tồn tại trong bảng Dim tương ứng không, tránh lỗi orphan record khi join
- Kiểm tra dữ liệu bất thường trước khi phân tích (`CallDuration < 0 OR WaitTime < 0`)

**4️⃣ Bước 4 - SSMS: Gộp 4 bảng Fact đã làm sạch thành một view duy nhất:**
- Sau khi mỗi bảng đã có cột `SLA_Compliance`, gộp cả 4 bảng theo năm thành view `v_Fact_All` bằng `UNION ALL`

---
 
## 6. SQL

**🔗 Full script:** [SQL Analysis](https://github.com/nvtngan244/Call_Center_Data-SQL-PBI/blob/a9b02af311557d0b199cdf801d35a1458cf6c3f0/Project_CallCenterData.sql)

**Một số bước chính:**
- Tạo cột đánh giá chất lượng dịch vụ (Service Level Agreement - SLA): `SLA_Compliance` (kiểu `VARCHAR(20)`) vào từng bảng Fact theo năm
  - Gán giá trị `'Within SLA'` nếu `WaitTime < 35`
  - Ngược lại là `'Outside SLA'`

- Tạo view thông tin chi tiết cuộc gọi của tất cả các năm: `v_Call_All`
  - Sử dụng `UNION ALL` cho 4 bảng FACT
  - Sau đó `INNER JOIN` với 3 bảng DIM

- Trả lời các câu hỏi:
  - Tỷ lệ tuân thủ SLA tổng thể là bao nhiêu %
  - Phân tích sự biến động của cuộc gọi theo giờ, ngày, tháng
  - Top 5 và Bottom 5 nhân viên xử lý cuộc gọi hiệu quả nhất (theo thời gian chờ và tỷ lệ tuân thủ SLA)
  - Loại cuộc gọi nào chiếm tỷ trọng lớn nhất? Có mối tương quan nào giữa Call Type và thời gian chờ không?

---
 
## 7. Power BI

**1️⃣ Xây dựng bảng Dim_Date:**

- Vì bảng `Fact_Call` chỉ có cột `CallTimestamp` dạng _datetime_, cần tạo riêng một bảng `Dim_Date` bằng DAX để hỗ trợ phân tích theo tháng, ngày, thứ, phục vụ theo dõi xu hướng theo thời gian mà không bị ảnh hưởng bởi các bộ lọc
- Sau đó tạo thêm cột `Call Date` ở bảng Fact để lấy ra dạng tháng/ngày/năm của cột `Call Timestamp` (bỏ giờ) để có thể nối bảng `Dim_Date` với bảng `Fact_Call` bằng trường thời gian


**2️⃣ Data Modeling:**

<img width="1000" alt="Data Modeling" src="https://github.com/user-attachments/assets/052e4aed-6b43-42a4-9315-34664e4f5076" />


**3️⃣ Dashboard:**
- **Trang 1 - Tổng Quan SLA (Overall):**
<img width="1000" alt="CallCenterData_PBI_Dashboard_Page1" src="https://github.com/user-attachments/assets/e1e954dd-ab07-431b-b8e8-a7255107a61c" />

- **Trang 2 - Phân tích Loại cuộc gọi & Hiệu suất Chi nhánh (Breakdown):**
<img width="1000" alt="CallCenterData_PBI_Dashboard_Page2" src="https://github.com/user-attachments/assets/0d5d25c6-18be-4ba0-8e13-94cc81c78c97" />

- **Trang 3 - Hiệu suất Nhân sự (Personnel):**
<img width="1000" alt="CallCenterData_PBI_Dashboard_Page3" src="https://github.com/user-attachments/assets/79a3225d-3484-4e3b-a176-4cc2f296adc9" />


---
 
## 8. Insights chính
- 🔑 SLA trung bình 2018–2021 đạt 88.22%, xu hướng tăng nhưng chững lại ở năm gần nhất (chỉ tăng 0.01% so với năm trước)
- 🔑 Không có khác biệt đáng kể giữa các loại cuộc gọi (thời gian chờ, tỷ lệ tuân thủ SLA đều tương đương) và giữa các chi nhánh (tỷ lệ tuân thủ SLA, số cuộc gọi mỗi nhân viên nhận đồng đều dù tổng số cuộc gọi mỗi chi nhanh tiếp nhận khác nhau)
- 🔑 Khối lượng cuộc gọi tập trung rõ theo thời gian: cao điểm 8h–12h và đầu tháng, thấp điểm cuối ngày và cuối tháng
- 🔑 Có nhóm nhân sự ổn định tốt và nhóm yếu ở cả 2 chỉ số (thời gian chờ và tỷ lệ tuân thủ SLA); chi nhánh Aurora, CO ổn định nhất, chi nhánh Spokane, WA phân hóa hiệu suất nội bộ mạnh nhất

---
 
## 9. Kiến nghị
- ✅ Không cần can thiệp theo loại cuộc gọi và chi nhánh - các chỉ số đều ổn định
- ✅ Ưu tiên bố trí nhân sự tập trung nhiều hơn vào khung 8h–12h
- ✅ Đào tạo lại nhóm nhân sự yếu; kiểm tra vấn đề nằm ở cá nhân hay quản lý
- ✅ Rà soát quy trình đào tạo/phân ca tại chi nhánh Spokane, WA

---
 
## 10. Khó khăn & Hạn chế
- **Không sử dụng được triệt để dữ liệu Giá cước (Call Charge):** Dataset chỉ có giá cước mỗi phút, không rõ là phí khách trả hay chi phí vận hành cuộc gọi nên chưa sử dụng được dữ liệu này
- **Không đưa ra được insight trực tiếp về bố trí nhân sự:** Dataset không có bảng ca trực nên không thể trực tiếp tính phân bổ nhân sự trực ca, chỉ có thể tính gián tiếp bằng số cuộc gọi mỗi nhân viên nhận ở mỗi chi nhánh
- **Không tính được First Call Resolution (FCR) - tỷ lệ phần trăm của các cuộc gọi được giải quyết trong lần liên hệ đầu tiên:** FCR là chỉ số quan trọng ở nhiều trung tâm cuộc gọi, tuy nhiên dataset này không có các cột thể hiện kết quả xử lý cuộc gọi, ID người gọi, ID vấn đề cần xử lý nên không thể tính được

**>> Đề xuất lên Stakeholders về việc bổ sung các chỉ số trên**

---

# 🌟 Thanks for reading!
 
---
[^1]: KrispCall, 2026. https://krispcall.com/call-contact-center/what-is-a-call-center/
