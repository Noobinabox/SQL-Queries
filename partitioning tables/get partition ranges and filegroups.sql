/*****************************************************************************************
** File:	get_partition_ranges_and_filesgroups.sql
** Name:	Get Partition Range and Filegroups
** Desc:	Displays information on a specific table on which ranger it's in and filegroup
** Auth:	Seth Lyon
** Date:	Oct 21, 2015
********************************************************
** Change History
********************************************************
** PR	Date		Author			Description	
** --	----------	------------	------------------------------------
** 1	10/21/2015	Seth Lyon		Created
*****************************************************************************************/

SELECT t.name as TableName,
	   i.name as IndexName,
	   p.partition_id as partitionID,
	   p.partition_number,
	   rows, 
	   fg.name, 
	   r.value
FROM sys.tables AS t 
INNER JOIN sys.indexes AS i ON 
	(t.object_id = i.object_id)
INNER JOIN sys.partitions AS p ON 
	(t.object_id = p.object_id and i.index_id = p.index_id)
INNER JOIN sys.destination_data_spaces AS dds ON 
	(p.partition_number = dds.destination_id)
INNER JOIN sys.filegroups AS fg ON 
	(dds.data_space_id = fg.data_space_id)
JOIN  sys.partition_schemes AS s ON 
	(i.data_space_id = s.data_space_id)
JOIN sys.partition_functions AS f ON 
	(s.function_id = f.function_id)
JOIN sys.data_spaces AS ds on 
	(p.partition_number = ds.data_space_id)
LEFT JOIN sys.partition_range_values AS r ON 
	(f.function_id = r.function_id and r.boundary_id = p.partition_number)
WHERE 
	(t.name = '{TableNameHere}') and (i.index_id IN (0,1))
