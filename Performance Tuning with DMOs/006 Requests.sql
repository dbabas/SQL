--Ill-designed queries, along with a failure to make proper use of indexes, will cause more data to be read more often than is
--necessary. If this data is read from the buffer cache, this is referred to as logical I/O, and can be an expensive operation.
--If the data is not in memory, and so needs to be read from disk (or, of course, if data needs to be written), this is physical
--I/O and is even more expensive.

--The information returned from sys.dm_exec_requests is real time; it's not returned after the fact.




SELECT [session_id]
      ,[request_id]
      ,[start_time]
      ,[status] --Running. Runnable (Signal wait). Suspended (Resource wait - Waiter list).
      ,[command]
      ,[sql_handle] --sql_handle column, identifies the currently executing batch or procedure (or one that is in the cache – see Chapter 3). We pass this handle to the sys.dm_exec_sql_text DMF, to obtain the SQL text of the executing batch.
      ,[statement_start_offset]
      ,[statement_end_offset]
      ,[plan_handle] --identifies the execution plan for the procedure or batch.
      ,[database_id]
      ,[user_id]
      ,[connection_id]
      ,[blocking_session_id] --lists the session_id that is blocking the request
      ,[wait_type] --the wait type for a request that is currently waiting for a resource being used by another process;
      ,[wait_time] --the amount of time the request has been waiting, in milliseconds, cumulatively
      ,[last_wait_type]
      ,[wait_resource] --the last resource that the session waited on
      ,[open_transaction_count]
      ,[open_resultset_count]
      ,[transaction_id]
      ,[context_info]
      ,[percent_complete] --can be used as a metric for completion status for certain operations
      ,[estimated_completion_time]
      ,[cpu_time] --the total amount of processing time spent on this request (in milliseconds)
      ,[total_elapsed_time]
      ,[scheduler_id]
      ,[task_address]
      ,[reads] --physical reads
      ,[writes] --physical writes
      ,[logical_reads] --lgical reads
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
      ,[row_count] --the number of rows that were processed for the request
      ,[prev_error]
      ,[nest_level]
      ,[granted_query_memory] --number of pages allocated to the execution of the request. Conversion from pages to MB: MB = (Number of 8 KB Pages)/1024 * 8
      ,[executing_managed_code]
      ,[group_id]
      ,[query_hash]
      ,[query_plan_hash]
      ,[statement_sql_handle]
      ,[statement_context_id]
      ,[dop]
      ,[parallel_worker_count]
      ,[external_script_request_id]
  FROM sys.dm_exec_requests