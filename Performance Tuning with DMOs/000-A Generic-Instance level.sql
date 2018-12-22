Select @@VERSION
--SELECT SERVERPROPERTY('productversion'), SERVERPROPERTY ('productlevel'), SERVERPROPERTY ('edition')

SELECT sqlserver_start_time FROM sys.dm_os_sys_info
--Or one of the below for 2005
--SELECT login_time FROM sys.dm_exec_sessions WHERE session_id = 1;  
--select start_time from sys.traces where is_default = 1  
--SELECT crdate FROM sysdatabases WHERE name='tempdb'  
--SELECT create_date FROM sys.databases WHERE name = 'tempdb' 

DBCC TRACESTATUS
--To turn on for all sessions in the instance
--DBCC TRACON (1117,-1)
--DBCC TRACON (1118,-1)


--Info about MAXDOP and NAV: https://www.archerpoint.com/node/5166
SELECT  *
FROM    sys.configurations
where name in ('max degree of parallelism','max server memory (MB)')
ORDER BY name ;