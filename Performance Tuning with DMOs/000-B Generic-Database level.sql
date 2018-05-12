--------------------------------------------------1
--Flush the plan cache might be a good pracitce to examine 
--DBCC FREEPROCCACHE --Flushes cache for all databases
--DBCC FLUSHPROCINDB (<DatabaseID>) --Flushes cache for one database

--Determine the id of your database
-- DECLARE @intDBID INTEGER
-- SET @intDBID = ( SELECT dbid
                 -- FROM    master.dbo.sysdatabases
                 -- WHERE  name = 'mydatabasename'
               -- )
 ----Flush the procedure cache for your database
--DBCC FLUSHPROCINDB (@intDBID)


---------------------------------------------------2
--Gather details for database files
SELECT 
    [TYPE] = A.TYPE_DESC
    ,[FILE_Name] = A.name
    ,[FILEGROUP_NAME] = fg.name
    ,[File_Location] = A.PHYSICAL_NAME
    ,[FILESIZE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0)
	,[USEDSPACE_MB] = CONVERT(DECIMAL(10,2),CAST(FILEPROPERTY(A.NAME, 'SPACEUSED') AS INT)/128.0)
    ,[FREESPACE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0 - CAST(FILEPROPERTY(A.NAME, 'SPACEUSED') AS INT)/128.0)
    ,[FREESPACE_%] = CONVERT(DECIMAL(10,2),((A.SIZE/128.0 - CAST(FILEPROPERTY(A.NAME, 'SPACEUSED') AS INT)/128.0)/(A.SIZE/128.0))*100)
    ,[AutoGrow] = 'By ' + CASE is_percent_growth WHEN 0 THEN CAST(growth/128 AS VARCHAR(10)) + ' MB -' 
        WHEN 1 THEN CAST(growth AS VARCHAR(10)) + '% -' ELSE '' END 
        + CASE max_size WHEN 0 THEN 'DISABLED' WHEN -1 THEN ' Unrestricted' 
            ELSE ' Restricted to ' + CAST(max_size/(128*1024) AS VARCHAR(10)) + ' GB' END 
        + CASE is_percent_growth WHEN 1 THEN ' [autogrowth by percent, BAD setting!]' ELSE '' END
FROM sys.database_files A LEFT JOIN sys.filegroups fg ON A.data_space_id = fg.data_space_id 
order by A.TYPE , A.NAME;
Go

---------------------------------------------------3
--Gather database properties
select	name
		,recovery_model_desc
		,is_auto_shrink_on
		,is_auto_create_stats_on
		,is_auto_update_stats_on
from sys.databases
where name=DB_NAME()
Go
