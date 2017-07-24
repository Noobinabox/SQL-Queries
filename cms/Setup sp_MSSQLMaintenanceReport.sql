/*******************************************************************************************
** File:	sp_MSSQLMaintenanceReport.sql  	
** Name:	Setup sp_MSSQLMaintenance Report
** Desc:	Creates a stored procedure to email out a report of all servers
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

DROP PROCEDURE [dbo].[MSSQLMaintenanceReport];
GO


--<summary> Create Stored Procedure
--	Creating the stored procedure MSSQLMaintenaceReport
--</summary>
CREATE PROCEDURE [dbo].[MSSQLMaintenanceReport]
AS
BEGIN
	SET NOCOUNT ON;
	SET QUOTED_IDENTIFIER ON;

	DECLARE @Body					NVARCHAR(MAX)
	       ,@HTMLHead				VARCHAR(MAX)
		   ,@HTMLTail				VARCHAR(1000)
		   ,@FailedSummary			VARCHAR(MAX)
		   ,@FailedSummaryBody		NVARCHAR(MAX)
		   ,@FailedDetails			VARCHAR(MAX)
		   ,@FailedDetailBody		NVARCHAR(MAX)
		   ,@SuccessSummary			VARCHAR(MAX)
		   ,@SuccessSummaryBody		NVARCHAR(MAX)
		   ,@SuccessDetails			VARCHAR(MAX)
		   ,@SuccessDetailBody		NVARCHAR(MAX)
		   ,@TopDatabaseBackup		VARCHAR(MAX)
		   ,@TopDatabaseBackupBody	NVARCHAR(MAX)
		   ,@TopDatabases			VARCHAR(MAX)
		   ,@TopDatabasesBody		NVARCHAR(MAX)
		   ,@TopRebuild				VARCHAR(MAX)
		   ,@TopRebuildBody			NVARCHAR(MAX)
		   ,@TopLongIndex			VARCHAR(MAX)
		   ,@TopLongIndexBody		NVARCHAR(MAX)
		   ,@TopLongStats			VARCHAR(MAX)
		   ,@TopLongStatBody		NVARCHAR(MAX)
		   ,@TotalFailed			NVARCHAR(3)
		   ,@TotalSuccess			NVARCHAR(4);


	SET @TotalFailed = ( SELECT COUNT(*) FROM FailedMaintenance WHERE DateEntry >= DATEADD(DAY, -1, GETDATE()));
	SET @TotalSuccess = ( SELECT COUNT(*) FROM ServerMaintenance WHERE StartTime >= DATEADD(DAY, -1, GETDATE()));
	

	SET @HTMLHead = '<!DOCTYPE html><html><head><meta http-equiv="Content-Type" content="text/html; charset=us-ascii">'
		+ '<meta http-equiv="X-UA-Compatible" content="IE=edge"><style type="text/css">body, table, a{ font-family: segoe ui, sans-serif, arial; font-size: 13px; }table{ border-collapse: collapse;}table.tableStyle{ max-width: 100%; }table.nstd{ width:100%; }table.nstdSml{ width:100%; font-size:smaller; }tr.ev{ background-color: #E0F0FF; }th, td{ border: 1px solid #BFBFBF; vertical-align: top; padding: 2px 5px; }th.colHdr{ color: #777777; background-color: #DDDDDD; font-weight: normal; padding: 0 5px; }td.dfltCt, td.scsCt, td.alRt{ text-align: right; }td.errCt{ color: #FF0000; text-align: right; font-weight: bold; }td.wrnCt{ color: #F09040; text-align: right; font-weight: bold; }th.err{ background-color: #FF5555; text-align: left; }th.ntw{ background-color: #AA7755; text-align: left; }th.wrn{ background-color: #FEE66F; text-align: left; }th.scs{ background-color: #AAEE99; text-align: left; }th.smry{ background-color: #ACCFFA; text-align: left; }a{ color: #003399; }p.inv{ display:none; color:white; visibility:hidden; }td.sep{ mso-line-height-rule: exactly; line-height: 0; border: 0; }</style><!--[if gte mso 9]><style type="text/css">table.tableStyle{ width: 900px; }</style><![endif]-->'
		+ '</head><body><a name="Top"></a>'
		+ '<br><table class=tableStyle" style="width: 900px">'
		+ '<tr><th class="smry" colspan="3">Summary</th></tr>'
		+ '<tr><th class="colHdr">Entry Type</th>'
		+ '<th class="colHdr">Result</th>'
		+ '<th class="colHdr">Entry Count</th></tr>'
		+ '<td rowspan="2">Maintenance Actions</td>'
		+ '<td>Errors</td>'
		+ '<td class="errCt">' + @TotalFailed + '</td></tr>'
		+ '<tr><td>Successful</td>'
		+ '<td class="scsCt">' + @TotalSuccess + '</td></tr></table>'

	SET @FailedSummary = '<br><table class="tableStyle" style="width: 900px">'
		+ '<tr><th class="err" colspan="2">Failed Maintenance Summary</th></tr>'
		+ '<tr><th class="colHdr">Failed Maintenance Jobs</th>'
		+ '<th class="colHdr">Total Amount</th></tr>' ;
	
	SET @FailedSummaryBody = ( SELECT td = Job, '',
									  td = COUNT(*), ''
							   FROM FailedMaintenance
							   WHERE DateEntry >= DATEADD(DAY, -1, GETDATE())
							   GROUP BY Job
							   ORDER BY Job ASC
							   FOR XML RAW('tr'),
									ELEMENTS XSINIL
							 );

	SELECT @FailedSummary = @FailedSummary + ISNULL(@FailedSummaryBody, '') + '</table>';

	SET @FailedDetails = '<table class="tableStyle" style="width: 900px">'
		+ '<tr><th class="err" colspan="5">Failed Maintenance Details</th></tr>' 
		+ '<tr><th class="colHdr">HostName</th>'
		+ '<th class="colHdr">Job</th>'
		+ '<th class="colHdr">Command</th>'
		+ '<th class="colHdr">Error Message</th>'
		+ '<th class="colHdr">Date Entry</th></tr>' ;

	SET @FailedDetailBody = ( SELECT    td = HostName, '',
					                    td = Job, '',
							            td = Command, '',
						                td = ErrorMessage, '',
						                td = DateEntry, ''
						      FROM      FailedMaintenance
			                  WHERE DateEntry >= DATEADD(DAY, -1, GETDATE())
                              FOR   XML RAW('tr'),
                                    ELEMENTS XSINIL);

	SELECT @FailedDetails = @FailedDetails + ISNULL(@FailedDetailBody, '') + '</table>';

	SET @SuccessSummary = '<br><br> <table class="tableStyle" style="width: 900px">'
		+ '<tr><th class="scs" colspan="2">Successful Maintenance Summary</th></tr>' 
		+ '<tr><th class="colHdr">Successful Maintenance Jobs</th>'
		+ '<th class="colHdr">Total Amount</th></tr>' ;

	SET @SuccessSummaryBody = ( SELECT td = MaintenanceDone, '',
									   td = COUNT(*), ''
							FROM ServerMaintenance
							WHERE StartTime >= DATEADD(DAY, -1, GETDATE())
							GROUP BY MaintenanceDone
							ORDER BY MaintenanceDone ASC
							FOR		XML RAW('tr'),
									ELEMENTS XSINIL);

	SELECT @SuccessSummary = @SuccessSummary + ISNULL(@SuccessSummaryBody, '') + '</table>';

	SET @TopDatabaseBackup = '<table class="tableStyle" style="width: 900px">'
		+ '<tr><th class="scs" colspan="7">Top 10 Longest Running Backups</th></tr>'
		+ '<tr><th class="colHdr">Host Name</th>'
		+ '<th class="colHdr">Database Name</th>'
		+ '<th class="colHdr">Backup Type</th>'
		+ '<th class="colHdr">Backup Size MB</th>'
		+ '<th class="colHdr">Start Time</th>'
		+ '<th class="colHdr">End Time</th>'
		+ '<th class="colHdr">Duration Min</th></tr>';

	SET @TopDatabaseBackupBody = ( SELECT TOP 10
										  td = HostName, '',
										  td = DatabaseName, '',
										  td = BackupType, '',
										  td = BackupSizeMB, '',
										  td = StartTime, '',
										  td = EndTime, '',
										  td = DATEDIFF(MINUTE, StartTime, EndTime), ''
									FROM BackupMaintenance
									WHERE StartTime >= DATEADD(DAY, -1, GETDATE())
									AND Successful = 1
									ORDER BY 13 DESC
									FOR		XML RAW('tr'),
											ELEMENTS XSINIL);

	SELECT @TopDatabaseBackup = @TopDatabaseBackup + ISNULL(@TopDatabaseBackupBody, '') + '</table>';										

	SET @SuccessDetails = '<table class="tableStyle" style="width: 900px">'
		+ '<tr><th class="scs" colspan="6">Total Maintenance Details</th></tr>'
		+ '<tr><th class="colHdr">Host Name</th>'
		+ '<th class="colHdr">Database Name</th>'
		+ '<th class="colHdr">Full Database Backups</th>'
		+ '<th class="colHdr">Transcation Log Backups</th>'
		+ '<th class="colHdr">Index Maintenance</th>'
		+ '<th class="colHdr">Statistic Maintenance</th></tr>';


	SELECT
		 DISTINCT A.HostName AS 'Hostname'
		,A.DatabaseName AS 'Database Name'
		,COALESCE(C.CM,0) AS 'Full Database Backups'
		,COALESCE(D.CM,0) AS 'Transaction Log Backups'
		,COALESCE(E.CM,0) AS 'Index Maintenance'
		,COALESCE(B.CM,0) AS 'Statistic Maintenance'
	INTO #DailyMaintenanceReport
	FROM DatabaseInformation AS A
	LEFT OUTER JOIN
	(
		SELECT HostName, DatabaseName, COUNT(MaintenanceDone) AS 'CM'
		FROM ServerMaintenance
		WHERE MaintenanceDone = 'Update Statistics'
		AND StartTime > DATEADD(DAY, -1, GETDATE())
		GROUP BY HostName, DatabaseName
	) AS B ON B.HostName = A.HostName AND B.DatabaseName = A.DatabaseName
	LEFT OUTER JOIN
	(
		SELECT HostName, DatabaseName, COUNT(MaintenanceDone) AS 'CM'
		FROM ServerMaintenance
		WHERE MaintenanceDone LIKE 'FULL Database Backup%'
		AND StartTime > DATEADD(DAY,-1,GETDATE())
		GROUP BY HostName, DatabaseName
	) AS C ON C.HostName = A.HostName AND C.DatabaseName = A.DatabaseName
	LEFT OUTER JOIN
	(
		SELECT HostName, DatabaseName, COUNT(MaintenanceDone) AS 'CM'
		FROM ServerMaintenance
		WHERE MaintenanceDone LIKE 'Transaction Log Backup%'
		AND StartTime > DATEADD(DAY,-1,GETDATE())
		GROUP BY HostName, DatabaseName
	) AS D ON D.HostName = A.HostName AND D.DatabaseName = D.DatabaseName
	LEFT OUTER JOIN
	(
		SELECT HostName, DatabaseName, COUNT(MaintenanceDone) AS 'CM'
		FROM ServerMaintenance
		WHERE MaintenanceDone = 'Rebuild and Reorganize of Fragmented Indexes'
		AND StartTime > DATEADD(DAY,-1,GETDATE())
		GROUP BY HostName, DatabaseName
	) AS E ON E.HostName = A.HostName AND E.DatabaseName = A.DatabaseName
	WHERE A.DatabaseName NOT IN ('master','tempdb','model','msdb', 'ReportServerTempDB')
	and A.DateScanned > DATEADD(MONTH,-1,GETDATE())
	GROUP BY A.HostName, A.DatabaseName, B.CM, C.CM, D.CM, E.CM
	ORDER BY A.HostName, A.DatabaseName

	SET @SuccessDetailBody = (SELECT
									 td = Hostname, ''
									,td = [Database Name], ''
									,td = [Full Database Backups], ''
									,td = [Transaction Log Backups], ''
									,td = [Index Maintenance], ''
									,td = [Statistic Maintenance], ''
							  FROM #DailyMaintenanceReport
							  ORDER BY Hostname, [Database Name]
							  FOR		XML RAW('tr'),
								ELEMENTS XSINIL);

	SELECT @SuccessDetails = @SuccessDetails + ISNULL(@SuccessDetailBody, '') + '</table>';

	SET @HTMLTail = '</body></html>';

	SELECT @Body = @HTMLHead + ISNULL(@FailedSummary, '') + ISNULL(@FailedDetails, '') 
				   + ISNULL(@SuccessSummary, '') + ISNULL(@TopDatabaseBackup, '') 
				   + ISNULL(@SuccessDetails, '') + @HTMLTail;

	--<WARNING>
	--	Change the profile name and recipient to your company's information or
	--	this will not work!
	--</WARNING>
	EXEC msdb.dbo.sp_send_dbmail
	@profile_name = N'{Profile Name here}',
	@recipients = N'{Enter email address here}',
	@subject = 'MSSQL Daily Maintenance Report',
	@body = @Body,
	@body_format = 'HTML',
	@importance = 'high';
END
