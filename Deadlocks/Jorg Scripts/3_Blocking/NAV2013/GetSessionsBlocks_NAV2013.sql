
USE [Demo Database NAV (7-1)]
GO

SET STATISTICS IO OFF
SET NOCOUNT ON
GO

-- Load Trace Data into table
DECLARE @ProfilerTrace NVARCHAR(250)
SET @ProfilerTrace = 'C:\Users\jstryk\Desktop\NAV TechDays 2015\Session\Scripts\3_Blocking\NAV2013\Example_Nav7_SQLTrace_Blocks.trc'
SELECT * INTO #tmp_Trace FROM ::fn_trace_gettable(@ProfilerTrace, default) 
WHERE [EventClass] IN (12) AND ( CHARINDEX('*/', [TextData]) > 0 )
GO

DECLARE @first datetime, @last datetime
SELECT TOP 1 @first = [StartTime] FROM #tmp_Trace ORDER BY [StartTime] ASC
SELECT TOP 1 @last = [StartTime] FROM #tmp_Trace ORDER BY [StartTime] DESC
SELECT @first AS [Trace_From], @last AS [Trace_To]

--

/* Combine Blocks & Trace-Data */

SELECT [db]
      --,[waitresource]
      ,[table_name]
      ,[index_name]
      ,[start_time]
      ,[waittime]
      --,[lastwaittype]
      ,[spid]
      ,[loginame]

			,(
				SELECT TOP 1 
						SUBSTRING(
								[TextData], 
								CHARINDEX('User:', [TextData]) + 6,
								(CHARINDEX('*/', [TextData]) - CHARINDEX('User:', [TextData]) ) - 8
						)  AS [User]
				FROM #tmp_Trace trc
				WHERE (trc.SPID = b.spid) AND (trc.StartTime <= b.start_time) AND (trc.DatabaseName collate database_default = b.db)
				AND (trc.LoginName collate database_default = b.loginame)
				ORDER BY trc.StartTime DESC
				) AS blocked_user

      ,[hostname]
      ,[program_name]
      ,[cmd]

			,(
				SELECT TOP 1 [TextData] AS [CallStack]
				FROM #tmp_Trace trc
				WHERE (trc.SPID = b.spid) AND (trc.StartTime <= b.start_time) AND (trc.DatabaseName collate database_default = b.db)
				AND (trc.LoginName collate database_default = b.loginame)
				ORDER BY trc.StartTime DESC
				) AS nav_callstack_blocked

      --,[status]
      --,[cpu]
      ,[lock_timeout]
      ,[blocked by]
      ,[loginame 2]

			,(
				SELECT TOP 1 
						SUBSTRING(
								[TextData], 
								CHARINDEX('User:', [TextData]) + 6,
								(CHARINDEX('*/', [TextData]) - CHARINDEX('User:', [TextData]) ) - 8
						)  AS [User]
				FROM #tmp_Trace trc
				WHERE (trc.SPID = b.[blocked by]) AND (trc.StartTime <= b.start_time) AND (trc.DatabaseName collate database_default = b.db)
				AND (trc.LoginName collate database_default = b.[loginame 2])
				ORDER BY trc.StartTime DESC
				) AS blocking_user


      ,[hostname 2]
      ,[program_name 2]
      ,[cmd 2]

			,(
				SELECT TOP 1 [TextData] AS [CallStack]
				FROM #tmp_Trace trc
				WHERE (trc.SPID = b.[blocked by]) AND (trc.StartTime <= b.start_time) AND (trc.DatabaseName collate database_default = b.db)
				AND (trc.LoginName collate database_default = b.[loginame 2])
				ORDER BY trc.StartTime DESC
				) AS nav_callstack_blocker

      --,[status 2]
      --,[cpu 2]
      ,[block_orig_id]
      ,[block_orig_loginame]

			,(
				SELECT TOP 1 
						SUBSTRING(
								[TextData], 
								CHARINDEX('User:', [TextData]) + 6,
								(CHARINDEX('*/', [TextData]) - CHARINDEX('User:', [TextData]) ) - 8
						)  AS [User]
				FROM #tmp_Trace trc
				WHERE (trc.SPID = b.block_orig_id) AND (trc.StartTime <= b.start_time) AND (trc.DatabaseName collate database_default = b.db)
				AND (trc.LoginName collate database_default = b.[block_orig_loginame])
				ORDER BY trc.StartTime DESC
				) AS block_originator_user

			,(
				SELECT TOP 1 [TextData] AS [CallStack]
				FROM #tmp_Trace trc
				WHERE (trc.SPID = b.block_orig_id) AND (trc.StartTime <= b.start_time) AND (trc.DatabaseName collate database_default = b.db)
				AND (trc.LoginName collate database_default = b.[block_orig_loginame])
				ORDER BY trc.StartTime DESC
				) AS nav_callstack_block_originator

FROM ssi_BlockLog b /* Freeware Block-Detection */
--FROM ssi_BlockCheck_Tab b /* full PTB version */

WHERE b.start_time >= @first AND b.start_time <= @last
AND b.[table_name] not in ('DEADLOCK', 'TIMEOUT')
ORDER BY b.[start_time] DESC
GO

--

SELECT  
  trc.[SPID], 
  SUBSTRING(
    [TextData], 
	   CHARINDEX('User:', [TextData]) + 6,
	   (CHARINDEX('*/', [TextData]) - CHARINDEX('User:', [TextData]) ) - 8
		)  AS [User],
		[StartTime],
		[TextData] as [CallStack]
FROM #tmp_Trace trc
--ORDER BY trc.[SPID]
ORDER BY [StartTime]
GO


DROP TABLE #tmp_Trace
GO