/*******************************************************************************************
** File:    sp_DatabaseBackup.sql
** Name:	CMS SP Database Backup
** Desc:	Creates a stored procedure in master database for backing up
			databases
** Auth:	Seth Lyon
** Date:	September 21 2016
********************************************************
** Change History
********************************************************
** PR	Date		Author			Description	
** --	----------	------------	------------------------------------
** 1	9/21/2016	Seth Lyon		Created
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
			WHERE object_id = OBJECT_ID(N'[{Company Schema Here}].[sp_DatabaseBackup]')
				  AND type IN ( N'P',N'PC'))
BEGIN
	DROP PROCEDURE [{Company Schema Here}].[sp_DatabaseBackup];
END
GO


CREATE PROCEDURE [{Company Schema Here}].[sp_DatabaseBackup]
	 @pDatabase		nvarchar(120)
	,@pDirectory	nvarchar(2000)
	,@pBackupType	nvarchar(5)
	,@pCompress		tinyint = 1
	,@pLogToTable	tinyint = 1
	,@pExpireDate	datetime = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET QUOTED_IDENTIFIER ON;

	DECLARE	@FormatedTime		nvarchar(30)
		   ,@LinkSvr			nvarchar(130)
		   ,@BackupSize			decimal(9,2)
		   ,@CBackupSize		decimal(9,2)
		   ,@Results			varchar(4000)
		   ,@HostName			varchar(130)
		   ,@Retval				int
		   ,@BackupFileName		varchar(1000)
		   ,@FolderLocation		varchar(3000)
		   ,@JobStartTime		datetime
		   ,@BackupName			varchar(200)
		   ,@MSSQLVersion		decimal(5,2)
		   ,@SQLCommand			nvarchar(4000)
		   ,@ReportCommand		nvarchar(4000)
		   ,@CRLF				char(2)
		   ,@JobDesc			nvarchar(100)
		   ,@ParmDefinition		nvarchar(1000)
		   ,@SQLString			nvarchar(4000);

	SET @LinkSvr = '{Linked Server Here}';
	SET @HostName = @@SERVERNAME;
	SET @JobStartTime = CURRENT_TIMESTAMP;
	SET @FormatedTime = CONVERT(nvarchar, CURRENT_TIMESTAMP, 126);
	SET @FormatedTime = REPLACE(@FormatedTime, ':','.');
	SET @FolderLocation = @pDirectory + '\' + @pDatabase + '\';
	SET @MSSQLVersion = LEFT(CONVERT(varchar, SERVERPROPERTY('ProductVersion')), 4);
	SET @CRLF = CHAR(13) + CHAR(10);

	IF(UPPER(@pBackupType) = 'COPY')
	BEGIN
		SET @BackupFileName = @FolderLocation + @pDatabase + '_' + @FormatedTime + '.cpy';
		IF (@MSSQLVersion >= 10.50 AND @pCompress = 1)
		BEGIN
			SET @ReportCommand = 'BACKUP DATABASE @pDatabase TO DISK = @BackupFileName WITH '
				+ 'COPY_ONLY';
			SET @SQLCommand = 'BACKUP DATABASE [' + @pDatabase + ']' + @CRLF;
			SET @SQLCommand = @SQLCommand + '   TO DISK = ''' + @BackupFileName + '''' + @CRLF;
			SET @SQLCommand = @SQLCommand + 'WITH' + @CRLF;
			SET @SQLCommand = @SQLCommand + '   COMPRESSION' + @CRLF;
			SET @SQLCommand = @SQLCommand + '  ,COPY_ONLY' + @CRLF;
			IF(@pExpireDate IS NOT NULL)
			BEGIN
				SET @SQLCommand = @SQLCommand + '   ,EXPIREDATE = ''' + @pExpireDate + '''' + @CRLF;
			END
			SET @JobDesc = 'Full Database Backup(Compressed, Copy_Only)';
		END
		ELSE
		BEGIN
			SET @ReportCommand = 'BACKUP DATABASE @pDatabase TO DISK = @BackupFileName WITH '
				+ 'COPY_ONLY';
			SET @SQLCommand = 'BACKUP DATABASE [' + @pDatabase + ']' + @CRLF;
			SET @SQLCommand = @SQLCommand + '   TO DISK = ''' + @BackupFileName + '''' + @CRLF;
			SET @SQLCommand = @SQLCommand + 'WITH' + @CRLF;
			SET @SQLCommand = @SQLCommand + '  COPY_ONLY' + @CRLF;
			IF(@pExpireDate IS NOT NULL)
			BEGIN
				SET @SQLCommand = @SQLCommand + '   ,EXPIREDATE = ''' + @pExpireDate + '''' + @CRLF;
			END
			SET @JobDesc = 'Full Database Backup(Non-Compressed, Copy_Only)';
		END
	END

	IF(UPPER(@pBackupType) = 'FULL')
	BEGIN
		SET @BackupFileName = @FolderLocation + @pDatabase + '_' + @FormatedTime + '.bak';
		SET @BackupName = @pDatabase + '-Full Database Backup ' + CONVERT(nvarchar, CURRENT_TIMESTAMP);
		IF (@MSSQLVersion >= 10.50 AND @pCompress = 1)
		BEGIN
			SET @ReportCommand = 'BACKUP DATABASE  @pDatabase TO DISK = @BackupFileName WITH '
				+ 'NOFORMAT, COMPRESSION, NOINIT, NAME = ''@BackupName'', SKIP';
			SET @SQLCommand = 'BACKUP DATABASE [' + @pDatabase + ']' + @CRLF;
			SET @SQLCommand = @SQLCommand + '    TO DISK = ''' + @BackupFileName + '''' + @CRLF;
			SET @SQLCommand = @SQLCommand + 'WITH' + @CRLF;
			SET @SQLCommand = @SQLCommand + '    NOFORMAT' + @CRLF;
			SET @SQLCommand = @SQLCommand + '   ,COMPRESSION' + @CRLF;
			SET @SQLCommand = @SQLCommand + '   ,NOINIT' + @CRLF;
			SET @SQLCommand = @SQLCommand + '   ,NAME = N''' + @BackupName + '''' + @CRLF;
			SET @SQLCommand = @SQLCommand + '   ,SKIP' + @CRLF;
			IF(@pExpireDate IS NOT NULL)
			BEGIN
				SET @SQLCommand = @SQLCommand + '   ,EXPIREDATE = ''' + @pExpireDate + '''' + @CRLF;
			END
			SET @JobDesc = 'Full Database Backup(Compressed)'; 
		END
		ELSE
		BEGIN
			SET @ReportCommand = 'BACKUP DATABASE  @pDatabase TO DISK = @BackupFileName WITH '
				+ 'NOFORMAT, NOINIT, NAME = ''@BackupName'', SKIP';
			SET @SQLCommand = 'BACKUP DATABASE [' + @pDatabase + ']' + @CRLF;
			SET @SQLCommand = @SQLCommand + '    TO DISK = ''' + @BackupFileName + '''' + @CRLF;
			SET @SQLCommand = @SQLCommand + 'WITH' + @CRLF;
			SET @SQLCommand = @SQLCommand + '    NOFORMAT' + @CRLF;
			SET @SQLCommand = @SQLCommand + '   ,NOINIT' + @CRLF;
			SET @SQLCommand = @SQLCommand + '   ,NAME = N''' + @BackupName + '''' + @CRLF;
			SET @SQLCommand = @SQLCommand + '   ,SKIP' + @CRLF;
			IF(@pExpireDate IS NOT NULL)
			BEGIN
				SET @SQLCommand = @SQLCommand + '   ,EXPIREDATE = ''' + @pExpireDate + '''' + @CRLF;
			END
			SET @JobDesc = 'Full Database Backup(Non-Compressed)';
		END
	END

	IF(UPPER(@pBackupType) = 'TLOG')
	BEGIN
		SET @BackupFileName = @FolderLocation + @pDatabase + '_' + @FormatedTime + '.trn';
		SET @BackupName = @pDatabase + '-Transaction Log Backup ' + CONVERT(nvarchar, CURRENT_TIMESTAMP);
		IF (@MSSQLVersion >= 10.50 AND @pCompress = 1)
		BEGIN
			SET @ReportCommand = 'BACKUP LOG  @pDatabase TO DISK = @BackupFileName WITH '
				+ 'NOFORMAT, COMPRESSION, NOINIT, NAME = ''@BackupName'', SKIP';
			SET @SQLCommand = 'BACKUP LOG [' + @pDatabase + ']' + @CRLF;
			SET @SQLCommand = @SQLCommand + '    TO DISK = ''' + @BackupFileName + '''' + @CRLF;
			SET @SQLCommand = @SQLCommand + 'WITH' + @CRLF;
			SET @SQLCommand = @SQLCommand + '    NOFORMAT' + @CRLF;
			SET @SQLCommand = @SQLCommand + '   ,COMPRESSION' + @CRLF;
			SET @SQLCommand = @SQLCommand + '   ,NOINIT' + @CRLF;
			SET @SQLCommand = @SQLCommand + '   ,NAME = N''' + @BackupName + '''' + @CRLF;
			SET @SQLCommand = @SQLCommand + '   ,SKIP' + @CRLF;
			IF(@pExpireDate IS NOT NULL)
			BEGIN
				SET @SQLCommand = @SQLCommand + '   ,EXPIREDATE = ''' + @pExpireDate + '''' + @CRLF;
			END
			SET @JobDesc = 'Transaction Log Backup(Compressed)';
		END
		ELSE
		BEGIN
			SET @ReportCommand = 'BACKUP LOG  @pDatabase TO DISK = @BackupFileName WITH '
				+ 'NOFORMAT, NOINIT, NAME = ''@BackupName'', SKIP';
			SET @SQLCommand = 'BACKUP LOG [' + @pDatabase + ']' + @CRLF;
			SET @SQLCommand = @SQLCommand + '    TO DISK = ''' + @BackupFileName + '''' + @CRLF;
			SET @SQLCommand = @SQLCommand + 'WITH' + @CRLF;
			SET @SQLCommand = @SQLCommand + '    NOFORMAT' + @CRLF;
			SET @SQLCommand = @SQLCommand + '   ,NOINIT' + @CRLF;
			SET @SQLCommand = @SQLCommand + '   ,NAME = N''' + @BackupName + '''' + @CRLF;
			SET @SQLCommand = @SQLCommand + '   ,SKIP' + @CRLF;
			IF(@pExpireDate IS NOT NULL)
			BEGIN
				SET @SQLCommand = @SQLCommand + '   ,EXPIREDATE = ''' + @pExpireDate + '''' + @CRLF;
			END
			SET @JobDesc = 'Transaction Log Backup(Non-Compressed)';
		END
	END
	
	IF(UPPER(@pBackupType) = 'DIFF')
	BEGIN
		SET @BackupFileName = @FolderLocation + @pDatabase + '_' + @FormatedTime + '.diff';
		SET @BackupName = @pDatabase + '-Differential Database Backup ' + CONVERT(nvarchar, CURRENT_TIMESTAMP);
		IF (@MSSQLVersion >= 10.50 AND @pCompress = 1)
		BEGIN
			SET @ReportCommand = 'BACKUP DATABASE  @pDatabase TO DISK = @BackupFileName WITH '
				+ 'DIFFERENTIAL, NOFORMAT, COMPRESSION, NOINIT, NAME = ''@BackupName'', SKIP';
			SET @SQLCommand = 'BACKUP DATABASE [' + @pDatabase + ']' + @CRLF;
			SET @SQLCommand = @SQLCommand + '    TO DISK = ''' + @BackupFileName + '''' + @CRLF;
			SET @SQLCommand = @SQLCommand + 'WITH' + @CRLF;
			SET @SQLCommand = @SQLCommand + '    DIFFERENTIAL' + @CRLF;
			SET @SQLCommand = @SQLCommand + '   ,NOFORMAT' + @CRLF;
			SET @SQLCommand = @SQLCommand + '   ,COMPRESSION' + @CRLF;
			SET @SQLCommand = @SQLCommand + '   ,NOINIT' + @CRLF;
			SET @SQLCommand = @SQLCommand + '   ,NAME = N''' + @BackupName + '''' + @CRLF;
			SET @SQLCommand = @SQLCommand + '   ,SKIP' + @CRLF;
			IF(@pExpireDate IS NOT NULL)
			BEGIN
				SET @SQLCommand = @SQLCommand + '   ,EXPIREDATE = ''' + @pExpireDate + '''' + @CRLF;
			END
			SET @JobDesc = 'Differential Database Backup(Compressed)';
		END
		ELSE
		BEGIN
			SET @ReportCommand = 'BACKUP DATABASE  @pDatabase TO DISK = @BackupFileName WITH '
				+ 'DIFFERENTIAL, NOFORMAT, NOINIT, NAME = ''@BackupName'', SKIP';
			SET @SQLCommand = 'BACKUP DATABASE [' + @pDatabase + ']' + @CRLF;
			SET @SQLCommand = @SQLCommand + '    TO DISK = ''' + @BackupFileName + '''' + @CRLF;
			SET @SQLCommand = @SQLCommand + 'WITH' + @CRLF;
			SET @SQLCommand = @SQLCommand + '    DIFFERENTIAL' + @CRLF;
			SET @SQLCommand = @SQLCommand + '   ,NOFORMAT' + @CRLF;
			SET @SQLCommand = @SQLCommand + '   ,NOINIT' + @CRLF;
			SET @SQLCommand = @SQLCommand + '   ,NAME = N''' + @BackupName + '''' + @CRLF;
			SET @SQLCommand = @SQLCommand + '   ,SKIP' + @CRLF;
			IF(@pExpireDate IS NOT NULL)
			BEGIN
				SET @SQLCommand = @SQLCommand + '   ,EXPIREDATE = ''' + @pExpireDate + '''' + @CRLF;
			END
			SET @JobDesc = 'Differential Database Backup(Non-Compressed)';
		END
	END

	IF OBJECT_ID('tempdb.dbo.#Results') IS NOT NULL DROP TABLE #Results
	CREATE TABLE #Results (LogDate datetime,ProcessInfo nvarchar(100),LogText nvarchar(4000))

	BEGIN TRY
		EXEC @Retval = model.sys.sp_testlinkedserver @LinkSvr;
	END TRY
	BEGIN CATCH
		SET @Retval = SIGN(@@ERROR);
	END CATCH

	BEGIN TRY
		IF NOT EXISTS(SELECT 1 FROM sys.databases WHERE name = @pDatabase)
		BEGIN
			RAISERROR('Database does not exist.',
					   16,
					   1);
		END	
		EXEC master.sys.xp_create_subdir @FolderLocation;
		EXEC sp_executesql @SQLCommand;

		IF (@Retval = 0 AND @pLogToTable = 1)
		BEGIN
			IF(@MSSQLVersion >= 10.50 AND @pCompress = 1)
			BEGIN
				SET @ParmDefinition = N'@BackupSize_out decimal(9,2) OUTPUT, @CBackupSize_out decimal(9,2) OUTPUT';
				SET @SQLString = 'SELECT TOP 1 @BackupSize_out = CONVERT(decimal, (backup_size / 1000000))' + @CRLF;
				SET @SQLString = @SQLString + '   ,@CBackupSize_out = CONVERT(decimal, (compressed_backup_size / 1000000))' + @CRLF;
				SET @SQLString = @SQLString + 'FROM msdb.dbo.backupset' + @CRLF;
				SET @SQLString = @SQLString + 'WHERE database_name = ''' + @pDatabase + '''' + @CRLF;
				SET @SQLString = @SQLString + 'ORDER BY backup_start_date DESC';
				EXEC sp_executesql @SQLString, @ParmDefinition, @BackupSize_out=@BackupSize OUTPUT, @CBackupSize_out=@CBackupSize OUTPUT;
			END
			ELSE
			BEGIN
				SELECT TOP 1 @BackupSize = CONVERT(decimal(9,2),(backup_size / 1000000)) FROM msdb.dbo.backupset WHERE database_name = @pDatabase ORDER BY backup_start_date DESC;
				SET @CBackupSize = 0.00;
			END
			INSERT INTO [{Linked Server Here}].[MSSQLMaintenance].[dbo].[BackupMaintenance] 
				(HostName, DatabaseName, BackupType, Command, StartTime, FilePath, BackupSizeMB, CompressedBackupSizeMB) 
				VALUES 
				(@HostName, @pDatabase, @JobDesc, @ReportCommand, @JobStartTime, @BackupFileName, @BackupSize, @CBackupSize)
			INSERT INTO [{Linked Server Here}].[MSSQLMaintenance].[dbo].[ServerMaintenance] 
				(HostName, DatabaseName, MaintenanceDone, StartTime) 
				VALUES 
				(@HostName, @pDatabase, @JobDesc, @JobStartTime);
		END
	END TRY
	BEGIN CATCH
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;

		SELECT
			@ErrorSeverity = ERROR_SEVERITY(),
			@ErrorState = ERROR_STATE()

		INSERT #Results
			EXEC  xp_readerrorlog 0, 1, N'Backup',@pDatabase

		SELECT @Results = LogText FROM #Results WHERE ProcessInfo = 'spid'+CAST(@@SPID AS varchar(6)) ORDER BY logdate DESC

		IF(@Results = '')
			SET @Results = 'BACKUP failed to complete on the database ' + @pDatabase + '. Check the backup application log for detailed messages.';

		If (@Retval = 0 AND @pLogToTable = 1)
		BEGIN
			INSERT INTO [{Linked Server Here}].[MSSQLMaintenance].[dbo].[BackupMaintenance] (HostName, DatabaseName, BackupType, Command, StartTime, FilePath, Successful) VALUES 
				(@HostName, @pDatabase, @JobDesc, @ReportCommand, @JobStartTime, @BackupFileName, 0);
			INSERT INTO [{Linked Server Here}].[MSSQLMaintenance].[dbo].[FailedMaintenance] (HostName, Job, Command, ErrorMessage) VALUES
				(@HostName, @JobDesc, @ReportCommand, @Results);
		END
		RAISERROR(@Results,@ErrorSeverity,@ErrorState);
	END CATCH
END