/******************************************************************************************
** File:    cms_database_setup.sql
** Name:	CMS Database Setup
** Desc:	Setup the database and tables for CMS
** Auth:	Seth Lyon
** Date:	Feb 24 2016
********************************************************
** Change History
********************************************************
** PR	Date		Author			Description	
** --	----------	------------	------------------------------------
** 1	2/24/2016	Seth Lyon		Created
** 2	2/25/2016	Seth Lyon		Added DatabaseInformation table
** 3	2/29/2016	Seth Lyon		Fixed constraints for default values
** 4    7/17/2017	Seth Lyon		Added Indexes and comments
*****************************************************************************************/

CREATE DATABASE [sfmcsyadmin]
GO


USE [sfmcsysadmin]
GO


--<summary> Index Maintenance Table
--	Here is where we store all the information on the index that we are rebuilding or reorganizing. You 
--  can report on this table for trending pattern on fragmentation. 
--</summary>
IF OBJECT_ID(N'IndexMaintenance', N'U') IS NOT NULL
	DROP TABLE IndexMaintenance

CREATE TABLE IndexMaintenance
(
	[IndexMaintenance_ID] INT IDENTITY(1,1) NOT NULL,
	[HostName] nvarchar(130) NOT NULL,
	[DatabaseName] nvarchar(130) NOT NULL,
	[IndexName] nvarchar(130) NOT NULL,
	[SchemaName] nvarchar(130) NOT NULL,
	[TableName] nvarchar(130) NOT NULL,
	[FragLevel] float NOT NULL CONSTRAINT [DF_IndexMaintenance_FragLevel] DEFAULT 0.00,
	[PageCount] int NOT NULL CONSTRAINT [DF_IndexMaintenance_PageCount] DEFAULT 0,
	[ActionTaken] nvarchar(10) NOT NULL,
	[Command] nvarchar(2000) NOT NULL,
	[StartTime] DATETIME NOT NULL,
	[EndTime] DATETIME NULL CONSTRAINT [DF_IndexMaintenance_EndTime] DEFAULT GETDATE(),
	CONSTRAINT [PK_IndexMaintenanceID] PRIMARY KEY CLUSTERED ([IndexMaintenance_ID] ASC)
)

--<summary> Server Maintenance Table
--	This table is used for storing all the summarized data on maintenance being done on the servers.
--</summary>
IF OBJECT_ID(N'ServerMaintenance', N'U') IS NOT NULL
	DROP TABLE ServerMaintenance;

CREATE TABLE ServerMaintenance
(
	[ServerMaintenanceID] INT IDENTITY(1,1) NOT NULL,
	[HostName] NVARCHAR(130) NOT NULL,
	[DatabaseName] NVARCHAR(130) NOT NULL,
	[MaintenanceDone] NVARCHAR(254) NOT NULL,
	[StartTime] DATETIME NOT NULL,
	[EndTime] DATETIME NULL CONSTRAINT [DF_ServerMaintenance_EndTime] DEFAULT GETDATE(),
	[DurationMin] AS DATEDIFF(Mi, [StartTime],[EndTime])
	CONSTRAINT [PK_ServerMaintenanceID] PRIMARY KEY CLUSTERED ([ServerMaintenanceID] ASC),
)

--<summary> Backup Maintenance Table
--	Here is where we store all the backup maintenance information.
--</summary>
IF OBJECT_ID(N'BackupMaintenance', N'U') IS NOT NULL
	DROP TABLE BackupMaintenance;

CREATE TABLE BackupMaintenance
(
	[BackupMaintenanceID] INT IDENTITY(1,1) NOT NULL,
	[HostName] NVARCHAR(130) NOT NULL,
	[DatabaseName] NVARCHAR(130) NOT NULL,
	[BackupType] NVARCHAR(20) NOT NULL,
	[Command] NVARCHAR(1000) NOT NULL,
    	[BackupSizeMB] DECIMAL(9,2) NULL CONSTRAINT [DF_BackupMaintenance_BackupSize] DEFAULT 0.00,
   	[CompressedBackupSizeMB] DECIMAL(9,2) NULL CONSTRAINT [DF_BackupMaintenance_CompressedBackupSize] DEFAULT 0.00,
	[FilePath] NVARCHAR(1000) NOT NULL,
	[Successful] BIT CONSTRAINT [DF_BackupMaintenance_Successful] DEFAULT 1,
	[StartTime] DATETIME NOT NULL,
	[EndTime] DATETIME DEFAULT GETDATE(),
	CONSTRAINT [PK_BackupMaintenanceID] PRIMARY KEY CLUSTERED ([BackupMaintenanceID] ASC)
)

--<summary> Statistics Maintenance Table
--	Here's where we store all the statistic maintenance done to a server.
--</summary>
IF OBJECT_ID(N'StatisticsMaintenance', N'U') IS NOT NULL
	DROP TABLE StatisticsMaintenance;

CREATE TABLE StatisticsMaintenance
(
	[StatisticsMaintenanceID] INT IDENTITY(1,1) NOT NULL,
	[HostName] NVARCHAR(130) NOT NULL,
	[DatabaseName] NVARCHAR(130) NOT NULL,
	[TableName] NVARCHAR(130) NOT NULL,
	[Command] NVARCHAR(1000) NOT NULL,
	[StartTime] DATETIME NOT NULL,
	[EndTime] DATETIME NULL CONSTRAINT [DF_StatisticsMaintenance_EndTime] DEFAULT GETDATE(),
	CONSTRAINT [PK_StatisticsMaintenanceID] PRIMARY KEY CLUSTERED ([StatisticsMaintenanceID] ASC)
)

--<summary> Server Information Table
--	This table should only be populated once, per server, or after a hardware/SQL Server change.
--</summary>
IF OBJECT_ID(N'ServerInformation', N'U') IS NOT NULL
	DROP TABLE ServerInformation

CREATE TABLE ServerInformation
(
	[ServerID] INT IDENTITY(1,1) NOT NULL,
	[HostName] NVARCHAR(130) NOT NULL,
	[IPAddress] NVARCHAR(40) NOT NULL,
	[WindowsVersion] NVARCHAR(120) NOT NULL,
	[MSSQLVersion] NVARCHAR(120) NOT NULL,
	[ServerMemoryMB] BIGINT NOT NULL,
	[CPUTotal] INT NOT NULL,
	[ApplicationOwner] NVARCHAR(130) NULL,
	[Virtualized] BIT CONSTRAINT [DF_ServerInformation_Virtualized] DEFAULT 0,
	[DateAdded] DATETIME NULL CONSTRAINT [DF_ServerInformation_DateAdded] DEFAULT GETDATE(),
	CONSTRAINT [PK_ServerInformationID] PRIMARY KEY CLUSTERED ([ServerID] ASC, [HostName] ASC)
)

--<summary> Database Information Table
--	This table should be populated nightly for every server. I typically schedule a daily job at 12:00AM to report on this.
--</summary>
IF OBJECT_ID(N'DatabaseInformation', N'U') IS NOT NULL
	DROP TABLE DatabaseInformation

CREATE TABLE DatabaseInformation
(
	[DatabaseInformationID] INT IDENTITY(1,1) NOT NULL,
	[HostName] NVARCHAR(130) NOT NULL,
	[DatabaseName] NVARCHAR(254) NOT NULL,
	[DatabaseSizeMB] DECIMAL(20,2) NOT NULL,
	[DatabaseSpaceUsedMB] DECIMAL(20,2) NOT NULL,
	[DatabaseSpaceAvailableMB] AS ([DatabaseSizeMB] - [DatabaseSpaceUsedMB]),
	[LogSizeMB] DECIMAL(20,2) NOT NULL,
	[LogSpaceUsedMB] DECIMAL(20,2) NOT NULL,
	[LogSpaceAvailableMB] AS ([LogSizeMB] - [LogSpaceUsedMB]),
	[RecoveryModel] NVARCHAR(24) NOT NULL,
	[CompatibilityLevel] SMALLINT NOT NULL,
	[DatabaseStatus] NVARCHAR(24) NOT NULL,
	[DateScanned] DATETIME NULL CONSTRAINT [DF_DatabaseInformation_DateScanned] DEFAULT GETDATE(),
	CONSTRAINT [PK_DatabaseInformationID] PRIMARY KEY CLUSTERED([DatabaseInformationID])
)

--<summary> Failed Maintenance Table
--	If a maintenance job has failed we report it here.
--</summary>
IF OBJECT_ID(N'FailedMaintenance', N'U') IS NOT NULL
	DROP TABLE FailedMaintenance

CREATE TABLE FailedMaintenance
(
	[FailedID] INT IDENTITY(1,1) NOT NULL,
	[HostName] NVARCHAR(130) NOT NULL,
	[Job] NVARCHAR(1000) NOT NULL,
	[Command] NVARCHAR(1000) NOT NULL,
	[ErrorMessage] NVARCHAR(2000) NOT NULL,
	[DateEntry] DATETIME NULL CONSTRAINT [DF_FailedMaintenance_DateEntry] DEFAULT GETDATE(),
	CONSTRAINT [PK_FailedID] PRIMARY KEY CLUSTERED ([FailedID] ASC)
)
GO

--<summary> Index Creation
--	All index creations should be written here.
--</summary>
CREATE NONCLUSTERED INDEX [IX_IndexMaintenance_HostName_StartTime] ON [dbo].[IndexMaintenance]
(
	[HostName] ASC,
	[StartTime] ASC
)
INCLUDE (
	[IndexMaintenance_ID],
	[DatabaseName],
	[IndexName],
	[SchemaName],
	[TableName],
	[FragLevel],
	[PageCount],
	[ActionTaken],
	[Command],
	[EndTime]
) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON);
GO

CREATE NONCLUSTERED INDEX [IX_DatabaseInformation_HostName_DatabaseSpaceUsedMB_DateScanned] ON [dbo].[DatabaseInformation]
(
	[HostName] ASC,
	[DatabaseSpaceUsedMB] ASC,
	[DateScanned] ASC
) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON);

CREATE NONCLUSTERED INDEX [IX_DatabaseInformation_HostName_DateScanned] ON [dbo].[DatabaseInformation]
(
	[HostName] ASC,
	[DateScanned] ASC
)
INCLUDE
(
	[DatabaseInformationID],
	[DatabaseName],
	[DatabaseSizeMB],
	[DatabaseSpaceUsedMB],
	[DatabaseSpaceAvailableMB],
	[LogSizeMB],
	[LogSpaceUsedMB],
	[LogSpaceAvailableMB],
	[RecoveryModel],
	[CompatibilityLevel],
	[DatabaseStatus]
) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON);

CREATE NONCLUSTERED INDEX [IX_BackupMaintenance_HostName_DatabaseName] ON [dbo].[BackupMaintenance]
(
	[HostName] ASC,
	[DatabaseName] ASC,
	[BackupMaintenanceID] ASC
)
INCLUDE ( 	[BackupType],
	[Command],
	[BackupSizeMB],
	[StartTime],
	[EndTime],
	[CompressedBackupSizeMB],
	[FilePath],
	[Successful]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO
