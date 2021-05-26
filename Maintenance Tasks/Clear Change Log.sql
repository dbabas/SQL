--Uses a two setup fields on the Company Information
--One Formula Duration visible to the user
--and one date field which is auto-calculated based on the above.

Use [Polystar_Test]

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
	SET @cmd = N'delete FROM [' + @name + N'$Change Log Entry] Where [Date and Time] < (Select [Change Log - Delete Date] from ['
		+ @name + N'$Company Information])';
	EXEC (@cmd);
  END;

CLOSE curs;
DEALLOCATE curs;

DROP TABLE #companies
GO