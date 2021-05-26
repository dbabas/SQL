USE [<database name>]
GO

DECLARE @RC int
DECLARE @CutOffDate date

set @CutOffDate = '2021-05-18'

EXECUTE @RC = [dbo].[Change Log Entry - ClearLog4] 
   @CutOffDate
GO