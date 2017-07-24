/*******************************************************************************************
** File:	linked_server_setup.sql    	
** Name:	Linked Server Setup for CMS
** Desc:	Sets up everything for linked server to CMS
** Auth:	Seth Lyon
** Date:	Mar 1, 2016
********************************************************
** Change History
********************************************************
** PR	Date		Author			Description	
** --	----------	------------	------------------------------------
** 1	3/1/2016	Seth Lyon		Created
*****************************************************************************************/

USE [master]
GO
EXEC master.dbo.sp_addlinkedserver @server = N'{Linked Server Name Here}', @srvproduct=N'SQL Server'

GO
EXEC master.dbo.sp_serveroption @server=N'ENP-MPSQL', @optname=N'collation compatible', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'ENP-MPSQL', @optname=N'data access', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'ENP-MPSQL', @optname=N'dist', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'ENP-MPSQL', @optname=N'pub', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'ENP-MPSQL', @optname=N'rpc', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'ENP-MPSQL', @optname=N'rpc out', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'ENP-MPSQL', @optname=N'sub', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'ENP-MPSQL', @optname=N'connect timeout', @optvalue=N'30'
GO
EXEC master.dbo.sp_serveroption @server=N'ENP-MPSQL', @optname=N'collation name', @optvalue=null
GO
EXEC master.dbo.sp_serveroption @server=N'ENP-MPSQL', @optname=N'lazy schema validation', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'ENP-MPSQL', @optname=N'query timeout', @optvalue=N'30'
GO
EXEC master.dbo.sp_serveroption @server=N'ENP-MPSQL', @optname=N'use remote collation', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'ENP-MPSQL', @optname=N'remote proc transaction promotion', @optvalue=N'true'
GO
USE [master]
GO
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname = N'{Linked Server Name Here}', @locallogin = NULL , @useself = N'False', @rmtuser = N'{Linked Server Name Here}', @rmtpassword = N'{Password}'
GO
