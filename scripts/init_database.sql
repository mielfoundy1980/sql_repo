/* CREATE A 'DataWarehouse' DATABASE and SCHEMAS : Bronze, Silver & Gold */
USE master;
GO

-- Drop the 'DataWarehouse' database if Exists
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO

-- Re Create the 'DataWarehouse' database
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- Create Schemas for layers : Bronze, Silver and Gold
-- Drop schemas only if they exist to avoid errors
IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Bronze')
BEGIN
    DROP SCHEMA Bronze;
END;
GO

CREATE SCHEMA Bronze;
GO

IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Silver')
BEGIN
    DROP SCHEMA Silver;
END;
GO

CREATE SCHEMA Silver;
GO

IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Gold')
BEGIN
    DROP SCHEMA Gold;
END;
GO

CREATE SCHEMA Gold;
GO
