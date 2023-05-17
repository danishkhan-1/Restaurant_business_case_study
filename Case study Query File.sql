-- Which item was purchased first by the customer after they became a member?

WITH member_sales_cte AS
(
 SELECT s.customer_id, m.join_date, s.order_date, s.product_id,
 DENSE_RANK() OVER(PARTITION BY s.customer_id
 ORDER BY s.order_date) AS ranking
 FROM dbo.sales AS s
 JOIN dbo.members AS m
 ON s.customer_id = m.customer_id
 WHERE s.order_date >=  m.join_date
)
SELECT ms.customer_id, ms.order_date, m2.product_name
FROM member_sales_cte AS ms
JOIN dbo.menu AS m2
 ON ms.product_id = m2.product_id 
 where ms.ranking = 1 ;
 
 
 
 -- Which item was purchased right before the customer became a member?
 
 WITH member_sales_cte AS
(
 SELECT s.customer_id, m.join_date, s.order_date, s.product_id,
 DENSE_RANK() OVER(PARTITION BY s.customer_id
 ORDER BY s.order_date desc) AS ranking
 FROM dbo.sales AS s
 JOIN dbo.members AS m
 ON s.customer_id = m.customer_id
 WHERE s.order_date <  m.join_date
)
SELECT ms.customer_id, ms.order_date, m2.product_name
FROM member_sales_cte AS ms
JOIN dbo.menu AS m2
 ON ms.product_id = m2.product_id 
 where ms.ranking = 1 ;
 
 
 
 -- What is the total number of items and amount spent for each member before they became a member?
 
 select s.customer_id , sum(m2.price) as amt_spent , count(m2.product_id) as Total_items 
 from dbo.sales as s 
 inner join dbo.members as m1 
 on s.customer_id = m1.customer_id
 left join dbo.menu m2 
 on s.product_id=m2.product_id
 where  s.order_date <  m1.join_date
 group by 1 ;
 
 
 -- If each customers’ $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have
 
 WITH price_points AS
 (
 SELECT *,
 CASE WHEN product_name = 'sushi' THEN price*20 ELSE price*10 END AS points
 FROM
 dbo.menu
 )
 SELECT s.customer_id, SUM(p.points) AS total_points
FROM price_points AS p
JOIN dbo.sales AS s
ON p.product_id = s.product_id
GROUP BY s.customer_id
ORDER BY customer_id ;


-- In the first week after a customer joins the program, (including their join date) they earn 2x points on all items; not just sushi —
-- how many points do customer A and B have at the end of Jan21?

WITH dates_cte AS
(
SELECT * ,
 join_date + INTERVAL'6 day' AS valid_date,
 DATE('2021-01-31') AS last_date
 FROM dbo.members AS m
 ),
 points_cte AS 
 (
 SELECT d.customer_id, s.order_date, d.join_date,
 d.valid_date, d.last_date, m.product_name, m.price,
 SUM( CASE WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price
     WHEN s.order_date BETWEEN d.join_date AND d.valid_date THEN 2 * 10 * m.price
     ELSE 10 * m.price
     END 
    ) AS points
   
    FROM dates_cte AS d
    JOIN dbo.sales AS s
     ON d.customer_id = s.customer_id
    JOIN dbo.menu AS m
     ON s.product_id = m.product_id
    WHERE s.order_date < d.last_date
    GROUP BY d.customer_id, s.order_date, d.join_date, d.valid_date, d.last_date,  m.product_name, m.price
   
  ) -- end of points_cte 
  
SELECT
customer_id, SUM(points) AS total_points
FROM points_cte
GROUP BY customer_id ;
 
 