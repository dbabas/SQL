
/***  (c) 2012, STRYK System Improvement, Jörg Stryk   ***/
/***                   www.stryk.info                  ***/

-- Create Block-Detection Alert

USE msdb
GO

declare @instance varchar(128), @perfcon varchar(256)
if @@servicename = 'MSSQLSERVER' -- Standard-Instance
  set @instance = 'SQLServer'
else -- Named Instance
  set @instance = 'MSSQL$' + @@servicename
set @perfcon = @instance + N':General Statistics|Processes blocked||>|0'

EXEC sp_add_alert @name=N'SSI: Block Detection',
  @message_id=0,
  @severity=0,
  @enabled=1,
  @delay_between_responses=10,  -- 10 seconds; requires Registry change
  @include_event_description_in=0,
  @performance_condition= @perfcon,
  @job_name=N'SSI: Block Detection'
GO


-- Reduce "Performance Sample Rate" to 10 seconds (default = 20 sec)

USE [master]
GO
EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE',
  N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
  N'PerformanceSamplingInterval', REG_DWORD, 10 -- 10 seconds
GO