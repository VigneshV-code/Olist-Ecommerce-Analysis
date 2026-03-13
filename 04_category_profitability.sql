-- ==============================================================================================================================
-- Analysis 3: category profitability
-- Purpose   : Identify least profitable catagories by measuring net margin after freight costs 
--			 **  helps priortise which categories need cost optimization or repricing 
-- Tables    : olist_order_item,olist_orders,olist_sellers,vm_latest_reviews,product_category_translation,olist_products
-- ==============================================================================================================================

-- cte is used to pre calculate aggregation so aliases can be referenced directly in outer query for net marngin calculation

with cte_base_query as (
select
	pc.category_name_english,
	count(o.order_id)     as totalorders ,
	sum(oi.price)         as totalrevenue,
	sum(oi.freight_value) as totalfreightcost,

-- net revenue = revenue remaining after shipping costs
	sum(oi.price)-sum(oi.freight_value) as netrevenue,

-- lower avg score for category signals recurring fulfilment issues
	avg(vr.review_score) as avg_review_score

from olist_order_items oi
left join olist_orders o
	on oi.order_id=o.order_id
left join olist_products p
	on oi.product_id=p.product_id
left join product_category_translation pc
	on p.product_category_name=pc.category_name_portuguese
left join vw_latest_review vr
	on oi.order_id=vr.order_id
where o.order_status = 'delivered'
	and o.order_delivered_customer_date is not null
	and DATEDIFF(d,o.order_purchase_timestamp,order_delivered_customer_date) <=60
	group by pc.category_name_english
)
-- outer query references cte to compute net margin cleanly 
-- also net revenue cast to float to avoid integer division
select
	category_name_english,
	totalorders,
	totalrevenue,
	totalfreightcost,
	netrevenue,
	round((cast(netrevenue as float)/totalrevenue)*100,2) netmargin,
	avg_review_score
from cte_base_query 
order by netmargin 
