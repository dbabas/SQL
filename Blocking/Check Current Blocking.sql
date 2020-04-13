-- Check Current Blocking
-- Note that Blocking Tsql might return NULL if the blocking request is complete and not active at the time of run
SELECT	dtl.request_session_id AS WaitingSessionID,
		der.blocking_session_id AS BlockingSessionID,
		dowt.resource_description,
		der.wait_type,
		dowt.wait_duration_ms,
		DB_NAME( dtl.resource_database_id) AS DatabaseName,
		dtl.resource_associated_entity_id AS WaitingAssociatedEntity,
		dtl.resource_type AS WaitingResourceType,
		dtl.request_type AS WaitingRequestType,
		dest.[text] AS WaitingTSql,
		dtlbl.request_type BlockingRequestType,
		destbl.[text] AS BlockingTsql
FROM	sys.dm_tran_locks AS dtl
			JOIN	sys.dm_os_waiting_tasks AS dowt
				ON dtl.lock_owner_address = dowt.resource_address
			JOIN	sys.dm_exec_requests AS der
				ON der.session_id = dtl.request_session_id CROSS APPLY sys.dm_exec_sql_text( der.sql_handle) AS dest
			LEFT JOIN	sys.dm_exec_requests derbl
				ON derbl.session_id = dowt.blocking_session_id OUTER APPLY sys.dm_exec_sql_text( derbl.sql_handle) AS destbl
			LEFT JOIN	sys.dm_tran_locks AS dtlbl
				ON derbl.session_id = dtlbl.request_session_id;


