--Monitor blocking with Extended Events
--by using blocked_process_report event
--Sents results to ring_buffer. You can see the sql queries under <inputbuf>

exec sp_configure 'show advanced option', '1';
reconfigure;

exec sp_configure 'blocked process threshold', 3; --threshold to 3 seconds
reconfigure;

CREATE EVENT SESSION [Blocking Monitoring] ON SERVER 
ADD EVENT sqlserver.blocked_process_report
ADD TARGET package0.ring_buffer(SET max_memory=(10240)) 
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO

-- start a session
--ALTER EVENT SESSION [Blocking Monitoring] ON SERVER STATE = START;

-- stop a session
--ALTER EVENT SESSION [Blocking Monitoring] ON SERVER STATE = STOP;

-- delete the event session
--DROP EVENT SESSION [Blocking Monitoring] ON SERVER 
--GO