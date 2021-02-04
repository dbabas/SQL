-- Server Uptime
SELECT cast((datediff(hh, create_date, getdate())) / 24 AS VARCHAR(3)) + ' days, ' + cast((datediff(hh, create_date, getdate())) % 24 AS VARCHAR(2)) + ' hours' AS [SQL Server Service Uptime]
FROM sys.databases
WHERE name = 'tempdb'
GO

