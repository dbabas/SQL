--  Who is running what at this instant
SELECT  dest.text AS [Command text] , --this is the complete T-SQL batch for the request
        des.login_time ,
        des.[host_name] ,
        des.[program_name] ,
        der.session_id ,
        dec.client_net_address ,
        der.status ,
        der.command ,
        DB_NAME(der.database_id) AS DatabaseName,
		der.statement_start_offset/2 as start_offset ,
        (Case when der.statement_end_offset<>-1 then der.statement_end_offset/2 else der.statement_end_offset end) as end_offset ,
		SUBSTRING(dest.text, der.statement_start_offset / 2,
                  ( CASE WHEN der.statement_end_offset = -1
                         THEN DATALENGTH(dest.text)
                         ELSE der.statement_end_offset
                    END - der.statement_start_offset ) / 2) AS statement_executing -- this is the exact statement executed at the moment

FROM    sys.dm_exec_requests der
        INNER JOIN sys.dm_exec_connections dec
                       ON der.session_id = dec.session_id
        INNER JOIN sys.dm_exec_sessions des
                       ON des.session_id = der.session_id
        CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS dest
WHERE   des.is_user_process = 1
		AND der.session_id <> @@spid --to exclude the current session.
