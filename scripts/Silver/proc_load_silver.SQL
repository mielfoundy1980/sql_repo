
/*
===============================================================
Stored Procedure : Load Silver Layer from 'Bronze' to 'Silver'.
The present procedure trauncates the 'Silver' Tables before
loading data using 'BULK INSERT' command.

SQL code to execute the procedure : EXEC Silver.load_silver;
===============================================================
*/

CREATE OR ALTER PROCEDURE Silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE();

		PRINT '==================================================';
		PRINT 'Loading Silver Layer';
		PRINT '==================================================';
		-- Empty 'Silver.crm_cust_info' table then pouplate it from 'Bronze.crm_cust_info' table
		PRINT '==================================================';
		PRINT 'Loading table : Silver.crm_cust_info';
		PRINT '==================================================';
		
		SET @start_time = GETDATE();
		PRINT '>> Truncating the table : Silver.crm_cust_info'
		TRUNCATE TABLE Silver.crm_cust_info

		PRINT '>> Inserting Data into : Silver.crm_cust_info'

		INSERT INTO Silver.crm_cust_info (
		cst_id, 
		cst_key, 
		cst_firstname, 
		cst_lastname, 
		cst_marital_status,
		cst_gndr, 
		cst_create_date
		)
		SELECT
			cst_id,
			cst_key,
			TRIM(cst_firstname) AS cst_firstname, -- Data Consistency
			TRIM(cst_lastname) AS cst_lastname, -- Data Consistency
			CASE
				WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
				WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
				ELSE 'n/a' -- Handling missing values
			END cst_marital_status, -- Normalize marital_status values to readable format
			CASE
				WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
				WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
				ELSE 'n/a' -- Handling missing values
			END cst_gndr, -- Normalize gender values to readable format
			cst_create_date
		FROM (
			SELECT
				*,
				ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
			FROM Bronze.crm_cust_info
			) t
		WHERE flag_last = 1 AND cst_id IS NOT NULL; -- Select the most recent record per customer in order to remove duplicates

		SET @end_time = GETDATE();
		PRINT '>> Load Duration : ' + CAST (DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-----------------------------------'

		-- Empty 'Silver.crm_prd_info' table then pouplate it from 'Bronze.crm_prd_info' table
		PRINT '==================================================';
		PRINT 'Loading table : Silver.crm_prd_info';
		PRINT '==================================================';
		
		SET @start_time = GETDATE();
		PRINT '>> Truncating the table : Silver.crm_prd_info'
		TRUNCATE TABLE Silver.crm_prd_info

		PRINT '>> Inserting Data into : Silver.crm_prd_info'

		INSERT INTO Silver.crm_prd_info (
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		SELECT 
			prd_id,
			REPLACE(LEFT(prd_key, 5), '-', '_') AS cat_id, -- Extract category_id
			SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key, -- Extract product_key
			TRIM(prd_nm) AS prd_nm,
			ISNULL(prd_cost, 0) AS prd_cost,
			CASE UPPER(TRIM(prd_line))
				WHEN 'M' THEN 'Mountain'
				WHEN 'R' THEN 'Road'
				WHEN 'S' THEN 'Other Sales'
				WHEN 'T' THEN 'Touring'
				ELSE 'n/a'
			END AS prd_line, -- Map product line codes to descriptive values
			CAST (prd_start_dt AS DATE) AS prd_start_dt,
			CAST (
				LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE
				) AS prd_end_dt -- Calculate end date as one day before the next start date
		FROM Bronze.crm_prd_info;

		SET @end_time = GETDATE();
		PRINT '>> Load Duration : ' + CAST (DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-----------------------------------'

		-- Empty 'Silver.crm_sales_details' table then pouplate it from 'Bronze.crm_sales_details' table
		PRINT '==================================================';
		PRINT 'Loading table : Silver.crm_sales_details';
		PRINT '==================================================';
		
		SET @start_time = GETDATE();
		PRINT '>> Truncating the table : Silver.crm_sales_details'
		TRUNCATE TABLE Silver.crm_sales_details

		PRINT '>> Inserting Data into : Silver.crm_sales_details'
		INSERT INTO Silver.crm_sales_details (
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)
		SELECT
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			CASE
				WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
				ELSE CAST (CAST (sls_order_dt AS VARCHAR) AS DATE)
			END sls_order_dt,
			CASE
				WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
			END sls_ship_dt,
			CASE
				WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
			END sls_due_dt,
			CASE 
				WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != (sls_quantity * ABS(sls_price)) 
					THEN ABS(sls_quantity) * ABS(sls_price)
				ELSE sls_sales
			END AS sls_sales, -- Recalculate sales if original value is missing or incorrect
			sls_quantity,
			CASE
				WHEN sls_price IS NULL OR sls_price <= 0
					THEN ABS(sls_sales) / NULLIF(ABS(sls_quantity), 0)
				ELSE sls_price -- Derive price if original value is invalid
			END AS sls_price
		FROM Bronze.crm_sales_details;

		SET @end_time = GETDATE();
		PRINT '>> Load Duration : ' + CAST (DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-----------------------------------'

		-- Empty 'Silver.erp_cust_az12' table then pouplate it from 'Bronze.erp_cust_az12' table
		PRINT '==================================================';
		PRINT 'Loading table : Silver.erp_cust_az12';
		PRINT '==================================================';
		
		SET @start_time = GETDATE();
		PRINT '>> Truncating the table : Silver.erp_cust_az12'
		TRUNCATE TABLE Silver.erp_cust_az12

		PRINT '>> Inserting Data into : Silver.erp_cust_az12'

		INSERT INTO Silver.erp_cust_az12 (
			cid,
			bdate,
			gen
		)
		SELECT
			CASE
				WHEN CID LIKE 'NAS%' THEN SUBSTRING(TRIM(CID), 4, LEN(TRIM(CID)))
				ELSE TRIM(CID)
			END AS CID,
			CASE
				WHEN BDATE > GETDATE() THEN NULL
				ELSE BDATE
			END AS BDATE,
			CASE 
				WHEN UPPER(TRIM(GEN)) IN ('F', 'FEMALE') THEN 'Female'
				WHEN UPPER(TRIM(GEN)) IN ('M', 'MALE') THEN 'Male'
				ELSE 'n/a'
			END AS GEN
		FROM Bronze.erp_cust_az12;

		SET @end_time = GETDATE();
		PRINT '>> Load Duration : ' + CAST (DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-----------------------------------'

		-- Empty 'Silver.erp_loc_a101' table then pouplate it from 'Bronze.erp_loc_a101' table
		PRINT '==================================================';
		PRINT 'Loading table : Silver.erp_loc_a101';
		PRINT '==================================================';
		
		SET @start_time = GETDATE();

		PRINT '>> Truncating the table : Silver.erp_loc_a101'
		TRUNCATE TABLE Silver.erp_loc_a101

		PRINT '>> Inserting Data into : Silver.erp_loc_a101'

		INSERT INTO Silver.erp_loc_a101 (
			cid,
			cntry
		)
		SELECT
			REPLACE(TRIM(CID), '-', '') AS CID,
			CASE 
				WHEN TRIM(CNTRY) = 'DE' THEN 'Germany'
				WHEN TRIM(CNTRY) IN ('USA', 'US') THEN 'United States'
				WHEN TRIM(CNTRY) IS NULL OR TRIM(CNTRY) = '' THEN 'n/a'
				ELSE TRIM(CNTRY)
			END AS CNTRY
		FROM Bronze.erp_loc_a101

		SET @end_time = GETDATE();
		PRINT '>> Load Duration : ' + CAST (DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-----------------------------------'

		-- Empty 'Silver.erp_px_cat_g1v2' table then pouplate it from 'Bronze.erp_px_cat_g1v2' table
		PRINT '==================================================';
		PRINT 'Loading table : Silver.erp_px_cat_g1v2';
		PRINT '==================================================';
		
		SET @start_time = GETDATE();

		PRINT '>> Truncating the table : Silver.erp_px_cat_g1v2'
		TRUNCATE TABLE Silver.erp_px_cat_g1v2

		PRINT '>> Inserting Data into : Silver.erp_px_cat_g1v2'

		INSERT INTO Silver.erp_px_cat_g1v2 (
			id,
			cat,
			subcat,
			maintenance
		)
		SELECT
			TRIM(ID) AS ID,
			TRIM(CAT) AS CAT,
			SUBCAT,
			TRIM(MAINTENANCE) AS MAINTENANCE
		FROM Bronze.erp_px_cat_g1v2;

		SET @end_time = GETDATE();
		PRINT '>> Load Duration : ' + CAST (DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-----------------------------------'

		SET @batch_end_time = GETDATE();
	PRINT '+++++++++++++++++++++++++++++++++++';
	PRINT '>> Loading Silver Layer is completed.';
	PRINT '>> - Total Load Duration : ' + CAST (DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
	PRINT '+++++++++++++++++++++++++++++++++++';
	
	END TRY
	BEGIN CATCH
		PRINT '==================================================';
		PRINT 'Error Occured During Loading Bronze Layer !';
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '==================================================';
	END CATCH

END
