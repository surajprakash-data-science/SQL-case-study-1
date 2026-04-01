# 1. The Cleaning Steps:
CREATE TABLE data_mart.clean_weekly_sales AS
SELECT 
	TO_DATE(week_date, 'DD/MM/YY') AS week_date,
    DATE_PART('week', TO_DATE(week_date, 'DD/MM/YY')) AS WEEK_NUMBER,
    DATE_PART('month',TO_DATE(week_date, 'DD/MM/YY')) AS MONTH_NUMBER,
    DATE_PART('year', TO_DATE(week_date, 'DD/MM/YY')) AS calendar_year,
    CASE
    	WHEN segment ='null' OR segment IS NULL THEN 'UNKNOWN'
        ELSE segment
    END AS segment,
    CASE
    	WHEN segment LIKE '%1' THEN 'Young Adults'
        WHEN segment LIKE '%2' THEN 'Middle Aged'
        WHEN segment LIKE '%3' OR segment LIKE '%4' THEN 'Retirees'
        ELSE 'UNKNOWN'
    END AS age_band,
    CASE
    	WHEN segment LIKE 'C%' THEN 'Couples'
        WHEN segment LIKE 'F%' THEN 'Families'
        ELSE 'UNKNOWN'
    END AS demographic,
    region,
    platform,
    customer_type,
    transactions,
    sales,
    ROUND(sales/transactions,2) AS avg_transaction
FROM data_mart.weekly_sales;

SELECT * FROM data_mart.clean_weekly_sales LIMIT 5;

# 2. Data Exploration:
SELECT DISTINCT TO_CHAR(week_date, 'Day') FROM data_mart.clean_weekly_sales;

SELECT series_week from generate_series(1,52) AS series_week 
EXCEPT
SELECT DISTINCT week_number
FROM data_mart.clean_weekly_sales
ORDER BY series_week;

SELECT calendar_year, COUNT(*) transactions_per_year 
FROM data_mart.clean_weekly_sales
GROUP BY calendar_year;

SELECT region, month_number, SUM(sales) total_sales
FROM data_mart.clean_weekly_sales
GROUP BY region, month_number
ORDER BY region, month_number;

SELECT platform, SUM(transactions) total_transactions
FROM data_mart.clean_weekly_sales
GROUP BY platform
ORDER BY platform;

SELECT 
	ROUND(100.0*(SUM(CASE WHEN platform LIKE 'Retail' THEN sales Else 0 END))/SUM(sales),2) retail_sales,
    ROUND(100.0*(SUM(CASE WHEN platform LIKE 'Shopify' THEN sales ELSE 0 END))/SUM(sales),2) shopify_sales
FROM data_mart.clean_weekly_sales;

SELECT platform,
	SUM(sales) AS toal_sales, 
    ROUND(100.0*SUM(sales)/SUM(SUM(sales)) OVER (),2) sales_percentage
FROM data_mart.clean_weekly_sales
GROUP BY platform;

SELECT region, calendar_year,
	SUM(sales) AS toal_sales, 
    ROUND(100.0*SUM(sales)/SUM(SUM(sales)) OVER (),2) sales_percentage
FROM data_mart.clean_weekly_sales
GROUP BY region, calendar_year
ORDER BY region, calendar_year;

SELECT region,
	SUM(sales) AS toal_sales, 
    ROUND(100.0*SUM(sales)/SUM(SUM(sales)) OVER (),2) sales_percentage
FROM data_mart.clean_weekly_sales WHERE platform LIKE 'Retail'
GROUP BY region
ORDER BY sales_percentage DESC;

SELECT age_band,
	SUM(sales) AS toal_sales, 
    ROUND(100.0*SUM(sales)/SUM(SUM(sales)) OVER (),2) sales_percentage
FROM data_mart.clean_weekly_sales WHERE platform LIKE 'Retail'
GROUP BY age_band 
ORDER BY sales_percentage DESC;

SELECT calendar_year, platform,
	AVG(avg_transaction) AS avg_transactions_per_year
FROM data_mart.clean_weekly_sales
GROUP BY calendar_year, platform
ORDER BY calendar_year;

# 3. Before & After Analysis:
WITH before_change AS (
SELECT *, ROW_NUMBER() OVER(ORDER BY week_date ASC) as row_id 
FROM data_mart.clean_weekly_sales
WHERE week_date < '2020-06-15'
),
after_change AS(
SELECT *, ROW_NUMBER() OVER(ORDER BY week_date ASC) as row_id 
FROM data_mart.clean_weekly_sales
WHERE week_date >= '2020-06-15'
)
SELECT 
b.week_date AS before_date, b.sales AS before_sales, b.week_number,
a.week_date AS after_date, a.sales AS after_sales, a.week_number
FROM before_change b JOIN after_change a
ON b.row_id=a.row_id LIMIT 5;

SELECT before_sales, after_sales, after_sales-before_sales AS actual_change,
ROUND(100.0*(after_sales-before_sales)/before_sales,2) AS sales_rate 
FROM(
  SELECT
	SUM(CASE WHEN week_number BETWEEN 21 AND 24 THEN sales ELSE 0 END) AS before_sales,
    SUM(CASE WHEN week_number BETWEEN 25 AND 28 THEN sales ELSE 0 END) AS after_sales
FROM data_mart.clean_weekly_sales
  ) AS tt;
  

SELECT before_sales, after_sales, after_sales-before_sales AS actual_change,
ROUND(100.0*(after_sales-before_sales)/before_sales,2) AS sales_rate 
FROM(
  SELECT
	SUM(CASE WHEN week_number BETWEEN 13 AND 24 THEN sales ELSE 0 END) AS before_sales,
    SUM(CASE WHEN week_number BETWEEN 25 AND 36 THEN sales ELSE 0 END) AS after_sales
FROM data_mart.clean_weekly_sales
  ) AS tt;
  
  
  
SELECT 
	total_sales_2018,
    total_sales_2019,
    total_sales_2019-total_sales_2018 AS sales_difference,
    ROUND(100.0*(total_sales_2019-total_sales_2018)/total_sales_2018, 2) AS prev_year_rate,
	before_sales, 
    after_sales, 
    after_sales-before_sales AS actual_change,
	ROUND(100.0*(after_sales-before_sales)/before_sales,2) AS sales_rate 
FROM(
  SELECT
	SUM(CASE WHEN week_number BETWEEN 13 AND 24 THEN sales ELSE 0 END) AS before_sales,
    SUM(CASE WHEN week_number BETWEEN 25 AND 36 THEN sales ELSE 0 END) AS after_sales,
  SUM(CASE WHEN calendar_year=2018 THEN sales ELSE 0 END) total_sales_2018,
  SUM(CASE WHEN calendar_year=2019 THEN sales ELSE 0 END) total_sales_2019
FROM data_mart.clean_weekly_sales
  ) AS t;
