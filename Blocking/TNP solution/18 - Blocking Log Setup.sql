
If DB_NAME() in ('master','tempdb','model','msdb','ReportServer','ReportServerTempDB')
Begin
	RAISERROR ('Cannot run this script against system database !!!',20,1) with log
End

-------------------------- Create table to store blocking details ------------------------

CREATE TABLE [dbo].[ZZ_BlockingLog] 
( 
[Entry No] BIGINT IDENTITY CONSTRAINT [ZZ_BlockingLog_PK] PRIMARY KEY CLUSTERED, 
[Timestamp] DATETIME,
[Batch No] INT, 
[Waitresource] VARCHAR(128), 
[Waitresource Name] VARCHAR(128) COLLATE database_default,
[Blocker SQL] VARCHAR(max),
[Blocked SQL] VARCHAR(max),
[Waittime] BIGINT, 
[Lastwaittype] VARCHAR(128), 
[Spid] INT, 
[Name] VARCHAR(128) COLLATE database_default, 
[Hostname] VARCHAR(128) COLLATE database_default,
[LastBatch] DATETIME, 
[Cmd] NVARCHAR(255) COLLATE database_default, 
[Status] VARCHAR(128) COLLATE database_default, 
[Cpu] BIGINT, 
[Blocker Spid] INT, 
[Blocker Name] VARCHAR(128) COLLATE database_default, 
[Blocker Hostname] VARCHAR(128) COLLATE database_default, 
[Blocker Cmd] NVARCHAR(255) COLLATE database_default, 
[Blocker Status] VARCHAR(128) COLLATE database_default, 
[Blocker Cpu] BIGINT, 
[Database Name] VARCHAR(128) COLLATE database_default, 
) 


CREATE NONCLUSTERED INDEX [IDX_BatchNo] ON [dbo].[ZZ_BlockingLog] ([Batch No])

GO
--------------------------------------------------------------------------------------------------------- 


------------ Create usp_Blockdetect Stored Procedure -----------------------------------------------------

Create Procedure dbo.usp_Blockdetect @LogBlockedTable int = 0 WITH ENCRYPTION
AS
BEGIN
	
	BEGIN TRY
		SET NOCOUNT ON

		Declare @i as integer
		Declare @CurrTime as datetime
		Declare @LastBatchNo as int
		CREATE TABLE #SysProcesses (spid smallint,blocked smallint,waittime bigint,lastwaittype nchar(32),waitresource nchar(50),
					dbid smallint,cpu int,status nchar(30),hostname nchar(128),LastBatch DATETIME,cmd nchar(16),loginame nchar(128),sql_handle binary(20))  
		Set @i = 0 
		If @LogBlockedTable = 1
		BEGIN
			While @i <= 1			-------------------- Slower Version --------------------
			BEGIN 
				IF EXISTS(SELECT TOP 1 NULL  FROM sys.sysprocesses with (nolock) WHERE [blocked] <> 0) 
				BEGIN
					BEGIN Tran T1
						CREATE TABLE #SysLockInfo (rsc_objid int,req_spid int,rsc_type int)

						Set @CurrTime = CAST(LEFT(CONVERT(varchar,GETDATE(),120),19) AS datetime)
						Set @LastBatchNo = ISNULL((Select MAX([Batch No]) From [ZZ_BlockingLog]),0)

						Insert into #SysProcesses
						Select spid,blocked,waittime,lastwaittype,waitresource,dbid,cpu,status,hostname,last_batch,cmd,loginame,sql_handle From sys.sysprocesses WITH (nolock)
					
						Insert into #SysLockInfo 
						Select rsc_objid,req_spid,rsc_type From master.dbo.syslockinfo WITH (nolock)


						INSERT INTO [ZZ_BlockingLog] 
						([Timestamp] ,[Batch No],[Waitresource] ,[Waitresource Name] ,[Blocker SQL],[Blocked SQL],[Waittime] 
						,[Lastwaittype] ,[Spid] ,[Name] ,[Hostname] ,[LastBatch],[Cmd] ,[Status] 
						,[Cpu] ,[Blocker Spid] ,[Blocker Name] ,[Blocker Hostname] ,[Blocker Cmd] 
						,[Blocker Status] ,[Blocker Cpu] ,[Database Name] 
						) 

						SELECT  [Timestamp] = @CurrTime ,
							[Batch No] = @LastBatchNo+1,
							RTRIM(sp1.[waitresource]) as [Waitresource], 
							Object_Name(SL1.rsc_objid) as [Waitresource Name],
							cast((select [text] from sys.dm_exec_sql_text(sp2.sql_handle)) as nvarchar(max)) as [Blocker SQL],
							cast((select [text] from sys.dm_exec_sql_text(sp1.sql_handle)) as nvarchar(max)) as [Blocked SQL],
							sp1.[waittime] as [Waittime],
							RTRIM(sp1.[lastwaittype]) as [Lastwaittype],
							sp1.[spid] as [Spid],
							RTRIM(sp1.[loginame]) as [Name], 
							RTRIM(sp1.[hostname]) as [Hostname],
							sp1.LastBatch as [LastBatch],
							RTRIM(sp1.[cmd]) as [Cmd],
							RTRIM(sp1.[status]) as [Status],
							sp1.[cpu] as [CPU], 
							sp1.[blocked] as [Blocker Spid], 
							RTRIM(sp2.[loginame]) as [Blocker Name], 
							RTRIM(sp2.[hostname]) as [Blocker Hostname], 
							RTRIM(sp2.[cmd]) as [Blocker Cmd], 
							RTRIM(sp2.[status]) as [Blocker Status], 
							sp2.[cpu] as [Blocker Cpu], 
							[Database Name] = DB_NAME(sp1.[dbid])
						FROM    #SysProcesses AS sp1 LEFT OUTER JOIN 
							#SysProcesses AS sp2 ON sp2.spid = sp1.blocked LEFT OUTER JOIN
							(Select rsc_objid,req_spid 
								From #SysLockInfo 
								Where rsc_type IN (4,5,6,7)
								Group by rsc_objid,req_spid) as SL1 on SL1.req_spid = sp1.spid LEFT OUTER JOIN
							(Select rsc_objid,req_spid 
								From #SysLockInfo 
								Where rsc_type IN (4,5,6,7)
								Group by rsc_objid,req_spid) as SL2 on SL2.req_spid = sp2.spid and (SL1.rsc_objid = SL2.rsc_objid)
						WHERE	(sp1.blocked > 0)
						ORDER BY sp1.Waittime DESC

						DROP TABLE #SysLockInfo
						Truncate TABLE #SysProcesses
					COMMIT TRAN T1
				END
				Set @i = @i + 1
				If @i = 1 
					WAITFOR DELAY '00:00:10' -- Wait for 10 Seconds
				Else
					WAITFOR DELAY '00:00:09' -- Wait for 09 Seconds	
			END
		END
		ELSE BEGIN
			While @i <= 3			-------------------- Faster Version --------------------
			BEGIN 
				IF EXISTS(SELECT TOP 1 NULL  FROM sys.sysprocesses with (nolock) WHERE [blocked] <> 0) 
				BEGIN
					BEGIN Tran T1

						Set @CurrTime = CAST(LEFT(CONVERT(varchar,GETDATE(),120),19) AS datetime)
						Set @LastBatchNo = ISNULL((Select MAX([Batch No]) From [ZZ_BlockingLog]),0)

						Insert into #SysProcesses
						Select spid,blocked,waittime,lastwaittype,waitresource,dbid,cpu,status,hostname,last_batch,cmd,loginame,sql_handle From sys.sysprocesses WITH (nolock)
					
						INSERT INTO [ZZ_BlockingLog] 
						([Timestamp] ,[Batch No],[Waitresource] ,[Waitresource Name] ,[Blocker SQL],[Blocked SQL],[Waittime] 
						,[Lastwaittype] ,[Spid] ,[Name] ,[Hostname] ,[LastBatch],[Cmd] ,[Status] 
						,[Cpu] ,[Blocker Spid] ,[Blocker Name] ,[Blocker Hostname] ,[Blocker Cmd] 
						,[Blocker Status] ,[Blocker Cpu] ,[Database Name] 
						)
					
						SELECT  [Timestamp] = @CurrTime ,
							[Batch No] = @LastBatchNo+1,
							RTRIM(sp1.[waitresource]) as [Waitresource], 
							Case Left(sp1.[waitresource],3)
							When 'KEY' then
								(Select Distinct object_name(object_id) from sys.partitions where hobt_id =
								SUBSTRING(sp1.[waitresource],Charindex(':',sp1.[waitresource],5)+1,Charindex('(',sp1.[waitresource]) - Charindex(':',sp1.[waitresource],5) - 1))
							When 'TAB' then
								Object_Name(SUBSTRING(sp1.[waitresource],Charindex(':',sp1.[waitresource],5)+1,Charindex(':',sp1.[waitresource],Charindex(':',sp1.[waitresource],5)+1) - Charindex(':',sp1.[waitresource],5)-1))
							When 'PAG' then
								(SELECT Distinct OBJECT_NAME([object_id]) FROM sys.partitions WHERE [hobt_id] = (reverse(SUBSTRING(reverse((Select resource_description From sys.dm_os_waiting_tasks Where session_id = sp1.spid and blocking_session_id = sp2.spid)),1,charindex('=',reverse((Select resource_description From sys.dm_os_waiting_tasks Where session_id = sp1.spid and blocking_session_id = sp2.spid)))-1))))
							End  as [Waitresource Name],
							cast((select [text] from sys.dm_exec_sql_text(sp2.sql_handle)) as nvarchar(max)) as [Blocker SQL],
							cast((select [text] from sys.dm_exec_sql_text(sp1.sql_handle)) as nvarchar(max)) as [Blocked SQL],
							sp1.[waittime] as [Waittime],
							RTRIM(sp1.[lastwaittype]) as [Lastwaittype],
							sp1.[spid] as [Spid],
							RTRIM(sp1.[loginame]) as [Name], 
							RTRIM(sp1.[hostname]) as [Hostname],
							sp1.LastBatch as [LastBatch],
							RTRIM(sp1.[cmd]) as [Cmd],
							RTRIM(sp1.[status]) as [Status],
							sp1.[cpu] as [CPU], 
							sp1.[blocked] as [Blocker Spid], 
							RTRIM(sp2.[loginame]) as [Blocker Name], 
							RTRIM(sp2.[hostname]) as [Blocker Hostname], 
							RTRIM(sp2.[cmd]) as [Blocker Cmd], 
							RTRIM(sp2.[status]) as [Blocker Status], 
							sp2.[cpu] as [Blocker Cpu], 
							[Database Name] = DB_NAME(sp1.[dbid])
						FROM    #SysProcesses AS sp1 LEFT OUTER JOIN 
							#SysProcesses AS sp2 ON sp2.spid = sp1.blocked
						WHERE	(sp1.blocked > 0)
						ORDER BY sp1.Waittime DESC

						Truncate TABLE #SysProcesses
					COMMIT TRAN T1
				END
				Set @i = @i + 1
				If @i = 3 
					WAITFOR DELAY '00:00:04' -- Wait for 04 Seconds
				Else
					WAITFOR DELAY '00:00:05' -- Wait for 05 Seconds	
			END
		END
		DROP TABLE #SysProcesses
		
	END TRY
	BEGIN CATCH
		IF (@@TRANCOUNT > 0) ROLLBACK TRAN T1
		IF OBJECT_ID('tempdb..#SysProcesses') IS NOT NULL Drop Table #SysProcesses
		IF OBJECT_ID('tempdb..#SysLockInfo') IS NOT NULL Drop Table #SysLockInfo
		Declare @ErrMsg nvarchar(max)
		Declare @ErrLine int
		Set @ErrMsg = ERROR_MESSAGE()
		Set @ErrLine = ERROR_LINE()
		Set @ErrMsg = 'Error Line No '+cast(@ErrLine as nvarchar(max)) + ' '+ @ErrMsg
		RAISERROR (@ErrMsg,18,1)
	END CATCH
END

GO

--------------- Create the Job to run the block detection stored procedure -----------------

BEGIN TRANSACTION
	DECLARE @ReturnCode INT
	DECLARE @jobId BINARY(16)
	DECLARE @DatabaseName varchar(255)

	SET @DatabaseName = db_name()
	SELECT @ReturnCode = 0

	EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Block Detection', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0,
		@owner_login_name = 'sa', 
		@description=N'No description available.',
		@job_id = @jobId OUTPUT
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

	EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Block detect', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL',
		@command=N'
--- If the Block Tracking Job is already running do not run it again ---
declare @result int
exec @result = usp_IsJobRunning ''Block Detection''
if @result = 0
	return
---------------------------------------------

--- Enable the Monitor Job ---
Declare @BlockTrackMonitorJob nvarchar(128)
set @BlockTrackMonitorJob = ''Block Tracking Job Monitor''
if exists(select [name] from msdb.dbo.sysjobs where [enabled] = 0 and [name] = @BlockTrackMonitorJob)
	exec msdb.dbo.sp_update_job @job_name=@BlockTrackMonitorJob,@enabled=1
---------------------------------------------

exec usp_Blockdetect

--- Disable the Monitor Job ---
if exists(select [name] from msdb.dbo.sysjobs where [enabled] = 1 and [name] = @BlockTrackMonitorJob)
	exec msdb.dbo.sp_update_job @job_name=@BlockTrackMonitorJob,@enabled=0
---------------------------------------------', 
		@flags=0,
		@database_name= @DatabaseName;

	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
	
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
	EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId
	
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION

GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

-------------------------------------------------------------------------------------------

------------ Add an Alert to 'Block Detection' Job (in SQL 2005) --------------------------

Declare @instance varchar(128), @perfcon varchar(256)

if @@servicename = 'MSSQLSERVER' -- Standard-Instance
  set @instance = 'SQLServer'
else 				-- Named Instance
  set @instance = 'MSSQL$' + @@servicename
set @perfcon = @instance + N':General Statistics|Processes blocked||>|0'

EXEC msdb.dbo.sp_add_alert @name=N'Block Detection', 
        @enabled=1, 
        @delay_between_responses=1, 
        @include_event_description_in=0, 
        @performance_condition=@perfcon, 
        @job_name=N'Block Detection' 
GO

----------------------------- Procedure to see if a job is running -----------------------------------

Create Procedure dbo.usp_IsJobRunning @JobName sysname,@MinRunTimeSec int = 2 WITH ENCRYPTION
AS
BEGIN

	set nocount on 

	-- Create table to hold job information
	Declare @JobStatus table ( 
		Job_ID uniqueidentifier,
		Last_Run_Date int,
		Last_Run_Time int,
		Next_Run_Date int,
		Next_Run_Time int,
		Next_Run_Schedule_ID int,
		Requested_To_Run int,
		Request_Source int,
		Request_Source_ID varchar(100),
		Running int,
		Current_Step int,
		Current_Retry_Attempt int, 
		State int
	)

	-- Get a list of jobs  
	insert into @JobStatus execute master.dbo.xp_sqlagent_enum_jobs 1,'something'

	-- Convert the unique id into binary
	DECLARE @jobId BINARY(16)

	set @jobId = (select JobStatus.[Job_ID] from @JobStatus as JobStatus,
	msdb..sysjobs as Job
	where running = 1 and JobStatus.[Job_ID] = Job.[job_id] and Job.[Name] = @JobName) 

	-- Convert the unique id into text
	declare @i varbinary(10)
	declare @digits char(16)
	declare @l int
	set @digits = '0123456789ABCDEF'
	declare @s varchar(100)
	declare @h varchar(100)
	declare @j int
	set @l = 16
	set @j = 0 
	set @h = ''
	-- process all  bytes
	while @j < @l
	begin
	  set @j= @j + 1
	  -- get first character of byte
	  set @i = substring(cast(@jobId as varbinary(100)),@j,1)
	  -- get the first character
	  set @s = cast(substring(@digits,@i%16+1,1) as char(1))
	  -- shift over one character
	  set @i = @i/16 
	  -- get the second character
	  set @s = cast(substring(@digits,@i%16+1,1) as char(1)) + @s
	  -- build string of hex characters
	  set @h = @h + @s
	end

	-- Now get the SPID for the job
	DECLARE @SPIDJob int
	set @SPIDJob = (select spid from master..sysprocesses where substring(program_name,32,32) = @h and DATEADD("second", @MinRunTimeSec, login_time) <= GETDATE())

	if @SPIDJob <> 0 
		return (0) -- Job Running
    else
		return (1) -- Job Not Running	
END
GO

----------------------------- Procedure to terminate a over running job -----------------------------------

Create Procedure dbo.usp_KillOverRunningJob @JobName sysname,@MaxRunTimeMin int WITH ENCRYPTION
AS
BEGIN

	set nocount on 

	-- Create table to hold job information
	Declare @JobStatus table ( 
		Job_ID uniqueidentifier,
		Last_Run_Date int,
		Last_Run_Time int,
		Next_Run_Date int,
		Next_Run_Time int,
		Next_Run_Schedule_ID int,
		Requested_To_Run int,
		Request_Source int,
		Request_Source_ID varchar(100),
		Running int,
		Current_Step int,
		Current_Retry_Attempt int, 
		State int
	)

	-- Get a list of jobs  
	insert into @JobStatus execute master.dbo.xp_sqlagent_enum_jobs 1,'something'

	-- Convert the unique id into binary
	DECLARE @jobId BINARY(16)

	set @jobId = (select JobStatus.[Job_ID] from @JobStatus as JobStatus,
	msdb..sysjobs as Job
	where running = 1 and JobStatus.[Job_ID] = Job.[job_id] and Job.[Name] = @JobName) 

	-- Convert the unique id into text
	declare @i varbinary(10)
	declare @digits char(16)
	declare @l int
	set @digits = '0123456789ABCDEF'
	declare @s varchar(100)
	declare @h varchar(100)
	declare @j int
	set @l = 16
	set @j = 0 
	set @h = ''
	-- process all  bytes
	while @j < @l
	begin
	  set @j= @j + 1
	  -- get first character of byte
	  set @i = substring(cast(@jobId as varbinary(100)),@j,1)
	  -- get the first character
	  set @s = cast(substring(@digits,@i%16+1,1) as char(1))
	  -- shift over one character
	  set @i = @i/16 
	  -- get the second character
	  set @s = cast(substring(@digits,@i%16+1,1) as char(1)) + @s
	  -- build string of hex characters
	  set @h = @h + @s
	end

	-- Now get the SPID for the job
	DECLARE @SPIDJob int
	set @SPIDJob = (select spid from master..sysprocesses where substring(program_name,32,32) = @h and DATEADD("Minute", @MaxRunTimeMin, login_time) <= GETDATE())

	-- Kill the process
	if @SPIDJob <> 0 
		exec ('kill ' + @SPIDJob) 
END
GO
----------------------------- Add Job To minitor Block Tracking Job -----------------------------------
BEGIN TRANSACTION
DECLARE @ReturnCode INT
DECLARE @jobId1 BINARY(16)
DECLARE @DatabaseName varchar(255)

SET @DatabaseName = db_name()
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Block Tracking Job Monitor', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0,
		@owner_login_name = 'sa', 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@job_id = @jobId1 OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId1, @step_name=N'Block Tracking Job Monitor', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec usp_KillOverRunningJob ''Block Detection'',1', 
		@database_name= @DatabaseName, 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId1, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId1, @name=N'Monitor Block Tracking', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_time=0, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId1, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
---------------------------------------------------------------------------------------------------------- 
