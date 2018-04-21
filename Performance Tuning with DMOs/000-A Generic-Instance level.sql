Select @@VERSION
--SELECT SERVERPROPERTY('productversion'), SERVERPROPERTY ('productlevel'), SERVERPROPERTY ('edition')

SELECT sqlserver_start_time FROM sys.dm_os_sys_info

DBCC TRACESTATUS

SELECT  *
FROM    sys.configurations
where name = 'max degree of parallelism'
ORDER BY name ;