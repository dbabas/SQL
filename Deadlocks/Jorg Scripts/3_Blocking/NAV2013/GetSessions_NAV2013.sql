
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

SELECT  
  trc.[SPID], 
  SUBSTRING(
    [TextData], 
	CHARINDEX('User:', [TextData]) + 6,
	( CHARINDEX('*/', [TextData]) - CHARINDEX('User:', [TextData]) ) - 8
  )  AS [User],
  sysproc.login_time AS [LoginTime],
  sysproc.last_batch AS [LastBatch],
		[TextData] as [CallStack]
FROM #tmp_Trace trc
LEFT JOIN master..sysprocesses sysproc ON sysproc.[spid] = trc.[SPID]
ORDER BY trc.[SPID], trc.[StartTime]
GO

DROP TABLE #tmp_Trace
GO
