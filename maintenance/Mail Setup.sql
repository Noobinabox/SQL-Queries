sp_configure 'show advanced option', 1;
GO
RECONFIGURE
GO
sp_configure 'Database Mail XPs', 1;
GO
RECONFIGURE
GO

EXECUTE msdb.dbo.sysmail_add_profile_sp
		@profile_name = 'Notifications',
		@description = 'Profile for sending outgoing notifications using sendmail';
GO

EXECUTE msdb.dbo.sysmail_add_principalprofile_sp
		@profile_name ='Notifications',
		@principal_name = 'public',
		@is_default = 1;
GO

EXECUTE msdb.dbo.sysmail_add_account_sp
		@account_name = 'Exchange',
		@description = 'Account for outgoing notifications',
		@email_address = '{EmailAddressHere}',
		@display_name = 'SQL Alerts and Notifications',
		@mailserver_name = '{MailServerHere}',
		@port = 587,
		@enable_ssl = 1,
		@username = '{UserNameHere}',
		@password = '{PasswordHere}'
GO

EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
		@profile_name = 'Notifications',
		@account_name = 'Exchange',
		@sequence_number = 1
GO


USE [msdb]
GO
EXEC msdb.dbo.sp_add_operator @name=N'DB Notifications', 
		@enabled=1, 
		@pager_days=0, 
		@email_address=N'{EmailAddressHere}'
GO
