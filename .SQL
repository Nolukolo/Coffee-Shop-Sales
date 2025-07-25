-- This query analyzes Bright Coffee Shop sales data to generate business insights
-- It includes custom time segments, spend bands, and  date fields (month, day name, ISO week)

-- Step 1: Creating the summary table that calculates total transaction value
WITH sales_summary AS (
    SELECT
        TRANSACTION_ID,
        TRANSACTION_QTY,
        UNIT_PRICE,
        TRANSACTION_DATE,
        TRANSACTION_TIME,
        PRODUCT_CATEGORY,
        PRODUCT_TYPE,
        PRODUCT_DETAIL,
        STORE_ID,
        STORE_LOCATION,
        (TRANSACTION_QTY * UNIT_PRICE) AS transaction_value -- total sale per transaction
    FROM "Coffee Shop".SHOPS.COFFEESHOPSALES
),

-- Step 2: Calculating total daily spend per store
store_daily_summary AS (
    SELECT
        STORE_LOCATION,
        TRANSACTION_DATE,
        SUM(transaction_value) AS daily_store_spend -- this helps us classify stores into spend bands
    FROM sales_summary
    GROUP BY STORE_LOCATION, TRANSACTION_DATE
),

-- Step 3: Assign a spend_band to each store-day based on how much was earned
store_spend_band AS (
    SELECT
        STORE_LOCATION,
        TRANSACTION_DATE,
        CASE
            WHEN daily_store_spend BETWEEN 0 AND 20 THEN 'Low'
            WHEN daily_store_spend BETWEEN 21 AND 50 THEN 'Medium'
            WHEN daily_store_spend BETWEEN 51 AND 100 THEN 'High'
            ELSE 'Very High'
        END AS spend_band
    FROM store_daily_summary
)

-- Final Step: Build the main output for analysis, including date parts and time brackets
SELECT
    s.TRANSACTION_DATE,
    TO_CHAR(s.TRANSACTION_DATE, 'Mon') AS month_name, -- for monthly trend analysis
    DAYNAME(s.TRANSACTION_DATE) AS day_name,           -- for weekly pattern analysis
    WEEKISO(s.TRANSACTION_DATE) AS week_number,        -- ISO week (Monday-starting)

    -- Time bracket based on transaction time
    CASE
        WHEN s.TRANSACTION_TIME BETWEEN '06:00:00' AND '11:59:59' THEN 'Morning'
        WHEN s.TRANSACTION_TIME BETWEEN '12:00:00' AND '15:59:59' THEN 'Afternoon'
        WHEN s.TRANSACTION_TIME BETWEEN '16:00:00' AND '20:00:00' THEN 'Evening'
        ELSE 'Night'
    END AS time_bracket,

    sb.spend_band,            -- performance category per store/day
    s.STORE_LOCATION,
    s.PRODUCT_CATEGORY,
    s.PRODUCT_TYPE,
    s.PRODUCT_DETAIL,
    s.UNIT_PRICE,

    COUNT(s.TRANSACTION_ID) AS number_of_sales,           -- number of transactions
    SUM(s.TRANSACTION_QTY) AS number_of_units_sold,       -- total items sold
    SUM(s.transaction_value) AS total_revenue             -- total revenue for that group

FROM sales_summary s
JOIN store_spend_band sb
  ON s.STORE_LOCATION = sb.STORE_LOCATION
 AND s.TRANSACTION_DATE = sb.TRANSACTION_DATE

-- Group by the necessary fields for aggregation
GROUP BY
    s.TRANSACTION_DATE,
    TO_CHAR(s.TRANSACTION_DATE, 'Mon'),
    DAYNAME(s.TRANSACTION_DATE),
    WEEKISO(s.TRANSACTION_DATE),
    CASE
        WHEN s.TRANSACTION_TIME BETWEEN '06:00:00' AND '11:59:59' THEN 'Morning'
        WHEN s.TRANSACTION_TIME BETWEEN '12:00:00' AND '15:59:59' THEN 'Afternoon'
        WHEN s.TRANSACTION_TIME BETWEEN '16:00:00' AND '20:00:00' THEN 'Evening'
        ELSE 'Night'
    END,
    sb.spend_band,
    s.STORE_LOCATION,
    s.PRODUCT_CATEGORY,
    s.PRODUCT_TYPE,
    s.PRODUCT_DETAIL,
    s.PRODUCT_DETAIL,
    s.UNIT_PRICE;
