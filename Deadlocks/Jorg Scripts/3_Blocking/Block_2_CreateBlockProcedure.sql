
/***  (c) 2012, STRYK System Improvement, Jörg Stryk   ***/
/***                   www.stryk.info                  ***/

-- Create Block-Detection Procedure

-- IMPORTANT NOTICE: Replace <DatabaseName> with actual name of the NAV database!

USE [<DatabaseName>]  -- select NAV database here
GO

CREATE PROCEDURE [dbo].[ssi_blockdetection]
AS
BEGIN

  set nocount on
  set statistics io off

  if exists (select * from sys.dm_exec_requests where [blocking_session_id] <> 0) begin
      insert into [ssi_BlockLog]
      ([timestamp],[db],[waitresource],[table_name],[index_name],[start_time],[waittime],[lastwaittype],
       [spid],[loginame],[hostname],[program_name],[cmd],[query_plan],[status],[cpu],[lock_timeout],
       [blocked by],[loginame 2],[hostname 2],[program_name 2],[cmd 2],[query_plan 2],[status 2],[cpu 2])
      select getdate(),
             [db] = db_name(s1.[database_id]), 
             [waitresource] = ltrim(rtrim(s1.[wait_resource])),
             [table_name] = object_name(sl.rsc_objid),            
             [index_name] = si.[name],
             s1.[start_time],
             s1.[wait_time],              
             s1.[last_wait_type], 
             s1.[session_id],
             session1.[login_name], 
             session1.[host_name], 
             session1.[program_name], 
             [cmd] = isnull(st1.[text], ''),
             null, -- [query_plan] = isnull(qp1.[query_plan], ''),
             session1.[status],
             session1.[cpu_time], 
             s1.[lock_timeout],
             [blocked by] = s1.[blocking_session_id],             
             [login_name 2] = session2.[login_name],
             [hostname 2] = session2.[host_name],
             [program_name 2] = session2.[program_name],
             [cmd 2] = isnull(st2.[text], ''),
             null, -- [query_plan 2] = isnull(qp2.[query_plan], ''),
             session2.[status],
             session2.[cpu_time]
       from sys.dm_exec_requests (nolock) s1 
       outer apply sys.dm_exec_sql_text(s1.sql_handle) st1
       outer apply sys.dm_exec_query_plan(s1.plan_handle) qp1
       left outer join sys.dm_exec_requests (nolock) s2 on s2.[session_id] = s1.[blocking_session_id]
       outer apply sys.dm_exec_sql_text(s2.sql_handle) st2
       outer apply sys.dm_exec_query_plan(s2.plan_handle) qp2
       left outer join sys.dm_exec_sessions (nolock) session1 on session1.[session_id] = s1.[session_id]
       left outer join sys.dm_exec_sessions (nolock) session2 on session2.[session_id] = s1.[blocking_session_id]
       left outer join  master.dbo.syslockinfo (nolock) sl on s1.[session_id] = sl.req_spid
       left outer join sys.indexes (nolock) si on sl.rsc_objid = si.[object_id] and sl.rsc_indid = si.[index_id]
       where s1.[blocking_session_id] <> 0 
             and (sl.rsc_type in (2,3,4,5,6,7,8,9)) and sl.req_status = 3
             and s1.[wait_time] >= 1000 -- milliseconds
    
  end
END