SELECT TOP 1000 SUBSTRING(st.TEXT, (qs.statement_start_offset / 2) + 1, (
			(
				CASE statement_end_offset
					WHEN - 1
						THEN DATALENGTH(st.TEXT)
					ELSE qs.statement_end_offset
					END - qs.statement_start_offset
				) / 2
			) + 1) AS statement_text
	,execution_count
	,total_worker_time AS Total_CPU_Time
	,CASE 
		WHEN min_logical_reads = 0
			THEN 0
		ELSE (max_logical_reads - min_logical_reads) / (min_logical_reads) * 100
		END AS 'diff_reads %'
	,CASE 
		WHEN execution_count = 0
			THEN NULL
		ELSE total_logical_reads / execution_count
		END AS avg_logical_reads
	,total_logical_reads
	,total_physical_reads
	,min_logical_reads
	,max_logical_reads
	,CASE 
		WHEN execution_count = 0
			THEN NULL
		ELSE total_logical_writes / execution_count
		END AS avg_logical_writes
	,total_logical_writes
	,min_logical_writes
	,max_logical_writes
	,CASE 
		WHEN execution_count = 0
			THEN NULL
		ELSE total_elapsed_time / execution_count
		END AS 'avg_elapsed_time'
	,max_elapsed_time
	,total_elapsed_time
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
WHERE execution_count >= 100
	AND CASE 
		WHEN execution_count = 0
			THEN NULL
		ELSE total_logical_reads / execution_count
		END >= 100
ORDER BY total_logical_reads DESC