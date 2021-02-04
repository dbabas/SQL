declare @Table as varchar(250)= 'Head Office$Value Entry' --Enter table name here.

SELECT i.[name] AS IndexName
    ,SUM(s.[used_page_count]) * 8 AS IndexSizeKB
FROM sys.dm_db_partition_stats AS s
	INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id]
		AND s.[index_id] = i.[index_id]
		and s.object_id = (select object_id
							from sys.objects
							where name = @Table
								and  type IN ('U','V'))
GROUP BY i.[name]
ORDER BY i.[name]
GO