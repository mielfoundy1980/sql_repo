/*
======================================================
Create Views for Gold Layers:
1. Customers Dimension View : Gold.dim_coustomers
2. Products Dimension View : Gold.dim_products
3. Sales Fact View : Gold.fact_sales
======================================================
*/

-- 1. Customers Dimension View : Gold.dim_coustomers

IF OBJECT_ID('Gold.dim_coustomers', 'V') IS NOT NULL
  DROP VIEW Gold.dim_coustomers;
GO
CREATE VIEW Gold.dim_customers AS
SELECT
	ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	cl.CNTRY AS country,
	ci.cst_marital_status AS marital_status,
	CASE
		WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the Master for Gender Info
		ELSE COALESCE(ca.GEN, 'n/a')
	END AS gender,
	ca.BDATE AS birthdate,
	ci.cst_create_date AS create_date
FROM Silver.crm_cust_info ci
	LEFT JOIN Silver.erp_cust_az12 ca
ON ci.cst_key = ca.CID
	LEFT JOIN Silver.erp_loc_a101 cl
ON ca.CID = cl.CID;

-- 2. Products Dimension View : Gold.dim_products
IF OBJECT_ID('Gold.dim_products', 'V') IS NOT NULL
  DROP VIEW Gold.dim_products;
GO
CREATE VIEW Gold.dim_products AS
SELECT
	ROW_NUMBER() OVER (ORDER BY pd.prd_start_dt, pd.prd_key) AS product_key,
	pd.prd_id AS product_id,
	pd.prd_key AS product_number,
	pd.prd_nm AS product_name,
	pd.prd_line AS product_line,
	pd.cat_id AS category_id,
	pc.CAT AS category,
	pc.SUBCAT AS sub_category,
	pc.MAINTENANCE AS maintenance,
	pd.prd_cost AS cost,
	pd.prd_start_dt AS start_date
FROM Silver.crm_prd_info pd
LEFT JOIN Silver.erp_px_cat_g1v2 pc
ON pd.cat_id = pc.ID
WHERE prd_end_dt IS NULL; -- Filer out all historical data

-- 3. Sales Fact View : Gold.fact_sales
IF OBJECT_ID('Gold.fact_sales', 'V') IS NOT NULL
  DROP VIEW Gold.fact_sales;
GO
CREATE VIEW Gold.fact_sales AS
SELECT
	sls_ord_num AS order_number,
	dp.product_key AS product_key,
	dc.customer_key AS customer_key,
	sls_quantity AS quantity,
	sls_price AS price,
	sls_sales AS sales_amount,
	sls_order_dt AS order_date,
	sls_ship_dt AS shipping_date,
	sls_due_dt AS due_date
FROM Silver.crm_sales_details sd
LEFT JOIN Gold.dim_products dp
ON sd.sls_prd_key = dp.product_number
LEFT JOIN Gold.dim_customers dc
ON sd.sls_cust_id = dc.customer_id;
