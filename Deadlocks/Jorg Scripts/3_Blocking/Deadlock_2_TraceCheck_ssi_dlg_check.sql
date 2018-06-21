
USE NAV_403_PTB
GO

-- Courtesy of http://www.midnightdba.com/DBARant/?p=570


/*

DROP TABLE [dbo].[ssi_DeadlockTrace]
GO

*/

IF NOT EXISTS(SELECT TOP 1 NULL FROM sys.tables WHERE name = 'ssi_DeadlockTrace') BEGIN
    CREATE TABLE [dbo].[ssi_DeadlockTrace](
	   [entry_no] [bigint] IDENTITY NOT NULL,
	   [DeadlockTime] [datetime] NOT NULL,

	   [VictimProcessID] [nvarchar](15) NULL,
	   [VictimLoginName] [nvarchar](128) NULL,
	   [VictimHostName] [nvarchar](128) NULL,
	   [VictimClientApp] [nvarchar](128) NULL,
	   [VictimLastBatchStarted] [nchar](23) NULL,
	   [VictimLockMode] [nvarchar](15) NULL,
	   [VictimIsolationLevel] [nvarchar](15) NULL,
	   [VictimWaitResource] [nvarchar](15) NULL,
	   [VictimObjName] [nvarchar](128) NULL,
	   [VictimLockModeHeld] [nvarchar](50) NULL,
	   [LiveLockModeRequest] [nvarchar](50) NULL,
	   [VictimProcName] [nvarchar](100) NULL,
	   [VictimExecStack] [varchar](max) NULL,
	   [VictimInputBuffer] [nvarchar](4000) NULL,
	   [LiveProcessID] [nvarchar](15) NULL,
	   [LiveLoginName] [nvarchar](128) NULL,
	   [LiveHostName] [nvarchar](128) NULL,
	   [LiveClientApp] [nvarchar](128) NULL,
	   [LiveLastBatchStarted] [nchar](23) NULL,
	   [LiveLockMode] [nvarchar](15) NULL,
	   [LiveIsolationLevel] [nvarchar](15) NULL,
	   [LiveWaitResource] [nvarchar](15) NULL,
	   [LiveObjName] [nvarchar](128) NULL,
	   [LiveLockModeHeld] [nvarchar](50) NULL,
	   [VictimLockModeRequest] [nvarchar](50) NULL,
	   [LiveProcName] [nvarchar](max) NULL,
	   [LiveExecStack] [varchar](max) NULL,
	   [LiveInputBuffer] [nvarchar](4000) NULL
    ) 
    ALTER TABLE [dbo].[ssi_DeadlockTrace] ADD CONSTRAINT [ssi_DeadlockTrace$0]
    PRIMARY KEY CLUSTERED ([entry_no])
END
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ssi_dlg_trace_check]') and objectproperty(id, N'IsProcedure') = 1)
drop procedure [dbo].ssi_dlg_trace_check
go

create procedure [dbo].ssi_dlg_trace_check
  @tracefile nvarchar(1000) = ''    -- SQL Deadlock Tracefile to be checked
 ,@append tinyint = 1               -- append data (0 = no, 1 = yes)
with encryption
as

set nocount on
set statistics io off

print '*********************************************************'
print '***              STRYK System Improvement             ***'
print '***    Performance Optimization & Troubleshooting     ***'
print '***  (c) 2014, STRYK System Improvement, Jörg Stryk   ***'
print '***                   www.Stryk.info                  ***'
print '*********************************************************'
print '              Version 1.01, Date: 28.11.2014             '
print ''

if @tracefile = '' begin
  raiserror ('Tracefile must be specified.', 15, 1)
  return
end
if @append not in (0,1) begin
  raiserror ('Invalid parameter for @append: %i.', 15, 1, @append)
  return
end

if @append = 0 truncate table [ssi_DeadlockTrace]

select [StartTime], [TextData] into #ssi_DeadlockTrace  
from ::fn_trace_gettable(@tracefile, default) 
where [TextData] is not null
and [StartTime] is not null

--select * from #ssi_DeadlockTrace order by StartTime

declare @xml xml, @time datetime
declare dl_cur cursor fast_forward for select [StartTime],[TextData] from #ssi_DeadlockTrace order by [StartTime]
open dl_cur
fetch from dl_cur into @time, @xml
while @@fetch_status = 0 begin

    BEGIN TRY

	   INSERT INTO [dbo].[ssi_DeadlockTrace]
           (
		  [DeadlockTime]
           ,[VictimProcessID]
           ,[VictimLoginName]
           ,[VictimHostName]
           ,[VictimClientApp]
           ,[VictimLastBatchStarted]
           ,[VictimLockMode]
           ,[VictimIsolationLevel]
           ,[VictimWaitResource]
           ,[VictimObjName]
           ,[VictimLockModeHeld]
           ,[LiveLockModeRequest]
           ,[VictimProcName]
           ,[VictimExecStack]
           ,[VictimInputBuffer]
           ,[LiveProcessID]
           ,[LiveLoginName]
           ,[LiveHostName]
           ,[LiveClientApp]
           ,[LiveLastBatchStarted]
           ,[LiveLockMode]
           ,[LiveIsolationLevel]
           ,[LiveWaitResource]
           ,[LiveObjName]
           ,[LiveLockModeHeld]
           ,[VictimLockModeRequest]
           ,[LiveProcName]
           ,[LiveExecStack]
           ,[LiveInputBuffer]
	   )
      
	  
       SELECT
	  
	  @time as DeadlockTime,

	  --Victim - Process
	  DeadlockList.Graphs.value('(process-list/process[1]/@spid)[1]', 'NVarChar(15)') AS VictimProcessID,
	  DeadlockList.Graphs.value('(process-list/process[1]/@loginname)[1]', 'NVarChar(128)') AS VictimLoginName,
	  DeadlockList.Graphs.value('(process-list/process[1]/@hostname)[1]', 'NVarChar(128)') AS VictimHostName,
	  DeadlockList.Graphs.value('(process-list/process[1]/@clientapp)[1]', 'NVarChar(128)') AS VictimClientApp,
	  DeadlockList.Graphs.value('(process-list/process[1]/@lastbatchstarted)[1]', 'NChar(23)') AS VictimLastBatchStarted,
	  DeadlockList.Graphs.value('(process-list/process[1]/@lockMode)[1]', 'NVarChar(15)') AS VictimLockMode,	 
  	  DeadlockList.Graphs.value('(process-list/process[1]/@isolationlevel)[1]', 'NVarChar(15)') AS VictimIsolationLevel,
	  DeadlockList.Graphs.value('(process-list/process[1]/@waitresource)[1]', 'NVarChar(15)') AS VictimWaitResource,	 	 

	  --Victim resource.
	  DeadlockList.Graphs.value('(resource-list/keylock[2]/@objectname)[1]', 'NVarChar(128)') AS VictimObjName,
	  DeadlockList.Graphs.value('(resource-list/keylock[2]/@mode)[1]', 'NVarChar(50)') AS VictimLockModeHeld,  
	  DeadlockList.Graphs.value('(resource-list/keylock[2]/waiter-list/waiter/@mode)[1]', 'NVarChar(50)') AS LiveLockModeRequest,

	  -- Victim inputbuffers
	  DeadlockList.Graphs.value('(process-list/process[1]/executionStack/frame/@procname)[1]', 'NVarChar(100)') AS VictimProcName,
	  DeadlockList.Graphs.value('(process-list/process[1]/executionStack/frame)[1]', 'VarChar(max)') AS VictimExecStack,
	  RTRIM(LTRIM(REPLACE(DeadlockList.Graphs.value('(process-list/process[1]/inputbuf)[1]', 'NVarChar(2048)'), NCHAR(10), N''))) AS VictimInputBuffer,

	  --

	  --Live - Process
	  DeadlockList.Graphs.value('(process-list/process[2]/@spid)[1]', 'NVarChar(15)') AS LiveProcessID,
	  DeadlockList.Graphs.value('(process-list/process[2]/@loginname)[1]', 'NVarChar(128)') AS LiveLoginName,
	  DeadlockList.Graphs.value('(process-list/process[2]/@hostname)[1]', 'NVarChar(128)') AS LiveHostName,
	  DeadlockList.Graphs.value('(process-list/process[2]/@clientapp)[1]', 'NVarChar(128)') AS LiveClientApp,
	  DeadlockList.Graphs.value('(pprocess-list/process[2]/@lastbatchstarted)[1]', 'NChar(23)') AS LiveLastBatchStarted,
	  DeadlockList.Graphs.value('(process-list/process[2]/@lockMode)[1]', 'NVarChar(15)') AS LiveLockMode,
    	  DeadlockList.Graphs.value('(process-list/process[2]/@isolationlevel)[1]', 'NVarChar(15)') AS LiveIsolationLevel,	 
	  DeadlockList.Graphs.value('(process-list/process[2]/@waitresource)[1]', 'NVarChar(15)') AS LiveWaitResource,	 	 
	  
	  --Live resource.
	  DeadlockList.Graphs.value('(resource-list/keylock[1]/@objectname)[1]', 'NVarChar(128)') AS LiveObjName,
	  DeadlockList.Graphs.value('(resource-list/keylock[1]/@mode)[1]', 'NVarChar(50)') AS LiveLockModeHeld,
	  DeadlockList.Graphs.value('(resource-list/keylock[1]/waiter-list/waiter/@mode)[1]', 'NVarChar(50)') AS VictimLockModeRequest,
	  
	  --Live Inputbuffers
	  DeadlockList.Graphs.value('(process-list/process[2]/executionStack/frame/@procname)[1]', 'NVarChar(max)') AS LiveProcName,
	  DeadlockList.Graphs.value('(process-list/process[2]/executionStack/frame)[1]', 'VarChar(max)') AS LiveExecStack,
	  RTrim(LTrim(Replace(DeadlockList.Graphs.value('(process-list/process[2]/inputbuf)[1]', 'NVARCHAR(2048)'), NChar(10), N''))) AS LiveInputBuffer	 

	  FROM @xml.nodes('/deadlock-list/deadlock') AS DeadlockList(Graphs)

    END TRY
    BEGIN CATCH
    END CATCH

  fetch from dl_cur into @time, @xml
end
close dl_cur
deallocate dl_cur
drop table #ssi_DeadlockTrace
go

-----

/*

TRUNCATE TABLE ssi_DeadlockTrace
GO

exec ssi_dlg_trace_check 'E:\PTB_Log\ssi_Deadlock_Trace.trc', 1
go

SELECT * FROM ssi_DeadlockTrace (nolock) order by entry_no
GO

*/