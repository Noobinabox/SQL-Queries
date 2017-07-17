Here are all my DMV, or DMOs, queries that I have wrote/collected over the years. Please, use them as you see fit and let me know if something needs improvement or not.

# Dynamic Management Objects
* [Advanced sp_who2](#Advanced-sp_who2)
* [Current Locks in Database](#Current-Locks-in-Database)
* [IO Bottlenecks](#IO-Bottlenecks)
* 

#### [Advanced sp_who2](/Advanced%20sp_who2.sql)
This script gives you detailed information much like `sp_who2` but includes both the SQL Text and execution plan. If you wanted to tie more DMVs to it that could easily be done.

#### [Current Locks in Database](/Current%20Locks%20in%20Database.sql)
This query utilizes sys.dm_tran_locks, sys.dm_exec_sessions, and sys.dm_exec_sql_text to return all locks that are being doing a the specific database being ran on and give you useful information such as the SQL Text and execution plans. 

#### [IO Bottlenecks](/IO%20Bottleneck.sql)
The results of this script will display all physical data files and logs with their i/o stall reads, writes, stalls, and more information about disk i/o. 

#### Current Thread Wait
