/*
Xóa cột "Call Abandoned" khỏi các file dữ liệu cuộc gọi
Tạo cột mới "SLA Compliance": Nếu "Waittime" < 35 giây thì gán là "Within SLA", ngược lại là "Outside SLA"
*/

delete from Dim_CallType
where CallTypeId is null

delete from Dim_CallCharges
where Call_Type_Key is null

alter table Fact_CallCenterData2018 add SLA_Compliance varchar(20)
alter table Fact_CallCenterData2019 add SLA_Compliance varchar(20)
alter table Fact_CallCenterData2020 add SLA_Compliance varchar(20)
alter table Fact_CallCenterData2021 add SLA_Compliance varchar(20)

update Fact_CallCenterData2018
	set SLA_Compliance = case when waittime < 35 then 'Within SLA' else 'Outside SLA' end
update Fact_CallCenterData2019
	set SLA_Compliance = case when waittime < 35 then 'Within SLA' else 'Outside SLA' end
update Fact_CallCenterData2020
	set SLA_Compliance = case when waittime < 35 then 'Within SLA' else 'Outside SLA' end
update Fact_CallCenterData2021
	set SLA_Compliance = case when waittime < 35 then 'Within SLA' else 'Outside SLA' end


------------------------

/*
1. Sức khỏe vận hành (Overall Service Level):
	Tỷ lệ tuân thủ SLA tổng thể là bao nhiêu %? Liệu có xu hướng đi lên hay xuống qua các năm 2018-2020?
*/
with Call1820 as (
	select * from Fact_CallCenterData2018
	union all select * from Fact_CallCenterData2019
	union all select * from Fact_CallCenterData2020 
	),
WithinSLA as (
	select year(CallTimeStamp) _Year, count(SLA_Compliance) as Call_WithinSLA
	from Call1820
	where SLA_Compliance = 'Within SLA'
	group by year(CallTimeStamp)
	)
select a._Year, max(a.Call_WithinSLA) as CallWithinSLA, count(b.SLA_Compliance) TotalCall, cast(max(a.Call_WithinSLA) * 100.00 / count(b.SLA_Compliance) as decimal(5,2)) as [%WithinSLA]
from WithinSLA a
right join Call1820 b on year(b.CallTimeStamp) = a._Year
group by _Year
order by _Year




/*
2. Giờ vàng & Giờ chết:
	Phân tích sự biến động của cuộc gọi theo giờ, ngày, tháng. Đâu là thời điểm nhà máy "nổ tung" vì lượng gọi quá tải?
*/
select * into #All_CallData
from (
    select * from Fact_CallCenterData2018
    union all 
    select * from Fact_CallCenterData2019
    union all 
    select * from Fact_CallCenterData2020
    union all 
    select * from Fact_CallCenterData2021
) as c

-- Thống kê số lượng cuộc gọi theo giờ (2018 - 2021)
select datepart(hour, CallTimestamp) as Hour, count(CallTimestamp) as CallCount
from #All_CallData
group by datepart(hour, CallTimestamp)
order by count(CallDuration) desc

-- Thống kê số lượng cuộc gọi theo ngày (2018 - 2021)
select day(CallTimestamp) as Day, count(CallTimestamp) as CallCount
from #All_CallData
group by day(CallTimestamp)
order by count(CallDuration) desc

-- Thống kê số lượng cuộc gọi theo tháng (2018 - 2021)
select month(CallTimestamp) as Month, count(CallTimestamp) as CallCount
from #All_CallData
group by month(CallTimestamp)
order by count(CallDuration) desc




/*
3. Hiệu suất nhân viên (Rep Performance): 
	Top 5 nhân viên xử lý cuộc gọi hiệu quả nhất và Bottom 5 nhân viên cần được đào tạo thêm dựa trên thời gian chờ (Waittime) và kết quả SLA?
*/
create view v_Call_All
as
with All_CallData as (
	select * from Fact_CallCenterData2018
	union all 
	select * from Fact_CallCenterData2019
	union all 
	select * from Fact_CallCenterData2020
	union all 
	select * from Fact_CallCenterData2021)
select d.EmployeeID, d.EmployeeName, 
	c.CallTypeID, b.Call_Type,
	a.CallDuration, a.WaitTime, a.SLA_Compliance
from All_CallData a
	inner join Dim_CallCharges b on a.Call_Type = b.Call_Type_Key
	inner join Dim_CallType c on b.Call_Type_Key = c.CallTypeID
	inner join Dim_Employee d on a.EmployeeID = d.EmployeeID

-- Top 5 nhân viên xử lý cuộc gọi hiệu quả nhất
select top 5 EmployeeID, EmployeeName, avg(cast(WaitTime as decimal(5,2))) as AVG_Waittime
from v_Call_All
group by EmployeeID, EmployeeName
order by avg(WaitTime)

-- Top 5 nhân viên xử lý cuộc gọi kém hiệu quả nhất
select top 5 EmployeeID, EmployeeName, avg(cast(WaitTime as decimal(5,2))) as AVG_Waittime
from v_Call_All
group by EmployeeID, EmployeeName
order by avg(WaitTime) desc




/*
4. Phân tích loại cuộc gọi:
	Loại cuộc gọi nào chiếm tỷ trọng lớn nhất? Có mối tương quan nào giữa Call Type và thời gian chờ không?
*/
with TotalCall as (
	select count(*) as TotalCall
	from v_Call_All)
select CallTypeID as Call_Type_Id, max(Call_Type) as Call_Type, cast(count(*) * 100.00 / t.TotalCall as decimal(5,2)) as [%_Call_Type]
from v_Call_All v
	cross join TotalCall t
group by CallTypeID, t.TotalCall
order by cast(count(*) * 100.00 / t.TotalCall as decimal(5,2)) desc
--> Loại cuộc gọi chiếm tỷ trọng lớn nhất: Tech support (50.23%)

select 
    CallTypeID, count(*) as TotalCall, avg(cast(WaitTime as decimal(5,2))) as AVG_Waittime
from v_Call_All
group by CallTypeID




/*
5. Báo cáo xu hướng (Trend Analysis)
	So sánh hiệu suất giữa 3 năm. Sự mở rộng của doanh nghiệp có làm giảm chất lượng dịch vụ (SLA) không?
*/
create view v_Call_2018
as
select d.EmployeeID, d.EmployeeName, 
	c.CallTypeID, b.Call_Type,
	a.CallDuration, a.WaitTime, a.SLA_Compliance
from Fact_CallCenterData2018 a
	inner join Dim_CallCharges b on a.Call_Type = b.Call_Type_Key
	inner join Dim_CallType c on b.Call_Type_Key = c.CallTypeID
	inner join Dim_Employee d on a.EmployeeID = d.EmployeeID

create view v_Call_2019
as
select d.EmployeeID, d.EmployeeName, 
	c.CallTypeID, b.Call_Type,
	a.CallDuration, a.WaitTime, a.SLA_Compliance
from Fact_CallCenterData2019 a
	inner join Dim_CallCharges b on a.Call_Type = b.Call_Type_Key
	inner join Dim_CallType c on b.Call_Type_Key = c.CallTypeID
	inner join Dim_Employee d on a.EmployeeID = d.EmployeeID

create view v_Call_2020
as
select d.EmployeeID, d.EmployeeName, 
	c.CallTypeID, b.Call_Type,
	a.CallDuration, a.WaitTime, a.SLA_Compliance
from Fact_CallCenterData2020 a
	inner join Dim_CallCharges b on a.Call_Type = b.Call_Type_Key
	inner join Dim_CallType c on b.Call_Type_Key = c.CallTypeID
	inner join Dim_Employee d on a.EmployeeID = d.EmployeeID

create view v_Call_2021
as
select d.EmployeeID, d.EmployeeName, 
	c.CallTypeID, b.Call_Type,
	a.CallDuration, a.WaitTime, a.SLA_Compliance
from Fact_CallCenterData2021 a
	inner join Dim_CallCharges b on a.Call_Type = b.Call_Type_Key
	inner join Dim_CallType c on b.Call_Type_Key = c.CallTypeID
	inner join Dim_Employee d on a.EmployeeID = d.EmployeeID

with Total2018 as (select count(*) as TotalCall from v_Call_2018),
	Total2019 as (select count(*) as TotalCall from v_Call_2019),
	Total2020 as (select count(*) as TotalCall from v_Call_2020),
	Total2021 as (select count(*) as TotalCall from v_Call_2021)
select 
	Total2018.TotalCall as [2018_TotalCall],
    (select cast(count(*) * 100.00 / t18.TotalCall as decimal(5,2)) 
     from v_Call_2018 cross join Total2018 t18 
     where SLA_Compliance = 'Within SLA' group by t18.TotalCall) as [2018_%_WithinSLA],
	 Total2019.TotalCall as [2019_TotalCall],
    (select cast(count(*) * 100.00 / t19.TotalCall as decimal(5,2)) 
     from v_Call_2019 cross join Total2019 t19 
     where SLA_Compliance = 'Within SLA' group by t19.TotalCall) as [2019_%_WithinSLA],
	 Total2020.TotalCall as [2020_TotalCall],
    (select cast(count(*) * 100.00 / t20.TotalCall as decimal(5,2)) 
     from v_Call_2020 cross join Total2020 t20 
     where SLA_Compliance = 'Within SLA' group by t20.TotalCall) as [2020_%_WithinSLA],
	 Total2021.TotalCall as [2021_TotalCall],
    (select cast(count(*) * 100.00 / t21.TotalCall as decimal(5,2)) 
     from v_Call_2021 cross join Total2021 t21 
     where SLA_Compliance = 'Within SLA' group by t21.TotalCall) as [2021_%_WithinSLA]
from Total2018 cross join Total2019 cross join Total2020 cross join Total2021
