-- ==============================================================================================================================
-- Analysis 5: Monthly Revenue & Order Volume Trends
-- Purpose   : Track MOM revenue ,Order Volume & Growth Trends to identify seasonality,peaks and business trajectory over 2016-2018 period
-- Tables    : olist_orders,olist_customers
-- ==============================================================================================================================


with cte_aggregation as (
-- cte pre-aggregates monthly metrics and computes Lag revenue
-- Lag can't be used directly in MOM formula at same level
select
	YEAR(o.order_purchase_timestamp) as year,
	MONTH(o.order_purchase_timestamp) as month_number,

	-- datename suitable for dashboard
	DATENAME(month,o.order_purchase_timestamp) as Month_name,
	SUM(price) as cur_revenue,

-- Lag fetches prev month revenue for comparision 
-- ordered by year and month to ensure correct chronological sequence 
	LAG(sum(price)) over( order by YEAR(o.order_purchase_timestamp),MONTH(o.order_purchase_timestamp)) as prev_revenue,
	count(o.order_id) as totalorders,
	SUM(oi.freight_value) as total_freight_cost 

from olist_order_items oi 
left join olist_orders o
	on oi.order_id=o.order_id

--  filters: delivered orders only , no extreme delivery outliers
where o.order_status = 'delivered'
	 and o.order_delivered_customer_date is not null
	 and DATEDIFF(d,o.order_purchase_timestamp,order_delivered_customer_date) <=60

group by YEAR(o.order_purchase_timestamp),
		 MONTH(o.order_purchase_timestamp),
		 DATENAME(month,o.order_purchase_timestamp) 

-- to filter after aggregation
having COUNT(o.order_id) > 10
)

select
year,
month_number,
Month_name,
totalorders,
cur_revenue as total_revenue,
total_freight_cost,

-- tracks revenue per order
round(cast(cur_revenue AS float)/totalorders,2) as avg_order_value,

-- MOM growth % =  how much revenue grew  vs prev month
-- nullif used to prevent division error just in case 
round(cast(cur_revenue-prev_revenue as float)/nullif(prev_revenue,null) *100,2) as 'mom revenue growth%'
from cte_aggregation

-- 181% hike in jan 2017 due to filteration of orders count < 10
