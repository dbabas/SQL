USE tempdb

SET NOCOUNT ON

DECLARE @temp SQL_VARIANT
DECLARE @temp1 NVARCHAR(300)
DECLARE @DatabaseSetting TABLE (
	ID INT IDENTITY
	,Property VARCHAR(max)
	,Value SQL_VARIANT
	,Comment VARCHAR(max)
	);
DECLARE @x FLOAT
	,@y FLOAT
	,@xy FLOAT
	,@x2 FLOAT
	,@n FLOAT;

WITH CTE (
	col1
	,col2
	)
AS (
	SELECT ABS(DATEDIFF(day, GetDate(), MAX(Backup_finish_date))) AS DaysSinceBackup
		,Round(A.backup_size / 1048576, 0) AS [Database Size (MB)]
	FROM msdb.dbo.backupset A
	WHERE A.type = 'D'
		AND A.database_name = db_name()
		AND Round(A.backup_size / 1048576, 0) > 0
		AND A.is_snapshot = 0
	GROUP BY A.backup_size
	)
SELECT @n = COUNT(*)
	,@x = SUM(col1)
	,@y = SUM(col2)
	,@xy = SUM(col1 * col2)
	,@x2 = SUM(col1 * col1)
FROM CTE
WHERE col1 < 31

INSERT INTO @DatabaseSetting
VALUES (
	'Database Name'
	,DB_NAME()
	,''
	)

SET @temp = (
		SELECT SUM(FILEPROPERTY(name, 'SpaceUsed') / 128) AS [Space Used (MB)]
		FROM dbo.sysfiles
		WHERE (
				CASE STATUS & 0x40
					WHEN 0x40
						THEN 'Log'
					ELSE 'Data'
					END
				) = 'Data'
		)

INSERT INTO @DatabaseSetting
VALUES (
	'Database Size (MB)'
	,@temp
	,''
	)

------------ Getting Number of Data Files ------------
DECLARE @serverver TABLE (
	ID INT
	,Name VARCHAR(max)
	,Internal_Value VARCHAR(max)
	,Char_Value SQL_VARIANT
	);

INSERT INTO @serverver
EXEC ('master..xp_msver')

SET @temp = (
		SELECT SUM(CASE files.STATUS & 0x40
					WHEN 0x40
						THEN 0
					ELSE 1
					END) AS 'No of Datafile'
		FROM sys.sysfiles AS files
		INNER JOIN sys.master_files AS alt ON alt.file_id = files.fileid
		WHERE database_id = db_id()
			AND file_id <> 1
		)

IF @temp = 0
	SET @temp = 1
SET @temp1 = ''

IF (
		DB_NAME() NOT IN (
			'master'
			,'model'
			,'msdb'
			,'ReportServer'
			)
		)
	AND (
		(@temp > 8)
		OR (@temp < 8)
		AND (
			(
				SELECT cast([Char_Value] AS INT)
				FROM @serverver
				WHERE ID = 16
				) <> @temp
			)
		)
	SET @temp1 = 'Need to create multiple data file upto 8 to match the CPU cores for better disk I/O'

INSERT INTO @DatabaseSetting
VALUES (
	'Number of Data Files'
	,@temp
	,@temp1
	)

------------ End of Getting Number of Data Files ------------ 
IF (@n * @x2 - (@x * @x)) <> 0
BEGIN
	SET @temp = (
			SELECT Round(- 1 * ((@n * @xy) - (@x * @y)) / (@n * @x2 - (@x * @x)), 2)
			)

	INSERT INTO @DatabaseSetting
	VALUES (
		'Database Growth (MB/Day)'
		,@temp
		,''
		)
END

SET @temp = (
		SELECT COUNT(*)
		FROM sys.sysusers
		WHERE hasdbaccess = 1
			AND name NOT IN ('dbo')
		)

INSERT INTO @DatabaseSetting
VALUES (
	'Number of users'
	,@temp
	,''
	)

SET @temp = (
		SELECT suser_sname(owner_sid)
		FROM sys.databases
		WHERE [name] = DB_NAME()
		)

INSERT INTO @DatabaseSetting
VALUES (
	'Owner'
	,@temp
	,''
	)

SET @temp = DATABASEPROPERTYEX(DB_NAME(), 'Recovery')
SET @temp1 = ''

IF DB_NAME() IN (
		'master'
		,'tempdb'
		,'msdb'
		,'ReportServer'
		,'ReportServerTempDB'
		)
	AND @temp = 'FULL'
	SET @temp1 = 'Recovery model should always be SIMPLE for system database.'

IF DB_NAME() NOT IN (
		'master'
		,'tempdb'
		,'msdb'
		,'ReportServer'
		,'ReportServerTempDB'
		)
	AND @temp <> 'FULL'
	SET @temp1 = 'Recovery model should always be FULL for production database.'

INSERT INTO @DatabaseSetting
VALUES (
	'Recovery Model'
	,@temp
	,@temp1
	)

SET @temp = (
		SELECT compatibility_level
		FROM master.sys.databases
		WHERE (name = DB_NAME())
		)

INSERT INTO @DatabaseSetting
VALUES (
	'Compatibility Level'
	,@temp
	,''
	)

SET @temp = DATABASEPROPERTYEX(DB_NAME(), 'Collation')

INSERT INTO @DatabaseSetting
VALUES (
	'Collation'
	,@temp
	,CASE 
		WHEN SERVERPROPERTY('Collation') <> @temp
			THEN 'Server & Database Collations are different.'
		ELSE ''
		END
	)

SET @temp = DATABASEPROPERTYEX(DB_NAME(), 'IsParameterizationForced')

INSERT INTO @DatabaseSetting
VALUES (
	'Parameterization'
	,CASE 
		WHEN @temp = 0
			THEN 'Simple'
		ELSE 'Forced'
		END
	,''
	)

SET @temp = DATABASEPROPERTYEX(DB_NAME(), 'IsTruncLog')

INSERT INTO @DatabaseSetting
VALUES (
	'Truncate Log On Check Point'
	,CASE 
		WHEN @temp = 0
			THEN 'No'
		ELSE 'Yes'
		END
	,''
	)

SET @temp = (
		SELECT snapshot_isolation_state
		FROM master.sys.databases
		WHERE (name = DB_NAME())
		)

INSERT INTO @DatabaseSetting
VALUES (
	'Allow Snapshot Isolation'
	,CASE 
		WHEN @temp = 0
			THEN 'No'
		ELSE 'Yes'
		END
	,''
	)

SET @temp = (
		SELECT is_read_committed_snapshot_on
		FROM master.sys.databases
		WHERE (name = DB_NAME())
		)

INSERT INTO @DatabaseSetting
VALUES (
	'Read Committed Snapshot'
	,CASE 
		WHEN @temp = 0
			THEN 'No'
		ELSE 'Yes'
		END
	,''
	)

SET @temp = DATABASEPROPERTYEX(DB_NAME(), 'IsAutoClose')

INSERT INTO @DatabaseSetting
VALUES (
	'Auto Close'
	,CASE 
		WHEN @temp = 0
			THEN 'No'
		ELSE 'Yes'
		END
	,CASE 
		WHEN @temp <> 0
			THEN 'This should be set to NO to remove system overhead'
		ELSE ''
		END
	)

SET @temp = DATABASEPROPERTYEX(DB_NAME(), 'IsAutoCreateStatistics')
SET @temp1 = ''

IF DB_NAME() NOT IN (
		'master'
		,'tempdb'
		,'model'
		,'msdb'
		,'ReportServer'
		,'ReportServerTempDB'
		)
BEGIN
	IF @temp = 0
		SET @temp1 = 'Ensure reindex or update statistics job exists.'

	IF @temp = 1
		SET @temp1 = 'This should be switched off and replaced with a nightly job to reindex or update statistics'
END

IF DB_NAME() IN ('tempdb')
BEGIN
	IF @temp = 0
		SET @temp1 = 'Non standard setting. Need to set auto create statistics to Yes'
END

INSERT INTO @DatabaseSetting
VALUES (
	'Auto Create Statistics'
	,CASE 
		WHEN @temp = 0
			THEN 'No'
		ELSE 'Yes'
		END
	,@temp1
	)

SET @temp = DATABASEPROPERTYEX(DB_NAME(), 'IsAutoUpdateStatistics')
SET @temp1 = ''

IF DB_NAME() NOT IN (
		'master'
		,'tempdb'
		,'model'
		,'msdb'
		,'ReportServer'
		,'ReportServerTempDB'
		)
BEGIN
	IF @temp = 0
		SET @temp1 = 'Ensure reindex or update statistics job exists.'

	IF @temp = 1
		SET @temp1 = 'This should be switched off and replaced with a nightly job to reindex or update statistics'
END

IF DB_NAME() IN ('tempdb')
BEGIN
	IF @temp = 0
		SET @temp1 = 'Non standard setting. Need to set auto update statistics to Yes'
END

INSERT INTO @DatabaseSetting
VALUES (
	'Auto Update Statistics'
	,CASE 
		WHEN @temp = 0
			THEN 'No'
		ELSE 'Yes'
		END
	,@temp1
	)

SET @temp = DATABASEPROPERTYEX(DB_NAME(), 'IsAutoShrink')

INSERT INTO @DatabaseSetting
VALUES (
	'Auto Shrink'
	,CASE 
		WHEN @temp = 0
			THEN 'No'
		ELSE 'Yes'
		END
	,CASE 
		WHEN @temp <> 0
			THEN 'This should be set to NO to remove system overhead'
		ELSE ''
		END
	)

SET @temp = (
		SELECT is_ansi_null_default_on
		FROM master.sys.databases
		WHERE (name = DB_NAME())
		)

INSERT INTO @DatabaseSetting
VALUES (
	'ANSI NULL Default'
	,CASE 
		WHEN @temp = 0
			THEN 'No'
		ELSE 'Yes'
		END
	,''
	)

SET @temp = (
		SELECT is_recursive_triggers_on
		FROM master.sys.databases
		WHERE (name = DB_NAME())
		)

INSERT INTO @DatabaseSetting
VALUES (
	'Recursive triggers'
	,CASE 
		WHEN @temp = 0
			THEN 'No'
		ELSE 'Yes'
		END
	,''
	)

SET @temp = (
		SELECT is_trustworthy_on
		FROM master.sys.databases
		WHERE (name = DB_NAME())
		)

INSERT INTO @DatabaseSetting
VALUES (
	'Is Trustworthy'
	,CASE 
		WHEN @temp = 0
			THEN 'No'
		ELSE 'Yes'
		END
	,''
	)

SET @temp = (
		SELECT page_verify_option_desc
		FROM master.sys.databases
		WHERE (name = DB_NAME())
		)

INSERT INTO @DatabaseSetting
VALUES (
	'Page Verify'
	,@temp
	,CASE 
		WHEN cast(@temp AS VARCHAR(20)) <> 'CHECKSUM'
			THEN 'This must be set to CHECKSUM'
		ELSE ''
		END
	)

DECLARE @loginfo TABLE (
	RecoveryUnitId INT
	,[FileId] INT
	,[FileSize] VARCHAR(25)
	,[StartOffset] VARCHAR(25)
	,[FSeqNo] VARCHAR(25)
	,[Status] VARCHAR(25)
	,[Parity] VARCHAR(25)
	,[CreateLSN] VARCHAR(25)
	)

INSERT INTO @loginfo
EXEC ('dbcc loginfo')

SET @temp = (
		SELECT count(*) AS [VLogs]
		FROM @loginfo
		)

INSERT INTO @DatabaseSetting
VALUES (
	'Log Fragments'
	,@temp
	,CASE 
		WHEN @temp > 16
			THEN 'Log is fragmented, need to shrink and resizing to correct size'
		ELSE ''
		END
	)

SET @temp = (
		SELECT ISNULL(CONVERT(VARCHAR, MAX(backup_finish_date), 120), 'NEVER') AS 'Last Full Backup'
		FROM msdb.dbo.backupset
		WHERE type = 'D'
			AND database_name = db_name()
			AND is_snapshot = 0
		)
SET @temp1 = ''

IF (
		DB_NAME() NOT IN (
			'tempdb'
			,'model'
			,'ReportServerTempDB'
			)
		)
	AND (
		@temp = 'NEVER'
		OR cast(@temp AS DATETIME) <= DATEADD(d, - 7, GETDATE())
		)
	SET @temp1 = 'URGENT Backup Required! Ensure a backup job exists and executes successfully!'

INSERT INTO @DatabaseSetting
VALUES (
	'Last Full Backup'
	,@temp
	,@temp1
	)

SET @temp = (
		SELECT ISNULL(CONVERT(VARCHAR, MAX(STATS_DATE(i.object_id, i.index_id)), 120), 'NEVER') AS 'Last Stats Updated'
		FROM sys.indexes i
		WHERE IndexProperty(i.object_id, i.name, 'IsAutoStatistics') <> 1
			AND i.object_id > 255
		)
SET @temp1 = ''

IF (
		DB_NAME() NOT IN (
			'master'
			,'tempdb'
			,'model'
			,'msdb'
			,'ReportServer'
			,'ReportServerTempDB'
			)
		)
	AND (
		@temp = 'NEVER'
		OR cast(@temp AS DATETIME) <= DATEADD(d, - 7, GETDATE())
		)
	SET @temp1 = 'URGENT Statistics Update Required! Ensure a Update Statistics job exists and executes successfully!'

INSERT INTO @DatabaseSetting
VALUES (
	'Last Stats Updated'
	,@temp
	,@temp1
	)

/*
Select top(1) @temp = Round(avg_fragmentation_in_percent,2),@temp1 = fragment_count
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL)
Order By avg_fragmentation_in_percent Desc
Insert Into @DatabaseSetting VALUES('Max Index Fragmentation %',@temp)
Insert Into @DatabaseSetting VALUES('Index Fragments',@temp1)
*/
SET @temp = (
		SELECT Cast(100 * (
					SELECT Cast(SUM(a.used_pages - CASE 
									WHEN a.type <> 1
										THEN a.used_pages
									WHEN p.index_id < 2
										THEN a.data_pages
									ELSE 0
									END) AS DECIMAL)
					FROM sys.indexes AS i
					JOIN sys.partitions AS p ON p.object_id = i.object_id
						AND p.index_id = i.index_id
					JOIN sys.allocation_units AS a ON a.container_id = p.partition_id
					) / (
					SELECT 1 + Cast(SUM(a.used_pages) AS DECIMAL)
					FROM sys.indexes AS i
					JOIN sys.partitions AS p ON p.object_id = i.object_id
						AND p.index_id = i.index_id
					JOIN sys.allocation_units AS a ON a.container_id = p.partition_id
					) AS NUMERIC(20, 2))
		)

INSERT INTO @DatabaseSetting
VALUES (
	'% Space Taken by Index'
	,@temp
	,''
	)

DECLARE @IndexUse TABLE ([Total Usage] BIGINT)

INSERT INTO @IndexUse
SELECT CASE 
		WHEN dmv.user_seeks IS NULL
			THEN 0
		ELSE dmv.user_seeks
		END + CASE 
		WHEN dmv.user_scans IS NULL
			THEN 0
		ELSE dmv.user_scans
		END + CASE 
		WHEN dmv.user_lookups IS NULL
			THEN 0
		ELSE dmv.user_lookups
		END AS [Total Usage]
FROM sys.objects(NOLOCK) AS SO
INNER JOIN sys.sysindexes(NOLOCK) AS SI ON SO.object_id = SI.id
LEFT OUTER JOIN sys.dm_db_index_usage_stats AS dmv ON SI.id = dmv.object_id
	AND SI.indid = dmv.index_id
WHERE (
		dmv.database_id = db_id()
		OR dmv.database_id IS NULL
		)
	AND SO.type IN (
		'U'
		,'V'
		)
	AND (IndexProperty(SI.id, SI.name, 'IsStatistics') <> 1)

SET @temp = (
		SELECT count(*)
		FROM @IndexUse
		WHERE [Total Usage] = 0
		)

INSERT INTO @DatabaseSetting
VALUES (
	'Unused Index Count'
	,@temp
	,''
	)

SELECT Property
	,Value
	,Comment AS Comments
FROM @DatabaseSetting