/*******************************************************************************************
** File:	first_run_server_information.sql
** Name:	First Run Server Information for CMS
** Desc:	Gets information for ServerInformation table
** Auth:	Seth Lyon
** Date:	Mar 1, 2016
********************************************************
** Change History
********************************************************
** PR	Date		Author			Description	
** --	----------	------------	------------------------------------
** 1	3/1/2016	Seth Lyon		Created
** 2	3/2/2016	Seth Lyon		Changed the check for SQL Version
** 3	3/3/2016	Seth Lyon		Code change for MSSQL Version Report
*****************************************************************************************/

DECLARE @sqlvercheck numeric(4,2);
DECLARE @sqlcommand nvarchar(4000);
DECLARE @ipaddress nvarchar(20);
DECLARE @hostname nvarchar(120);
DECLARE @windowsversion nvarchar(120);
DECLARE @mssqlversion nvarchar(120);
DECLARE @totalphysicalmemory bigint;
DECLARE @cpucount tinyint;
DECLARE @virtual_machine_type bit;
DECLARE @ParmDefinition nvarchar(1024);
DECLARE @LinkedSvr nvarchar(20);
DECLARE @Retval int;


SELECT @windowsversion = 
	CASE RIGHT(SUBSTRING(@@VERSION, CHARINDEX('Windows NT', @@VERSION), 14), 3)
		WHEN '6.3' THEN 
			'Windows Server 2012R2' 
		WHEN '6.2' THEN 
			'Windows Server 2012'
		WHEN '6.1' THEN 
			'Windows Server 2008R2'
		WHEN '6.0' THEN 
			'Windows Server 2008'
		WHEN '5.2' THEN 
			'Windows Server 2003'
		WHEN '5.0' THEN 
			'Windows Server 2000'
	END


SET @hostname = @@SERVERNAME;
SET @virtual_machine_type = 0;
SET @LinkedSvr = N'{Linked Server Here}';
SELECT @sqlvercheck = LEFT(CAST(SERVERPROPERTY('ProductVersion') AS varchar), 4);
SELECT @mssqlversion = 
		CASE(@sqlvercheck)
			WHEN 13.00 THEN
				'Microsoft SQL Server 2016 ' + CAST(SERVERPROPERTY('edition') AS nvarchar(30))
			WHEN 12.00 THEN
				'Microsoft SQL Server 2014 ' + CAST(SERVERPROPERTY('edition') AS nvarchar(30))
			WHEN 11.00 THEN
				'Microsoft SQL Server 2012 ' + CAST(SERVERPROPERTY('edition') AS nvarchar(30))
			WHEN 10.50 THEN
				'Microsoft SQL Server 2008 R2 ' + CAST(SERVERPROPERTY('edition') AS nvarchar(30))
			WHEN 10.00 THEN
				'Microsoft SQL Server 2008 ' + CAST(SERVERPROPERTY('edition') AS nvarchar(30))
			WHEN 9.00 THEN
				'Microsoft SQL Server 2005 ' + CAST(SERVERPROPERTY('edition') AS nvarchar(30))
			WHEN 8.00 THEN
				'Microsoft SQL Server 2000 ' + CAST(SERVERPROPERTY('edition') AS nvarchar(30))
		END;

IF @sqlvercheck >= 11.00
BEGIN
	SET @ParmDefinition = N'@totalphysicalmemory_out bigint OUTPUT, @cpucount_out tinyint OUTPUT, @virtual_machine_type_out bit OUTPUT';
	SET @sqlcommand = N'SELECT @totalphysicalmemory_out = (physical_memory_kb / 1024), @cpucount_out = cpu_count, @virtual_machine_type_out = IIF(virtual_machine_type > 0, 1, 0)  from sys.dm_os_sys_info';
	exec sp_executesql @sqlcommand, @ParmDefinition, @totalphysicalmemory_out=@totalphysicalmemory OUTPUT, @cpucount_out=@cpucount OUTPUT, @virtual_machine_type_out=@virtual_machine_type OUTPUT
END
ELSE IF (@sqlvercheck = 10.50)
BEGIN
	SET @ParmDefinition = N'@totalphysicalmemory_out bigint OUTPUT, @cpucount_out tinyint OUTPUT, @virtual_machine_type_out bit OUTPUT';
	SET @sqlcommand = N'SELECT @totalphysicalmemory_out = ((physical_memory_in_bytes / 1024) / 1024), @cpucount_out = cpu_count, @virtual_machine_type_out = virtual_machine_type from sys.dm_os_sys_info; IF(@virtual_machine_type_out > 0) SET @virtual_machine_type_out = 1;';
	exec sp_executesql @sqlcommand, @ParmDefinition, @totalphysicalmemory_out=@totalphysicalmemory OUTPUT, @cpucount_out=@cpucount OUTPUT, @virtual_machine_type_out=@virtual_machine_type OUTPUT;
END
ELSE IF (@sqlvercheck < 10.50)
BEGIN
	SET @ParmDefinition = N'@totalphysicalmemory_out bigint OUTPUT, @cpucount_out tinyint OUTPUT';
	SET @sqlcommand = N'SELECT @totalphysicalmemory_out = ((physical_memory_in_bytes / 1024) / 1024), @cpucount_out = cpu_count from sys.dm_os_sys_info';
	exec sp_executesql @sqlcommand, @ParmDefinition, @totalphysicalmemory_out=@totalphysicalmemory OUTPUT, @cpucount_out=@cpucount OUTPUT;

END

SELECT @ipaddress = LOCAL_NET_ADDRESS FROM sys.dm_exec_connections WHERE SESSION_ID = @@SPID

BEGIN TRY
	EXEC @Retval = sys.sp_testlinkedserver @LinkedSvr;
END TRY
BEGIN CATCH
	SET @Retval = SIGN(@@ERROR);
END CATCH


IF @Retval = 0
BEGIN
	INSERT INTO [{Linked Server Here}].[MSSQLMaintenance].[dbo].[ServerInformation] (HostName, IPAddress, WindowsVersion, MSSQLVersion, ServerMemoryMB, CPUTotal, Virtualized)
		VALUES (@hostname, @ipaddress, @windowsversion, @mssqlversion, @totalphysicalmemory, @cpucount, @virtual_machine_type)
END