
/***  (c) 2012, STRYK System Improvement, Jörg Stryk   ***/
/***                   www.stryk.info                  ***/

-- Create Deadlock Trace - Existing file management

-- IMPORTANT NOTICE: DO NOT EXECUTE THIS SCRIPT! This is just showing a part of the "Deadlock Trace" JOB!


-- Check & Stop existing Trace
DECLARE @TraceID int, @cmd varchar(250), @no varchar(20)
SELECT @TraceID = [traceid] FROM ::fn_trace_getinfo(0)
WHERE CONVERT(varchar(250), [value]) LIKE '%Deadlock%'
IF @TraceID IS NOT NULL BEGIN
  EXEC sp_trace_setstatus @TraceID, 0  -- end
  EXEC sp_trace_setstatus @TraceID, 2  -- delete
END
SET @no = replace(replace(replace(convert(varchar(30), getdate(), 120), '-', ''), ':', ''), ' ', '_')
SET @cmd = 'c:\windows\system32\cmd.exe /c move "<Path>\ssi_DeadlockTrace.trc" "<Path>\ssi_DeadlockTrace_' + @no + '.trc"'
EXEC xp_cmdshell @cmd
