SET NOCOUNT ON

DECLARE @serverver TABLE (
	ID INT
	,Name VARCHAR(max)
	,Internal_Value VARCHAR(max)
	,Char_Value SQL_VARIANT
	);

INSERT INTO @serverver
EXEC ('master..xp_msver')

DECLARE @ServerSetting TABLE (
	ID INT IDENTITY
	,Property VARCHAR(max)
	,Value SQL_VARIANT
	,Comment VARCHAR(max)
	);
DECLARE @temp SQL_VARIANT
DECLARE @temp1 NVARCHAR(300)

--------------------------------- Get Windows Detail -----------------------------------------------
-- Server Uptime
SELECT @temp = cast((datediff(hh, create_date, getdate())) / 24 AS VARCHAR(3)) + ' days, ' + cast((datediff(hh, create_date, getdate())) % 24 AS VARCHAR(2)) + ' hours'
FROM sys.databases
WHERE name = 'tempdb'

INSERT INTO @ServerSetting
VALUES (
	'SQL Server Service Uptime'
	,@temp
	,''
	)

SET @temp = (
		SELECT LEFT(CONVERT(VARCHAR, GETDATE(), 120), 19)
		)

INSERT INTO @ServerSetting
VALUES (
	'Sample Date & Time'
	,@temp
	,''
	)

SET @temp = (
		SELECT [Char_Value]
		FROM @serverver
		WHERE ID = 4
		)

INSERT INTO @ServerSetting
VALUES (
	'Windows Platform'
	,@temp
	,CASE 
		WHEN CHARINDEX('64', Cast(@temp AS VARCHAR(MAX))) = 0
			THEN 'Operating system needs to be upgraded to 64bit for better memory management'
		ELSE ''
		END
	)

SET @temp = (
		SELECT OSVersion = RIGHT(@@version, LEN(@@version) - 3 - charindex(' ON ', @@VERSION))
		)

INSERT INTO @ServerSetting
VALUES (
	'Windows Version'
	,@temp
	,''
	)

SET @temp = (
		SELECT [Char_Value]
		FROM @serverver
		WHERE ID = 16
		)

INSERT INTO @ServerSetting
VALUES (
	'Processor Count'
	,@temp
	,''
	)

SET @temp = (
		SELECT [Char_Value]
		FROM @serverver
		WHERE ID = 19
		)

INSERT INTO @ServerSetting
VALUES (
	'Physical Memory (MB)'
	,@temp
	,''
	)

------- Get Windows page file -------
DECLARE @OriginalSetting INT
DECLARE @TheResult TABLE ([Output] VARCHAR(1024))
DECLARE @SQLCmd VARCHAR(200)
DECLARE @TheString VARCHAR(1024)

------- Store the original settings -------
SET @OriginalSetting = (
		SELECT cast([value] AS INT)
		FROM sys.configurations
		WHERE [name] = 'xp_cmdshell'
		)


SET @TheString = NULL

SELECT @TheString = COALESCE(@TheString + ',', '') + [Output]
FROM @TheResult
WHERE [Output] LIKE '%.sys%'

INSERT INTO @ServerSetting
VALUES (
	'Windows Page File'
	,@TheString
	,''
	)

-------------------------- End of Get Windows Detail ----------------------------------------
-------------------------------- Get SQL Server Detail ----------------------------------------------
INSERT INTO @ServerSetting
VALUES (
	''
	,''
	,''
	)

INSERT INTO @ServerSetting
VALUES (
	'Server Name'
	,SERVERPROPERTY('servername')
	,''
	)

INSERT INTO @ServerSetting
VALUES (
	'Instance Name'
	,ISNULL(SERVERPROPERTY('InstanceName'), 'Default')
	,''
	)

SET @temp = '<Get the Service Account Name>'
SET @temp1 = ''

IF (
		SELECT object_id('sys.dm_server_services')
		) IS NOT NULL
BEGIN
	SET @temp = (
			SELECT service_account
			FROM sys.dm_server_services
			WHERE servicename LIKE '%SQL Server (%'
			)

	IF (CHARINDEX('NETWORKSERVICE', Cast(@temp AS VARCHAR(MAX))) <> 0)
		OR (CHARINDEX('LocalSystem', Cast(@temp AS VARCHAR(MAX))) <> 0)
		SET @temp1 = 'Service Account needs to be a domain account'
END

INSERT INTO @ServerSetting
VALUES (
	'Service Account'
	,@temp
	,@temp1
	)

INSERT INTO @ServerSetting
VALUES (
	'Collation'
	,SERVERPROPERTY('Collation')
	,CASE 
		WHEN SERVERPROPERTY('Collation') <> 'Latin1_General_CI_AS'
			THEN 'Non Statndard Server Collation in use'
		ELSE ''
		END
	)

SET @temp = (
		SELECT [Char_Value]
		FROM @serverver
		WHERE ID = 8
		)

INSERT INTO @ServerSetting
VALUES (
	'File Version'
	,@temp
	,''
	)

INSERT INTO @ServerSetting
VALUES (
	'Clustered'
	,CASE 
		WHEN SERVERPROPERTY('IsClustered') = 0
			THEN 'No'
		ELSE 'Yes'
		END
	,''
	)

SET @temp = (
		SELECT CONVERT(VARCHAR, min([login_time]), 120)
		FROM master..sysprocesses
		WHERE [lastwaittype] LIKE '%LAZY%'
		)

INSERT INTO @ServerSetting
VALUES (
	'Server Start Time'
	,@temp
	,''
	)

INSERT INTO @ServerSetting
VALUES (
	'License Type'
	,SERVERPROPERTY('LicenseType')
	,''
	)

INSERT INTO @ServerSetting
VALUES (
	'Edition'
	,SERVERPROPERTY('Edition')
	,CASE 
		WHEN CHARINDEX('Developer', Cast(SERVERPROPERTY('Edition') AS VARCHAR(MAX))) = 1
			THEN 'Developer Edition should not be used for production'
		ELSE ''
		END
	)

INSERT INTO @ServerSetting
VALUES (
	'Engine Edition'
	,SERVERPROPERTY('EngineEdition')
	,''
	)

INSERT INTO @ServerSetting
VALUES (
	'Major Version'
	,(@@microsoftversion / 0x1000000) & 0xFF
	,''
	)

INSERT INTO @ServerSetting
VALUES (
	'Version'
	,SERVERPROPERTY('ProductVersion')
	,''
	)

INSERT INTO @ServerSetting
VALUES (
	'Product Level'
	,SERVERPROPERTY('ProductLevel')
	,''
	)

---------------------------- End of Getting SQL Server Detail ------------------------------------------
--------------------------------- Get SQL Server Settings -----------------------------------------------
INSERT INTO @ServerSetting
VALUES (
	''
	,''
	,''
	)

INSERT INTO @ServerSetting
VALUES (
	'Server Authentication'
	,CASE 
		WHEN SERVERPROPERTY('IsIntegratedSecurityOnly') = 1
			THEN 'Windows'
		ELSE 'SQL Server & Windows'
		END
	,CASE 
		WHEN @temp = 1
			THEN 'For retail implimentation need to set authentication to SQL Server & Windows'
		ELSE ''
		END
	)

SET @temp = (
		SELECT [value]
		FROM sys.sysconfigures
		WHERE config = 1543
		)

INSERT INTO @ServerSetting
VALUES (
	'Min Server Memory (MB)'
	,@temp
	,CASE 
		WHEN @temp = 0
			THEN 'Need to set the min server memory appropriately'
		ELSE ''
		END
	)

SET @temp1 = (
		SELECT cast([Char_Value] AS VARCHAR(max))
		FROM @serverver
		WHERE ID = 19
		)
SET @temp1 = left(@temp1, Charindex('(', @temp1) - 1)
SET @temp = (
		SELECT [value]
		FROM sys.sysconfigures
		WHERE config = 1544
		)
SET @TheString = ''

IF @temp > 1073741824
	SET @TheString = 'Need to set the max server memory appropriately'
ELSE IF @temp >= cast(@temp1 AS BIGINT)
	SET @TheString = 'Should not set max server memory to equal physical memory or more'

INSERT INTO @ServerSetting
VALUES (
	'Max Server Memory (MB)'
	,@temp
	,@TheString
	)

SET @temp = (
		SELECT [value]
		FROM sys.sysconfigures
		WHERE config = 503
		)

INSERT INTO @ServerSetting
VALUES (
	'Max Worker Threads'
	,@temp
	,CASE 
		WHEN @temp <> 0
			THEN 'Non standard setting, better to set this to the default value of 0'
		ELSE ''
		END
	)

SET @temp = (
		SELECT [value]
		FROM sys.sysconfigures
		WHERE config = 1569
		)

INSERT INTO @ServerSetting
VALUES (
	'Blocked process threshold'
	,@temp
	,''
	)

SET @temp = (
		SELECT [value]
		FROM sys.sysconfigures
		WHERE config = 106
		)

INSERT INTO @ServerSetting
VALUES (
	'No of Locks'
	,@temp
	,''
	)

SET @temp = (
		SELECT [value]
		FROM sys.sysconfigures
		WHERE config = 1548
		)
SET @TheString = ''

IF (@temp <> 0)
	AND (
		(
			SELECT CHARINDEX('64', Cast([Char_Value] AS VARCHAR(max)))
			FROM @serverver
			WHERE ID = 4
			) <> 0
		)
	SET @TheString = 'There is no need to enable AWE in 64bit server'

IF (@temp = 0)
	AND (
		(
			SELECT CHARINDEX('64', Cast([Char_Value] AS VARCHAR(max)))
			FROM @serverver
			WHERE ID = 4
			) = 0
		)
	AND (cast(@temp1 AS INT) > 4096)
	SET @TheString = 'Need to enable AWE in 32bit server to access more than 4GB of memory'

INSERT INTO @ServerSetting
VALUES (
	'AWE Enabled'
	,CASE 
		WHEN @temp = 0
			THEN 'No'
		ELSE 'Yes'
		END
	,@TheString
	)

SET @temp = (
		SELECT [value]
		FROM sys.sysconfigures
		WHERE config = 1562
		)

INSERT INTO @ServerSetting
VALUES (
	'CLR Enabled'
	,CASE 
		WHEN @temp = 0
			THEN 'No'
		ELSE 'Yes'
		END
	,CASE 
		WHEN @temp <> 0
			THEN 'Non standard setting. Need explanation why CLR is enabled'
		ELSE ''
		END
	)

SET @temp = (
		SELECT [value]
		FROM sys.sysconfigures
		WHERE config = 1546
		)

INSERT INTO @ServerSetting
VALUES (
	'Use Windows Fibres'
	,CASE 
		WHEN @temp = 0
			THEN 'No'
		ELSE 'Yes'
		END
	,CASE 
		WHEN @temp <> 0
			THEN 'Non standard setting. Need to set this setting to No'
		ELSE ''
		END
	)

SET @temp = (
		SELECT [value]
		FROM sys.sysconfigures
		WHERE config = 16391
		)

INSERT INTO @ServerSetting
VALUES (
	'Ad Hoc Distributed Queries Enabled'
	,CASE 
		WHEN @temp = 0
			THEN 'No'
		ELSE 'Yes'
		END
	,CASE 
		WHEN @temp <> 0
			THEN 'Non standard setting. Need explanation why this is enabled'
		ELSE ''
		END
	)

SET @temp = (
		SELECT [value]
		FROM sys.sysconfigures
		WHERE config = 1581
		)

INSERT INTO @ServerSetting
VALUES (
	'Optimize for ad hoc workloads'
	,CASE 
		WHEN @temp = 1
			THEN 'Yes'
		ELSE 'No'
		END
	,CASE 
		WHEN @temp <> 1
			THEN 'Need to set this property to Yes for better performance'
		ELSE ''
		END
	)

SET @temp = (
		SELECT [value]
		FROM sys.sysconfigures
		WHERE config = 16385
		)

INSERT INTO @ServerSetting
VALUES (
	'SQL Mail Enabled'
	,CASE 
		WHEN @temp = 0
			THEN 'No'
		ELSE 'Yes'
		END
	,CASE 
		WHEN @temp <> 0
			THEN 'Non standard setting. Need explanation why this is enabled'
		ELSE ''
		END
	)

SET @temp = (
		SELECT [value]
		FROM sys.sysconfigures
		WHERE config = 1517
		)

INSERT INTO @ServerSetting
VALUES (
	'Boost SQL Server Priority'
	,CASE 
		WHEN @temp = 0
			THEN 'No'
		ELSE 'Yes'
		END
	,CASE 
		WHEN @temp <> 0
			THEN 'Need to set this setting to No'
		ELSE ''
		END
	)

SET @temp = (
		SELECT [value]
		FROM sys.sysconfigures
		WHERE config = 1538
		)

INSERT INTO @ServerSetting
VALUES (
	'Cost Threshold for Parallelism'
	,@temp
	,''
	)

SET @temp = (
		SELECT [value]
		FROM sys.sysconfigures
		WHERE config = 1539
		)

INSERT INTO @ServerSetting
VALUES (
	'Max Degree of Parallelism'
	,@temp
	,CASE 
		WHEN @temp = 0
			THEN 'For Dynamics. NAV implimentation need to set this to 1 and change stored procedure and other direct SQL query to have Option (maxdop 0) hint'
		ELSE ''
		END
	)

SET @temp = (
		SELECT [value]
		FROM sys.sysconfigures
		WHERE config = 1568
		)

INSERT INTO @ServerSetting
VALUES (
	'Default Trace Enabled'
	,CASE 
		WHEN @temp = 0
			THEN 'No'
		ELSE 'Yes'
		END
	,CASE 
		WHEN @temp = 0
			THEN 'Non standard setting. Need to enable default trace for better troubleshooting'
		ELSE ''
		END
	)

SET @temp = (
		SELECT CASE 
				WHEN EXISTS (
						SELECT *
						FROM sys.traces
						WHERE is_default = 0
						)
					THEN 1
				ELSE 0
				END
		)

IF @temp = 1
	INSERT INTO @ServerSetting
	VALUES (
		'Other Trace Enabled'
		,CASE 
			WHEN @temp = 0
				THEN 'No'
			ELSE 'Yes'
			END
		,'Non standard setting. Running profiler trace may degrade system performance'
		)

------- Get Global Trace -------
DECLARE @GlobalTrace TABLE (
	TraceFlag NVARCHAR(max)
	,STATUS INT
	,GLOBAL INT
	,Session INT
	);

INSERT INTO @GlobalTrace
EXEC ('DBCC TRACESTATUS(-1)')

SET @TheString = NULL

SELECT @TheString = COALESCE(@TheString + '|', '') + [TraceFlag]
FROM @GlobalTrace
WHERE STATUS = 1

INSERT INTO @ServerSetting
VALUES (
	'Global Trace'
	,CASE 
		WHEN @TheString IS NULL
			THEN ''
		ELSE @TheString
		END
	,''
	)

------- End of Getting Global Trace -------
SELECT Property
	,Value
	,Comment AS Comments
FROM @ServerSetting