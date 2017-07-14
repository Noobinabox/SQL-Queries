SELECT
	 t.NAME AS [TableName]
	,s.Name AS [SchemaName]
	,p.rows AS [RowsCounts]
	,SUM(a.total_pages) * 8 AS [TotalSpaceKB]
	,SUM(a.used_pages) * 8 AS [UsedSpaceKB]
	,(SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS [UnusedSpaceKB]
FROM
	sys.tables AS t
		INNER JOIN
	sys.indexes AS i on t.OBJECT_ID = i.object_id
		INNER JOIN
	sys.partitions AS p on i.object_id = p.OBJECT_ID and i.index_id = p.index_id
		INNER JOIN
	sys.allocation_units AS a on p.partition_id = a.container_id
		LEFT OUTER JOIN
	sys.schemas AS s on t.schema_id = s.schema_id
WHERE
	t.NAME NOT LIKE 'dt%'
		AND
	t.is_ms_shipped = 0
		AND
	i.OBJECT_ID > 255
GROUP BY
	t.NAME, s.Name, p.Rows
ORDER BY
	TotalSpaceKB DESC;
