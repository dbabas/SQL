
-- Create a Queue
declare @rc int
declare @TraceID int
declare @maxfilesize bigint
set @maxfilesize = 100 

-- Please replace the text InsertFileNameHere, with an appropriate
-- filename prefixed by a path, e.g., c:\MyFolder\MyTrace. The .trc extension
-- will be appended to the filename automatically. If you are writing from
-- remote server to local drive, please use UNC path and make sure server has
-- write access to your network share

exec @rc = sp_trace_create @TraceID output, 0, N'H:\SSI\PTB_Log\ssi_Session_Trace', @maxfilesize, NULL 
if (@rc != 0) goto error

-- Client side File and Table cannot be scripted

-- Set the events
declare @on bit
set @on = 1
exec sp_trace_setevent @TraceID, 12, 1, @on
exec sp_trace_setevent @TraceID, 12, 11, @on
exec sp_trace_setevent @TraceID, 12, 8, @on
exec sp_trace_setevent @TraceID, 12, 10, @on
exec sp_trace_setevent @TraceID, 12, 12, @on
exec sp_trace_setevent @TraceID, 12, 14, @on
exec sp_trace_setevent @TraceID, 12, 35, @on
exec sp_trace_setevent @TraceID, 12, 51, @on


-- Set the Filters
declare @intfilter int
declare @bigintfilter bigint

exec sp_trace_setfilter @TraceID, 1, 0, 6, N'/*%'
exec sp_trace_setfilter @TraceID, 1, 0, 7, N'%connection%'
exec sp_trace_setfilter @TraceID, 10, 0, 6, N'%NAV%'
-- Set the trace status to start
exec sp_trace_setstatus @TraceID, 1

-- display trace id for future references
select TraceID=@TraceID
goto finish

error: 
select ErrorCode=@rc

finish: 
go

---

/*

-- Stopping running Trace
if exists(select * from ::fn_trace_getinfo(0) where [property] = 2 and [value] = 'H:\SSI\PTB_Log\ssi_Session_Trace.trc')
  exec [MEDEL].dbo.ssi_trace_stop 'H:\SSI\PTB_Log\ssi_Session_Trace.trc'

-- Saving old Output
declare @cmd varchar(200), @no varchar(20)
set @no = replace(replace(replace(convert(varchar(30), getdate(), 120), '-', ''), ':', ''), ' ', '_')
set @cmd = 'c:\windows\system32\cmd.exe /c move "H:\SSI\PTB_Log\ssi_Session_Trace.trc" "H:\SSI\PTB_Log\ssi_Session_Trace_' + @no + '.trc"'
print @cmd
exec xp_cmdshell @cmd


*/
