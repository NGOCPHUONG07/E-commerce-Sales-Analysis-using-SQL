-- 1.Which traffic source drives the highest number of orders?
select utm_source as [Traffic Source], count(order_id) as [Number of Orders]
from orders a
	inner join website_sessions b on a.website_session_id = b.website_session_id
group by utm_source
/* Insight 
Given that Google Search drives the largest number of orders, the company should consider further optimizing search-related marketing efforts
and allocating resources to maintain this strong-performing channel. For sessions with missing utm_source values, implementing more consistent 
campaign tracking and attribution mechanisms would improve data quality and provide more accurate insights into customer acquisition performance.
*/
-- 2. Which campaign generates the highest revenue?
select b.utm_campaign as [Campaign], sum(a.price_usd) as [Revenue]
from orders a 
	inner join website_sessions b on a.website_session_id = b.website_session_id
group by b.utm_campaign
order by [Revenue] desc
/*	Insight
Insight:
The nonbrand campaign generated the highest revenue among all campaigns, making it the strongest revenue-driving campaign in this analysis. 
This suggests that nonbrand marketing efforts are effective at attracting and converting customers. 
The company should continue investing in this campaign while monitoring its long-term profitability and return on investment.
*/
-- 3.Which device type generates more orders: mobile or desktop?
select b.device_type as [Device Type], count(a.order_id) as [Total Orders]
from orders a 
	inner join website_sessions b on a.website_session_id = b.website_session_id
group by b.device_type
/*	Insight
Desktop users placed almost five times more orders than mobile users. This indicates that desktop is currently the main channel for online purchases.
The large difference between the two device types may suggest that customers feel more comfortable completing transactions on desktop,
or that there are opportunities to improve the mobile shopping experience.
The company should continue optimizing the desktop experience while also investigating ways to increase mobile conversions and 
encourage more purchases from mobile users.
*/
-- 4.Which traffic source has the highest conversion rate (session → order)?
select c.utm_source as [Traffic Source], c._website_session_id as [Total Sessions],d._order_id as [Total Orders], 
(d._order_id*1.00/c._website_session_id*1.00) *100.0 as [Conversion Rate (%)]
from 
(
select utm_source, count(website_session_id) as _website_session_id
from website_sessions
group by utm_source
) as c
inner join
(
select b.utm_source, count(a.order_id) as _order_id
from orders a
	inner join website_sessions b on a.website_session_id=b.website_session_id
group by utm_source
) as d
on c.utm_source = d.utm_source
order by [Conversion Rate (%)] desc
/*	Insight
Insight:
Bsearch achieved a slightly higher conversion rate than gsearch despite generating fewer orders,
while socialbook showed the weakest conversion performance. This suggests that traffic quality differs across acquisition channels
and that higher traffic volume does not always lead to better conversion efficiency.
The company may consider further optimizing bsearch while reviewing the effectiveness of socialbook campaigns.
*/
-- 5. What is the net revenue after refunds?
select sum(price_usd) as _total_amount,  sum(total_refund) as _refund_amount, sum(price_usd)-sum(total_refund) as _net_amount
from orders o
LEFT JOIN (

    select
        order_id,
        SUM(refund_amount_usd) as total_refund
    from order_item_refunds
    group by order_id
) r
ON o.order_id = r.order_id
/*	Insight
After accounting for refunds, the company generated approximately 1.85 million dollar in net revenue.
Although refunds reduced total revenue by about 85,000 dolllar, their overall impact remained relatively small compared to total sales. 
The business should continue monitoring refund patterns to identify products or customer segments that may contribute to revenue loss.
*/
-- 6. Which product generates the highest profit?
select top 1 c.product_id, max(c.product_name) as _product_name, sum(b.price_usd-b.cogs_usd) as _profit
from order_items b 
	inner join products c on b.product_id = c.product_id
group by c.product_id
order by sum(b.price_usd-b.cogs_usd) desc
/* Insight:
The Original Mr. Fuzzy was the most profitable product, generating approximately 738,893 dollar in profit. 
Its strong performance highlights its importance to the company's product portfolio.
Further analysis of its pricing, marketing, and customer demand could provide insights for improving the profitability of other products.
*/
-- 7. Do returning customers have a higher purchase rate than new customers?
select case when b.is_repeat_session = 0 then 'New Customer'
		when b.is_repeat_session = 1 then 'Returning Customer'
		end 'Customer Type',count(b.website_session_id) as [Total Sessions], count(a.order_id) as [Total Orders], 
		(count(a.order_id)*1.00/count(b.website_session_id)*1.00*100) as [Purchase Rate (%)]
from orders a
	right join website_sessions b on a.website_session_id = b.website_session_id
group by b.is_repeat_session
/*	Insight:
Returning customers were more likely to make a purchase than new customers, with a purchase rate of 7.83% compared to 6.64%. 
This highlights the value of customer retention and suggests that repeat customers play an important role in driving sales.
*/
-- 8. Which primary product generates the most add-on purchases?
select max(b.product_name) as [Product Name],
count(order_id) as [Units Sold], 
(sum(a.items_purchased)-count(order_id)) as [Add-on Products Sold], 
(sum(a.items_purchased)-count(order_id))*1.00/count(order_id)*1.00*100 as [Add-on Rate (%)]
from orders a
	inner join products b on a.primary_product_id=b.product_id
group by a.primary_product_id
/* Insight:
The Original Mr. Fuzzy generated the highest number of add-on product purchases, making it the strongest driver of cross-selling volume.
However, The Birthday Sugar Panda achieved the highest add-on rate, suggesting that customers who purchase this product are more likely to buy additional items. 
This indicates an opportunity to leverage The Birthday Sugar Panda in future cross-selling and bundling strategies.
*/
-- 9. Which product has the highest refund rate?
select top 1 max(b.product_id) as [Product ID], 
max(b.product_name) as [Product Name], 
count(a.order_item_id) as [Total Items Sold],
count(c.order_item_refund_id) as [Total Refunded Items],
count(c.order_item_refund_id)*1.00/count(a.order_item_id)*1.00*100 as [Refund Rate (%)]
from order_items a
	inner join products b on a.product_id=b.product_id
	left join order_item_refunds c on a.order_item_id= c.order_item_id
group by b.product_id
order by count(c.order_item_refund_id)*1.00/count(a.order_item_id)*1.00*100 desc
/*	Insight:
The Birthday Sugar Panda recorded the highest refund rate at 6.04%, with 301 refunded items out of 4,985 items sold. 
This suggests that the product may face challenges related to customer expectations, product quality, or overall customer satisfaction.
Further investigation could help identify the root causes and reduce future refunds.
*/

-- 10. Who are the top 10 customers by revenue?
select top 10 user_id,
sum(price_usd) as [Total Revenue]
from orders
group by user_id
order by sum(price_usd) desc
-- The top 10 customers each generated more than 200 dollar in revenue, with Customer 341972 contributing the highest amount at approximately 252 dollar.
-- 11. How long does it take, on average, for a user to place an order after entering the website? 
select avg(datediff(minute,a.created_at,c.created_at)) as [Average Time to Purchase (Minutes)]
from website_sessions a 
	inner join orders c on a.website_session_id =c.website_session_id
	-- Users took an average of 14 minutes to place an order after entering the website.
	--This suggests that the purchasing process is relatively efficient and that customers can quickly move from browsing to checkout.
-- 12. Which traffic source generates the most returning customers?
select utm_source as [Traffic Source], 
count ( distinct user_id) as [Returning Customers]
from website_sessions
where is_repeat_session = 1
group by utm_source
	--Gsearch generated the highest number of returning customers, with over 21,000 repeat users, significantly outperforming other traffic sources. 
	--This suggests that gsearch is not only effective at acquiring customers but also at bringing them back to the website. 
	-- Continue investment in this channel
-- 13. Which product pairs are most frequently purchased together?

Select
    Case
        When p1.product_name < p2.product_name
        Then CONCAT(p1.product_name, ' & ', p2.product_name)
        else CONCAT(p2.product_name, ' & ', p1.product_name)
    end as [Product Pair],
    count (DISTINCT oi1.order_id) AS [Orders]
from order_items oi1
inner join order_items oi2
    on oi1.order_id = oi2.order_id
    and oi1.product_id < oi2.product_id
inner join products p1
    on oi1.product_id = p1.product_id
inner join products p2
    on oi2.product_id = p2.product_id
group by
    case
        when p1.product_name < p2.product_name
        then CONCAT(p1.product_name, ' & ', p2.product_name)
        else CONCAT(p2.product_name, ' & ', p1.product_name)
    end

order by [Orders] desc
/*     Insight:
The Original Mr. Fuzzy and The Hudson River Mini Bear were the most frequently purchased product pair, appearing together in 3,142 orders.
The popularity of this combination suggests a strong cross-selling relationship between the two products.
Promoting them as a bundle could help increase average order value and overall sales.
*/