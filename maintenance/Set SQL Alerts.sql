/*****************************************************************************************
** File:	set_sql_alerts.sql
** Name:	Set SQL Alerts
** Desc:	Goes through all your default alerts and sends an email to operator DB Notifications
** Auth:	Seth Lyon
** Date:	Oct 21, 2015
********************************************************
** Change History
********************************************************
** PR	Date		Author			Description	
** --	----------	------------	------------------------------------
** 1	10/21/2015	Seth Lyon		Created
*****************************************************************************************/


PRINT ''
PRINT 'Installing default alerts and Level 24 Errors...'
GO
 
USE [msdb]
GO

--<summary>
--	This section just checks if the alerts current exist and deletes them.
--</summary>
 
/****** Object:  Alert [Full msdb log]    ******/
IF  EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Full msdb log')
EXEC msdb.dbo.sp_delete_alert @name=N'Full msdb log'
GO
 
/****** Object:  Alert [Severity Errors]    ******/
IF  EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Full tempdb')
EXEC msdb.dbo.sp_delete_alert @name=N'Full tempdb'
GO
 
/****** Object:  Alert [Severity 14265 Errors]    ******/
IF  EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 14265 Errors')
EXEC msdb.dbo.sp_delete_alert @name=N'Severity 14265 Errors'
GO
 
/****** Object:  Alert [Severity 1459 Errors]    ******/
IF  EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 1459 Errors')
EXEC msdb.dbo.sp_delete_alert @name=N'Severity 1459 Errors'
GO
 
/****** Object:  Alert [Severity 17405 Errors]    ******/
IF  EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 17405 Errors')
EXEC msdb.dbo.sp_delete_alert @name=N'Severity 17405 Errors'
GO
 
/****** Object:  Alert [Severity 19 Errors]    ******/
IF  EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 19 Errors')
EXEC msdb.dbo.sp_delete_alert @name=N'Severity 19 Errors'
GO
 
/****** Object:  Alert [Severity 20 Errors]    ******/
IF  EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 20 Errors')
EXEC msdb.dbo.sp_delete_alert @name=N'Severity 20 Errors'
GO
 
/****** Object:  Alert [Severity 21 Errors]    ******/
IF  EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 21 Errors')
EXEC msdb.dbo.sp_delete_alert @name=N'Severity 21 Errors'
GO
 
/****** Object:  Alert [Severity 22 Errors]    ******/
IF  EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 22 Errors')
EXEC msdb.dbo.sp_delete_alert @name=N'Severity 22 Errors'
GO
 
/****** Object:  Alert [Severity 23 Errors]    ******/
IF  EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 23 Errors')
EXEC msdb.dbo.sp_delete_alert @name=N'Severity 23 Errors'
GO
 
/****** Object:  Alert [Severity 24 Errors]    ******/
IF  EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 24 Errors')
EXEC msdb.dbo.sp_delete_alert @name=N'Severity 24 Errors'
GO
 
/****** Object:  Alert [Severity 25 Errors]    ******/
IF  EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 25 Errors')
EXEC msdb.dbo.sp_delete_alert @name=N'Severity 25 Errors'
GO
 
/****** Object:  Alert [Severity 3628 Errors]    ******/
IF  EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 3628 Errors')
EXEC msdb.dbo.sp_delete_alert @name=N'Severity 3628 Errors'
GO
 
/****** Object:  Alert [Severity 5125 Errors]    ******/
IF  EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 5125 Errors')
EXEC msdb.dbo.sp_delete_alert @name=N'Severity 5125 Errors'
GO
 
/****** Object:  Alert [Severity 5159 Errors]******/
IF  EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 5159 Errors')
EXEC msdb.dbo.sp_delete_alert @name=N'Severity 5159 Errors'
GO
 
/****** Object:  Alert [Severity 823 Errors]******/
IF  EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 823 Errors')
EXEC msdb.dbo.sp_delete_alert @name=N'Severity 823 Errors'
GO
 
/****** Object:  Alert [Severity 824 Errors]******/
IF  EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 824 Errors')
EXEC msdb.dbo.sp_delete_alert @name=N'Severity 824 Errors'
GO
 
/****** Object:  Alert [Severity 832 Errors]******/
IF  EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 832 Errors')
EXEC msdb.dbo.sp_delete_alert @name=N'Severity 832 Errors'
GO
 
/****** Object:  Alert [Severity 9015 Errors]******/
IF  EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 9015 Errors')
EXEC msdb.dbo.sp_delete_alert @name=N'Severity 9015 Errors'
GO

IF	EXISTS (SELECT name FROM msdb.dbo.sysalerts WHERE name = N'Severity 3014 Errors')
EXEC msdb.dbo.sp_delete_alert @name=N'Severity 3041 Errors'
GO

USE [msdb]
GO


--<summary>
--	Here we are creating the alert and assigning the message_id. Make sure to replace @operator_name with your actual
--  operator name.
--</summary>
 
/****** Object:  Alert [Full msdb log]******/
EXEC msdb.dbo.sp_add_alert @name=N'Full msdb log',
        @message_id=9002,
        @severity=0,
        @enabled=1,
        @delay_between_responses=10,
        @include_event_description_in=5,
        @database_name=N'msdb',
        @category_name=N'[Uncategorized]',
        @job_id=N'00000000-0000-0000-0000-000000000000'
GO
 
EXEC msdb.dbo.sp_add_notification @alert_name=N'Full msdb log', @operator_name=N'DB Notifications', @notification_method = 1
GO
 
/****** Object:  Alert [Severity Errors]******/
EXEC msdb.dbo.sp_add_alert @name=N'Full tempdb',
        @message_id=9002,
        @severity=0,
        @enabled=1,
        @delay_between_responses=10,
        @include_event_description_in=5,
        @database_name=N'tempdb',
        @category_name=N'[Uncategorized]',
        @job_id=N'00000000-0000-0000-0000-000000000000'
GO
 
EXEC msdb.dbo.sp_add_notification @alert_name=N'Full tempdb', @operator_name=N'DB Notifications', @notification_method = 1
GO
 
/****** Object:  Alert [Severity 14265 Errors]******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 14265 Errors',
        @message_id=14265,
        @severity=0,
        @enabled=1,
        @delay_between_responses=10,
        @include_event_description_in=5,
        @category_name=N'[Uncategorized]',
        @job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 14265 Errors', @operator_name=N'DB Notifications', @notification_method = 1
GO
 
/****** Object:  Alert [Severity 1459 Errors]******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 1459 Errors',
        @message_id=1459,
        @severity=0,
        @enabled=1,
        @delay_between_responses=10,
        @include_event_description_in=5,
        @category_name=N'[Uncategorized]',
        @job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 1459 Errors', @operator_name=N'DB Notifications', @notification_method = 1
GO
/****** Object:  Alert [Severity 17405 Errors]******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 17405 Errors',
        @message_id=17405,
        @severity=0,
        @enabled=1,
        @delay_between_responses=10,
        @include_event_description_in=5,
        @category_name=N'[Uncategorized]',
        @job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 17405 Errors', @operator_name=N'DB Notifications', @notification_method = 1
GO
/****** Object:  Alert [Severity 19 Errors]******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 19 Errors',
        @message_id=0,
        @severity=19,
        @enabled=1,
        @delay_between_responses=10,
        @include_event_description_in=5,
        @category_name=N'[Uncategorized]',
        @job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 19 Errors', @operator_name=N'DB Notifications', @notification_method = 1
GO
/****** Object:  Alert [Severity 20 Errors]******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 20 Errors',
        @message_id=0,
        @severity=20,
        @enabled=1,
        @delay_between_responses=10,
        @include_event_description_in=5,
        @category_name=N'[Uncategorized]',
        @job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 20 Errors', @operator_name=N'DB Notifications', @notification_method = 1
GO
/****** Object:  Alert [Severity 21 Errors]******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 21 Errors',
        @message_id=0,
        @severity=21,
        @enabled=1,
        @delay_between_responses=10,
        @include_event_description_in=5,
        @category_name=N'[Uncategorized]',
        @job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 21 Errors', @operator_name=N'DB Notifications', @notification_method = 1
GO
/****** Object:  Alert [Severity 22 Errors]******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 22 Errors',
        @message_id=0,
        @severity=22,
        @enabled=1,
        @delay_between_responses=10,
        @include_event_description_in=5,
        @category_name=N'[Uncategorized]',
        @job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 22 Errors', @operator_name=N'DB Notifications', @notification_method = 1
GO
/****** Object:  Alert [Severity 23 Errors]******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 23 Errors',
        @message_id=0,
        @severity=23,
        @enabled=1,
        @delay_between_responses=10,
        @include_event_description_in=5,
        @category_name=N'[Uncategorized]',
        @job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 23 Errors', @operator_name=N'DB Notifications', @notification_method = 1
GO
/****** Object:  Alert [Severity 24 Errors]******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 24 Errors',
        @message_id=0,
        @severity=24,
        @enabled=1,
        @delay_between_responses=10,
        @include_event_description_in=5,
        @category_name=N'[Uncategorized]',
        @job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 24 Errors', @operator_name=N'DB Notifications', @notification_method = 1
GO
/****** Object:  Alert [Severity 25 Errors]******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 25 Errors',
        @message_id=0,
        @severity=25,
        @enabled=1,
        @delay_between_responses=10,
        @include_event_description_in=5,
        @category_name=N'[Uncategorized]',
        @job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 25 Errors', @operator_name=N'DB Notifications', @notification_method = 1
GO
/****** Object:  Alert [Severity 3628 Errors]******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 3628 Errors',
        @message_id=3628,
        @severity=0,
        @enabled=1,
        @delay_between_responses=10,
        @include_event_description_in=5,
        @category_name=N'[Uncategorized]',
        @job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 3628 Errors', @operator_name=N'DB Notifications', @notification_method = 1
GO
/****** Object:  Alert [Severity 5125 Errors]******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 5125 Errors',
        @message_id=5125,
        @severity=0,
        @enabled=1,
        @delay_between_responses=10,
        @include_event_description_in=5,
        @category_name=N'[Uncategorized]',
        @job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 5125 Errors', @operator_name=N'DB Notifications', @notification_method = 1
GO
/****** Object:  Alert [Severity 5159 Errors]******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 5159 Errors',
        @message_id=5159,
        @severity=0,
        @enabled=1,
        @delay_between_responses=10,
        @include_event_description_in=5,
        @category_name=N'[Uncategorized]',
        @job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 5159 Errors', @operator_name=N'DB Notifications', @notification_method = 1
GO
/****** Object:  Alert [Severity 823 Errors]******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 823 Errors',
        @message_id=823,
        @severity=0,
        @enabled=1,
        @delay_between_responses=0,
        @include_event_description_in=0,
        @category_name=N'[Uncategorized]',
        @job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 823 Errors', @operator_name=N'DB Notifications', @notification_method = 1
GO
/****** Object:  Alert [Severity 824 Errors]******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 824 Errors',
        @message_id=824,
        @severity=0,
        @enabled=1,
        @delay_between_responses=10,
        @include_event_description_in=5,
        @category_name=N'[Uncategorized]',
        @job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 824 Errors', @operator_name=N'DB Notifications', @notification_method = 1
GO
/****** Object:  Alert [Severity 832 Errors]******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 832 Errors',
        @message_id=832,
        @severity=0,
        @enabled=1,
        @delay_between_responses=10,
        @include_event_description_in=5,
        @category_name=N'[Uncategorized]',
        @job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 832 Errors', @operator_name=N'DB Notifications', @notification_method = 1
GO
/****** Object:  Alert [Severity 9015 Errors]******/
EXEC msdb.dbo.sp_add_alert @name=N'Severity 9015 Errors',
        @message_id=9015,
        @severity=0,
        @enabled=1,
        @delay_between_responses=10,
        @include_event_description_in=5,
        @category_name=N'[Uncategorized]',
        @job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 9015 Errors', @operator_name=N'DB Notifications', @notification_method = 1
GO
 
EXEC msdb.dbo.sp_add_alert @name=N'Severity 3041 Errors',
        @message_id=3041,
        @severity=0,
        @enabled=1,
        @delay_between_responses=10,
        @include_event_description_in=5,
        @category_name=N'[Uncategorized]',
        @job_id=N'00000000-0000-0000-0000-000000000000'
GO
EXEC msdb.dbo.sp_add_notification @alert_name=N'Severity 3041 Errors', @operator_name=N'DB Notifications', @notification_method = 1
GO

PRINT ''
PRINT 'Completed.'
 
--<summary>
--	Display all alerts setup on the server.
--</summary>
EXECUTE msdb.dbo.sp_help_alert;
GO