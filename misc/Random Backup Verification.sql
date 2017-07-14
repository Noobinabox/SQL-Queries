/*******************************************************************************************
** File:    randVerifyBackup.sql
** Name:	Randomly Verifying Full Database Backup
** Desc:	Gets all the full backups within the last 24 hours and randomly picks
**          one to verify
** Auth:	Seth Lyon
** Date:	December 21, 2016
********************************************************
** Change History
********************************************************
** PR	Date		Author			Description	
** --	----------	------------	------------------------------------
** 1	12/21/16	Seth Lyon		Created
*****************************************************************************************/

IF OBJECT_ID('tempdb..#BackupSet') IS NOT NULL DROP TABLE #BackupSet;
GO

DECLARE	 @randNumberHigh		smallint
		,@randDBindex			smallint
		,@backupLocation		nvarchar(254)
		,@databaseName			nvarchar(128);

CREATE TABLE #BackupSet (
	BackupSet_ID INT IDENTITY(1,1) NOT NULL,
	database_name varchar(128) NOT NULL,
	physical_device_name varchar(254) NOT NULL
)
INSERT INTO #BackupSet
SELECT
	 BS.database_name
	,BMF.physical_device_name
FROM msdb.dbo.backupset AS BS
JOIN msdb.dbo.backupmediafamily AS BMF on BS.media_set_id = BMF.media_set_id
WHERE backup_start_date >= DATEADD(DAY,-1,GETDATE()) 
	AND name like '%Full%';

PRINT 'Getting all full database backups in the last 24 hours.';

SELECT @randNumberHigh = COUNT(*) FROM #BackupSet;

IF @randNumberHigh = 0
	raiserror('No database backups recorded in 24 hours.',20,-1) with log

SELECT @randDBindex = FLOOR(RAND()*(@randNumberHigh+1-1)+1);

PRINT 'Randomly selecting database backup to verify.';

SELECT @databaseName = database_name, @backupLocation = physical_device_name FROM #BackupSet WHERE BackupSet_ID = @randDBindex;

PRINT 'Verifying backup for the database, ' + @databaseName + '.';

RESTORE VERIFYONLY FROM DISK = @backupLocation;

DROP TABLE #BackupSet;