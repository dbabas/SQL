-- Wait statistics (Paul S. Randal – www.sqlskills.com) 09.12.2010

/*

-- Reset WaitStats
DBCC SQLPERF ('sys.dm_os_wait_stats', CLEAR);
GO

*/

WITH Waits AS
(
    SELECT DISTINCT
    wait_type,
    wait_time_ms / 1000.0 AS WaitS,
    (wait_time_ms - signal_wait_time_ms) / 1000.0 AS ResourceS,
    signal_wait_time_ms / 1000.0 AS SignalS,
    waiting_tasks_count AS WaitCount,
    100.0 * wait_time_ms / SUM (wait_time_ms) OVER() AS Percentage,
    ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS RowNum
    FROM sys.dm_os_wait_stats
    WHERE wait_type NOT IN (
    'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 'SLEEP_TASK',
    'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH', 'WAITFOR', 'LOGMGR_QUEUE',
    'CHECKPOINT_QUEUE', 'REQUEST_FOR_DEADLOCK_SEARCH', 'XE_TIMER_EVENT', 'BROKER_TO_FLUSH',
    'BROKER_TASK_STOP', 'CLR_MANUAL_EVENT', 'CLR_AUTO_EVENT', 'DISPATCHER_QUEUE_SEMAPHORE',
    'FT_IFTS_SCHEDULER_IDLE_WAIT', 'XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN', 'BROKER_EVENTHANDLER',
    'TRACEWRITE', 'FT_IFTSHC_MUTEX', 'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
    'BROKER_RECEIVE_WAITFOR', 'ONDEMAND_TASK_QUEUE', 'DBMIRROR_EVENTS_QUEUE',
    'DBMIRRORING_CMD', 'BROKER_TRANSMITTER', 'SQLTRACE_WAIT_ENTRIES',
    'SLEEP_BPOOL_FLUSH', 'SQLTRACE_LOCK', 'DIRTY_PAGE_POLL', 'SP_SERVER_DIAGNOSTICS_SLEEP', 'SOS_SCHEDULER_YIELD')
	AND wait_type NOT LIKE 'HADR_%' AND wait_type NOT LIKE 'QDS_%'
)
SELECT
    W1.wait_type AS WaitType, 
    CAST (W1.WaitS AS DECIMAL(14, 2)) AS Total_Wait_sec,
    --CAST (W1.ResourceS AS DECIMAL(14, 2)) AS Total_Resource_sec,
    --CAST (W1.SignalS AS DECIMAL(14, 2)) AS Total_Signal_sec,
    W1.WaitCount AS WaitCount,
    CAST (W1.Percentage AS DECIMAL(4, 2)) AS Percentage,
    CAST ((W1.WaitS / W1.WaitCount) AS DECIMAL (14, 4)) AS Avg_Wait_sec,
    --CAST ((W1.ResourceS / W1.WaitCount) AS DECIMAL (14, 4)) AS Avg_Res_sec,
    --CAST ((W1.SignalS / W1.WaitCount) AS DECIMAL (14, 4)) AS Avg_Sig_sec,
    CASE 
    	   WHEN W1.wait_type LIKE 'PAGEIOLATCH_%' THEN 'DISK: transfer from disk to RAM; should be less than 0.015 sec'
	   WHEN W1.wait_type IN ('WRITELOG', 'IO_COMPLETION') THEN 'DISK: disk I/O; should be less than 0.015 sec'
	   WHEN W1.wait_type LIKE 'PREEMPTIVE_OS_%' THEN 'OS: Operating System'
	   WHEN W1.wait_type LIKE 'LCK_%' THEN 'APP: Blocks; check application/queries'
	   WHEN W1.wait_type IN ('ASYNC_NETWORK_IO', 'OLEDB') THEN 'LAN: communication with clients; should be less than 0.001 sec'
	   WHEN W1.wait_type = 'CXPACKET' THEN 'CPU: check "Max. Degree of Parallelism"'
	   ELSE ''
    END AS Comment
FROM Waits AS W1
INNER JOIN Waits AS W2 ON W2.RowNum <= W1.RowNum
GROUP BY W1.RowNum, W1.wait_type, W1.WaitS, W1.ResourceS, W1.SignalS, W1.WaitCount, W1.Percentage
HAVING SUM (W2.Percentage) - W1.Percentage < 99; -- percentage threshold
GO 
