/*******************************************************************************************
** File:    create_database_snapshot.sql
** Name:	Create Database Snapshot
** Desc:	Creates a snapshot of the database AdventureworksDW2012
** Auth:	Seth Lyon
** Date:	November 18, 2015
********************************************************
** Change History
********************************************************
** PR	Date		Author			Description	
** --	----------	------------	------------------------------------
** 1	11/18/15	Seth Lyon		Created
*****************************************************************************************/


USE [master];
GO

CREATE DATABASE AdventureWorksDW2012_dbss_1400 ON 
	( NAME = AdventureWorksDW2012_Data,
	  FILENAME= 'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\AdventureWorksDW2012_data_1400.ss' )
	  AS SNAPSHOT OF AdventureWorksDW2012;
GO