-- ===============================================================================================================================================================
-- Analysis 4: Delivery performance vs customer satisfaction
-- Purpose   : quantify the relationship between delivery delays and customers ratings to prove opretional inefficiency is related to customer dis-satisfaction
-- Tables    : olist_orders,olist_customers,vm_latest_reviews
-- ===============================================================================================================================================================

-- ===============================
--1)  Delivery Bucket Analysis
-- ===============================

select
	delay_bucket,
	COUNT(order_id) Totalorders,
	AVG(review_score) Average_review_score,

-- 1% star : Proportion of dissatisfied customer per delay bucket
	round(cast(sum(case when review_score = 1 then 1 end)as float)/COUNT(review_score)*100,2) 'as percentage of 1 star reviews' 
from(
	-- Subquery creates buckets before grouping to counter  references limitation 
select
	CASe when DATEDIFF(d,order_estimated_delivery_date,order_delivered_customer_date) <0 then 'Early'
		 when DATEDIFF(d,order_estimated_delivery_date,order_delivered_customer_date) =0 then 'On Time'
		 when DATEDIFF(d,order_estimated_delivery_date,order_delivered_customer_date) between 1 and 3 then '1-3 days late'
		 when DATEDIFF(d,order_estimated_delivery_date,order_delivered_customer_date) between 4 and 7 then '4-7 days late'
	 else '7+ days late' end as delay_bucket,
	 o.order_id,
	 vr.review_score
from olist_orders o
left join vw_latest_review vr
	on o.order_id = vr.order_id

--  filters: delivered orders only , no extreme delivery outliers
where o.order_status = 'delivered'
	and o.order_delivered_customer_date is not null
	and DATEDIFF(d,o.order_purchase_timestamp,order_delivered_customer_date) <=60
)t
group by delay_bucket

-- case when forces logical sequence instead of alphabetical 
order by 
	case when delay_bucket = 'Early' then 1 
		 when delay_bucket = 'On Time' then 2
		 when delay_bucket = '1-3 days late' then 3
		 else 4 end;

-- ============================================
--2)  Delivery Delays per customer state 
-- ==========================================

select
	c.customer_state,

-- average delivery days from purchasesate , Higher the delays = unplesant  experience (based on state)
	avg(DATEDIFF(d,o.order_purchase_timestamp,order_delivered_customer_date)) avg_delivery_days,
	AVG(vr.review_score) avg_review_score,
	COUNT(o.order_id) totalorders
from olist_orders o
left join olist_customers c
	on o.customer_id=c.customer_id
left join vw_latest_review vr
	on o.order_id = vr.order_id

--  filters: delivered orders only , no extreme delivery outliers
where o.order_status = 'delivered'
	 and o.order_delivered_customer_date is not null
	 and DATEDIFF(d,o.order_purchase_timestamp,order_delivered_customer_date) <=60
group by c.customer_state

-- states with longest delivery days appears first
order by avg_delivery_days desc
