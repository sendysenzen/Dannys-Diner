## My First Markdown File 

#### In this section I tried to provide explanation on the solution and the business insights

This is the first markdown file and as part of my learning to practice providing insights for the business.
However, in this study case it is limited to the business questions provided in the study case. 

In this study case I didn't create a join table, instead only approach with common table expression or subquery. No data cleaning as well. 


**1. What is the total amount each customer spent at the restaurant?**

```sql
SELECT 
    s.customer_id,
    SUM(m.price)
FROM sales s, menu m
WHERE s.product_id = m.product_id
GROUP BY 1
ORDER BY 1; 
```
**I will update this file again soon**

*to be continued*

