# SQL-case-study-1
Link to case study: https://8weeksqlchallenge.com/case-study-5/

## Case Study Solutions
### Section 1: Data Cleansing
I created a new table clean_weekly_sales where I:
1. Converted week_date to a standard DATE format.
2. Extracted week_number, month_number, and calendar_year.
3. Used CASE statements to map segment codes (e.g., 1 = Young Adults, C = Couples).
4. Replaced all null strings with 'UNKNOWN'.
5. Calculated avg_transaction as sales / transactions.

### Section 2: Data Exploration

1. What day of the week is used for each week_date value?

		SELECT DISTINCT TO_CHAR(week_date, 'Day') FROM data_mart.clean_weekly_sales;

2. What range of week numbers are missing from the dataset?

		SELECT series_week from generate_series(1,52) AS series_week

		EXCEPT

		SELECT DISTINCT week_number

		FROM data_mart.clean_weekly_sales

		ORDER BY series_week;


3. How many total transactions were there for each year in the dataset?

		SELECT calendar_year, COUNT(*) transactions_per_year 

		FROM data_mart.clean_weekly_sales

		GROUP BY calendar_year;


4. What is the total sales for each region for each month?

		SELECT region, month_number, SUM(sales) total_sales

		FROM data_mart.clean_weekly_sales

		GROUP BY region, month_number

		ORDER BY region, month_number;


5. What is the total count of transactions for each platform

		SELECT platform, SUM(transactions) total_transactions

		FROM data_mart.clean_weekly_sales

		GROUP BY platform

		ORDER BY platform;


6. What is the percentage of sales for Retail vs Shopify for each month?

		SELECT 

			ROUND(100.0*(SUM(CASE WHEN platform LIKE 'Retail' THEN sales Else 0 END))/SUM(sales),2) retail_sales,
	
			ROUND(100.0*(SUM(CASE WHEN platform LIKE 'Shopify' THEN sales ELSE 0 END))/SUM(sales),2) shopify_sales
	
		FROM data_mart.clean_weekly_sales;


OR

	SELECT platform,

		SUM(sales) AS toal_sales, 
	
		ROUND(100.0*SUM(sales)/SUM(SUM(sales)) OVER (),2) sales_percentage
	
	FROM data_mart.clean_weekly_sales

	GROUP BY platform;


7. What is the percentage of sales by demographic for each year in the dataset?

		SELECT region, calendar_year,
	
			SUM(sales) AS toal_sales, 
		
   	 		ROUND(100.0*SUM(sales)/SUM(SUM(sales)) OVER (),2) sales_percentage
	
		FROM data_mart.clean_weekly_sales

		GROUP BY region, calendar_year

		ORDER BY region, calendar_year;


8. Which age_band and demographic values contribute the most to Retail sales?

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


9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

		SELECT calendar_year, platform,

			AVG(avg_transaction) AS avg_transactions_per_year
	
		FROM data_mart.clean_weekly_sales

		GROUP BY calendar_year, platform

		ORDER BY calendar_year;


### Section 1: Before & After Analysis.

This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.
Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

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

Using this analysis approach - answer the following questions:

1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?

		SELECT before_sales, after_sales, after_sales-before_sales AS actual_change,
			ROUND(100.0*(after_sales-before_sales)/before_sales,2) AS sales_rate 
		FROM(
 			 SELECT
				SUM(CASE WHEN week_number BETWEEN 21 AND 24 THEN sales ELSE 0 END) AS before_sales,
    			SUM(CASE WHEN week_number BETWEEN 25 AND 28 THEN sales ELSE 0 END) AS after_sales
			FROM data_mart.clean_weekly_sales
  			) AS tt;
  
2. What about the entire 12 weeks before and after?

		SELECT before_sales, after_sales, after_sales-before_sales AS actual_change,
			ROUND(100.0*(after_sales-before_sales)/before_sales,2) AS sales_rate 
		FROM(
  			SELECT
				SUM(CASE WHEN week_number BETWEEN 13 AND 24 THEN sales ELSE 0 END) AS before_sales,
    			SUM(CASE WHEN week_number BETWEEN 25 AND 36 THEN sales ELSE 0 END) AS after_sales
			FROM data_mart.clean_weekly_sales
  			) AS tt;
  
3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

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

## Key Insights & Conclusion
Through this SQL deep dive, several critical business insights emerged:

	Impact of Change: The sustainable packaging change saw a slight reduction in sales in the immediate 4-week period. This allowed the business to discuss whether this was due to customer sentiment or external supply chain factors.
	Platform Disparity: Retail transactions significantly outweigh Shopify, but Shopify's avg_transaction size provides an interesting opportunity for high-value growth.
	The "Unknown" Factor: A large portion of the sales come from the 'Unknown' segment. This highlights a massive opportunity for Data Mart to improve their loyalty program and data collection at the Point of Sale.

## How To Run The Code
1. Copy the queries in "sql_queries.sql" file.
2. Open the link: https://www.db-fiddle.com/f/jmnwogTsUE8hGqkZv9H7E8/8#
3. Paste the queries in "Query SQL" section.
4. RUN the queries.
  
