--creating daytabase for shopping market
-- savdo bozori uchun malumotlar bazasini yaratish

create database shopping_market;

create table sales_store(
transaction_id varchar(15),
customer_id varchar(15),
customer_name nvarchar(30),
customer_age int,
gender varchar(15),
product_id varchar(15),
product_name varchar(15),
product_category varchar(15),
quantity int,
prce float,
payment_mode varchar(15),
purchase_date date,
time_of_purchase time,
status varchar (15)
);
select * from sales_store;

--importing csv die into sales_store table
--csv faylni sales_store jadvaliga yuklash

set dateformat dmy
bulk insert sales_store
from 'C:\Users\nozim\Downloads\sales.csv'
	with (
	firstrow=2,
	fieldterminator=',',
	rowterminator='\n'
);

-- copying all data from sales_store table into a new table 
-- sales_store jadvalidagi barcha malumotlarni sales nomli yangi jadvalga kochirish


select * from sales_store
select * into sales from sales_store;

select * from sales_store
select * from sales;

--1.->a) to check for duplicate

select transaction_id, count(*)
from sales
group by transaction_id
having count(transaction_id) >1

-->b) select transactions with row numbers for duplicate check  
-- takror qiymatlarni tekshirish uchun tranzaksiyalarni tartib raqami bilan olish

with cte as (
select *, 
	row_number() over (partition by transaction_id
	order by transaction_id)as row_num
	from sales
)
select * from cte
--where row_num>1;
where transaction_id in ('TXN240646','TXN342128','TXN855235',
'XN981773')

-->c) deleting dublicate records
-- takror qiymatlarni o'chirish

with cte as (
select *, 
	row_number() over (partition by transaction_id
	order by transaction_id)as row_num
	from sales
)
delete from cte where row_num=2

--2. correction of headers
-- sarlavhalarni tuzish

select * from sales

exec sp_rename'sales.prce','price','column'

--3. to check datatype
-- malumot turini tekshirish

select column_name, data_type
from information_schema.columns
where table_name='sales'

--4. to check null values
-- qiymat kiritilmagan joyini tekshirish
--a)to check null count
-- qiymat kiritilmagan joyini sanog'ini tekshirish

declare @sql nvarchar(max)='';
select @sql =string_agg(
	'select '''+column_name+'''as columname,
	count(*) as nullcount
	from ' +quotename (table_schema) + '.sales
	where '+quotename(column_name) + 'is null',
	' union all '
)
within group (order by column_name)
from information_schema.columns
where table_name= 'sales';

--b) execute the dynamic sql
--dinamik(harakatga keladigan, o'zgaruvchi) sqlni ishga tushirish
exec sp_executesql @sql;


--c) treating null values
-- qiymati bo'lmagan joyi bilan ishlash

select * from sales
where transaction_id is null
or 
customer_id is null
or
customer_name is null
or 
customer_age is null
or
gender is null
or
product_id is null
or
product_name is null
or
product_category is null
or
quantity is null
or
price is null
or
payment_mode is null
or
purchase_date is null
or
time_of_purchase is null
or
status is null

delete from sales
where transaction_id is null

select * from sales 
where customer_name='Ehsaan Ram'

update sales
set customer_id='CUST9494'
where transaction_id='TXN977900'

select * from sales
where customer_name='Damini Raju'
update sales
set customer_id='CUST1401'
where transaction_id='TXN985663'


select * from sales
where customer_id='CUST1003'

update sales
set customer_name='Mahika Saini', customer_age=35, gender='Male'
where transaction_id='TXN432798'

select * from sales

--5. data cleaning 

select distinct gender
from sales

update sales
set gender='F'
where gender= 'Female'

update sales
set gender='M'
where gender= 'Male'

select distinct payment_mode
from sales

update sales
set payment_mode='Credit Card'
where payment_mode= 'CC'

----------------------Data analysis--------------------------
--------------------Malumotlar tahlili--------------------------

--1. what are the top 5 most selling products by quantity?
-- eng ko'p sotilgan 5 ta mahsulot miqdor boyicha

select top 5 product_name, sum(quantity) as total_quantity_sold
from sales
where status='delivered'
group by product_name
order by total_quantity_sold desc

--business problem: we don't know whic products are most in demand
-- muammo: qaysi mahsulot eng kop talab qilinishini bilmaymiz
-- business impact: helps prioritize stock and boost sales through targeted promotions.
-- yechim: mahsulotlarni ustuvorligini va savdoni oshirish
-----------------------------------
--2. which products are most frequently canceled?
-- qaysi mahsulotlar eng kop bekor qilingan?

select top 5 product_name, count(*) as total_cancelled
from sales
where status='cancelled'
group by product_name
order by total_cancelled desc

--business problem: frequent cancellations affect revenue and customer trust.
-- muammo: ko'p bekor qilishlar daromad va mijozni ishonchiga ta'sir qiladi
--business impact: indentify poor-performing products to improve quality or remove from catalog
--yechim: sifati past mahsulotlarni aniqlab, yaxshilash yoki sotuvdan chiqarish

--3. what time of the day has the highest number of purchase?
-- kunning qaysi paytida eng ko'p xarid amalga oshiladi?

select * from sales
	select 
		case
			when datepart(hour, time_of_purchase) between 0 and 5 then 'night'
			when datepart(hour, time_of_purchase) between 6 and 11 then 'moeningt'
			when datepart(hour, time_of_purchase) between 12 and 17 then 'afternoon'
			when datepart(hour, time_of_purchase) between 18 and 23 then 'evening'
		end as time_of_day,
		count(*) as total_orders
	from sales
	group by 
		case 
			when datepart(hour, time_of_purchase) between 0 and 5 then 'night'
			when datepart(hour, time_of_purchase) between 6 and 11 then 'moeningt'
			when datepart(hour, time_of_purchase) between 12 and 17 then 'afternoon'
			when datepart(hour, time_of_purchase) between 18 and 23 then 'evening'
		end
	order by total_orders desc

--business problem solved: find peak sales  times
--muammo: savdo ko'payadigan eng faol vaqtlarini aniqlash
--business impact: optimizde staffing , promotions, and server loads.
--yechim: Xodimlar sonini to'g'ri taqsimlash, reklama kompaniyalarini samarali tashkil etish va server yukini boshqarishni yaxshilash

--4. who are the top 5 highest spending customers?
--eng kop xarajat qilgan 5 ta mijozni aniqlash

select * from sales

select top 5 customer_name,
	format(sum(price*quantity), 'C0', 'en-US') as total_spend
from sales
group by customer_name 
order by total_spend desc

--business problem solved: indentify vip customers
-- muammo: vip mijozni aniqlash
-- business impact: personlized offers, loyalty rewards, and retention
-- shaxsiy takliflar, bu uchun maxsus sovg'alar va mijozni shu yo'l bilan ushlab qolish

--5. which product categories generate the highest revenue?
-- qaysi mahsulot kategoriyalari(m: kiyim-kechak, mevalar) eng yuqori daromat keltiradi
select 
	product_category,
	format(sum(price*quantity),'C0', 'en-US') as revenue
from sales
group by product_category
order by sum(price*quantity) desc

--business problem solved: identify top-performing product categories.
--muammoga yechim: eng yaxshi sotilayotgan mahsulot kategoriyalarini aniqlash
--business impact: refine product strategy, supply chain, and promotions
-- mahsulot bo'yicha strategiyalarini, ta'minot zanjirini va reklama kompaniyalarini takomillashtirish
--allowing the business to invest more in high-margin or high-demand categories.
--bunda biznesga yuqori foyda yo talabga ega kategoriyalarga koproq sarmoya kiritishga yordam beradi. 

--6. what is the return/cancellation rate per product category?
--Mahsulot kategoriyasiga kora qaytarish/bekor qilish darajasi
--a) cancellation
-- bekor bolish

select product_category,
	format(count(case when status='cancelled' then 1 end)*100.0/count(*), 'N3')+ ' %' as cancelled_percent
from sales
group by product_category
order by cancelled_percent desc
--b) return
--qaytarsh

select product_category,
	format(count(case when status='returned' then 1 end)*100.0/count(*), 'N3')+ ' %' as cancelled_percent
from sales
group by product_category
order by cancelled_percent desc

---business problem solved: Monitor dissatisfaction trends per category
--muammoga yechim: Har bir kategoriyadagi mijoz norozilik holatini kuzatish
---business impact: reduce returns, improve product descriptions/expectations
-- Qaytarishlarni kamaytirish, mahsulot tavsiflarini va mijoz kutganlarini yaxshilash
---helps identify and fix product or logistics issues
--Mahsulot yoki logistika muammolarini aniqlash va tuzatishga
----------------------------------------
--7. What is the most preferred payment mode?
--Eng kop afzal ko'riladigan to'lov usuli qaysi?

select payment_mode, count(payment_mode) as total_count
from sales
group by payment_mode
order by total_count desc

--business problem solved: know which payment options customers prefer.
--Mijozlar qaysi to'lov usullarini afzal korishini aniqlash.
--business impact: streamline payment processing, prioritize popular modes.
--To'lov jarayonini soddalashtirish, mashhur usullarga ustuvorlik berish.

--8. how does age group affect purchasing behaviour?
-- savdo qiluvchilar yosh boyicha savdoda qaysi darajada? 

select 
	case 
		when customer_age between 18 and 25 then '18-25'
		when customer_age between 26and 35 then '26-35'
		when customer_age between 36 and 50 then '36-50'
		else '51+'
	end as customer_age,
	format(sum (price*quantity), 'C0', 'en-us') as total_purchase
from sales
group by case
        when customer_age between 18 and 25 then '18-25'
		when customer_age between 26and 35 then '26-35'
		when customer_age between 36 and 50 then '36-50'
		else '51+'
	end
order by total_purchase desc

--business problem solved: understand customer demographics
--Mijozlarning demografik xususiyatlarini tushunish
--business impact: targeted marketing and product recommendations by age group
-- Yosh guruhlarga mos ravishda maqsadli marketing va mahsulot tavsiyalarini berish

--9. what's the monthly sales trend?
--oylik savdo qanday ketyapti
--method1
--1-usul
select 
	format(purchase_date, 'yyyy-MM') as month_year,
	format(sum(price*quantity), 'C0', 'en-us') as total_sales,
	sum(quantity) as total_quantity
from sales
group by format(purchase_date, 'yyyy-MM')
--method2 
-- 2-usul
select 
	--year(purchase_date) as years,
	month(purchase_date) as months,
	format(sum(price*quantity), 'C0', 'en-us') as total_sales,
	sum(quantity) as total_quantity
from sales
--group by year(purchase_date), month(purchase_date)
group by month(purchase_date)
order by months

--business problem: sales fluctuations go unnoticed
-- muammo:  Savdo o'zgarishlari e'tibordan chetda qolmoqda
--business impact: plan inventory and marketing according to seasonal trends
--rejalarni va marketingni mavsumiy korsatkichlarga muvofiq rejalashtirish.

--10. are cerntain genders buying more specific product categories?
--jins vakillari aynan qaysi mahsulot kategoriyalarini ko‘proq sotib olmoqda

select gender, product_category, count(product_category) as total_purchase
from sales
group by gender, product_category 
order by gender

--2

select * 
from(
	select gender, product_category
    from sales
	) as source_table
pivot(
	count (gender)
	for gender in ([M], [F])
	) as pivot_table
order by product_category

SELECT DISTINCT gender FROM sales;

--business problem solved: gender_based product preferences.
-- muammoga yechim: jinsga asoslangan mahsuot tanlovini aniqlash
--business impact: personalized ads, gender-focused campains
--shaxsiy reklama va jinsga yonaltirilgan aksiyalar