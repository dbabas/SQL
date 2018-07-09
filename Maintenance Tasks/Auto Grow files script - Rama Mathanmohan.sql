/* 
By : Rama Mathanmohan
Date : 03.07.08
Use : To Evenly Auto Grow Data Files based on Maximum and Minimum % Used.  Set the options below as required
*/

Declare @MinUsedPercent decimal
Declare @MaxUsedPercent decimal
Declare @DBName nvarchar(200) 
Declare @Filename nvarchar(200)
Declare @CurrentSize decimal
Declare @NewSize decimal

--- Set the options below ------------
Set @MinUsedPercent = 70
Set @MaxUsedPercent = 90
--- End of Setting the options -------

set @DBName = DB_NAME()

CREATE TABLE #TheDBFiles ([NameOfFile] nvarchar(200),[FullPath] nvarchar(1024),[CurrentSize(MB)] decimal,[SpaceUsed(MB)] decimal,[UsedPercent] decimal)
Insert into #TheDBFiles

SELECT name AS NameOfFile,filename as FullPath,
       size/128.0 as [TotalSizeInMB],
	   FILEPROPERTY(name, 'SpaceUsed' )/128.0 AS [SpaceUsed(MB)],
	   Round(CAST(FILEPROPERTY(name, 'SpaceUsed' )AS Decimal)/CAST (size AS Decimal) * 100,2) as '% Used'
FROM dbo.sysfiles
where FILEPROPERTY(name, 'IsPrimaryFile') = 0 and FILEPROPERTY(name, 'IsLogFile') = 0

DECLARE Get_File CURSOR FAST_FORWARD FOR 
Select [NameOfFile],[SpaceUsed(MB)] 
from #TheDBFiles where UsedPercent >= @MaxUsedPercent 

OPEN Get_File
FETCH NEXT FROM Get_File INTO @Filename,@CurrentSize
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @NewSize = @CurrentSize*100/@MinUsedPercent
  	exec ('ALTER DATABASE [' + @DBName + '] MODIFY FILE (NAME = [' + @Filename + '], SIZE = '+ @NewSize + 'MB)')
	FETCH NEXT FROM Get_File INTO @Filename,@CurrentSize
END
Close Get_File
DEALLOCATE Get_File

Drop Table [#TheDBFiles]