
USE [Demo Database NAV (7-1)]  -- select NAV database here
GO

SET STATISTICS IO OFF
SET NOCOUNT ON
GO


-- Load Trace Data into table
DECLARE @ProfilerTrace NVARCHAR(250)
SET @ProfilerTrace = 'C:\Users\jstryk\Desktop\NAV TechDays 2015\Session\Scripts\2_QueryStrategy\Example_Nav7_SQLTrace.trc'  -- Example
SELECT * INTO #tmp_Trace FROM ::fn_trace_gettable(@ProfilerTrace, default) 
WHERE [EventClass] IN (12, 45)
GO

------------------------------------------------------------------------------------------

/* ANALYSIS */

SELECT [DatabaseName], convert(nvarchar(max), [TextData]) as [TextData], 
avg(Reads) as [avg_Reads], avg(Writes) as [avg_Writes], avg(CPU) as [avg_CPU], avg(Duration/1000) as [avg_Duration],
count(*) as [Occurrence],
sum(Reads) as [sum_Reads], sum(Writes) as [sum_Writes], sum(CPU) as [sum_CPU], sum(Duration/1000) as [sum_Duration]
FROM #tmp_Trace
GROUP BY [DatabaseName], convert(nvarchar(max), [TextData])
ORDER BY [DatabaseName] ASC, [sum_Reads] DESC
GO

SELECT [DatabaseName], [LoginName], [HostName], [ApplicationName],
avg(Reads) as [avg_Reads], avg(Writes) as [avg_Writes], avg(CPU) as [avg_CPU], avg(Duration/1000) as [avg_Duration],
count(*) as [Occurrence],
sum(Reads) as [sum_Reads], sum(Writes) as [sum_Writes], sum(CPU) as [sum_CPU], sum(Duration/1000) as [sum_Duration]
FROM #tmp_Trace
GROUP BY [DatabaseName], [LoginName], [HostName], [ApplicationName]
ORDER BY [DatabaseName] ASC, [sum_Reads] DESC
GO

SELECT 
  isnull(DatabaseName, '') as [DbName],
  isnull(convert(varchar(max), [TextData]), '') as [Query],
  avg(Reads) as [Avg_Reads],
  max(Reads) as [Max_Reads],
  avg(CPU) as [Avg_CPU],
  max(CPU) as [Max_CPU],
  avg(Duration/1000) as [Avg_Duration],
  max(Duration/1000) as [Max_Duration],
  count(*) as [Occurrence],
  convert(bigint, avg(Reads) * count(*)) as [Total_Cost_Reads],
  convert(bigint,avg(CPU) * count(*)) as [Total_Cost_CPU],
  convert(bigint,avg(Duration/1000) * count(*)) as [Total_Cost_Duration]
FROM #tmp_Trace WITH (READUNCOMMITTED)
WHERE Reads is not null and Writes is not null and CPU is not null
-- and DatabaseName = 'DbName'
GROUP BY DatabaseName, convert(varchar(max), [TextData]) 
--HAVING count(RowNumber) >= 100
ORDER BY [Total_Cost_Reads] DESC
GO

DROP TABLE #tmp_Trace
GO