--How to assign a value to a sp procedure with sp_executesql and then use it in the remaining script.
Create PROCEDURE [dbo].[sp_CopyFromRawToStaging]
(
    @Company nvarchar(50),
	@FromDate nvarchar(20),
	@ToDate nvarchar(20),
	@CompressBy nvarchar(10), --Day,Week,Month
	@Result nvarchar(250) output
)
AS
BEGIN
	Declare @StagingEntryNoStart nvarchar(20)
			,@SQLcommand5 nvarchar(4000)
			,@ParmDefinition nvarchar(500);

	set @ParmDefinition = '';
	Select @SQLcommand5 = N'Set @StagingEntryNoStartOUT = (Select (Isnull(max("Entry No_"),0))+1 from ['+ @Company +N'$Sales Interface - Staging Data])';
	Set @ParmDefinition = N'@StagingEntryNoStartOUT int OUTPUT';
	exec sp_executesql @sqlcommand5, @ParmDefinition, @StagingEntryNoStartOUT = @StagingEntryNoStart OUTPUT;
	--Here the @StagingEntryNoStart gets the value of @StagingEntryNoStartOUT

END
GO


