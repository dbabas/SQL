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
	--SET @cmd = N'SELECT '''+@name+''',count(*) FROM [' + @name + N'$AutoNAV Log Entry]'; --Check number of records per company
	SET @cmd = N'TRUNCATE TABLE [' + @name + N'$AutoNAV Log Entry]';
	EXEC (@cmd);
  END;

CLOSE curs;
DEALLOCATE curs;

DROP TABLE #companies
GO