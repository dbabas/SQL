USE tempdb
GO

SELECT db_name(database_id) AS [Database Name]
	,files.name AS 'File Name'
	,files.filename AS [Full Path]
	,(
		CASE files.STATUS & 0x40
			WHEN 0x40
				THEN 'Log'
			ELSE 'Data'
			END
		) AS 'Usage'
	,(
		CASE 
			WHEN files.groupid = 0
				THEN ''
			ELSE (
					SELECT name
					FROM sys.filegroups
					WHERE data_space_id = files.groupid
					)
			END
		) AS 'File Group'
	,(
		CASE 
			WHEN files.groupid = 0
				THEN ''
			ELSE (
					CASE 
						WHEN (
								SELECT is_default
								FROM sys.filegroups
								WHERE data_space_id = files.groupid
								) = 1
							THEN 'Yes'
						ELSE 'No'
						END
					)
			END
		) AS 'Default File Group'
	,alt.size / 128 AS [Original Size (MB)]
	,files.size / 128 AS [Current Size (MB)]
	,files.size / 128 - CAST(FILEPROPERTY(files.name, 'SpaceUsed') AS INT) / 128 AS [Available Space (MB)]
	,FILEPROPERTY(files.name, 'SpaceUsed') / 128 AS [Space Used (MB)]
	,CAST(CAST(FILEPROPERTY(files.name, 'SpaceUsed') AS DECIMAL) / CAST(files.size AS DECIMAL) * 100 AS NUMERIC(20, 2)) AS [% Used]
	,CASE 
		WHEN (
				files.maxsize = - 1
				AND files.growth = 0
				)
			THEN 'Off'
		ELSE 'On'
		END AS [Auto Growth]
	,'Maxsize' = (
		CASE files.maxsize
			WHEN - 1
				THEN N'Unlimited'
			ELSE convert(NVARCHAR(15), convert(BIGINT, files.maxsize) * 8 / 1024) + N' MB'
			END
		)
	,'Growth' = (
		CASE files.STATUS & 0x100000
			WHEN 0x100000
				THEN convert(NVARCHAR(3), files.growth) + N'%'
			ELSE convert(NVARCHAR(15), files.growth * 8 / 1024) + N' MB'
			END
		)
FROM sys.sysfiles AS files
INNER JOIN sys.master_files AS alt ON alt.file_id = files.fileid
WHERE database_id = db_id()
ORDER BY [fileid]