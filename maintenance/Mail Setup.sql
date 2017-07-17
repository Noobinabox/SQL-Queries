/*****************************************************************************************
** File:	mail_setup.sql
** Name:	Mail Setup
** Desc:	Sets up sysmail on SQL Servers
** Auth:	Seth Lyon
** Date:	Oct 21, 2015
********************************************************
** Change History
********************************************************
** PR	Date		Author			Description	
** --	----------	------------	------------------------------------
** 1	10/21/2015	Seth Lyon		Created
*****************************************************************************************/


--<summary>
--	In order to enable database mail we muyst run show advanced options followed by
--	a reconfigure.
--</summary>
sp_configure 'show advanced option', 1;
GO
RECONFIGURE
GO
sp_configure 'Database Mail XPs', 1;
GO
RECONFIGURE
GO



EXECUTE msdb.dbo.sysmail_add_profile_sp
		@profile_name = 'Notifications', --Name this whatever you want
		@description = 'Profile for sending outgoing notifications using sendmail';
GO

EXECUTE msdb.dbo.sysmail_add_principalprofile_sp
		@profile_name ='Notifications', --Make sure this matches the previous profile_name
		@principal_name = 'public',
		@is_default = 1;
GO

EXECUTE msdb.dbo.sysmail_add_account_sp
		@account_name = 'Exchange', --Name this something meanful to you.
		@description = 'Account for outgoing notifications',
		@email_address = '{EmailAddressHere}', --The sending email address
		@display_name = 'SQL Alerts and Notifications',
		@mailserver_name = '{MailServerHere}', 
		@port = 587,
		@enable_ssl = 1,
		@username = '{UserNameHere}', --Username for connecting and sending mail
		@password = '{PasswordHere}'
GO

EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
		@profile_name = 'Notifications', --Has to match profile name
		@account_name = 'Exchange', --Has to match account_name
		@sequence_number = 1
GO


USE [msdb]
GO

--<summary>
--	This part sets up an operator which we can send emails to on notifications.
--</summary>
EXEC msdb.dbo.sp_add_operator @name=N'DB Notifications', --Name this something meanful to you.
		@enabled=1, 
		@pager_days=0, 
		@email_address=N'{EmailAddressHere}' 
GO
