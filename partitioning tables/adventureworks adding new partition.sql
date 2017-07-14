/*****************************************************************************************
** File:	adventureworks_adding_new_partition.sql
** Name:	AdventureWorks2014 Adding New Partition
** Desc:	Basic script to create partitions on the AdventureWorks2014 database
** Auth:	Seth Lyon
** Date:	Oct 21, 2015
********************************************************
** Change History
********************************************************
** PR	Date		Author			Description	
** --	----------	------------	------------------------------------
** 1	10/21/2015	Seth Lyon		Created
*****************************************************************************************/

ALTER DATABASE [AdventureWorks2014]
	ADD FILEGROUP AdventureWorks2014_Sales_P9;

ALTER DATABASE [AdventureWorks2014] ADD FILE (
	NAME=AdventureWorks2014_Sales_P9,
	FILENAME='C:\MSSQL Secondary FG\AdventureWorks2014_Sales_P9.ndf',
	SIZE=5MB,
	FILEGROWTH=10MB)
TO FILEGROUP AdventureWorks2014_Sales_P9;



--You need to alter the partition scheme first before splitting
--the range
BEGIN TRANSACTION

	ALTER PARTITION SCHEME [SOQuarterlyScheme]
	NEXT USED [AdventureWorks2014_Sales_P8]

	ALTER PARTITION FUNCTION [pfnSalesOrderDetails] ()
	SPLIT RANGE ('4/1/2014')

COMMIT TRANSACTION