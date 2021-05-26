USE [<database name>]
GO

/****** Object:  StoredProcedure [dbo].[Change Log Entry - ClearLog4]    Script Date: 26/05/2021 16:08:59 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[Change Log Entry - ClearLog4] @CutOffDate date
as
DECLARE @name nvarchar(80);
DECLARE @cmd nvarchar(4000);

begin try  
if (@CutOffDate >= dateadd(day,-8,getdate()))
	RAISERROR ('You can only delete records older than seven days', -- Message text.  
            16, -- Severity.  
            1 -- State.  
            );  
end try
BEGIN CATCH  
    DECLARE @ErrorMessage NVARCHAR(4000);  
    DECLARE @ErrorSeverity INT;  
    DECLARE @ErrorState INT;  
  
    SELECT   
        @ErrorMessage = ERROR_MESSAGE(),  
        @ErrorSeverity = ERROR_SEVERITY(),  
        @ErrorState = ERROR_STATE();  
  
    RAISERROR (@ErrorMessage, -- Message text.  
               @ErrorSeverity, -- Severity.  
               @ErrorState -- State.  
               );  
	return;
END CATCH;

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
	SET @cmd = N'DELETE FROM [' + @name + N'$Change Log Entry] '
				+ N'where [Table No_] in (9062296,9062297,9062298) '
				+ N'and try_convert(int,[Primary Key Field 1 Value])<0 '
				+ N'and [Date and Time] < '''+Convert(nvarchar(20), @CutOffDate) + '''';
	EXEC (@cmd);
  END;

CLOSE curs;
DEALLOCATE curs;

DROP TABLE #companies
GO


