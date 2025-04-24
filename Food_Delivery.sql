SELECT * FROM orders;


-- 1. Top 3 outlets by cuisine type without using limit and top function
WITH cte AS (
	SELECT Cuisine, Restaurant_id, COUNT(*) AS no_of_orders 
	FROM orders 
	GROUP BY Cuisine, Restaurant_id
)
SELECT *
FROM ( 
	SELECT *, ROW_NUMBER() OVER (PARTITION BY Cuisine ORDER BY no_of_orders DESC) AS rnk
	FROM cte
	) SUB
WHERE rnk <= 3


-- 2. Find the daily new customer count from the launch date (everyday how many new customers are we acquiring)
WITH cte AS (
	SELECT Customer_code, 
		CAST(MIN(placed_at) AS DATE) AS first_order_date
	FROM orders
	GROUP BY Customer_code
)
SELECT first_order_date, 
	COUNT(*) AS no_of_new_customers
FROM cte
GROUP BY first_order_date
ORDER BY first_order_date;


-- 3. Count of all the users who were acquired in Jan 2025 and only placed one order in Jan 
--    and did not place any other order

SELECT Customer_code, COUNT(*) AS no_of_orders
FROM orders
WHERE MONTH(placed_at) = 1 AND YEAR(placed_at) = 2025
AND Customer_code NOT IN ( 
	SELECT DISTINCT Customer_code
	FROM orders
	WHERE MONTH(placed_at) <> 1 AND YEAR(placed_at) = 2025 )
GROUP BY Customer_code
HAVING COUNT(*) = 1;


-- 4. List all the customers with no order in the last 7 days but were acquired one month ago 
--    with their first order on promo
WITH cte AS (
SELECT Customer_code, 
	MIN(placed_at) AS first_order_date,
	MAX(placed_at) AS latest_order_date
FROM orders
GROUP BY Customer_code)
SELECT cte.*, orders.Promo_code_Name AS first_order_promo 
FROM cte
INNER JOIN orders ON cte.Customer_code = orders.Customer_code AND cte.first_order_date = orders.Placed_at
WHERE latest_order_date < DATEADD(DAY, -7, GETDATE())
AND first_order_date < DATEADD(MONTH, -1, GETDATE()) AND orders.Promo_code_Name IS NOT NULL


-- 5. Growth team is planning to create a trigger that will target customers after their every
--	  third order with a personlized communication and they have asked you to create a query for this.
WITH cte AS (
	SELECT *,
		ROW_NUMBER() OVER (PARTITION BY Customer_code ORDER BY Placed_at) AS order_number
	FROM orders
)
SELECT * 
FROM cte
WHERE order_number % 3 = 0 AND CAST(Placed_at AS DATE) = '2025-03-31';


-- 6. List Customers who placed more than 1 order and all their orders on a promo only
SELECT Customer_code, 
	   COUNT(placed_at) AS no_of_orders, 
	   COUNT(Promo_code_Name) AS no_of_promo_codes
FROM orders
GROUP BY Customer_code
HAVING COUNT(*) > 1 
AND COUNT(placed_at) = COUNT(Promo_code_Name);


-- 7. What percentage of customers were organically acquired in Jan 2025. (Placed their first order without promo code)
WITH cte AS (
	SELECT *,
		ROW_NUMBER() OVER (PARTITION BY Customer_code ORDER BY Placed_at) AS rnk
	FROM orders
	WHERE MONTH(Placed_at) = 1
)
SELECT ROUND(COUNT(
			CASE WHEN rnk = 1 AND 
			Promo_code_Name IS NULL THEN Customer_code END) * 100.0 / COUNT(DISTINCT Customer_code), 2) AS percentage_of_customers
FROM cte;
