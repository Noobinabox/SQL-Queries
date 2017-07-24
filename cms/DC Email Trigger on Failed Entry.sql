/*******************************************************************************************
** File:	dc_email_trigger_for_failed_event.sql   	
** Name:	DC Email Trigger
** Desc:	Trigger to send email if anything gets entered into FailedMaintenance Table
** Auth:	Seth Lyon
** Date:	Feb 29, 2016
********************************************************
** Change History
********************************************************
** PR	Date		Author			Description	
** --	----------	------------	------------------------------------
** 1	2/29/2016	Seth Lyon		Created
*****************************************************************************************/


USE [MSSQLMaintenance]
GO

DROP TRIGGER [dbo].[FAILED_MAINTENANCE_EMAIL]
GO


--<summary>
--	This is a small trigger that notifies the DBA team when a failed backup
--	maintenance job has occured.
--</summary>
CREATE TRIGGER [dbo].[FAILED_MAINTENANCE_EMAIL] 
   ON  [dbo].[FailedMaintenance] 
   AFTER INSERT
AS 
BEGIN
	SET NOCOUNT ON;
	DECLARE
		@hostname nvarchar(130),
		@job nvarchar(100),
		@command nvarchar(1000),
		@errormessage nvarchar(4000),
		@subject nvarchar(1000),
		@body nvarchar(4000)

	SELECT
		@hostname = HostName,
		@job = Job,
		@command = Command,
		@errormessage = ErrorMessage
	FROM
		inserted

	SET @subject = @hostname + ' Failed Maintenance: ' + CAST(GETDATE() AS nvarchar(100))
	SET @body = '<table style="width:100%">
				<tr><td><b>Hostname:</b></td><td>' + @hostname + '</td></tr>' +
				'<tr><td><b>Job:</b></td><td>' + @job + '</td></tr>' +
				'<tr><td><b>Command:</b></td><td>' + @command + '</td></tr>' +
				'<tr><td><b>ErrorMessage:</b></td><td>' + @errormessage + '</td></tr>' +
				'</table>';

	--<WARNING>
	--	Change the profile name and recipient to your company's information or
	--	this will not work!
	--</WARNING>
	EXEC msdb.dbo.sp_send_dbmail
		@profile_name = N'{Profile Name Here}',
		@recipients = N'{Put Email Address here}',
		@subject = @subject,
		@body = @body,
		@body_format = 'HTML',
		@importance = 'high'
END
GO