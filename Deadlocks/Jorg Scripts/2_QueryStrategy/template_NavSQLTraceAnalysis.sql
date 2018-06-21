-- By MS Dynamics NAV; modified by Jörg Stryk
-- http://blogs.msdn.com/b/nav/archive/2012/09/18/example-of-how-to-use-sql-tracing-feature-to-profile-al-code.aspx
-- PLEASE READ THE ARTICLE BEFORE USING THE FEATURE!

-- Requires NAV 2013 Build 33595 (or higher)

-- IMPORTANT NOTICE: Replace <DatabaseName> with actual name of the NAV database!
-- IMPORTANT NOTICE: Replace <Path> with actual path and name of the Profiler Trace file!

USE [Demo Database NAV (7-1)]  -- select NAV database here
GO

SET STATISTICS IO OFF
SET NOCOUNT ON
GO

-- Load Trace Data into table
DECLARE @ProfilerTrace NVARCHAR(250)
--SET @ProfilerTrace = '<Path>'
SET @ProfilerTrace = 'C:\Users\jstryk\Desktop\NAV TechDays 2015\Session\Scripts\2_QueryStrategy\Example_Nav7_SQLTrace.trc'  -- Example
SELECT ROW_NUMBER() OVER (ORDER BY [EventSequence]) AS [RowNumber], * INTO #tmp_Trace FROM ::fn_trace_gettable(@ProfilerTrace, default) 
WHERE [EventClass] IN (12, 45)
GO

/*
-- Trace recorded in Table
SELECT * INTO #tmp_Trace FROM <TraceTable>
--SELECT * INTO #tmp_Trace FROM [master].[dbo].[NAV7_Trace]  -- Example
WHERE [EventClass] IN (12, 45)
GO
*/

/*
SELECT * FROM #tmp_Trace
*/

-- Investigate Trace Data
SELECT 'Investigating ' + CONVERT(VARCHAR(15), COUNT(*)) + ' lines of Trace Data ...' AS [Info] FROM #tmp_Trace
GO
DECLARE @ApplicationName NVARCHAR(100)
DECLARE @GetConnection NVARCHAR(100)
DECLARE @ReturnConnection NVARCHAR(100)
DECLARE @ContainsUserName NVARCHAR(100)
DECLARE @EmptyCallStack NVARCHAR(100)
SET @ApplicationName = 'Microsoft Dynamics NAV Service'
SET @GetConnection = '%Get connection%'
SET @ReturnConnection = '%Return connection%'
SET @ContainsUserName = '%User: Your user name%'
SET @EmptyCallStack = '/*__User: Your user name__*/'
IF OBJECT_ID('tempdb..#ProfilerData') IS NOT NULL
 DROP TABLE #ProfilerData
SELECT * INTO #ProfilerData FROM
(
 SELECT
  [RowNumber] AS [SqlStatement RowNumber],
  [TextData] AS [SQL Statement],
  [Reads],
  [Writes],
  [Duration],
  [CPU],
  [StartTime],
  [EndTime],
  [SPID]
 FROM #tmp_Trace
 WHERE
  [ApplicationName] = @ApplicationName and
 -- [TextData] not like @ContainsUserName and
  [TextData] not like @GetConnection and
  [TextData] not like @ReturnConnection --and
 -- [TextData] not like @EmptyCallStack
) SqlStatement
CROSS APPLY
(
 SELECT TOP 1
  [RowNumber] AS [Stack RowNumber],
  [TextData] AS [Call Stack]
 FROM #tmp_Trace
 WHERE
  [SPID] = SqlStatement.[SPID] and
  [RowNumber] < SqlStatement.[SqlStatement RowNumber] and
  [ApplicationName] = @ApplicationName -- and
  --[TextData] like @ContainsUserName
 ORDER BY [RowNumber] DESC
) AS Stack
GO

/*
SELECT * FROM #ProfilerData --this table contains mapping of SQL statements to the AL call stack
*/

/*** !!! ANALYSIS !!! ***/

-- Expensive AL & SQL Statements
SELECT
 CAST([Call Stack] AS NVARCHAR(max)) AS [Call Stack],
 CAST([SQL Statement] AS NVARCHAR(max)) AS [SQL Statement],
 AVG(Reads) AS [Avg Reads],
 AVG(Writes) AS [Avg Writes],
 AVG(Duration/1000) AS [Avg Duration],
 AVG(CPU) AS [Avg CPU],
 --MIN(Duration) AS [Min Duration],
 --MAX(Duration) AS [Max Duration],
 --SUM(Reads) AS [Sum Reads],
 --SUM(Writes) AS [Sum Writes],
 --SUM(Duration) AS [Sum Duration],
 COUNT(*) AS [Occurrence],
 AVG(Reads) * COUNT(*) AS [Costs]
FROM #ProfilerData
GROUP BY CAST([Call Stack] AS NVARCHAR(max)), CAST([SQL Statement] AS NVARCHAR(max))
ORDER BY [Costs] DESC
GO

----------------------------------------------------------------------------------------------------

/*
-- Examples:

SELECT * FROM #ProfilerData
WHERE [Call Stack] like '%"Sales-Post"(CodeUnit 80).OnRun(Trigger) line 1556%'

SELECT * FROM #ProfilerData
WHERE [Call Stack] like '%"Gen. Jnl.-Post Line"(CodeUnit 12).InsertGLEntry line 59%'

SELECT * FROM #ProfilerData
WHERE [Call Stack] like '%"Item Jnl.-Post Line"(CodeUnit 22).ApplyItemLedgEntry line 252%'
*/

----------------------------------------------------------------------------------------------------

-- Clean Up
IF OBJECT_ID('tempdb..#ProfilerData') IS NOT NULL
 DROP TABLE #ProfilerData
GO
IF OBJECT_ID('tempdb..#tmp_Trace') IS NOT NULL
 DROP TABLE #tmp_Trace
GO


