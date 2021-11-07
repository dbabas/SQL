--Uses a setup field on the Company Information, an integer to define the Months to keep.

Use [PolystarUpgrade]

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
	SET @cmd = N'delete FROM [' + @name + N'$Change Log Entry] Where [Date and Time] < dateadd(month,-(Select (case [Change Log - Delete Older Than] when 0 then 1200 else [Change Log - Delete Older Than] end) from ['
		+ @name + N'$Company Information]),CURRENT_TIMESTAMP)';

	EXEC (@cmd);
  END;

CLOSE curs;
DEALLOCATE curs;

DROP TABLE #companies
GO