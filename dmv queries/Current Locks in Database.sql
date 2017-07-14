 /*****************************************************************************************
** File:	current_locks_in_detail.sql
** Name:	Current Locks in Database with Details
** Desc:	Displays all current locks on the database and returns a detailed view of them.
** Auth:	Seth Lyon
** Date:	Mar 1, 2016
********************************************************
** Change History
********************************************************
** PR	Date		Author			Description	
** --	----------	------------	------------------------------------
** 1	3/1/2016	Seth Lyon		Created
*****************************************************************************************/

 SELECT	
		SessionID = DST.Session_id,
		resource_type,
		DatabaseName = DB_NAME(resource_database_id),
		request_mode,
		request_type,
		login_time,
		host_name,
		program_name,
		client_interface_name,
		login_name,
		nt_domain,
		nt_user_name,
		DST.status,
		last_request_start_time,
		last_request_end_time,
		DST.logical_reads,
		DST.reads,
		request_status,
		request_owner_type,
		objectid,
		dbid,
		DST.number,
		DST.encrypted ,
		DST.blocking_session_id,
		DST.text       
FROM   
		sys.dm_tran_locks AS TDL
		JOIN sys.dm_exec_sessions AS DES 
			ON TDL.request_session_id = DES.session_id
		LEFT JOIN   
			(SELECT  
					* 
			 FROM    
					sys.dm_exec_requests DER 
					CROSS APPLY sys.dm_exec_sql_text(sql_handle)) AS DST 
			ON DES.session_id = DST.session_id
