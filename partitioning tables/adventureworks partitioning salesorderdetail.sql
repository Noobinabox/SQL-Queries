/*****************************************************************************************
** File:	adventureworks_partitioning_salesorderdetail_with_filegroups.sql
** Name:	AdventureWorks2014 Partitioning with FileGroups
** Desc:	Adding filegroups to the database Adventureworks and creating the partition function
** Auth:	Seth Lyon
** Date:	Oct 21, 2015
********************************************************
** Change History
********************************************************
** PR	Date		Author			Description	
** --	----------	------------	------------------------------------
** 1	10/21/2015	Seth Lyon		Created
*****************************************************************************************/

USE [master];
GO


-- First we need to create the filegroups in Adventureworks
ALTER DATABASE [AdventureWorks2014] ADD FILEGROUP AdventureWorks2014_Sales_P1;
ALTER DATABASE [AdventureWorks2014] ADD FILEGROUP AdventureWorks2014_Sales_P2;
ALTER DATABASE [AdventureWorks2014] ADD FILEGROUP AdventureWorks2014_Sales_P3;
ALTER DATABASE [AdventureWorks2014] ADD FILEGROUP AdventureWorks2014_Sales_P4;
ALTER DATABASE [AdventureWorks2014] ADD FILEGROUP AdventureWorks2014_Sales_P5;
ALTER DATABASE [AdventureWorks2014] ADD FILEGROUP AdventureWorks2014_Sales_P6;
ALTER DATABASE [AdventureWorks2014] ADD FILEGROUP AdventureWorks2014_Sales_P7;
ALTER DATABASE [AdventureWorks2014] ADD FILEGROUP AdventureWorks2014_Sales_P8;


ALTER DATABASE [AdventureWorks2014] ADD FILE (
	NAME=AdventureWorks2014_Sales_P1,
	FILENAME='C:\MSSQL Secondary FG\AdventureWorks2014_Sales_P1.ndf',
	SIZE=5MB,
	FILEGROWTH=10MB)
TO FILEGROUP AdventureWorks2014_Sales_P1;

ALTER DATABASE [AdventureWorks2014] ADD FILE (
	NAME=AdventureWorks2014_Sales_P2,
	FILENAME='C:\MSSQL Secondary FG\AdventureWorks2014_Sales_P2.ndf',
	SIZE=5MB,
	FILEGROWTH=10MB)
TO FILEGROUP AdventureWorks2014_Sales_P2;

ALTER DATABASE [AdventureWorks2014] ADD FILE (
	NAME=AdventureWorks2014_Sales_P3,
	FILENAME='C:\MSSQL Secondary FG\AdventureWorks2014_Sales_P3.ndf',
	SIZE=5MB,
	FILEGROWTH=10MB)
TO FILEGROUP AdventureWorks2014_Sales_P3;

ALTER DATABASE [AdventureWorks2014] ADD FILE (
	NAME=AdventureWorks2014_Sales_P4,
	FILENAME='C:\MSSQL Secondary FG\AdventureWorks2014_Sales_P4.ndf',
	SIZE=5MB,
	FILEGROWTH=10MB)
TO FILEGROUP AdventureWorks2014_Sales_P4;

ALTER DATABASE [AdventureWorks2014] ADD FILE (
	NAME=AdventureWorks2014_Sales_P5,
	FILENAME='C:\MSSQL Secondary FG\AdventureWorks2014_Sales_P5.ndf',
	SIZE=5MB,
	FILEGROWTH=10MB)
TO FILEGROUP AdventureWorks2014_Sales_P5;

ALTER DATABASE [AdventureWorks2014] ADD FILE (
	NAME=AdventureWorks2014_Sales_P6,
	FILENAME='C:\MSSQL Secondary FG\AdventureWorks2014_Sales_P6.ndf',
	SIZE=5MB,
	FILEGROWTH=10MB)
TO FILEGROUP AdventureWorks2014_Sales_P6;

ALTER DATABASE [AdventureWorks2014] ADD FILE (
	NAME=AdventureWorks2014_Sales_P7,
	FILENAME='C:\MSSQL Secondary FG\AdventureWorks2014_Sales_P7.ndf',
	SIZE=5MB,
	FILEGROWTH=10MB)
TO FILEGROUP AdventureWorks2014_Sales_P7;

ALTER DATABASE [AdventureWorks2014] ADD FILE (
	NAME=AdventureWorks2014_Sales_P8,
	FILENAME='C:\MSSQL Secondary FG\AdventureWorks2014_Sales_P8.ndf',
	SIZE=5MB,
	FILEGROWTH=10MB)
TO FILEGROUP AdventureWorks2014_Sales_P8;

USE [AdventureWorks2014];
GO

CREATE PARTITION FUNCTION [pfnSalesOrderDetails] (datetime) AS RANGE RIGHT FOR VALUES
('5/31/2011','5/31/2012','5/31/2013','9/01/2013','1/01/2014','3/1/2014','7/1/2049')

CREATE PARTITION SCHEME [SOQuarterlyScheme] AS PARTITION [pfnSalesOrderDetails] TO
([AdventureWorks2014_Sales_P1],[AdventureWorks2014_Sales_P2],[AdventureWorks2014_Sales_P3],[AdventureWorks2014_Sales_P4],[AdventureWorks2014_Sales_P5],
[AdventureWorks2014_Sales_P6],[AdventureWorks2014_Sales_P7],[AdventureWorks2014_Sales_P8])

ALTER TABLE [Sales].[SalesOrderDetail] DROP CONSTRAINT [PK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID]


ALTER TABLE [Sales].[SalesOrderDetail] ADD  CONSTRAINT [PK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID] PRIMARY KEY NONCLUSTERED 
(
	[SalesOrderID] ASC,
	[SalesOrderDetailID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

CREATE CLUSTERED INDEX [ClusteredIndex_on_SOYearlyPartitionScheme_635797251742840844] ON [Sales].[SalesOrderDetail]
(
	[ModifiedDate]
)WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [SOQuarterlySCheme]([ModifiedDate])

