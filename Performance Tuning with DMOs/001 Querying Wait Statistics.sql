--Wait Statistics
--Each time a worker needs to wait for a resource, it is recorded in SQL Server.
--This information is cached and incremented until the next SQL Server service restart.
--By quering wait statistics we can identify resources with the bigest waiting times.

SELECT  wait_type ,
        SUM(wait_time_ms / 1000) AS [wait_time_s]
FROM    sys.dm_os_wait_stats DOWS
WHERE   wait_type NOT IN ( 'SLEEP_TASK', 'BROKER_TASK_STOP',
                           'SQLTRACE_BUFFER_FLUSH', 'CLR_AUTO_EVENT',
                           'CLR_MANUAL_EVENT', 'LAZYWRITER_SLEEP' )
GROUP BY wait_type
ORDER BY SUM(wait_time_ms) DESC

