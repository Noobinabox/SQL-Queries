/*******************************************************************************************
** File:    sp_index_maintenance.sql
** Name:	CMS SP Database Backup
** Desc:	Creates a stored procedure in master database for rebuilding indexes
** Auth:	Seth Lyon
** Date:	September 21 2016
********************************************************
** Change History
********************************************************
** PR	Date		Author			Description	
** --	----------	------------	------------------------------------
** 1	9/21/2016	Seth Lyon		Created
** 2	11/3/2016	Seth Lyon		CL1002
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
			WHERE object_id = OBJECT_ID(N'[{Company Schema Here}].[sp_IndexMaintenance]')
				  AND type IN ( N'P',N'PC'))
BEGIN
	DROP PROCEDURE [{Company Schema Here}].[sp_IndexMaintenance];
END
GO


CREATE PROCEDURE [{Company Schema Here}].[sp_IndexMaintenance]
	 @pDatabase		nvarchar(120)
	,@pLogToTable	tinyint = 1
AS
BEGIN
	SET NOCOUNT ON;
	SET QUOTED_IDENTIFIER ON;
	--
	/*----------------------------------------------------------------
	** Declaring all the variables needed for the script
	-----------------------------------------------------------------*/
	DECLARE  @objectid			int
			,@indexid			int
			,@partitioncount	bigint
			,@schemaname		nvarchar(130)
			,@objectname		nvarchar(130)
			,@index_type		nvarchar(130)
			,@indexname			nvarchar(130)
			,@page_count		int
			,@partitionnum		bigint
			,@partitions		bigint
			,@frag				float
			,@command			nvarchar(4000)
			,@lob_data			smallint
			,@actiontaken		nvarchar(10)
			,@startTime			datetime
			,@hostname			nvarchar(130)
			,@jobstarttime		datetime
			,@LinkSvr			nvarchar(30)
			,@SQLString			nvarchar(4000)
			,@ParmDefinition	nvarchar(4000)
			,@Retval			int
			,@CRLF				char(2);
	-----------------------------------------------------------------*/
	--
	--
	/*----------------------------------------------------------------
	** Setting the variable values
	-----------------------------------------------------------------*/
	SET @hostname = @@SERVERNAME;
	SET @jobstarttime = GETDATE();
	SET @LinkSvr = '{Linked Server Here}';
	SET @CRLF = CHAR(13) + CHAR(10);
	-----------------------------------------------------------------*/
	--
	--
	/*----------------------------------------------------------------
	** Check to see if Linked Server Connection is up
	-----------------------------------------------------------------*/
	IF EXISTS (SELECT * FROM tempdb.sys.all_objects WHERE name LIKE '#work_to_do') 
		DROP TABLE #work_to_do 
	BEGIN TRY
		EXEC @Retval = sys.sp_testlinkedserver @LinkSvr;
	END TRY
	BEGIN CATCH
		SET @Retval = SIGN(@@ERROR);
	END CATCH
	-----------------------------------------------------------------*/
	--
	--
	/*----------------------------------------------------------------
	** Select tables and indexes from the sys.dm_db_index_physical_stats
	** function and convert object and index IDs to names.
	-----------------------------------------------------------------*/
	SELECT object_id AS objectid
		  ,index_id AS indexid
		  ,partition_number AS partitionnum
		  ,avg_fragmentation_in_percent AS frag
		  ,index_type_desc AS index_type
		  ,page_count as page_count_kb
		  ,0 as lob_data
	INTO #work_to_do
	FROM sys.dm_db_index_physical_stats (DB_ID(@pDatabase), NULL, NULL, NULL, 'LIMITED')
	WHERE avg_fragmentation_in_percent > 10.0 AND index_id > 0;
	--
	--
	SET @SQLString = 'UPDATE #work_to_do SET lob_data = 1 WHERE #work_to_do.objectid IN ';
	SET @SQLString = @SQLString + '(SELECT [' + @pDatabase + '].[sys].[columns].[object_id] FROM ';
	SET @SQLString = @SQLString + '[' + @pDatabase + '].[sys].[columns] WHERE max_length IN (-1,16));';
	--
	--
	EXEC sp_executesql @SQLString;
	--
	--
	DECLARE partitions CURSOR LOCAL FOR SELECT * FROM #work_to_do;
	BEGIN TRY
		OPEN partitions;
		WHILE (1=1)
			BEGIN;
				FETCH NEXT
				   FROM partitions
				   INTO @objectid, @indexid, @partitionnum, @frag, @index_type, @page_count, @lob_data;
				IF @@FETCH_STATUS < 0 BREAK;
				SET @ParmDefinition = N'@objectname_out nvarchar(130) OUTPUT, @schemaname_out nvarchar(130) OUTPUT';
				SET @SQLString = 'SELECT    @objectname_out = QUOTENAME(o.name)' + @CRLF;
				SET @SQLString = @SQLString + '    ,@schemaname_out = QUOTENAME(s.name)' + @CRLF;
				SET @SQLString = @SQLString + 'FROM [' + @pDatabase + '].[sys].[objects] AS o' + @CRLF;
				SET @SQLString = @SQLString + 'JOIN [' + @pDatabase + '].[sys].[schemas] AS s ON s.schema_id = o.schema_id' + @CRLF;
				SET @SQLString = @SQLString + 'WHERE o.object_id = ' + CAST(@objectid AS nvarchar(30));
				EXEC sp_executesql @SQLString, @ParmDefinition, @objectname_out=@objectname OUTPUT, @schemaname_out=@schemaname OUTPUT;
				--
				--
				SET @ParmDefinition = N'@indexname_out nvarchar(130) OUTPUT';
				SET @SQLString = 'SELECT @indexname_out = QUOTENAME(name)' + @CRLF; 
				SET @SQLString = @SQLString + 'FROM [' + @pDatabase + '].[sys].[indexes]' + @CRLF;
				SET @SQLString = @SQLString + 'WHERE object_id = ' + CAST(@objectid AS nvarchar(30)) + @CRLF;
				SET @SQLString = @SQLString + 'AND index_id = ' + CAST(@indexid AS nvarchar(30)) + ';';
				EXEC sp_executesql @SQLString, @ParmDefinition, @indexname_out=@indexname OUTPUT;
				--
				--
				SET @ParmDefinition = N'@partitioncount_out bigint OUTPUT';
				SET @SQLString = 'SELECT @partitioncount_out = count(*)' + @CRLF;
				SET @SQLString = @SQLString + 'FROM [' + @pDatabase + '].[sys].[partitions]' + @CRLF;
				SET @SQLString = @SQLString + 'WHERE object_id = ' + CAST(@objectid AS nvarchar(30)) + ' AND index_id = ' + CAST(@indexid AS nvarchar(30)) + ';';
				EXEC sp_executesql @SQLString, @ParmDefinition, @partitioncount_out=@partitioncount OUTPUT;
				--
				--
				--
				IF @frag < 30.0 and @lob_data = 0
				BEGIN
					SET @command = N'ALTER INDEX ' + @indexname + N' ON [' + @pDatabase + N'].' + @schemaname + N'.' + @objectname + N' REORGANIZE';
					SET @actiontaken = 'REORGANIZE';
				END
				IF @frag >= 30.0 and @lob_data = 1
				BEGIN
					SET @command = N'ALTER INDEX ' + @indexname + N' ON [' + @pDatabase + N'].' + @schemaname + N'.' + @objectname + N' REBUILD WITH (SORT_IN_TEMPDB = ON, MAXDOP = 1)';
					SET @actiontaken = 'REBUILD'
				END

				IF @frag >= 30.0 and @lob_data = 0 and SERVERPROPERTY('EDITION') IN ('Developer Edition', 'Enterprise Edition', 'Enterprise Evaluation Edition')
				BEGIN
					SET @command = N'ALTER INDEX ' + @indexname + N' ON [' + @pDatabase + N'].' + @schemaname + N'.' + @objectname + N' REBUILD WITH (ONLINE = ON, SORT_IN_TEMPDB = ON, MAXDOP = 1)';  
					SET @actiontaken = 'REBUILD'
				END
				IF @frag >= 30.0 and @lob_data = 0 and SERVERPROPERTY('EDITION') NOT IN ('Developer Edition', 'Enterprise Edition', 'Enterprise Evaluation Edition')
				BEGIN
					SET @command = N'ALTER INDEX ' + @indexname + N' ON [' + @pDatabase + N'].' + @schemaname + N'.' + @objectname + N' REBUILD WITH (SORT_IN_TEMPDB = ON, MAXDOP = 1)';  		
					SET @actiontaken = 'REBUILD'
				END
			/********************************************************************************/
				IF @partitioncount > 1
					SET @command = @command + N' PARTITION=' + CAST(@partitionnum AS nvarchar(10));
				--
				--
				SET @startTime = CURRENT_TIMESTAMP;
				EXEC sp_executesql @command;
				SET @indexname = REPLACE(@indexname, '[','');
				SET @indexname = REPLACE(@indexname, ']','');
				SET @schemaname = REPLACE(@schemaname, '[','');
				SET @schemaname =  REPLACE(@schemaname, ']','');
				SET @objectname = REPLACE(@objectname, '[','');
				SET @objectname = REPLACE(@objectname, ']','');
				--
				--
				IF (@Retval = 0 AND @pLogToTable = 1)
					BEGIN
						INSERT INTO [{Linked Server Here}].[MSSQLMaintenance].[dbo].[IndexMaintenance] 
						(IndexName, SchemaName, TableName, FragLevel, ActionTaken, StartTime, Command, PageCount, HostName, DatabaseName) 
						VALUES 
						(@indexname, @schemaname, @objectname, @frag, @actiontaken, @startTime, @command, @page_count, @hostname, @pDatabase)
					END
			END;

			-- Close and deallocate the cursor.
			CLOSE partitions;
			DEALLOCATE partitions;
			--
			--
			IF (@Retval = 0 AND @pLogToTable = 1)
				BEGIN
					INSERT INTO [{Linked Server Here}].[MSSQLMaintenance].[dbo].[ServerMaintenance] 
					(HostName, DatabaseName, MaintenanceDone, StartTime) 
					VALUES 
					(@hostname, @pDatabase, 'Rebuild and Reorganize of Fragmented Indexes', @jobstarttime);
				END
		END TRY
		BEGIN CATCH
			/*----------------------------------------------------------------
			** Something bad happened lets try to catch it
			----------------------------------------------------------------*/
			DECLARE @ErrorSeverity INT;
			DECLARE @ErrorState INT;
			DECLARE @ErrorMessage varchar(4000);
			--
			--
			SELECT
				@ErrorSeverity = ERROR_SEVERITY(),
				@ErrorState = ERROR_STATE(),
				@ErrorMessage = ERROR_MESSAGE()
			--
			--
			If (@Retval = 0 AND @pLogToTable = 1)
			BEGIN
				INSERT INTO [{Linked Server Here}].[MSSQLMaintenance].[dbo].[FailedMaintenance](HostName, Job, Command, ErrorMessage) VALUES
					(@hostname, 'Rebuild and Reorganize of Fragmented Indexes', @command, @ErrorMessage)
			END
			--
			--
			RAISERROR(@ErrorMessage, @ErrorSeverity,@ErrorState);
		END CATCH
	-- Drop the temporary table.
	DROP TABLE #work_to_do;
END
GO


