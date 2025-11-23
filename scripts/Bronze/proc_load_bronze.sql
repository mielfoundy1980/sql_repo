/*
===============================================================
Stored Procedure : Load Bronze Layer from 'Source' to 'Bronze'.
The present procedure trauncates the 'Bronze' Tables before
loading data using 'BULK INSERT' command.

SQL code to execute the procedure : EXEC Bronze.load_bronze;
===============================================================
*/
CREATE OR ALTER PROCEDURE Bronze.load_bronze AS 
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		-- Empty Table then pouplate the table from the CRM source 'cust_info.csv' file
		PRINT '==================================================';
		PRINT 'Loading Bronze Layer';
		PRINT '==================================================';

		PRINT '--------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '--------------------------------------------------';

		SET @start_time = GETDATE();

		PRINT '>> Truncating Table : Bronze.crm_cust_info';
		TRUNCATE TABLE Bronze.crm_cust_info;

		PRINT '>> Inserting Data Into Table : Bronze.crm_cust_info';
		BULK INSERT Bronze.crm_cust_info
		FROM 'C:\Users\Pc\Desktop\DOSSIER PERSONNEL\ANALYSE DONNEES\SQL PROJECTS\SALES_PROJECT_BARAA\Raw_Data\source_crm_csv_files\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK 
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration : ' + CAST (DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-----------------------------------'

		-- Empty Table then pouplate the table from the CRM source 'prd_info.csv' file
		SET @start_time = GETDATE();

		PRINT '>> Truncating Table : Bronze.crm_prd_info';
		TRUNCATE TABLE Bronze.crm_prd_info;

		PRINT '>> Inserting Data Into Table : Bronze.crm_prd_info';
		BULK INSERT Bronze.crm_prd_info
		FROM 'C:\Users\Pc\Desktop\DOSSIER PERSONNEL\ANALYSE DONNEES\SQL PROJECTS\SALES_PROJECT_BARAA\Raw_Data\source_crm_csv_files\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK 
		);

		SET @end_time = GETDATE();
		PRINT '>> Load Duration : ' + CAST (DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-----------------------------------'

		-- Empty Table then pouplate the table from the CRM source 'sales_details.csv' file

		SET @start_time = GETDATE();

		PRINT '>> Truncating Table : Bronze.crm_sales_details';
		TRUNCATE TABLE Bronze.crm_sales_details;

		PRINT '>> Inserting Data Into Table : Bronze.crm_sales_details';
		BULK INSERT Bronze.crm_sales_details
		FROM 'C:\Users\Pc\Desktop\DOSSIER PERSONNEL\ANALYSE DONNEES\SQL PROJECTS\SALES_PROJECT_BARAA\Raw_Data\source_crm_csv_files\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK 
		);

		SET @end_time = GETDATE();
		PRINT '>> Load Duration : ' + CAST (DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-----------------------------------'
		
		-- Empty Table then pouplate the table from the ERP source 'CUST_AZ12.csv' file
		SET @start_time = GETDATE();

		PRINT '--------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '--------------------------------------------------';

		PRINT '>> Truncating Table : Bronze.erp_cust_az12';
		TRUNCATE TABLE Bronze.erp_cust_az12;

		PRINT '>> Inserting Data Into Table : Bronze.erp_cust_az12';
		BULK INSERT Bronze.erp_cust_az12
		FROM 'C:\Users\Pc\Desktop\DOSSIER PERSONNEL\ANALYSE DONNEES\SQL PROJECTS\SALES_PROJECT_BARAA\Raw_Data\source_erp_csv_files\CUST_AZ12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK 
		);

		SET @end_time = GETDATE();
		PRINT '>> Load Duration : ' + CAST (DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-----------------------------------'
		
		-- Empty Table then pouplate the table from the ERP source 'LOC_A101.csv' file
		SET @start_time = GETDATE();

		PRINT '>> Truncating Table : Bronze.erp_loc_a101';
		TRUNCATE TABLE Bronze.erp_loc_a101;

		PRINT '>> Inserting Data Into Table : Bronze.erp_loc_a101';
		BULK INSERT Bronze.erp_loc_a101
		FROM 'C:\Users\Pc\Desktop\DOSSIER PERSONNEL\ANALYSE DONNEES\SQL PROJECTS\SALES_PROJECT_BARAA\Raw_Data\source_erp_csv_files\LOC_A101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK 
		);

		SET @end_time = GETDATE();
		PRINT '>> Load Duration : ' + CAST (DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-----------------------------------'
		
		
		-- Empty Table then pouplate the table from the ERP source 'PX_CAT_G1V2.csv' file
		SET @start_time = GETDATE();

		PRINT '>> Truncating Table : Bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE Bronze.erp_px_cat_g1v2;

		PRINT '>> Inserting Data Into Table : Bronze.erp_px_cat_g1v2';
		BULK INSERT Bronze.erp_px_cat_g1v2
		FROM 'C:\Users\Pc\Desktop\DOSSIER PERSONNEL\ANALYSE DONNEES\SQL PROJECTS\SALES_PROJECT_BARAA\Raw_Data\source_erp_csv_files\PX_CAT_G1V2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK 
		);

		SET @end_time = GETDATE();
		PRINT '>> Load Duration : ' + CAST (DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-----------------------------------';
	
	SET @batch_end_time = GETDATE();
	PRINT '+++++++++++++++++++++++++++++++++++';
	PRINT '>> Loading Bronze Layer is completed.';
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
