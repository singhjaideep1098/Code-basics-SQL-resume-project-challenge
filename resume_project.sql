-- 1
select distinct market 
from dim_customer
where customer="Atliq Exclusive" AND region = "APAC";
-- 2
with uniqueproducts_2020 as(
select count(distinct dim_product.product_code) as unique_products_2020
      from dim_product join fact_sales_monthly
      on dim_product.product_code=fact_sales_monthly.product_code
       where fact_sales_monthly.fiscal_year=2020),
       uniqueproducts_2021 as(
select count(distinct dim_product.product_code) as unique_products_2021
      from dim_product join fact_sales_monthly
      on dim_product.product_code=fact_sales_monthly.product_code
       where fact_sales_monthly.fiscal_year=2021),
       percent_change as ( select (((uniqueproducts_2021.unique_products_2021-uniqueproducts_2020.unique_products_2020)/uniqueproducts_2020.unique_products_2020)*100) as percentage_change
        from uniqueproducts_2021,uniqueproducts_2020)
        select uniqueproducts_2020. unique_products_2020,uniqueproducts_2021.unique_products_2021, percent_change. percentage_change 
        from uniqueproducts_2020,uniqueproducts_2021, percent_change;
        
-- 3
select segment,count( distinct product_code) as product_count
from dim_product
group by segment order by product_count desc;

-- 4

WITH segment_inc_2021 AS (
    SELECT dim_product.segment AS segment,COUNT(DISTINCT dim_product.product_code) AS product_count_2021
    FROM
        dim_product JOIN fact_sales_monthly ON dim_product.product_code = fact_sales_monthly.product_code
    WHERE
        fact_sales_monthly.fiscal_year = 2021
    GROUP BY
        segment
), segment_inc_2020 AS (
    SELECT dim_product.segment AS segment,COUNT(DISTINCT dim_product.product_code) AS product_count_2020
    FROM
        dim_product JOIN fact_sales_monthly ON dim_product.product_code = fact_sales_monthly.product_code
    WHERE
        fact_sales_monthly.fiscal_year = 2020
    GROUP BY
        segment
), difference_ AS (
    SELECT
        segment_inc_2021.segment AS segment,
        segment_inc_2021.product_count_2021 - segment_inc_2020.product_count_2020 AS difference,
        ((segment_inc_2021.product_count_2021 - segment_inc_2020.product_count_2020) / segment_inc_2020.product_count_2020) * 100 AS percentage_difference
    FROM
        segment_inc_2021 JOIN segment_inc_2020 
        ON segment_inc_2021.segment = segment_inc_2020.segment
)
SELECT
    segment_inc_2021.segment, segment_inc_2020.product_count_2020,segment_inc_2021.product_count_2021,difference_.difference
FROM
    segment_inc_2021 JOIN
    segment_inc_2020 ON segment_inc_2021.segment = segment_inc_2020.segment
JOIN
    difference_ ON segment_inc_2021.segment = difference_.segment;


-- 5
    select distinct dim_product.product_code, dim_product.product, fact_manufacturing_cost.manufacturing_cost
    from dim_product JOIN fact_manufacturing_cost
    on dim_product.product_code=fact_manufacturing_cost.product_code
    where fact_manufacturing_cost.manufacturing_cost IN (select max(manufacturing_cost) from fact_manufacturing_cost 
    union
    select min(manufacturing_cost)
    from fact_manufacturing_cost)
    order by fact_manufacturing_cost.manufacturing_cost desc;
    

-- 6
    SELECT dim_customer.customer_code, dim_customer.customer, AVG(fact_pre_invoice_deductions.pre_invoice_discount_pct)  AS average_discount_percentage
FROM fact_pre_invoice_deductions
JOIN dim_customer ON fact_pre_invoice_deductions.customer_code = dim_customer.customer_code
WHERE dim_customer.market = "India" AND fact_pre_invoice_deductions.fiscal_year = "2021"
GROUP BY dim_customer.customer_code, dim_customer.customer
ORDER BY average_discount_percentage DESC
LIMIT 5;


-- 7
with get_table as(
select monthname(fact_sales_monthly.date) as month ,year(fact_sales_monthly.date)as year ,fact_gross_price.gross_price*fact_sales_monthly.sold_quantity as Gross_sales
from fact_sales_monthly join fact_gross_price 
on fact_sales_monthly.product_code=fact_gross_price.product_code
where fact_sales_monthly.customer_code IN (select customer_code from dim_customer
where customer="Atliq Exclusive"))
select month , year,sum(Gross_sales) from get_table 
group by month , year 
order by year ;


-- 8
with clt_table as 
(select month( date + INTERVAL 4 MONTH) as quat_month , sold_quantity,fiscal_year
 from fact_sales_monthly 
)
select CASE
     when quat_month<=3 then "Q1"
     when quat_month<=6 then "Q2"
     when quat_month<=9 then "Q3"
     else "Q4"
     end as Quaters ,
     round(sum(sold_quantity)/1000000,2) as total_sold_quantity_in_millions
      from clt_table  
      where fiscal_year = 2020
      group by Quaters
     order by total_sold_quantity_in_millions desc ;
     
     
-- 9
with temp_table as (select distinct dim_customer.channel as channel,sum(fact_sales_monthly.sold_quantity*fact_gross_price.gross_price) as gross_sales_mn
from fact_sales_monthly join fact_gross_price 
on fact_sales_monthly.product_code=fact_gross_price.product_code
join dim_customer on fact_sales_monthly.customer_code=dim_customer.customer_code
where fact_sales_monthly.fiscal_year=2021
group by dim_customer.channel)

select temp_table.channel,round(temp_table.gross_sales_mn/1000000,3)  as gross_sales_mn,
round(((temp_table.gross_sales_mn/(select sum(gross_sales_mn) from temp_table))*100),3) as percentage 
from temp_table 

order by gross_sales_mn desc ;

-- 10
with total_sold as (select p.division as division,p.product_code as product_code,p.product as product
, sum(s.sold_quantity) as total_sold_quant ,
RANK() OVER(PARTITION BY division ORDER BY SUM(s.sold_quantity) DESC) AS rank_order 
from  fact_sales_monthly as s join dim_product as p
on s.product_code=p.product_code
where s.fiscal_year=2021
group by p.division,p.product_code,p.products
ORDER BY total_sold_quant DESC)
select division,product_code,product,total_sold_quant as total_sold_quantity
FROM total_sold 
where rank_order<=3;

