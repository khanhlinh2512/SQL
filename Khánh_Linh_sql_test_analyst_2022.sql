--PART 1
--1. Show list of transactions occurring in February 2018 with SHIPPED status.

select * from Table1 
where [status] = 'SHIPPED' AND MONTH([transaction_date]) = 2 
and year([transaction_date]) = 2018

--2. Show list of transactions occurring from midnight to 9 AM

with tb as(
SELECT id, customer_id, vendor,
[status],convert(Time,[transaction_date]) AS [Time] from Table1)
select * from tb 
where [Time] BETWEEN '00:00:00' AND '09:00:00'

--3. Show a list of only the last transactions from each vendor

with cte as(
select [order_id],[transaction_date], Vendor, status, DENSE_RANK() OVER (PARTITION By Vendor  ORDER BY [transaction_date] Desc) 
AS Rank from Table1)
select [order_id],[transaction_date], Vendor from cte where [Rank]=1

--4. Show a list of only the second last transactions from each vendor

with cte as(
select [order_id],[transaction_date], Vendor,status, DENSE_RANK() OVER (PARTITION By Vendor  ORDER BY [transaction_date] Desc) 
AS Rank from Table1)
select [order_id],[transaction_date], Vendor, status 
from cte where [Rank] = 2

--5. Count the transactions from each vendor with the status CANCELLED per day

Select vendor,count(*) as [Count_trans_cancel], [transaction_date] from Table1 
where [status] = 'CANCELLED'
group by vendor, [transaction_date]
order by [transaction_date]

--6. Show a list of customers who made more than 1 SHIPPED purchases

select [customer_id] from (
select [customer_id], count([status])as [count of shipped] from Table1
where [status] = 'SHIPPED'
group by [customer_id]
having count([status])>=2) as T

--7. Show the total transactions (volume) and category of each vendors by following these criteria:
--a. Superb: More than 2 SHIPPED and 0 CANCELLED transactions
--b. Good: More than 2 SHIPPED and 1 or more CANCELLED transactions
--c. Normal: other than Superb and Good criteria
--Order the vendors by the best category (Superb, Good, Normal), then by the biggest 
--transaction volum
--Cách 1: 
with trans as(
select D.*,T.ship_trans from ((
select Vendor, count(*) as [total_trans] from Table1
group by Vendor) as D 
join
(select Vendor, count(*) as [ship_trans] from Table1
where [status] = 'SHIPPED'
group by Vendor) as T
on T.vendor = D.Vendor))
Select Vendor, total_trans as [Total Transaction],
(case when total_trans - ship_trans = 0 and ship_trans > 2 then 'Superb'
	when total_trans - ship_trans >= 1 and ship_trans > 2 then 'Good'
	else 'Normal' 
	end) as [Category]
from trans
--Cách 2: 
with a as(
SELECT vendor,customer_id, order_id, transaction_date,
(CASE WHEN [status] = 'SHIPPED' THEN 1 END) AS [SHIPPED],
(CASE WHEN [status] = 'CANCELLED' THEN 0 END) AS [CANCELLED]
FROM Table1)
select vendor, count([SHIPPED]) + count([CANCELLED]) AS [total_transaction],
case when count([SHIPPED]) > 2 and  COUNT([CANCELLED]) = 0 then 'Superb'
	 when count([SHIPPED]) > 2 and  COUNT([CANCELLED]) >= 1 then 'Good'
	 else 'Normal'
	 end as [Category]
from a
group by vendor
--8. Group the transactions by hour of transaction_date

SELECT DATEPART(HOUR, [transaction_date]) as [Hours], count(*) as [Total Transaction] FROM TABLE1
group by DATEPART(HOUR, [transaction_date])

--9. Group the transactions by day and statuses as the example below

SELECT CONVERT(DATE,[transaction_date]) as [Date], 
count(case when [status] = 'SHIPPED' then [status] end) as [SHIPPED],
count(case when [status] = 'CANCELLED' then [status] end) as [CANCELLED],
count(case when [status] = 'PROCESSING' then [status] end) as [PROCESSING]
FROM TABLE1
group by CONVERT(DATE,[transaction_date])
ORDER BY CONVERT(DATE,[transaction_date])

--10.Calculate the average, minimum and maximum of days interval of each transaction (how  many days from one transaction to the next)

select avg(diff) as [Average Interval], min(diff) as [Minimum Interval],
max(diff) as [Maximum Interval] 
from(
select [order_id],DATEDIFF(DAY,[transaction_date],(SELECT TOP 1 [transaction_date] 
FROM  Table1 d1 
WHERE d1.[transaction_date] > d2.[transaction_date]
ORDER BY d1.[transaction_date])) as diff , [transaction_date]  FROM TABLE1 d2) as T

--PART 2: 
---1. Show the sum of the total value of the products shipped along with the Distributor 
--Commissions (2% of the total product value if total quantity is 100 or less, 4% of the total 
--product value if total quantity sold is more than 100)

SELECT product_name, sum([price]*[quantity]) as [Value (quantity x price)],
(case when sum(quantity) <= 100 then sum([price]*[quantity]*0.02)
	else sum([price]*[quantity]*0.04)
	end) as [Distributor Commission]
FROM TABLE2
GROUP BY product_name


--2. Show total quantity of “Indomie (all variant)” shipped within February 2018

select sum([quantity]) as [total_quantity] from table2
where product_name like 'Indomie%' and trx_id in (
select id from Table1 
where month([transaction_date]) = 2 and year([transaction_date]) = 2018) 

--3. For each product, show the ID of the last transaction which contained that particular product
with last_trans as(
select trx_id,[product_name],DENSE_RANK() OVER (PARTITION By product_name  ORDER BY trx_id Desc) as [Last Transaction ID]
from table2)
select [product_name],trx_id from last_trans where [Last Transaction ID] = 1
order by [product_name]