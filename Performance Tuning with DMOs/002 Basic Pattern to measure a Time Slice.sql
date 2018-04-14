--Basic Pattern to measure a "time slice"

--Take a baseline measurement and insert it into a temporary table.
SELECT  DB_NAME(mf.database_id) AS databaseName ,
        mf.physical_name ,
        divfs.num_of_reads ,
        divfs.num_of_bytes_read ,
        divfs.io_stall_read_ms ,
        divfs.num_of_writes ,
        divfs.num_of_bytes_written ,
        divfs.io_stall_write_ms ,
        divfs.io_stall ,
        divfs.size_on_disk_bytes ,
        GETDATE() AS baselineDate
INTO    #baseline
FROM    sys.dm_io_virtual_file_stats(NULL, NULL) AS divfs
        JOIN sys.master_files AS mf
			ON mf.database_id = divfs.database_id AND mf.file_id = divfs.file_id

--After an apporpriate time lag, use a CTE to capture current values, join with temp and calc difference.
WITH  currentLine
        AS ( SELECT   DB_NAME(mf.database_id) AS databaseName ,
                        mf.physical_name ,
						divfs.num_of_reads ,
						divfs.num_of_bytes_read ,
						divfs.io_stall_read_ms ,
						divfs.num_of_writes ,
						divfs.num_of_bytes_written ,
						divfs.io_stall_write_ms ,
						divfs.io_stall ,
						divfs.size_on_disk_bytes ,
                        GETDATE() AS currentlineDate
             FROM     sys.dm_io_virtual_file_stats(NULL, NULL) AS divfs
                        JOIN sys.master_files AS mf
                          ON mf.database_id = divfs.database_id
                             AND mf.file_id = divfs.file_id
             )
  SELECT  currentLine.databaseName ,
        currentLine.physical_name ,
		currentLine.num_of_reads - #baseline.num_of_reads AS num_of_reads,
		currentLine.num_of_bytes_read - #baseline.num_of_bytes_read  AS num_of_bytes_read,
		currentLine.io_stall_read_ms - #baseline.io_stall_read_ms  AS io_stall_read_ms,
		currentLine.num_of_writes - #baseline.num_of_writes  AS num_of_writes,
		currentLine.num_of_bytes_written - #baseline.num_of_bytes_written  AS num_of_bytes_written,
		currentLine.io_stall_write_ms - #baseline.io_stall_write_ms  AS io_stall_write_ms,
		currentLine.io_stall - #baseline.io_stall  AS io_stall,
		currentLine.size_on_disk_bytes - #baseline.size_on_disk_bytes  AS size_on_disk_bytes,
        DATEDIFF(millisecond,baseLineDate,currentLineDate) AS elapsed_ms --gets the change in time since the baseline was taken
  FROM  currentLine
      INNER JOIN #baseline ON #baseLine.databaseName = currentLine.databaseName
        AND #baseLine.physical_name = currentLine.physical_name

--Delete temporary table
IF OBJECT_ID('tempdb..#baseline') IS NOT NULL
    DROP TABLE #baseline
