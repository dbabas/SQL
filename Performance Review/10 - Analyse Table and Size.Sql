SET NOCOUNT ON

IF OBJECT_ID('tempdb..#TheRecordCount') IS NOT NULL
	DROP TABLE #TheRecordCount

IF OBJECT_ID('tempdb..#TheObject') IS NOT NULL
	DROP TABLE #TheObject

IF OBJECT_ID('tempdb..#TheTableSize') IS NOT NULL
	DROP TABLE #TheTableSize

-- Insert into Temp Record Count Table
CREATE TABLE #TheRecordCount (
	[Object Name] NVARCHAR(200)
	,[No of rows] BIGINT
	,[No of Updates] BIGINT
	,[No of Indexes] INT
	,[TableID] NVARCHAR(200)
	,[TableName] NVARCHAR(200)
	,[Row x Index] BIGINT
	,[Total Space (KB)] INT
	,[Data Space Used (KB)] INT
	,[Index Space Used (KB)] INT
	)

INSERT INTO #TheRecordCount
SELECT OBJECT_NAME(id) AS 'Object Name'
	,MAX(rows) AS 'No of rows'
	,MAX(rowmodctr) AS 'No of Updates'
	,Count(id) AS 'No of Indexes'
	,SUBSTRING(OBJECT_NAME(id), 1, CHARINDEX('$', OBJECT_NAME(id)) + CHARINDEX('$', SUBSTRING(OBJECT_NAME(id), CHARINDEX('$', OBJECT_NAME(id)) + 1, len(OBJECT_NAME(id))))) AS [TableID]
	,SUBSTRING(OBJECT_NAME(id), CHARINDEX('$', OBJECT_NAME(id)) + 1, len(OBJECT_NAME(id))) AS [TableName]
	,CONVERT(bigint,MAX(rows)) * Count(id) AS 'Row x Index'
	,0 AS [Total Space (KB)]
	,0 AS [Data Space Used (KB)]
	,0 AS [Index Space Used (KB)]
FROM sysindexes
WHERE (id > 255)
	AND indexproperty(id, name, 'isautostatistics') = 0
	AND indexproperty(id, name, 'IsStatistics') = 0
GROUP BY id

-- Insert into Temp Table size Table
CREATE TABLE #TheTableSize (
	[Object Name] NVARCHAR(200)
	,[Data Space Used (KB)] INT
	,[Index Space Used (KB)] INT
	,[Total Space (KB)] INT
	)

DECLARE @PageSize FLOAT

SELECT @PageSize = v.low / 1024.0
FROM master.dbo.spt_values v
WHERE v.number = 1
	AND v.type = 'E' -- In (KB)

INSERT INTO #TheTableSize
SELECT Obj.name AS [Table Name]
	,ISNULL((
			SELECT @PageSize * SUM(CASE 
						WHEN a.type <> 1
							THEN a.used_pages
						WHEN p.index_id < 2
							THEN a.data_pages
						ELSE 0
						END)
			FROM sys.indexes AS i
			JOIN sys.partitions AS p ON p.object_id = i.object_id
				AND p.index_id = i.index_id
			JOIN sys.allocation_units AS a ON a.container_id = p.partition_id
			WHERE i.object_id = Obj.object_id
			), 0.0) AS [Data Space Used (KB)]
	,ISNULL((
			SELECT @PageSize * SUM(a.used_pages - CASE 
						WHEN a.type <> 1
							THEN a.used_pages
						WHEN p.index_id < 2
							THEN a.data_pages
						ELSE 0
						END)
			FROM sys.indexes AS i
			JOIN sys.partitions AS p ON p.object_id = i.object_id
				AND p.index_id = i.index_id
			JOIN sys.allocation_units AS a ON a.container_id = p.partition_id
			WHERE i.object_id = Obj.object_id
			), 0.0) AS [Index Space Used (KB)]
	,ISNULL((
			SELECT @PageSize * SUM(a.used_pages)
			FROM sys.indexes AS i
			JOIN sys.partitions AS p ON p.object_id = i.object_id
				AND p.index_id = i.index_id
			JOIN sys.allocation_units AS a ON a.container_id = p.partition_id
			WHERE i.object_id = Obj.object_id
			), 0.0) AS [Total Space (KB)]
FROM sys.objects AS Obj
WHERE type IN (
		'U'
		,'V'
		)
ORDER BY [name]

-- Insert into Temp Object Table
CREATE TABLE #TheObject (
	[TableNo] INT
	,[Company Name] NVARCHAR(200)
	,[NavTableName] NVARCHAR(200)
	,[TableID] NVARCHAR(200)
	,[SIFTTableID] NVARCHAR(200)
	)

----- For Old SIFT Tables -----
IF (
		SELECT [databaseversionno]
		FROM [$ndo$dbproperty]
		) < 93
BEGIN
	INSERT INTO #TheObject
	SELECT [ID] AS [TableNo]
		,[Company Name] AS [Company Name]
		,[Name] AS [NavTableName]
		,Replace([Company Name], '.', '_') + '$' + REPLACE(Replace([Name], '.', '_'), '/', '_') AS [TableID]
		,Replace([Company Name], '.', '_') + '$' + REPLACE(Replace([ID], '.', '_'), '/', '_') + '$' AS [SIFTTableID]
	FROM Object
	WHERE [Type] = 0
END
ELSE
BEGIN ----- For New Index Views -----
	INSERT INTO #TheObject
	SELECT TableNo
		,[Company Name]
		,[NavTableName]
		,TableID
		,[SIFTTableID]
	FROM (
		SELECT [ID] AS [TableNo]
			,c.Name AS [Company Name]
			,o.[Name] AS [NavTableName]
			,Replace(c.Name, '.', '_') + '$' + REPLACE(Replace(o.[Name], '.', '_'), '/', '_') AS [TableID]
			,Replace(c.Name, '.', '_') + '$' + REPLACE(Replace(o.[Name], '.', '_'), '/', '_') + '$' AS [SIFTTableID]
		FROM Object o
		LEFT OUTER JOIN Company c ON 1 = 1
		WHERE [Type] = 0
		
		UNION ALL
		
		SELECT [ID] AS [TableNo]
			,'' AS [Company Name]
			,o.[Name] AS [NavTableName]
			,REPLACE(Replace(o.[Name], '.', '_'), '/', '_') AS [TableID]
			,REPLACE(Replace(o.[Name], '.', '_'), '/', '_') + '$' AS [SIFTTableID]
		FROM Object o
		WHERE [Type] = 0
		) x
	INNER JOIN (
		SELECT x.name
		FROM (
			SELECT name
			FROM sys.tables
				--union
				--Select Name 
				--from Object
			) x
		INNER JOIN sys.tables z ON x.name = z.name collate Database_Default
		) p ON p.name = TableID collate Database_Default
END

-- Update temp Object Table (replacing leters) 
UPDATE #TheObject
SET [NavTableName] = Replace([NavTableName], '"', '_')

UPDATE #TheObject
SET [NavTableName] = Replace([NavTableName], '\', '_')

UPDATE #TheObject
SET [NavTableName] = Replace([NavTableName], '/', '_')

UPDATE #TheObject
SET [NavTableName] = Replace([NavTableName], '''', '_')

UPDATE #TheObject
SET [NavTableName] = Replace([NavTableName], '.', '_')

UPDATE #TheObject
SET [TableID] = Replace([TableID], '"', '_')

UPDATE #TheObject
SET [TableID] = Replace([TableID], '\', '_')

UPDATE #TheObject
SET [TableID] = Replace([TableID], '/', '_')

UPDATE #TheObject
SET [TableID] = Replace([TableID], '''', '_')

UPDATE #TheObject
SET [SIFTTableID] = Replace([SIFTTableID], '"', '_')

UPDATE #TheObject
SET [SIFTTableID] = Replace([SIFTTableID], '\', '_')

UPDATE #TheObject
SET [SIFTTableID] = Replace([SIFTTableID], '/', '_')

UPDATE #TheObject
SET [SIFTTableID] = Replace([SIFTTableID], '''', '_')

UPDATE #TheObject
SET [TableID] = [NavTableName]
WHERE [Company Name] = ''

UPDATE #TheObject
SET [SIFTTableID] = cast([TableNo] AS VARCHAR(50)) + '$'
WHERE [Company Name] = ''

-- Update the Space Reserved 
UPDATE #TheRecordCount
SET #TheRecordCount.[Total Space (KB)] = #TheTableSize.[Total Space (KB)]
	,#TheRecordCount.[Data Space Used (KB)] = #TheTableSize.[Data Space Used (KB)]
	,#TheRecordCount.[Index Space Used (KB)] = #TheTableSize.[Index Space Used (KB)]
FROM #TheRecordCount
INNER JOIN #TheTableSize ON (#TheTableSize.[Object Name] = #TheRecordCount.[Object Name])

-- Sum the Records
SELECT #TheObject.TableNo AS [Table No]
	,[Company Name]
	,BaseTable.[Object Name] AS [Table Name]
	,BaseTable.[No of rows] AS [Total Rows On Base Table]
	,BaseTable.[Total Space (KB)] + SUM(ISNULL(SIFTTable.[Total Space (KB)], 0)) AS [Total Space Used (Inc SIFT) (KB)]
	,BaseTable.[Data Space Used (KB)] AS [Data Space Used (KB)]
	,BaseTable.[Index Space Used (KB)] AS [Index Space Used (KB)]
	,BaseTable.[Total Space (KB)] AS [Base Table Size (KB)]
	,SUM(ISNULL(SIFTTable.[Total Space (KB)], 0)) AS [SIFT Table Size (KB)]
	,BaseTable.[No of Updates] AS [Total Updates On Base Table]
	,BaseTable.[No of Indexes]
	,SUM(ISNULL(SIFTTable.[No of rows], 0)) AS [Total Rows On SIFT Table]
	,SUM(ISNULL(SIFTTable.[No of Updates], 0)) AS [Total Updates On SIFT Table]
	,COUNT(SIFTTable.[Object Name]) AS [Number of SIFT]
	,cast(isnull(Cast(SUM(SIFTTable.[No of rows]) AS DECIMAL) / Cast((BaseTable.[No of rows] + 1) AS DECIMAL), 0) AS NUMERIC(20, 2)) AS [SIFT To Base Row Ratio]
	,cast(isnull(Cast(BaseTable.[No of Updates] AS DECIMAL) / Cast((BaseTable.[No of rows] + 1) AS DECIMAL), 0) AS NUMERIC(20, 2)) AS [Updates To Base Row Ratio]
	,cast(isnull(Cast(BaseTable.[Index Space Used (KB)] AS DECIMAL) / Cast((BaseTable.[Data Space Used (KB)] + 1) AS DECIMAL), 0) AS NUMERIC(20, 2)) AS [Index To Data Ratio]
	,BaseTable.[Row x Index] AS [Base Row x Index]
FROM #TheRecordCount AS BaseTable
RIGHT OUTER JOIN #TheObject ON BaseTable.[Object Name] = #TheObject.TableID
LEFT OUTER JOIN #TheRecordCount AS SIFTTable ON #TheObject.SIFTTableID = SIFTTable.TableID
GROUP BY #TheObject.TableNo
	,#TheObject.[Company Name]
	,BaseTable.[Object Name]
	,BaseTable.[No of rows]
	,BaseTable.[No of Indexes]
	,BaseTable.[Row x Index]
	,BaseTable.[Total Space (KB)]
	,BaseTable.[Data Space Used (KB)]
	,BaseTable.[Index Space Used (KB)]
	,BaseTable.[No of Updates]
ORDER BY [Base Row x Index] DESC