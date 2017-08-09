/*****************************************************************************************
** File:	whats_in_tempdb.sql
** Name:	What's Running in Tempdb
** Desc:	Gives you a detailed view of what's running in tempdb and allocated
**              resources
** Auth:	Seth Lyon
** Date:	Aug 9, 2017
********************************************************
** Change History
********************************************************
** PR	Date		Author			Description	
** --	----------	------------	------------------------------------
** 1	8/9/2017	Seth Lyon		Created
*****************************************************************************************/

SELECT
    des.session_id AS [SESSION ID],
    DB_NAME(ddssu.database_id) AS [DATABASE Name],
    HOST_NAME AS [System Name],
    program_name AS [Program Name],
    login_name AS [USER Name],
    des.status,
    des.cpu_time AS [CPU TIME (in milisec)],
    total_scheduled_time AS [Total Scheduled TIME (in milisec)],
    des.total_elapsed_time AS    [Elapsed TIME (in milisec)],
    (memory_usage * 8)      AS [Memory USAGE (in KB)],
    (user_objects_alloc_page_count * 8) AS [SPACE Allocated FOR USER Objects (in KB)],
    (user_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR USER Objects (in KB)],
    (internal_objects_alloc_page_count * 8) AS [SPACE Allocated FOR Internal Objects (in KB)],
    (internal_objects_dealloc_page_count * 8) AS [SPACE Deallocated FOR Internal Objects (in KB)],
    CASE is_user_process
            WHEN 1      THEN 'user session'
            WHEN 0      THEN 'system session'
    END AS [SESSION Type], des.row_count AS [ROW COUNT]
FROM 
	sys.dm_db_session_space_usage as ddssu
			INNER join
	sys.dm_exec_sessions as des
			ON ddssu.session_id = des.session_id
