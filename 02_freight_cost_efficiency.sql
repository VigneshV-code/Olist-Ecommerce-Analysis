-- =======================================================================================================
-- Analysis 1 : freight cost efficiency by category
-- Purpose    : identify categories with highest fright burden relative to revenue to falg operational inefficiency 
-- Tables     : olist_order_item,olist_products,olist_customers,product_category_translation
-- =======================================================================================================

with cte_category_wise_metric as(
-- Cte used to prepare the data for aggregation 

select
	pc.category_name_english,
	o.order_id		as orders,
	price			as revenue,
	freight_value	as freight_cost
from olist_order_items oi
left join olist_orders o
	on oi.order_id=o.order_id
left join olist_products p
	on oi.product_id=p.product_id
left join olist_customers c
	on o.customer_id = c.customer_id
left join product_category_translation pc
	on p.product_category_name=pc.category_name_portuguese

-- filter delivered orders only , no extreme delivery outliers
where o.order_status='delivered'
	and o.order_delivered_customer_date is not null
	and DATEDIFF(d,o.order_purchase_timestamp,order_delivered_customer_date) <=60
)

select
	category_name_english,
	COUNT(orders)  as total_orders,
	sum(revenue)         as total_revenue,
	SUM(freight_cost) as total_freight_cost,

-- freight as a percentage of revenue, Higher % = Less profitable shipping
	round((cast(SUM(freight_cost)AS float)/sum(revenue))*100,2) as 'freight-to-revenue-ratio',

-- Avg freight cost per order
	round(avg(freight_cost),2) as avg_freight_per_order,

-- Avg revenue per order
	round(avg(revenue),2)         as avg_price

from cte_category_wise_metric 

group by category_name_english

order by [freight-to-revenue-ratio] desc;


-- ==============================================================================================================================
-- Analysis 2  : Freight cost efficiency by state
-- Purpose     : Identify  which Brazilian state have the highest fright burden relative to revenue to flag operational inefficiency 
-- Tables      : olist_order_item,olist_products,olist_customers,product_category_translation
-- ==============================================================================================================================
select
	c.customer_state,
	COUNT(o.order_id)  as total_orders,
	sum(price)         as total_revenue,
	SUM(freight_value) as total_freight_cost,

-- freight as a percentage of revenue, remotes states expected to have higher ratios
	round((cast(SUM(freight_value)AS float)/sum(price))*100,2) as 'freight-to-revenue-ratio',
	round(avg(freight_value),2)  as avg_freight_per_order,
	round(avg(price),2)          as avg_price

from olist_order_items oi
left join olist_orders o
	on oi.order_id=o.order_id
left join olist_products p
	on oi.product_id=p.product_id
left join olist_customers c
	on o.customer_id = c.customer_id
left join product_category_translation pc
	on p.product_category_name=pc.category_name_portuguese

--  filter delivered orders only , no extreme delivery outliers
where o.order_status='delivered'
	and o.order_delivered_customer_date is not null
	and DATEDIFF(d,o.order_purchase_timestamp,order_delivered_customer_date) <=60

group by c.customer_state
order by [freight-to-revenue-ratio] desc