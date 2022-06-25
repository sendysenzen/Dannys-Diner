-- table menu and product id is created and inserted manually.
-- insert data into sales table: 

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
  
-- answering business questions
-- 1. What is the total amount each customer spent at the restaurant?
SELECT 
    s.customer_id,
    SUM(m.price)
FROM sales s, menu m
WHERE s.product_id = m.product_id
GROUP BY 1
ORDER BY 1; 

-- 2. How many days has each customer visited the restaurant?
SELECT
    s.customer_id, 
    COUNT(*) count_visit
FROM sales s
GROUP BY 1 
ORDER BY 1;

-- 3. What was the first item from the menu purchased by each customer?
-- note: because there are cases where 2 different items are ordered in their
-- first visit, we could we use rank(). We could use row_number() either with the 
-- assumptions that the first product they ordered is sorted by alphabetical or 
-- as stated in original data. I tried to use the row_number here. 

WITH cte AS ( 
    SELECT 
        s.customer_id, 
        m.product_name,
        ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date, m.product_name) row_num
    FROM sales s, menu m
    WHERE s.product_id = m.product_id
)
SELECT 
    customer_id,
    product_name
FROM cte
WHERE row_num = 1;

-- 4. What is the most purchased item on the menu and 
-- how many times was it purchased by all customers?
SELECT
    m.product_name, 
    COUNT(s.*)
FROM menu m, sales s
WHERE s.product_id = m.product_id 
GROUP BY 1
ORDER BY 2;

-- 5. Which item was the most popular for each customer?
-- there is a probability that frequency between menu is the same for every customer,
-- therefore I use dense_rank

WITH cte AS (
    SELECT 
        s.customer_id,
        m.product_name, 
        COUNT(s.*) as number_purchase,
        DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.*) DESC ) rank_num
    FROM sales s, menu m
    WHERE s.product_id = m.product_id 
    GROUP BY 1,2
    )
SELECT customer_id, 
    product_name popular_menu,
    number_purchase
FROM cte
WHERE rank_num = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH cte AS ( 
    SELECT 
        s.customer_id,
        s.order_date, 
        m.product_name,
        RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) rank_num
    FROM sales s 
    INNER JOIN members mb
        ON s.customer_id = mb.customer_id
    INNER JOIN menu m
        ON s.product_id = m.product_id
    WHERE s.order_date >= mb.join_date
) 
SELECT 
    customer_id,
    product_name
FROM cte
WHERE rank_num = 1
ORDER BY 1;

-- 7.Which item was purchased just before the customer became a member? 
WITH cte AS ( 
    SELECT 
        s.customer_id,
        s.order_date, 
        m.product_name,
        RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) rank_num
    FROM sales s 
    INNER JOIN members mb
        ON s.customer_id = mb.customer_id
    INNER JOIN menu m
        ON s.product_id = m.product_id  
    WHERE s.order_date < mb.join_date
) 
SELECT 
    customer_id,
    product_name
FROM cte
WHERE rank_num = 1;

-- 8.What is the number of unique menu items and 
-- total amount spent for each member before they became a member?
SELECT 
    s.customer_id,
    COUNT(DISTINCT s.product_id) count_unique, 
    SUM(m.price) total_amt
FROM sales s 
INNER JOIN menu m
    ON s.product_id = m.product_id  
INNER JOIN members mb
    ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date
GROUP BY 1
ORDER BY 1;

-- 9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
-- how many points would each customer have?
WITH cte AS ( 
    SELECT 
        s.customer_id, 
        s.order_date,
        m.product_name,
        CASE WHEN m.product_name = 'sushi' THEN m.price*10*2
        ELSE m.price*10 END points
    FROM sales s, menu m 
    WHERE s.product_id = m.product_id  
)
SELECT
    customer_id,
    SUM(points) total_pts
FROM cte
GROUP BY 1
ORDER BY 1;

-- 10.In the first week after a customer joins the program 
-- (including their join date) they earn 2x points on all items, not just sushi - 
-- how many points do customer A and B have at the end of January?
WITH cte AS ( 
    SELECT 
        s.customer_id, 
        s.order_date,
        m.product_name,
        CASE 
            WHEN s.order_date BETWEEN mb.join_date AND (mb.join_date + 6) THEN m.price*2*10
            WHEN m.product_name = 'sushi' THEN m.price*2*10
        ELSE m.price*10 END points
    FROM sales s 
    INNER JOIN members mb
        ON s.customer_id = mb.customer_id
    INNER JOIN menu m
        ON s.product_id = m.product_id 
)
SELECT
    customer_id, 
    SUM(points) total_pts
FROM cte
WHERE order_date <= '2021-01-31'
GROUP BY 1
ORDER BY 1;

-- (BONUS QUESTIONS) 11. Join and Rank all the things
-- Danny also requires further information about the ranking of customer products, 
-- but he purposely does not need the ranking for non-member purchases so 
-- he expects null ranking values for the records when 
-- customers are not yet part of the loyalty program.

WITH cte AS (
SELECT s.*,
    m.price,
    CASE WHEN s.order_date >= mb.join_date THEN 'Y' 
    ELSE 'N' END member
FROM sales s 
LEFT JOIN members mb
    ON s.customer_id = mb.customer_id
INNER JOIN menu m
    ON s.product_id = m.product_id 
)
SELECT 
    *,
    CASE WHEN member = 'Y' THEN
        CAST(RANK() OVER(PARTITION BY member,customer_id ORDER BY order_date) as text)
    ELSE 'Null' END ranking
FROM cte
ORDER BY customer_id, member, ranking;

