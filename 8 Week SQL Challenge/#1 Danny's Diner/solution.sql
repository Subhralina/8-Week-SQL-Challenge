USE dannys_diner;

-- 1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id as "Customer ID", 
	sum(m.price) as "Total Amount"
FROM sales as s
INNER JOIN menu AS m
ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT s.customer_id as "Customer ID",
	COUNT(DISTINCT s.order_date) as "Total Visits"
FROM sales as s
GROUP BY s.customer_id;

-- 3. What was the first item from the menu purchased by each customer?

SELECT first_prod_table.Customer_ID,
	first_prod_table.Product_Name
FROM
(
	SELECT DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) as Rank,
		s.customer_id as Customer_ID,
		m.product_name as Product_Name
	FROM sales as s
	INNER JOIN menu as m
	ON s.product_id = m.product_id) as first_prod_table
WHERE first_prod_table.Rank = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT  TOP 1 m.product_name as Product_Name,
	COUNT(m.product_name) as Order_Frequency
FROM sales as s
INNER JOIN menu as m
on s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY COUNT(m.product_name) DESC

-- 5. Which item was the most popular for each customer?

SELECT first_prod_table.Customer_ID,
	first_prod_table.Product_Name
FROM
(
	SELECT DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY count(m.product_name) DESC) as Rank,
		s.customer_id as Customer_ID,
		m.product_name as Product_Name,
		count(m.product_name) as Order_Frequency
	FROM sales as s
	INNER JOIN menu as m
	ON s.product_id = m.product_id
	GROUP BY s.customer_id,
		m.product_name) as first_prod_table
WHERE first_prod_table.Rank = 1;

-- 6. Which item was purchased first by the customer after they became a member?

SELECT first_prod_table.Customer_ID,
	first_prod_table.Product_Name
FROM
(
	SELECT DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) as Rank,
		s.customer_id as Customer_ID,
		m.product_name as Product_Name
	FROM sales as s
	INNER JOIN menu as m
	ON s.product_id = m.product_id
	INNER JOIN members as mem
	ON mem.customer_id = s.customer_id
	WHERE s.order_date >= mem.join_date) as first_prod_table
WHERE first_prod_table.Rank = 1;

-- 7. Which item was purchased just before the customer became a member?

SELECT first_prod_table.Customer_ID,
	first_prod_table.Product_Name
FROM
(
	SELECT DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) as Rank,
		s.customer_id as Customer_ID,
		m.product_name as Product_Name
	FROM sales as s
	INNER JOIN menu as m
	ON s.product_id = m.product_id
	INNER JOIN members as mem
	ON mem.customer_id = s.customer_id
	WHERE s.order_date < mem.join_date) as first_prod_table
WHERE first_prod_table.Rank = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id as Customer_ID,
	sum(m.price) as Total_Spend
FROM sales as s
INNER JOIN menu as m
ON s.product_id = m.product_id
INNER JOIN members as mem
ON mem.customer_id = s.customer_id
WHERE s.order_date < mem.join_date
GROUP  BY s.customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT s.customer_id as Customer_ID,
	sum(case when m.product_name = 'sushi'
		then m.price * 20
		else m.price * 10
		end) as Points
FROM sales as s
INNER JOIN menu as m
ON s.product_id = m.product_id
GROUP BY s.customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
--     not just sushi - how many points do customer A and B have at the end of January?

SELECT s.customer_id as Customer_ID,
		sum(case when datediff(DAY, s.order_date,mem.join_date) between 0 and 7
			then m.price * 20
			else (case when m.product_name = 'sushi'
					then m.price * 20
					else m.price * 10
					end)
			end) as Points
FROM sales as s
INNER JOIN menu as m
ON s.product_id = m.product_id
INNER JOIN members as mem
ON mem.customer_id = s.customer_id
WHERE s.order_date <= '2021-01-31'
GROUP BY s.customer_id