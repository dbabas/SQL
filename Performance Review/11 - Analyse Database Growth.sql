SELECT database_name AS Database_Name
	,[user_name] AS [Backup User]
	,ISNULL(STR(ABS(DATEDIFF(day, GetDate(), MAX(Backup_finish_date)))), 'NEVER') AS DaysSinceBackup
	,ISNULL(Convert(CHAR(10), MAX(backup_finish_date), 120), 'NEVER') AS BackupDate
	,Round(A.backup_size / 1048576, 0) AS [Database Size (MB)]
FROM msdb.dbo.backupset A
WHERE A.type = 'D'
	AND A.database_name = db_name()
	AND Round(A.backup_size / 1048576, 0) > 0
	AND A.is_snapshot = 0
GROUP BY [user_name]
	,database_name
	,A.backup_size
ORDER BY DaysSinceBackup DESC