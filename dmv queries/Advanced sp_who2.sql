/*****************************************************************************************
** File:	advanced_spwho2.sql
** Name:	Advanced SP_WHO2
** Desc:	A more detailed command to run which allows filtering, rather than sp_who2
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
	 des.session_id
	,des.status
	,des.login_name
	,des.[host_name]
	,der.blocking_session_id
	,DB_NAME(der.database_id) AS [database_name]
	,der.command
	,des.cpu_time
	,des.reads
	,des.writes
	,dec.last_write
	,des.[program_name]
	,der.wait_type
	,der.wait_time
	,der.last_wait_type
	,wait_resource
	,CASE des.transaction_isolation_level
		WHEN 0 THEN 'Unspecified'
		WHEN 1 THEN 'ReadUncommitted'
		WHEN 2 THEN 'ReadCommitted'
		WHEN 3 THEN 'Repeatable'
		WHEN 4 THEN 'Serializable'
		WHEN 5 THEN 'Snapshot'
	 END AS [transaction_isolation_level]
	,OBJECT_NAME(dest.objectid, der.database_id) AS [OBJECT_NAME]
	,SUBSTRING(dest.text, der.statement_start_offset / 2,
			( CASE WHEN der.statement_end_offset = -1
					THEN DATALENGTH(dest.text)
					ELSE der.statement_end_offset
			  END - der.statement_start_offset) / 2) AS [executing statement]
	,deqp.query_plan
FROM
	sys.dm_exec_sessions des
		LEFT JOIN
	sys.dm_exec_requests der
			ON des.session_id = der.session_id
		LEFT JOIN
	sys.dm_exec_connections dec
			ON des.session_id = dec.session_id
		CROSS APPLY
	sys.dm_exec_sql_text(der.sql_handle) dest
		CROSS APPLY
	sys.dm_exec_query_plan(der.plan_handle) deqp
WHERE
	des.session_id <> @@SPID
ORDER BY
	des.session_id
