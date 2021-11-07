/****** Object:  StoredProcedure [dbo].[SQLMaintenance]    Script Date: 06/11/2018 13:43:53 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


    CREATE PROCEDURE [dbo].[SQLMaintenance] (
	@MinPages INT = 10
	,@Actionpct INT = 10
	,@Rebuildpct INT = 30
	,@MaxStatsDate int = 5
	,@debug int = 0
	)
--	WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @Online INT
		,@Maxx INT
		,@editiontxt VARCHAR(9)
		,@edition INT
		,@x int
		,@sql varchar(max)
		,@t int
		,@obj int
		,@objname varchar(250)

	SET @editiontxt = convert(VARCHAR(50), SERVERPROPERTY('edition'))

	SELECT @edition = CASE 
			WHEN UPPER(@editiontxt) IN (
					'DEVELOPER'
					,'ENTERPRIS'
                    /*, 'SQL Azure' -- removed as was causing locks on tables */
					)
				THEN 1
			ELSE 0
			END

	IF OBJECT_ID('tempdb..#work_to_do') IS NOT NULL
		DROP TABLE #work_to_do

	CREATE TABLE #work_to_do (
		[ID] INT Identity(1, 1)
		,objectid INT
		,ObjectName VARCHAR(100)
		,indexid INT
		,IndexName VARCHAR(100)
		,schemaid INT
		,partitionnum INT
		,RowCnt BIGINT
		,Pages BIGINT
		,frag DECIMAL
		)

	INSERT INTO #work_to_do (
		objectid
		,ObjectName
		,indexid
		,IndexName
		,schemaid
		,partitionnum
		,RowCnt
		,Pages
		,frag
		)
	SELECT i.object_id AS objectid
		,OBJECT_NAME(i.object_id)
		,i.index_id AS indexid
		,a.NAME
		,o.schema_id AS schemaid
		,i.partition_number AS partitionnum
		,a.rowcnt
		,i.page_count
		,i.avg_fragmentation_in_percent AS frag
	FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') i
	INNER JOIN sys.objects o
		ON o.[object_id] = i.[object_id]
	INNER JOIN sys.sysindexes a
		ON a.id = i.object_id
			AND a.indid = i.index_id
	WHERE avg_fragmentation_in_percent >= @Actionpct
		and index_type_desc IN ('CLUSTERED INDEX' ,'NONCLUSTERED INDEX' ) 
		AND alloc_unit_type_desc ='IN_ROW_DATA'
		AND page_count >= CASE 
			WHEN @MinPages > 0
				THEN @MinPages
			ELSE page_count
			END
	ORDER BY frag DESC
	
	if @debug = 2 
		SELECT * FROM #work_to_do

	SET @x = 1
	SET @Maxx = (
			SELECT MAX(ID)
			FROM #work_to_do
			)

	WHILE @x <= @Maxx
	BEGIN
		Select @sql =  'ALTER INDEX [' + i.NAME + '] ON [' + SCHEMA_NAME(w.schemaid) + '].[' + Object_NAME(w.objectid) + ']' + CASE 
						WHEN @edition = 1
							AND w.frag < @Rebuildpct
							THEN ' REORGANIZE '
						ELSE ' REBUILD '
						END + CASE 
						WHEN NOT i.fill_factor IN (
								0
								,100
								)
							THEN 'with (Fillfactor = 100)'
						ELSE ''
						END
				,@obj = w.ID
				,@objname = Object_NAME(w.objectid)
		FROM #work_to_do w
		INNER JOIN sys.indexes i
			ON i.object_id = w.objectid
				AND i.index_id = w.indexid
		WHERE ID = @x

		
		If @debug in (1,2)
			PRINT @sql 
		If @debug in (0,2) begin
			IF EXISTS (	SELECT p.[object_id]
						FROM sys.dm_tran_locks l
							JOIN sys.partitions p ON l.resource_associated_entity_id = p.hobt_id
						WHERE p.[object_id] = @obj
					) BEGIN
				If @debug = 2
					PRINT (@objname + ' - Table Locked!!!!!')
				WAITFOR DELAY '00:00:10'
				IF NOT EXISTS (	SELECT p.[object_id]
								FROM sys.dm_tran_locks l
								JOIN sys.partitions p ON l.resource_associated_entity_id = p.hobt_id
								WHERE p.[object_id] = @obj) BEGIN
					EXEC (@sql)
				END ELSE BEGIN
					If @debug = 2
						PRINT (@objname + ' - Reindex skipped - Table Locked')
				END
			END else begin
				EXEC (@sql)
			END
		END
				
		
			
			
			--If @debug = 0
			--	EXEC (@sql)
			--If @debug = 1
			--	PRINT @sql 
			--If @debug = 2 begin 
			--	Print @sql
			--	EXEC (@sql)
			--END

		SET @x = @x + 1
	END

	/*
If (@MaxDuration > 0) and (DATEDIFF(mi,@StartTime,GETUTCDATE()) > @MaxDuration) 
	RETURN
*/
	IF OBJECT_ID('tempdb..#tablelist') IS NOT NULL
	BEGIN
		DROP TABLE #tablelist
	END

	CREATE TABLE #tablelist (
		ID INT identity(1, 1)
		,ObjectID VARCHAR(250)
		,ObjectName VARCHAR(250)
		,IndexID VARCHAR(250)
		,IndexName VARCHAR(250)
		,LastStatsDate DATETIME
		)

	INSERT INTO #tablelist (
		ObjectID
		,ObjectName
		,IndexID
		,IndexName
		,LastStatsDate
		)
	SELECT u.[Object_ID]
		,OBJECT_NAME(u.[object_id])
		,u.[index_id]
		,i.NAME
		,STATS_DATE(u.object_id, u.index_id)
	FROM sys.dm_db_index_usage_stats u
	INNER JOIN sys.indexes i
		ON i.object_id = u.object_id
			AND i.index_id = u.index_id
	WHERE database_id = DB_ID()
		AND user_updates > 0
		AND STATS_DATE(u.object_id, u.index_id) <= dateadd(d, - @MaxStatsDate, getutcdate())


	SET @t = (
			SELECT MAX(ID)
			FROM #tablelist
			)
	SET @x = 1

	WHILE @x < @t BEGIN
		SET @SQL = (SELECT 'update statistics [' + ObjectName + '] [' + IndexName + '] with FULLSCAN'
					FROM #tablelist
					WHERE ID = @x)

			--If @debug = 0
			--	EXEC (@sql)
			--If @debug = 1
			--	PRINT @sql 
			--If @debug = 2 begin 
			--	Print @sql
			--	EXEC (@sql)
			--END

		If @debug in (1,2) begin
			PRINT @sql 
		end
		If @debug in (0,2) begin
			IF EXISTS (	SELECT p.[object_id]
						FROM sys.dm_tran_locks l
							JOIN sys.partitions p ON l.resource_associated_entity_id = p.hobt_id
						WHERE p.[object_id] = @obj
					) BEGIN
				PRINT (@objname + ' - Table Locked!!!!!')
				WAITFOR DELAY '00:00:10'
				IF NOT EXISTS (	SELECT p.[object_id]
								FROM sys.dm_tran_locks l
								JOIN sys.partitions p ON l.resource_associated_entity_id = p.hobt_id
								WHERE p.[object_id] = @obj) BEGIN
					EXEC (@sql)
				END ELSE BEGIN
					PRINT (@objname + ' - Reindex skipped - Table Locked')
				END
			END
		END


		SET @x = @x + 1
	END
END

GO


