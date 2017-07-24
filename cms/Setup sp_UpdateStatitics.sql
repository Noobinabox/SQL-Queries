/*******************************************************************************************
** File:	sp_statistics_maintenance.sql
** Name:	Statistics Maintenance
** Desc:	This SP checks the stats of a database for anything that hasn't been updated
**			in 3 days and updates it.
** Auth:	Seth Lyon
** Date:	11/3/2016
********************************************************
** Change History
********************************************************
** PR	Date		Author			Description	
** --	----------	------------	------------------------------------
** 1	11/3/16		Seth Lyon		Created
** 2	11/3/16		Seth Lyon		CL1001
** 3	11/4/16		Seth Lyon		CL1004
** 4	11/7/16		Seth Lyon		CL1005
** 5	11/8/16		Seth Lyon		CL1006
** 6	12/13/16	Seth Lyon		CL1007
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
			WHERE object_id = OBJECT_ID(N'[{Company Schema Here}].[sp_UpdateStatistics]')
				  AND type IN ( N'P',N'PC'))
BEGIN
	DROP PROCEDURE [{Company Schema Here}].[sp_UpdateStatistics];
END
GO


CREATE PROCEDURE [{Company Schema Here}].[sp_UpdateStatistics]
	 @pDatabase		nvarchar(120)
	,@pLogToTable	tinyint = 1
AS
BEGIN

	SET QUOTED_IDENTIFIER ON;
	SET NOCOUNT ON;
	--
	DECLARE	@hostname				nvarchar(130)
		   ,@starttime				datetime
		   ,@jobstarttime			datetime
		   ,@LinkSvr				nvarchar(130)
		   ,@Retval					tinyint
		   ,@schema					SYSNAME
		   ,@tablename				SYSNAME
		   ,@statistics				SYSNAME
		   ,@SQLString				nvarchar(1024)
		   ,@SSS					nvarchar(4000)
		   ,@CRLF					char(2)
		   ,@dbname					nvarchar(120)
		   ,@dbstatid				int;
	--
	SET @hostname		= @@SERVERNAME;
	SET @jobstarttime	= CURRENT_TIMESTAMP;
	SET @LinkSvr		= 'ENP-MPSQL';
	SET @CRLF = CHAR(13) + CHAR(10);
	--
	BEGIN TRY
		EXEC @Retval = sys.sp_testlinkedserver @LinkSvr;
	END TRY
	BEGIN CATCH
		SET @Retval = SIGN(@@ERROR);
	END CATCH
	--
	IF OBJECT_ID('tempdb.dbo.StatsThatNeedUpdating') IS NULL
	BEGIN
		CREATE TABLE tempdb.dbo.StatsThatNeedUpdating (
			StatsID int NOT NULL IDENTITY(1,1),
			DatabaseName nvarchar(120),
			ObjectSchema varchar(1024),
			ObjectName SYSNAME,
			StatisticName SYSNAME,
			StatisticsUpdateDate DATETIME,
			StatUpdate bit,
			CONSTRAINT PK_StatsID_StatsThatNeedUpdating PRIMARY KEY CLUSTERED(StatsID ASC)
		)
		CREATE NONCLUSTERED INDEX IX_StatsThatNeedUpdating_ObjectName ON tempdb.dbo.StatsThatNeedUpdating (ObjectName);
		CREATE NONCLUSTERED INDEX IX_StatsThatNeedUpdating_StatisticName ON tempdb.dbo.StatsThatNeedUpdating (StatisticName);
	END
	--
	SET @SSS = 'USE [' + @pDatabase + '];' + @CRLF;
	SET @SSS = @SSS + 'INSERT INTO tempdb.dbo.StatsThatNeedUpdating' + @CRLF;
	SET @SSS = @SSS + '	SELECT	''' + @pDatabase + '''' + @CRLF; 
	SET @SSS = @SSS + '		,OBJECT_SCHEMA_NAME(OBJECT_ID)' + @CRLF;
	SET @SSS = @SSS + '		,OBJECT_NAME(object_id)' + @CRLF;
	SET @SSS = @SSS + '		,[name]' + @CRLF;
	SET @SSS = @SSS + '		,STATS_DATE([object_id], [stats_id])' + @CRLF;
	SET @SSS = @SSS + '		,0' + @CRLF;
	SET @SSS = @SSS + '	FROM [' + @pDatabase + '].[sys].[stats]' + @CRLF;
	SET @SSS = @SSS + '	WHERE STATS_DATE([object_id], [stats_id]) IS NOT NULL' + @CRLF;
	SET @SSS = @SSS + '		AND STATS_DATE([object_id], [stats_id]) < DATEADD(DAY, -3, GETDATE())' + @CRLF;
	SET @SSS = @SSS + '		AND OBJECT_NAME(object_id) NOT LIKE ''sys%''';
	--
	EXEC sp_executesql @SSS;
	--
	DECLARE cur CURSOR LOCAL STATIC FORWARD_ONLY FOR
		SELECT StatsID, DatabaseName, ObjectSchema, ObjectName, StatisticName 
		FROM tempdb.dbo.StatsThatNeedUpdating 
		WHERE DatabaseName = @pDatabase AND StatUpdate = 0;
	BEGIN TRY
		OPEN cur;
		WHILE (1=1)
			BEGIN;
				FETCH NEXT FROM cur INTO @dbstatid, @dbname, @schema, @tablename, @statistics;
				IF @@FETCH_STATUS < 0 BREAK;
				SET @SQLString = 'UPDATE STATISTICS [' + @dbname + '].[' + @schema + '].[' + @tablename + ']([' + @statistics + '])';
				SET @starttime = CURRENT_TIMESTAMP;
				EXEC sp_executesql @SQLString;
				UPDATE tempdb.dbo.StatsThatNeedUpdating SET StatUpdate = 1 WHERE StatsID = @dbstatid;
				IF (@Retval = 0 AND @pLogToTable = 1)
					BEGIN
						INSERT INTO [{Linked Server Here}].[MSSQLMaintenance].[dbo].[StatisticsMaintenance]
							(HostName, DatabaseName, TableName, Command, StartTime)
						VALUES
							(@hostname, @pDatabase, @schema + '.' + @tablename, @SQLString, @starttime);
					END
			END;
		CLOSE cur;
		DEALLOCATE cur;
		IF (@Retval = 0 AND @pLogToTable = 1)
			BEGIN
				INSERT INTO [{Linked Server Here}].[MSSQLMaintenance].[dbo].[ServerMaintenance]
					(HostName, DatabaseName, MaintenanceDone, StartTime)
				VALUES
					(@hostname, @pDatabase, 'Update Statistics', @jobstarttime);
			END
		IF NOT EXISTS(SELECT 1 FROM tempdb.dbo.StatsThatNeedUpdating WHERE StatUpdate = 0 AND DatabaseName = @pDatabase)
		BEGIN
			DELETE FROM tempdb.dbo.StatsThatNeedUpdating WHERE DatabaseName = @pDatabase;
		END
	END TRY
	BEGIN CATCH
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;
		DECLARE @ErrorMessage varchar(4000);

		DELETE FROM tempdb.dbo.StatsThatNeedUpdating WHERE DatabaseName = @pDatabase;

		SELECT
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE(),
			@ErrorMessage = ERROR_MESSAGE()

		If (@Retval = 0 AND @pLogToTable = 1)
		BEGIN
			INSERT INTO [{Linked Server Here}].[MSSQLMaintenance].[dbo].[FailedMaintenance]
				(HostName, Job, Command, ErrorMessage) 
			VALUES
				(@hostname, 'Update Statistics', @SQLString, @ErrorMessage)
		END

		RAISERROR(@ErrorMessage, @ErrorSeverity,@ErrorState);
	END CATCH
END