
SET NOCOUNT ON
GO

-- Server Uptime
SELECT cast((datediff(hh, create_date, getdate())) / 24 AS VARCHAR(3)) + ' days, ' + cast((datediff(hh, create_date, getdate())) % 24 AS VARCHAR(2)) + ' hours' AS [SQL Server Service Uptime]
FROM sys.databases
WHERE name = 'tempdb'
GO

SELECT TOP 100 SUBSTRING(st.TEXT, (qs.statement_start_offset / 2) + 1, (
			(
				CASE statement_end_offset
					WHEN - 1
						THEN DATALENGTH(st.TEXT)
					ELSE qs.statement_end_offset
					END - qs.statement_start_offset
				) / 2
			) + 1) AS statement_text
	,CASE 
		WHEN st.TEXT LIKE '%LIKE%'
			THEN 'LIKE'
		ELSE ''
		END AS [Wildcard]
	,execution_count
	,CASE 
		WHEN execution_count = 0
			THEN NULL
		ELSE total_logical_reads / execution_count
		END AS avg_logical_reads
	,CASE 
		WHEN execution_count = 0
			THEN NULL
		ELSE (total_worker_time / execution_count) / 1000
		END AS [avg_cpu_(msec)]
	,CASE 
		WHEN execution_count = 0
			THEN NULL
		ELSE (total_elapsed_time / execution_count) / 1000
		END AS [avg_duration_(msec)]
	,CASE 
		WHEN execution_count = 0
			THEN NULL
		ELSE total_rows / execution_count
		END AS [avg_rows]
	,
	-- Query Plan Information
	ph.query_plan
	,qs.creation_time
	,qs.last_execution_time
	,CASE 
		WHEN ph.query_plan.exist('declare namespace ns="http://schemas.microsoft.com/sqlserver/2004/07/showplan";(/ns:ShowPlanXML/ns:BatchSequence/ns:Batch/ns:Statements/ns:StmtCursor/ns:CursorPlan/@CursorRequestedType)[1]') = 0
			THEN ''
		ELSE ph.query_plan.value('declare namespace ns="http://schemas.microsoft.com/sqlserver/2004/07/showplan";(/ns:ShowPlanXML/ns:BatchSequence/ns:Batch/ns:Statements/ns:StmtCursor/ns:CursorPlan/@CursorRequestedType)[1]', 'nvarchar (max)')
		END AS cursor_type
	-- Missing Indexes
	,CASE 
		WHEN ph.query_plan.exist('declare namespace ns="http://schemas.microsoft.com/sqlserver/2004/07/showplan";(/ns:ShowPlanXML/ns:BatchSequence/ns:Batch/ns:Statements/ns:StmtSimple/ns:QueryPlan/ns:MissingIndexes/ns:MissingIndexGroup)[1]') = 0
			THEN ''
		ELSE ph.query_plan.value('declare namespace ns="http://schemas.microsoft.com/sqlserver/2004/07/showplan";(/ns:ShowPlanXML/ns:BatchSequence/ns:Batch/ns:Statements/ns:StmtSimple/ns:QueryPlan/ns:MissingIndexes/ns:MissingIndexGroup/@Impact)[1]', 'nvarchar (max)')
		END AS missing_index_impact
	,CASE 
		WHEN ph.query_plan.exist('declare namespace ns="http://schemas.microsoft.com/sqlserver/2004/07/showplan";(/ns:ShowPlanXML/ns:BatchSequence/ns:Batch/ns:Statements/ns:StmtSimple/ns:QueryPlan/ns:MissingIndexes/ns:MissingIndexGroup/ns:MissingIndex/@Table)[1]') = 0
			THEN ''
		ELSE ph.query_plan.value('declare namespace ns="http://schemas.microsoft.com/sqlserver/2004/07/showplan";(/ns:ShowPlanXML/ns:BatchSequence/ns:Batch/ns:Statements/ns:StmtSimple/ns:QueryPlan/ns:MissingIndexes/ns:MissingIndexGroup/ns:MissingIndex/@Table)[1]', 'nvarchar(max)')
		END AS missing_index_table
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS ph
WHERE (st.TEXT IS NOT NULL)
	--AND (execution_count >= 100)  -- change threshold
	AND (total_logical_reads / execution_count >= 1000) -- change threshold
ORDER BY total_worker_time DESC
GO

---
SELECT migs.group_handle
	,mig.index_handle
	,migs.user_seeks
	,migs.last_user_seek
	,migs.user_scans
	,migs.last_user_scan
	,migs.avg_user_impact
	,db_name(mid.database_id) AS db
	,object_name(mid.object_id) AS OBJECT
	,mid.equality_columns
	,mid.inequality_columns
	,mid.included_columns
	,'CREATE INDEX [ssi_' + convert(VARCHAR, migs.group_handle) + '_' + convert(VARCHAR, mig.index_handle) + '] ON [' + object_name(mid.object_id) + '] ' + '(' + CASE 
		WHEN mid.equality_columns IS NOT NULL
			THEN mid.equality_columns
		ELSE ''
		END + CASE 
		WHEN mid.equality_columns IS NULL
			AND mid.inequality_columns IS NOT NULL
			THEN mid.inequality_columns
		ELSE ''
		END + CASE 
		WHEN mid.equality_columns IS NOT NULL
			AND mid.inequality_columns IS NOT NULL
			THEN ', ' + mid.inequality_columns
		ELSE ''
		END + ')' + CASE 
		WHEN mid.included_columns IS NOT NULL
			THEN ' INCLUDE (' + mid.included_columns + ')'
		ELSE ''
		END AS tsql
FROM sys.dm_db_missing_index_group_stats AS migs
INNER JOIN sys.dm_db_missing_index_groups AS mig ON (migs.group_handle = mig.index_group_handle)
INNER JOIN sys.dm_db_missing_index_details AS mid ON (mig.index_handle = mid.index_handle)
WHERE (mid.database_id = db_id())
	AND (migs.user_seeks >= 100) -- change threshold
	AND (migs.avg_user_impact >= 90) -- change threshold
ORDER BY object_name(mid.object_id) ASC
	,migs.user_seeks DESC
	,migs.user_scans DESC
GO

