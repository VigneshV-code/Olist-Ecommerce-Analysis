-- ==============================================================================================================================
-- Analysis 2: seller performance ranking
-- Purpose   : rank sellers by operational performance to indentify underperforming sellers dragging customer satisfaction
-- Tables    : olist_order_item,olist_orders,olist_sellers,vm_latest_reviews
-- ==============================================================================================================================

select
	s.seller_id,
	s.seller_state,
	COUNT(o.order_id) as TotalOrders,
	SUM(oi.price)     as TotalRevenue,

-- on time delvery rate = orders delivered before/on estimated date divided by total delivery by seller 
round(cast(count(case when  o.order_delivered_customer_date <= o.order_estimated_delivery_date then 1 end )AS float)
/COUNT(o.order_id)*100,2) as 'On-time delivery rate%',

-- lower avg scores indicates sellers consistent service failure 
avg(vr.review_score)      as average_review_score,

-- count of late deliveries ( for volume context)
count(case when o.order_delivered_customer_date > o.order_estimated_delivery_date then 1 end )  as late_delivery_count

from olist_order_items oi
left join olist_sellers s
	on oi.seller_id=s.seller_id
left join olist_orders o
	on oi.order_id=o.order_id

-- using views instead of raw tables to avoid duplicates 
left join vw_latest_review vr
	on oi.order_id=vr.order_id

--  filters: delivered orders only , no extreme delivery outliers
where o.order_status = 'delivered'
	and o.order_delivered_customer_date is not null
	and DATEDIFF(d,o.order_purchase_timestamp,order_delivered_customer_date) <=60

group by s.seller_id,s.seller_state
order by [On-time delivery rate%] asc
