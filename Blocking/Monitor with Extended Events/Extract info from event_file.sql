--Extract info about blocking from ring_buffer

DECLARE @ExtendedEventsSessionName sysname = N'Blocking Monitoring'; --enter here the name of Extended Event session
DECLARE @StartTime datetimeoffset;
DECLARE @EndTime datetimeoffset;
DECLARE @Offset int;
DECLARE @path NVARCHAR(260) = N'C:\Temp\Blocks*'; -- Enter here the path and filename. Keep the asterisk to query all files.
SET @StartTime = DATEADD(HOUR, -4, GETDATE()); --modify this to suit your needs
SET @EndTime = GETDATE();
SET @Offset = DATEDIFF(MINUTE, GETDATE(), GETUTCDATE());
SET @StartTime = DATEADD(MINUTE, @Offset, @StartTime);
SET @EndTime = DATEADD(MINUTE, @Offset, @EndTime);

DROP TABLE IF EXISTS #xmlResults;
CREATE TABLE #xmlResults
(
      xeTimeStamp datetimeoffset NOT NULL
    , xeXML XML NOT NULL
	, xeBlockDuration bigint
);
 
 
SELECT StartTimeUTC = CONVERT(varchar(30), @StartTime, 127)
    , StartTimeLocal = CONVERT(varchar(30), DATEADD(MINUTE, 0 - @Offset, @StartTime), 120)
    , EndTimeUTC = CONVERT(varchar(30), @EndTime, 127)
    , EndTimeLocal = CONVERT(varchar(30), DATEADD(MINUTE, 0 - @Offset, @EndTime), 120);
 

WITH src
AS (SELECT CAST(fx.event_data AS XML) AS Event_Data
    FROM sys.fn_xe_file_target_read_file(@path,
                                         NULL,
                                         NULL,
                                         NULL) AS fx )
 
INSERT INTO #xmlResults (xeXML, xeTimeStamp, xeBlockDuration)
SELECT src.Event_Data
    , [xeTimeStamp] = src.Event_Data.value('(/event/@timestamp)[1]', 'datetimeoffset(7)')
	, [xeBlockDuration] = src.Event_Data.value('(event/data/value/blocked-process-report/blocked-process/process/@waittime)[1]', 'bigint')
FROM src;
 
SELECT [TimeStamp] = CONVERT(varchar(30), DATEADD(MINUTE, 0 - @Offset, xr.xeTimeStamp), 120)
    , xr.xeXML, xr.xeBlockDuration
FROM #xmlResults xr
WHERE xr.xeTimeStamp >= @StartTime
    AND xr.xeTimeStamp<= @EndTime
ORDER BY xr.xeTimeStamp;