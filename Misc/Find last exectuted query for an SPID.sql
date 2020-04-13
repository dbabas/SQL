-- Find last executed query for an SPID

DECLARE @sqltext VARBINARY(128)
SELECT @sqltext = sql_handle
FROM sys.sysprocesses
WHERE spid =  --Enter the spid here
SELECT TEXT
FROM sys.dm_exec_sql_text(@sqltext)
GO