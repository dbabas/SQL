--Microsoft recommends using sys.dm_exec_sessions to initially identify "sessions of interest"
--
--An interesting point to note is that the values in the sessions DMV are updated only when their associated requests have finished 
--executing, whereas the requests DMV provides a real-time view of what is happening right now on your system.
--
--Note that many of the columns in this DMV may have a NULL value associated with them if the sessions are internal to Microsoft SQL Server (those with session_id < 51).

SELECT [session_id]
      ,[login_time]
      ,[host_name]
      ,[program_name]
      ,[host_process_id]
      ,[client_version]
      ,[client_interface_name]
      ,[security_id]
      ,[login_name]
      ,[nt_domain]
      ,[nt_user_name]
      ,[status]
      ,[context_info]
      ,[cpu_time] --amount of CPU time, recorded in milliseconds, used by all of the requests associated with this session
      ,[memory_usage] --number of 8 KB pages of memory used by all requests associated with this session
      ,[total_scheduled_time] --total time in milliseconds that the requests associated with this session were scheduled for execution
      ,[total_elapsed_time] --time in milliseconds since the session was initiated
      ,[endpoint_id]
      ,[last_request_start_time]
      ,[last_request_end_time]
      ,[reads] --total number of reads from disk performed by all requests in the session
      ,[writes] --total number of writes performed by all requests in the session.
      ,[logical_reads]	--number of reads from the data cache performed by all requests associated with the session.
						--The I/O from an instance of SQL Server is divided into logical and physical I/O. A logical read occurs every time the database engine requests a page from the buffer cache. If the page is not currently in the buffer cache, a physical read is then performed to read the page into the buffer cache. If the page is currently in the cache, no physical read is generated; the buffer cache simply uses the page already in memory.
      ,[is_user_process]
      ,[text_size]
      ,[language]
      ,[date_format]
      ,[date_first]
      ,[quoted_identifier]
      ,[arithabort]
      ,[ansi_null_dflt_on]
      ,[ansi_defaults]
      ,[ansi_warnings]
      ,[ansi_padding]
      ,[ansi_nulls]
      ,[concat_null_yields_null]
      ,[transaction_isolation_level]
      ,[lock_timeout]
      ,[deadlock_priority]
      ,[row_count]
      ,[prev_error]
      ,[original_security_id]
      ,[original_login_name]
      ,[last_successful_logon]
      ,[last_unsuccessful_logon]
      ,[unsuccessful_logons]
      ,[group_id]
      ,[database_id]
      ,[authenticating_database_id]
      ,[open_transaction_count]
  FROM [master].[sys].[dm_exec_sessions]