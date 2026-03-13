
-- Data Cleaning & Exploration :


--====================================================
-- section 1 null deduction 
--====================================================

select
COUNT(*) as totalrows,
SUM(case when order_id is null then 1 else 0 end ) as null_order_id,
SUM(case when customer_id is null then 1 else 0 end) as null_customer_id,
SUM(case when order_status is null then 1 else 0 end) as null_orderstatus,
SUM(case when order_delivered_customer_date is null then 1 else 0 end) as null_delivery_date,
SUM(case when order_estimated_delivery_date is null then 1 else 0 end) as null_estimeated_date
from dbo.olist_orders;

-- results 2965 null delivery dates (can be filtered using order status)

select
COUNT(*) as total_rows,
SUM(case when order_id is null then 1 else 0 end ) as null_order_id,
SUM(case when product_id is null then 1 else 0 end ) as null_product_id,
SUM(case when seller_id is null then 1 else 0 end ) as null_seller_id,
SUM(case when price is null then 1 else 0 end ) as null_price,
SUM(case when freight_value is null then 1 else 0 end ) as null_freight_value
from olist_order_items;

-- result no null values

select
COUNT(*) total_rows,
SUM(case when product_category_name is null then 1 else 0 end ) as null_product_category_name,
SUM(case when product_weight_g is null then 1 else 0 end ) as null_product_weight,
SUM(case when product_length_cm is null then 1 else 0 end ) as null_product_length,
SUM(case when product_height_cm is null then 1 else 0 end ) as null_product_height,
SUM(case when product_width_cm is null then 1 else 0 end ) as null_product_width
from olist_products;

-- result 610 null product_categories found

-- action (falgged it as uncategorised "sem_categoria")

update olist_products
set product_category_name = 'sem_categoria'
where product_category_name is null;


--====================================================
-- step 2 duplicates check 
--====================================================

-- orders

select
order_id,
COUNT(*) as no_of_duplicates
from olist_orders
group by order_id
having COUNT(*) >  1
order by no_of_duplicates desc;
-- results (no duplicates found)

-- customers

select
customer_id,
COUNT(*) as no_of_duplicates
from olist_customers
group by customer_id
having COUNT(*) > 1
order by no_of_duplicates desc;

-- results (no duplicates found)

-- order reviews

select
order_id,
COUNT(*) as no_of_duplicates
from olist_order_reviews
group by order_id
having COUNT(*) >  1
order by no_of_duplicates desc;

 -- relsult 547 rows found ( as customer my have made multiple reviews for same order )

--  (action taken) -- view creation to find out latest rating of the customer ( as the customer has multiple review )

create view vw_latest_review as 
select
order_id,
review_score,
review_comment_message,
review_creation_date
from(
select
	order_id,
	review_score,
	review_comment_message,
	review_creation_date,
	ROW_NUMBER()over(partition  by order_id order by review_creation_date desc) as rn
from olist_order_reviews
)t
where rn=1;

-- payments

select
order_id,
COUNT(*) as no_of_duplicates
from olist_order_payments
group by order_id
having COUNT(*) >  1
order by no_of_duplicates desc; 

-- results 2961 duplicates in payments found
-- interpretation -- customer may have paid using multiple payment methods


--============================================================
-- Section 3 data validation 
--============================================================

-- data type verification 

select
	TABLE_NAME,
	COLUMN_NAME,
	DATA_TYPE,
	CHARACTER_MAXIMUM_LENGTH,
	NUMERIC_PRECISION,
	NUMERIC_SCALE
from INFORMATION_SCHEMA.COLUMNS

-- fix 
alter table olist_order_reviews
alter column review_score int;

alter table olist_order_payments
alter column payment_sequential int;

alter table olist_order_payments
alter column payment_installments int;


--====================================================
-- Section 4 outlier dedection 
--====================================================

-- price and freight outliers

select
MIN(price) as min_price,
MAX(price) as max_price,
AVG(price) as avg_price,
STDEV(price) as std_price, -- high deviation 
MIN(freight_value) as min_freight_value,
MAX(freight_value) as max_freight_value,
avg(freight_value) as avg_freight_value,
stdev(freight_value) as std_freight_value -- low deviation 
from olist_order_items;

-- negatives dedection 
select
COUNT(*) as zero_or_negative_p
from olist_order_items 
where price <=0;

select
COUNT(*) as zero_or_negative_p
from olist_order_items 
where freight_value <=0; -- 383 may be due to free shipping (should be falgged)

-- delivery days distributipn 

select
min(DATEDIFF(d,order_purchase_timestamp,order_delivered_customer_date)) min_delivery_date, 
max(DATEDIFF(d,order_purchase_timestamp,order_delivered_customer_date)) max_delivery_date, -- problem should filter it by 60 days
avg(DATEDIFF(d,order_purchase_timestamp,order_delivered_customer_date)) avg_delivery_date -- key kp1
from olist_orders
where order_status = 'delivered'
and order_delivered_customer_date is not null ;

-- review score distribution 

select
review_score,
COUNT(*) as total,
cast(COUNT(*) * 100.0/sum(COUNT(*)) over() as decimal(5,2)) as percentage
from olist_order_reviews
group by review_score
order by review_score;
-- key finding -- 11 perentage perople rated 1 or 2 and  57.5 rated 5


--====================================================
-- Section 5: relationship check
--====================================================

-- order to customers
select
COUNT(*) 
from olist_orders o
left join olist_customers c 
on o.customer_id=c.customer_id
where c.customer_id is null ;

select
COUNT(*)  orders_without_customers
from olist_orders o
where not exists(select 1 from olist_customers c where o.customer_id=c.customer_id);

-- order_items to orders 

select
COUNT(*) 
from  olist_order_items oi
left join olist_orders o
on oi.order_id=o.order_id
where o.order_id is null;

-- order items to purchase 

select
COUNT(*) o_items_without_products
from olist_order_items oi
left join olist_products p
on oi.product_id=p.product_id
where p.product_id is null;

-- order item to sellers

select
COUNT(*) item_without_sellers
from olist_order_items oi
left join olist_sellers s
on oi.seller_id=s.seller_id
where s.seller_id is null;


--====================================================
-- Section 6 full core join 
--====================================================

select top 10
o.order_id,
o.order_status,
o.order_purchase_timestamp,
c.customer_state,
oi.price,
oi.freight_value,
p.product_category_name,
s.seller_state,
vr.review_score
from olist_orders o
left join olist_customers c 
on o.customer_id=c.customer_id
left join olist_order_items oi 
on o.order_id=oi.order_id
left join olist_products p
on oi.product_id=p.product_id
left join olist_sellers s 
on oi.seller_id=s.seller_id
left join vw_latest_review vr
on o.order_id =vr.order_id
where o.order_status = 'delivered'
and o.order_delivered_customer_date is not null;