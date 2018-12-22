-- Transact-SQL script to analyse the database size growth using backup history.
-- Source: https://goo.gl/cwVCYL

DECLARE @endDate datetime, @months smallint, @databaseName varchar(10); 
SET @endDate = GetDate();  -- Include in the statistic all backups from today 
SET @months = 12;           -- back to the last x months.
SEt @databaseName = 'DOMOS'; -- Database Name.
 
SELECT	min(BS.database_name) AS DatabaseName 
        ,YEAR(BS.backup_start_date) AS Year
		,MONTH(BS.backup_start_date) as Month
        ,CONVERT(numeric(10, 1), AVG(BF.file_size / 1048576.0)) AS AvgSizeMB
FROM msdb.dbo.backupset as BS 
    INNER JOIN 
		(select backup_set_id
				,sum(file_size) as file_size
		from msdb.dbo.backupfile
		--where file_type='D' --Uncomment to get only data files
		group by backup_set_id)  AS BF 
        ON BS.backup_set_id = BF.backup_set_id 
WHERE BS.database_name =  @databaseName 
    AND BS.backup_start_date BETWEEN DATEADD(mm, - @months, @endDate) AND @endDate 
GROUP by YEAR(BS.backup_start_date) 
    ,MONTH(BS.backup_start_date)
order by YEAR(BS.backup_start_date) 
    ,MONTH(BS.backup_start_date)