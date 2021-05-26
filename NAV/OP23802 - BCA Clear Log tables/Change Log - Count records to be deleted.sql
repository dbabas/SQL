DECLARE @name nvarchar(80);
DECLARE @cmd nvarchar(4000);

SELECT REPLACE(Name, '.', '_') AS Name
INTO #companies
FROM Company

DECLARE curs CURSOR FOR SELECT * FROM #companies

OPEN curs

WHILE (1=1)
  BEGIN;
    FETCH NEXT
	  FROM curs
	  INTO @name;
    IF @@FETCH_STATUS < 0 BREAK;
	-- stuff to do
	SET @cmd = N'SELECT '''+@name+''',count(*) FROM [' + @name + N'$Change Log Entry] '
				+ N'where [Table No_] in (9062296,9062297,9062298) '
				+ N'and try_convert(int,[Primary Key Field 1 Value])<0 '
				+ N'and [Date and Time] <= dateadd(day,-7,CURRENT_TIMESTAMP)';
	EXEC (@cmd);
  END;

CLOSE curs;
DEALLOCATE curs;

DROP TABLE #companies
GO