-- Server-scoped information about physical connections into SQL Server. It is "network-centric" in the information it returns.
SELECT [session_id]
      ,[most_recent_session_id]
      ,[connect_time] --sp_who doesn't show this
      ,[net_transport]
      ,[protocol_type]
      ,[protocol_version]
      ,[endpoint_id]
      ,[encrypt_option] --Boolean to identify wether encryption is used on this connection
      ,[auth_scheme]
      ,[node_affinity]
      ,[num_reads] --number of packet reads that have occurred across this connection; note that this is not the same as sys.dm_exec_session.reads
      ,[num_writes] --number of data packet writes that have occurred over this connection; note that this is not the same as sys.dm_exec_session.writes
      ,[last_read]
      ,[last_write]
      ,[net_packet_size]
      ,[client_net_address] --Client IP address
      ,[client_tcp_port]
      ,[local_net_address]
      ,[local_tcp_port]
      ,[connection_id]
      ,[parent_connection_id]
      ,[most_recent_sql_handle]
  FROM [master].[sys].[dm_exec_connections]