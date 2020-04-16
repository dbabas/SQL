-- Retrieve Deadlock graph from system_health

DECLARE @path NVARCHAR(260)
--to retrieve the local path of system_health files 
SELECT @path = dosdlc.path
FROM sys.dm_os_server_diagnostics_log_configurations AS dosdlc;

SELECT @path = @path + N'system_health_*';

WITH fxd
AS (SELECT CAST(fx.event_data AS XML) AS Event_Data
    FROM sys.fn_xe_file_target_read_file(@path,
                                         NULL,
                                         NULL,
                                         NULL) AS fx )
SELECT dl.deadlockgraph
FROM
(   SELECT dl.query('.') AS deadlockgraph
    FROM fxd
        CROSS APPLY event_data.nodes('(/event/data/value/deadlock)') AS d(dl) ) AS dl;


SELECT [db_name], [wait_resource], [deadlock_xml] FROM (
    SELECT target_data_XML.query('/event/data[@name=''database_name'']/value').value('(/value)[1]', 'nvarchar(250)') AS [db_name],
    waitresource_node.value('@waitresource', 'nvarchar(250)') AS [wait_resource],
    deadlock_node.query('.') as [deadlock_xml]
    FROM CTE CROSS APPLY target_data_XML.nodes('(/event/data/value/deadlock)') AS T(deadlock_node)
    CROSS APPLY target_data_XML.nodes('(/event/data/value/deadlock/process-list/process)') AS U(waitresource_node)
) deadlock
WHERE [db_name] = '<YourDB>' -- Enter here the database name