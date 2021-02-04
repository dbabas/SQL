SELECT db_name(database_id) AS [Database Name]
	,file_name(file_id) AS [File Name]
	,[Filename] AS [Full Path]
	,size_on_disk_bytes / 1048576 AS [File Size (MB)]
	,FILEPROPERTY(name, 'SpaceUsed') / 128 AS [Space Used (MB)]
	,CAST(CAST(FILEPROPERTY(Sf.name, 'SpaceUsed') AS DECIMAL) / CAST(Sf.size AS DECIMAL) * 100 AS NUMERIC(20, 2)) AS [% Used]
	,CASE 
		WHEN num_of_reads = 0
			THEN 0
		ELSE io_stall_read_ms / num_of_reads
		END AS [Avg Read (ms)]
	,CASE 
		WHEN num_of_writes = 0
			THEN 0
		ELSE io_stall_write_ms / num_of_writes
		END AS [Avg Write (ms)]
	,CASE 
		WHEN (num_of_reads + num_of_writes) = 0
			THEN 0
		ELSE 100 * num_of_reads / (num_of_reads + num_of_writes)
		END AS [Read %]
	,CASE 
		WHEN (num_of_reads + num_of_writes) = 0
			THEN 0
		ELSE 100 * num_of_writes / (num_of_reads + num_of_writes)
		END AS [Write %]
	,Cast(num_of_reads * 100.0 / sample_ms AS NUMERIC(20, 2)) AS [Num of Reads (per Sec)]
	,Cast(num_of_writes * 100.0 / sample_ms AS NUMERIC(20, 2)) AS [Num of Writes (per Sec)]
	,Cast(num_of_bytes_read * 100.0 / (1024.0 * sample_ms) AS NUMERIC(20, 2)) AS [Bytes read (KB per Sec)]
	,Cast(num_of_bytes_written / (1024.0 * sample_ms) AS NUMERIC(20, 2)) AS [Bytes written (KB per Sec)]
	,CASE 
		WHEN num_of_reads = 0
			THEN 0
		ELSE Cast(num_of_bytes_read / (1024.0 * num_of_reads) AS NUMERIC(20, 2))
		END AS [No of Bytes per read (KB)]
	,CASE 
		WHEN num_of_writes = 0
			THEN 0
		ELSE Cast(num_of_bytes_written / (1024.0 * num_of_writes) AS NUMERIC(20, 2))
		END AS [No of Bytes per write (KB)]
	,Cast(Cast(io_stall_read_ms AS NUMERIC(20, 2)) / Cast(sample_ms AS NUMERIC(20, 2)) AS NUMERIC(20, 2)) AS [No of Read Wait (seconds)]
	,Cast(Cast(io_stall_write_ms AS NUMERIC(20, 2)) / Cast(sample_ms AS NUMERIC(20, 2)) AS NUMERIC(20, 2)) AS [No of Write Wait (seconds)]
	,CASE 
		WHEN (
				Sf.maxsize = - 1
				AND Sf.growth = 0
				)
			THEN 'Off'
		ELSE 'On'
		END AS [Auto Growth]
	,'Maxsize' = (
		CASE Sf.maxsize
			WHEN - 1
				THEN N'Unlimited'
			ELSE convert(NVARCHAR(15), convert(BIGINT, Sf.maxsize) * 8 / 1024) + N' MB'
			END
		)
	,'Growth' = (
		CASE Sf.STATUS & 0x100000
			WHEN 0x100000
				THEN convert(NVARCHAR(3), Sf.growth) + N'%'
			ELSE convert(NVARCHAR(15), Sf.growth * 8 / 1024) + N' MB'
			END
		)
FROM sys.dm_io_virtual_file_stats(db_id(), NULL) AS Fs
INNER JOIN sys.sysfiles AS Sf ON Fs.[file_id] = Sf.[fileid]