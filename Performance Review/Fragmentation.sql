	SELECT i.object_id AS objectid
		,OBJECT_NAME(i.object_id)
		,i.index_id AS indexid
		,a.NAME
		,o.schema_id AS schemaid
		,i.partition_number AS partitionnum
		,a.rowcnt
		,i.page_count
		,i.avg_fragmentation_in_percent AS frag
	FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') i
	INNER JOIN sys.objects o
		ON o.[object_id] = i.[object_id]
	INNER JOIN sys.sysindexes a
		ON a.id = i.object_id
			AND a.indid = i.index_id
	WHERE avg_fragmentation_in_percent >= 15
		and index_type_desc IN ('CLUSTERED INDEX' ,'NONCLUSTERED INDEX' ) 
		AND alloc_unit_type_desc ='IN_ROW_DATA'
		AND page_count >= 1
