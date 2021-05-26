DECLARE @name nvarchar(80);
DECLARE @cmd nvarchar(4000);

SELECT REPLACE(Name, '.', '_') AS Name
INTO #companies
FROM Company
NA
DECLARE curs CURSOR FOR SELECT * FROM #companies

OPEN curs

WHILE (1=1)
  BEGIN;
    FETCH NEXT
	  FROM curs
	  INTO @name;
    IF @@FETCH_STATUS < 0 BREAK;
	-- stuff to do
	SET @cmd = N'SELECT '''+@name+''',count(*) FROM [' + @name + N'$Change Log Entry] ';
	EXEC (@cmd);
  END;

CLOSE curs;
DEALLOCATE curs;

DROP TABLE #companies
GO