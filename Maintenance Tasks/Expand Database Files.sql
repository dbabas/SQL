declare @Filename as nvarchar(500), @Size as decimal(10,0), @FreeSpacePc as decimal(10,2),@sql nvarchar(500)
declare cur cursor local for 

SELECT 
    [FILE_Name] = A.name
	,[FILESIZE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0)
    ,[FREESPACE_%] = CONVERT(DECIMAL(10,2),((A.SIZE/128.0 - CAST(FILEPROPERTY(A.NAME, 'SPACEUSED') AS INT)/128.0)/(A.SIZE/128.0))*100)    
FROM sys.database_files A LEFT JOIN sys.filegroups fg ON A.data_space_id = fg.data_space_id 

open cur

fetch next from cur into @Filename, @size, @FreeSpacePc

while @@FETCH_STATUS = 0 BEGIN

    If @FreeSpacePc < 10
		begin
		set @sql =N'ALTER Database [Demo Database NAV (10-0)] MODIFY FILE (name = '''+@Filename+''', SIZE = '+cast((@size+100)*1000 as nvarchar(10))+'KB)'
		--set @sql =N'select * from sys.objects'
		execute sp_executesql @sql
		end

    fetch next from cur into @Filename, @size, @FreeSpacePc
END

close cur
deallocate cur


--Declare
--@Newsize int, 
--@sql nvarchar(500),
--@filename nvarchar(100)


--SELECT @Newsize=((size*8)/1024)*1.5,@filename=name
--FROM sys.master_files
--where DB_Name (database_id) = 'COSTDB'
--and type=0



--set @sql=N'ALTER Database COSTDB
--MODIFY FILE (name=''' +@filename+''', SIZE = '+cast(@newsize as nvarchar(10))+' mb)'

--execute sp_executesql @sql
