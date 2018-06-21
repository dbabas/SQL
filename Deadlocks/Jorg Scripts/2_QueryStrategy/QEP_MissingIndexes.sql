
USE [Demo Database NAV (7-1)] -- set db name
GO

SET NOCOUNT ON
GO

-- Server Uptime
select cast((datediff(hh, create_date, getdate()))/24 as varchar(3)) + ' days, '
     + cast((datediff(hh, create_date, getdate())) % 24 as varchar(2)) + ' hours'
     as [SQL Server Service Uptime]
from sys.databases where name = 'tempdb'
GO

SELECT TOP 100
SUBSTRING(st.text, (qs.statement_start_offset/2) + 1,
((CASE statement_end_offset 
WHEN -1 THEN DATALENGTH(st.text)
ELSE qs.statement_end_offset END 
- qs.statement_start_offset)/2) + 1) as statement_text,
case when st.text like '%LIKE%' then 'LIKE' else '' end AS [Wildcard],
execution_count,
case 
when execution_count = 0 then null
else total_logical_reads/execution_count 
end as avg_logical_reads, 
case 
when execution_count = 0 then null
else (total_worker_time/execution_count) / 1000
end as [avg_cpu_(msec)], 
case 
when execution_count = 0 then null
else (total_elapsed_time/execution_count) / 1000
end as [avg_duration_(msec)], 
case 
when execution_count = 0 then null
else total_rows/execution_count
end as [avg_rows], 

-- Query Plan Information
ph.query_plan,
qs.creation_time,
qs.last_execution_time,
case when 
ph.query_plan.exist('declare namespace ns="http://schemas.microsoft.com/sqlserver/2004/07/showplan";(/ns:ShowPlanXML/ns:BatchSequence/ns:Batch/ns:Statements/ns:StmtCursor/ns:CursorPlan/@CursorRequestedType)[1]') = 0
then '' else
ph.query_plan.value('declare namespace ns="http://schemas.microsoft.com/sqlserver/2004/07/showplan";(/ns:ShowPlanXML/ns:BatchSequence/ns:Batch/ns:Statements/ns:StmtCursor/ns:CursorPlan/@CursorRequestedType)[1]','nvarchar (max)')
end as cursor_type

-- Missing Indexes
,case when ph.query_plan.exist('declare namespace ns="http://schemas.microsoft.com/sqlserver/2004/07/showplan";(/ns:ShowPlanXML/ns:BatchSequence/ns:Batch/ns:Statements/ns:StmtSimple/ns:QueryPlan/ns:MissingIndexes/ns:MissingIndexGroup)[1]') = 0
then '' 
else ph.query_plan.value('declare namespace ns="http://schemas.microsoft.com/sqlserver/2004/07/showplan";(/ns:ShowPlanXML/ns:BatchSequence/ns:Batch/ns:Statements/ns:StmtSimple/ns:QueryPlan/ns:MissingIndexes/ns:MissingIndexGroup/@Impact)[1]','nvarchar (max)')
end as missing_index_impact,
case when ph.query_plan.exist('declare namespace ns="http://schemas.microsoft.com/sqlserver/2004/07/showplan";(/ns:ShowPlanXML/ns:BatchSequence/ns:Batch/ns:Statements/ns:StmtSimple/ns:QueryPlan/ns:MissingIndexes/ns:MissingIndexGroup/ns:MissingIndex/@Table)[1]') = 0
then ''
else ph.query_plan.value('declare namespace ns="http://schemas.microsoft.com/sqlserver/2004/07/showplan";(/ns:ShowPlanXML/ns:BatchSequence/ns:Batch/ns:Statements/ns:StmtSimple/ns:QueryPlan/ns:MissingIndexes/ns:MissingIndexGroup/ns:MissingIndex/@Table)[1]','nvarchar(max)')
end as missing_index_table

FROM sys.dm_exec_query_stats as qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as st 
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) as ph

WHERE (st.text is not null)

--AND (execution_count >= 100)  -- change threshold
AND (total_logical_reads/execution_count >= 1000) -- change threshold

ORDER BY total_worker_time DESC 
GO

---

SELECT migs.group_handle, mig.index_handle, migs.user_seeks, migs.last_user_seek, migs.user_scans, migs.last_user_scan, migs.avg_user_impact,
       db_name(mid.database_id) as db, object_name(mid.object_id) as object, mid.equality_columns, mid.inequality_columns, mid.included_columns,

	  'CREATE INDEX [ssi_' + convert(varchar, migs.group_handle) + '_' +  convert(varchar, mig.index_handle) + '] ON [' +  object_name(mid.object_id) + '] ' + '(' +
	   CASE WHEN mid.equality_columns is not null THEN mid.equality_columns ELSE '' END +
	   CASE WHEN mid.equality_columns is null AND mid.inequality_columns is not null THEN mid.inequality_columns ELSE '' END +
	   CASE WHEN mid.equality_columns is not null AND mid.inequality_columns is not null THEN ', ' + mid.inequality_columns ELSE '' END + ')' +
	   CASE WHEN mid.included_columns is not null THEN ' INCLUDE (' + mid.included_columns + ')' ELSE '' END as tsql
	    
FROM sys.dm_db_missing_index_group_stats AS migs
INNER JOIN sys.dm_db_missing_index_groups AS mig
    ON (migs.group_handle = mig.index_group_handle)
INNER JOIN sys.dm_db_missing_index_details AS mid
    ON (mig.index_handle = mid.index_handle)
WHERE (mid.database_id = db_id())

AND (migs.user_seeks >= 100)  -- change threshold
AND (migs.avg_user_impact >= 90)  -- change threshold

ORDER BY object_name(mid.object_id) ASC, migs.user_seeks DESC, migs.user_scans DESC
GO
  

