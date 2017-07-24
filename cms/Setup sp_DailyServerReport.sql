/*******************************************************************************************
** File:	daily_server_report.sql  	
** Name:	Daily Server Report
** Desc:	Does a report of database and log size plus space used to CMS
** Auth:	Seth Lyon
** Date:	Feb 29, 2016
********************************************************
** Change History
********************************************************
** PR	Date		Author			Description	
** --	----------	------------	------------------------------------
** 1	2/29/2016	Seth Lyon		Created
** 2	3/1/2016	Seth Lyon		Fixed some code issues
*****************************************************************************************/
USE [master]
GO

IF NOT EXISTS(SELECT * FROM sys.schemas WHERE name = '{Company Schema Here}')
BEGIN
	EXEC('CREATE SCHEMA [{Company Schema Here}]');
END
GO


SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF EXISTS( SELECT
				*
			FROM sys.objects
			WHERE object_id = OBJECT_ID(N'[{Company Schema Here}].[sp_DailyServerReport]')
				  AND type IN ( N'P',N'PC'))
BEGIN
	DROP PROCEDURE [{Company Schema Here}].[sp_DailyServerReport];
END
GO

CREATE PROCEDURE [{Company Schema Here}].[sp_DailyServerReport]
AS
BEGIN

	IF EXISTS (SELECT * FROM tempdb.sys.all_objects WHERE name LIKE '%#dbsize%') 
		DROP TABLE #dbsize 
	CREATE TABLE #dbsize 
	(
		Dbname SYSNAME,
		dbstatus varchar(50),
		Recovery_Model varchar(40) default ('NA'), 
		file_Size_MB decimal(30,2)default (0),
		Space_Used_MB decimal(30,2)default (0),
		Free_Space_MB decimal(30,2) default (0)
	);
	
  
	INSERT INTO #dbsize(Dbname,dbstatus,Recovery_Model,file_Size_MB,Space_Used_MB,Free_Space_MB) 
	EXEC sp_msforeachdb 
	'USE [?]; 
		SELECT 
			DB_NAME() AS DbName, 
			CONVERT(varchar(20),DatabasePropertyEx(''?'',''Status'')) ,  
			CONVERT(varchar(20),DatabasePropertyEx(''?'',''Recovery'')),  
			SUM(size)/128.0 AS File_Size_MB, 
			SUM(CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT))/128.0 AS Space_Used_MB, 
			SUM( size)/128.0 - SUM(CAST(FILEPROPERTY(name,''SpaceUsed'') AS INT))/128.0 AS Free_Space_MB  
		FROM sys.database_files  WHERE type=0 GROUP BY type';
  
	-------------------log size-------------------------------------- 
	IF EXISTS (SELECT * FROM tempdb.sys.all_objects WHERE name LIKE '#logsize%') 
		DROP TABLE #logsize 

	CREATE TABLE #logsize 
	(
		Dbname SYSNAME, 
		Log_File_Size_MB decimal(38,2)default (0),
		log_Space_Used_MB decimal(30,2)default (0),
		log_Free_Space_MB decimal(30,2)default (0)
	);
  
	INSERT INTO #logsize(Dbname,Log_File_Size_MB,log_Space_Used_MB,log_Free_Space_MB) 
	EXEC sp_msforeachdb 
	'USE [?]; 
		SELECT 
			DB_NAME() AS DbName, 
			sum(size)/128.0 AS Log_File_Size_MB, 
			sum(CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT))/128.0 as log_Space_Used_MB, 
			SUM( size)/128.0 - sum(CAST(FILEPROPERTY(name,''SpaceUsed'') AS INT))/128.0 AS log_Free_Space_MB  
		FROM sys.database_files  WHERE type=1 GROUP BY type';

	--------------------------------database free size 
	IF EXISTS (SELECT * FROM tempdb.sys.all_objects WHERE name LIKE '%#dbfreesize%') 
		DROP TABLE #dbfreesize 

	CREATE TABLE #dbfreesize 
	(
		name sysname, 
		database_size varchar(50), 
		Freespace varchar(50)default (0.00)
	) 
  
	INSERT INTO #dbfreesize(name,database_size,Freespace) 
	EXEC sp_msforeachdb 
	'USE [?];
		SELECT 
			database_name = db_name(), 
			database_size = LTRIM(STR((CONVERT(DECIMAL(15, 2), dbsize) + CONVERT(DECIMAL(15, 2), logsize)) * 8192 / 1048576, 15, 2) + ''MB''), 
			''unallocated space'' = LTRIM(STR(( 
					CASE  
						WHEN dbsize >= reservedpages 
							THEN (CONVERT(DECIMAL(15, 2), dbsize) - convert(DECIMAL(15, 2), reservedpages)) * 8192 / 1048576 
						ELSE 0 
						END 
					), 15, 2) + '' MB'') 
		FROM ( 
			SELECT dbsize = sum(convert(BIGINT, CASE  
						WHEN type = 0 
							THEN size 
						ELSE 0 
						END)) 
			,logsize = sum(convert(BIGINT, CASE  
						WHEN type <> 0 
							THEN size 
						ELSE 0 
						END)) 
			FROM sys.database_files 
			) AS files 
	,( 
		SELECT reservedpages = sum(a.total_pages) 
			,usedpages = sum(a.used_pages) 
			,pages = sum(CASE  
					WHEN it.internal_type IN ( 
							202 
							,204 
							,211 
							,212 
							,213 
							,214 
							,215 
							,216 
							) 
						THEN 0 
					WHEN a.type <> 1 
						THEN a.used_pages 
					WHEN p.index_id < 2 
						THEN a.data_pages 
					ELSE 0 
					END) 
		FROM sys.partitions p 
		INNER JOIN sys.allocation_units a 
			ON p.partition_id = a.container_id 
		LEFT JOIN sys.internal_tables it 
			ON p.object_id = it.object_id 
	) AS partitions' 
	----------------------------------- 
  
  
  
	IF EXISTS (select * from tempdb.sys.all_objects where name like '%#alldbstate%') 
		DROP TABLE #alldbstate  

	CREATE TABLE #alldbstate  
	(
		dbname sysname, 
		DBstatus varchar(55), 
		R_model Varchar(30)
	) 
   
	--select * from sys.master_files 
  
	INSERT INTO #alldbstate (dbname,DBstatus,R_model) 
		SELECT name,CONVERT(varchar(20),DATABASEPROPERTYEX(name,'status')),recovery_model_desc FROM sys.databases 
	--select * from #dbsize 
  
	INSERT INTO #dbsize(Dbname,dbstatus,Recovery_Model) 
		SELECT dbname,dbstatus,R_model FROM #alldbstate WHERE DBstatus <> 'online' 
  
	INSERT INTO #logsize(Dbname) 
		SELECT dbname FROM #alldbstate WHERE DBstatus <> 'online' 
  
	INSERT INTO #dbfreesize(name) 
		SELECT dbname FROM #alldbstate WHERE DBstatus <> 'online' 

	DECLARE @LinkSvr nvarchar(130);
	DECLARE @Retval int;

	SET @LinkSvr = '{Linked Server Here}';


	BEGIN TRY
		EXEC @Retval = sys.sp_testlinkedserver @LinkSvr;
	END TRY
	BEGIN CATCH
		SET @Retval = SIGN(@@ERROR);
	END CATCH

	IF @Retval = 0
	BEGIN
		INSERT INTO [{Linked Server Here}].[MSSQLMaintenance].[dbo].[DatabaseInformation] 
			(HostName, DatabaseName, DatabaseSizeMB, DatabaseSpaceUsedMB, LogSizeMB, LogSpaceUsedMB, RecoveryModel, CompatibilityLevel, DatabaseStatus) 
		SELECT
			@@SERVERNAME, 
			DBSize.Dbname,
			(file_size_mb + log_file_size_mb) as DBsize, 
			DBSize.Space_Used_MB,
			LGSize.Log_File_Size_MB,
			log_Space_Used_MB,
			DBSize.Recovery_Model, 
			SYSdb.compatibility_level,
			DBSize.dbstatus
		FROM 
			#dbsize AS DBSize 
			JOIN #logsize AS LGSize  
				ON DBSize.Dbname = LGSize.Dbname 
			JOIN #dbfreesize AS DBFreeSpace  
				ON DBSize.Dbname = DBFreeSpace.name 
			JOIN sys.databases AS SYSdb
				ON DBSize.Dbname = SYSdb.name
		ORDER BY Dbname 
	END
END