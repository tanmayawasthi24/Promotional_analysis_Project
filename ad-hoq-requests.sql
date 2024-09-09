#ad-hoc- requests
#1

select  distinct(product_name),base_price
from fact_events fe inner join dim_products dp on 
fe.product_code=dp.product_code
where promo_type="BOGOF" AND base_price>500;



#2 city wise store count

select city,count(store_id) as store_count from dim_stores
group by city
order by store_count desc;


#3 campaign wise total revenue before and after implementing promo.

select campaign_name,concat(round(sum(base_price *`quantity_sold(before_promo)`)/1000000,2),' M') as revenue_before_promo ,
concat(round(sum(case 
when promo_type = "BOGOF" then base_price * 0.5 * 2* `quantity_sold(after_promo)`
when promo_type = "50% OFF" then base_price * 0.5 * `quantity_sold(after_promo)`
when promo_type = "25% OFF" then base_price * 0.75* `quantity_sold(after_promo)`
when promo_type = "33% OFF" then base_price * 0.67 * `quantity_sold(after_promo)`
when promo_type = "500 cashback" then (base_price-500)* `quantity_sold(after_promo)`
end)/1000000,2),' M') as revenue_after_promo
 from 
 fact_events fe inner join dim_campaigns dc on fe.campaign_id=dc.campaign_id
 group by campaign_name;
 
 
 
 
 #4
 
 with CTE1 as 
(
select fc.campaign_id,fc.product_code,fc.base_price,fc.promo_type,fc.`quantity_sold(before_promo)`,fc.`quantity_sold(after_promo)`,
dc.campaign_name,dp.category,
case when promo_type="BOGOF" then `quantity_sold(after_promo)` *2
else `quantity_sold(after_promo)`
end as quantity_sold_AP
from fact_events fc inner join dim_campaigns dc on fc.campaign_id=dc.campaign_id inner join 
dim_products dp on fc.product_code=dp.product_code
where campaign_name="Diwali"
),
CTE2 as 
(select campaign_name,category,
(sum(quantity_sold_AP)-sum(`quantity_sold(before_promo)`))/sum(`quantity_sold(before_promo)`) *100 as 
ISU_percentage from CTE1
group by category
)
 select campaign_name, category,ISU_percentage, rank() over(order by ISU_percentage DESC) as `ISU%_Rank` from cte2;
 
 
 
 
 #5
 
 
 
 
 
 with CTE1 as 
(
select product_code,concat(round((base_price * `quantity_sold(before_promo)`)/1000,1),' K') as revenue_before_promo,
concat(round(case
when promo_type = "BOGOF" then base_price * 0.5 * 2* `quantity_sold(after_promo)`
when promo_type = "50% OFF" then base_price * 0.5 * `quantity_sold(after_promo)`
when promo_type = "25% OFF" then base_price * 0.75* `quantity_sold(after_promo)`
when promo_type = "33% OFF" then base_price * 0.67 * `quantity_sold(after_promo)`
when promo_type = "500 cashback" then (base_price-500)* `quantity_sold(after_promo)`
end/1000),' K') as revenue_after_promo 
from fact_events
),
CTE2 as
(
select product_code,round((sum(revenue_after_promo)-sum(revenue_before_promo))/sum(revenue_before_promo) * 100,2) as `IR%`
from CTE1
group by product_code
)
select CTE2.product_code,dp.category,CTE2.`IR%`,rank() over (order by `IR%` desc ) as Ranking
from CTE2 inner join dim_products dp on CTE2.product_code=dp.product_code
;