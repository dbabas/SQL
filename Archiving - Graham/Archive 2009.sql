USE [ZZ-Archive2009]
GO
/****** Object:  StoredProcedure [dbo].[ArchiveTables]    Script Date: 17/11/2020 16:55:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER Procedure [dbo].[ArchiveTables]
(
@BatchName varchar(100)
)
As Begin


--Declare @BatchName varchar(100)
If @BatchName is null 
	Set @BatchName = 'AAAAA'

if object_ID('tempdb..#Tables') is not null 
	DROP Table #Tables
Create table #Tables
	(
	ID int identity(1,1)
	,[LineNo] int
	,TableNo int
	,TableName varchar(250)
	,MasterTableName varchar(250)
	)

insert into #Tables
	([LineNo],TableNo,TableName,MasterTableName)
Select [Archive Line No_],[Table No_],[SQL Table Name],[Master Table Name]
from [Archive Table]
Where [Archive Batch] = @BatchName
	and Active = 1
order by [Sorting Key]

if object_ID('tempdb..#Fields') is not null 
	DROP Table #Fields
Create table #Fields
	(
	ID int identity(1,1)
	,[LineNo] int
	,FieldName varchar(250)
	,DataType varchar(20)
	,Length int
	)

if object_ID('tempdb..#LinkedFields') is not null 
	DROP Table #LinkedFields
Create table #LinkedFields
	(
	ID int identity(1,1)
	,[LineNo] int
	,TableName varchar(250)
	,FieldName varchar(250)
	,MasterTableName varchar(250)
	,MasterFieldName varchar(250)
	)


if object_ID('tempdb..#ClusteredIndex') is not null 
	DROP Table #ClusteredIndex
Create table #ClusteredIndex
	(
	ID int identity(1,1)
	,FieldName varchar(250)
	)

if object_ID('tempdb..#Where') is not null 
	DROP Table #Where
Create table #Where
	(
	ID int identity(1,1)
	,[LineNo] int
	,WhereField varchar(100)
	,Operator varchar(10)
	,WhereValue varchar(50)
	,WhereFieldDataType varchar(50)
	)

if object_ID('tempdb..#TopN') is not null 
	DROP Table #TopN
Create table #TopN
	(
	ID int identity(1,1)
	,TOPN INT
	)

if object_ID('tempdb..#DestinationExists') is not null 
	DROP Table #DestinationExists

Create table #DestinationExists
	(
	DestinationObjectID int
	)


If object_ID('tempdb..#AddFields') is not null
	DROP Table #AddFields

Create table #AddFields
(
	ID int identity(1,1)
	,TableName varchar(250)
	,FieldName varchar(100)
	,FieldType varchar(30)
	,FieldLength int
)
 
Declare @Company varchar(100)
		,@x int
		,@y int
		,@z int
		,@SQL varchar(max)
		,@SQLExists varchar(max)
		,@SQLCreate varchar(max)
		,@SQLDelete varchar(max)
		,@TableName varchar(250)
		,@TableCount int
		,@FieldCount int
		,@WhereCount int
		,@LinksCount int
		,@AddFieldsCount int
		,@IndexFieldCount int
		,@FieldList varchar(max)
		,@FieldListInsert varchar(max)
		,@FieldListCreate varchar(max)
		,@WhereClause varchar(max)
		,@LinkedTables varchar(max)
		,@InsertLog varchar(max)
		,@TopN varchar(max)
		,@SQLObjectID int
		,@DestinationDB varchar(100)
		,@SourceDB varchar(100)
		,@LineNo int
		,@ArchiveCount int
		,@DestinationObjectID int

Select @TableCount = Count(*) from [Archive Table]

Select @DestinationDB = [Destination Database] from [Archive Setup]
Select @SourceDB = [Source Database] from [Archive Setup]

Set @x = 1

While @x <= @TableCount begin
	Truncate Table #Fields
	Truncate Table #DestinationExists
	TRUNCATE TABLE #Where
	Select @TableName = TableName from #Tables where ID = @x
	Select @LineNo = [LineNo] from #Tables where ID = @x
	Select @SQLObjectID = object_ID(@TableName)
	Select @FieldCount = Count(*) from #Tables where ID = @x
	Set @FieldList = ''
	Set @FieldListInsert = ''
	sELECT @FieldListCreate = ''
	Set @y = 1

	Set @SQLExists = 'Select object_id from ['+@DestinationDB+'].sys.objects where name = '''+ @TableName+''''
	
	Insert into #DestinationExists
	Exec (@SQLExists)

	Insert into #Fields
	Select [Archive Line No_],[SQL Field Name],[SQL Field Type],[SQL Field length]
	From [Archive Fields]
	where [Archive Batch] = @BatchName
		and  [Archive Line No_]  = @LineNo
	
	Select @FieldCount = Count(*) from #Fields

	While @y <= @FieldCount begin
		
		Select @FieldList = @FieldList + Case When @y = 1 then 't.['+FieldName+']' ElsE ',t.[' + FieldName+']' END			
		from #Fields
		where ID = @y
		Select @FieldListInsert = @FieldListInsert + Case When @y = 1 then '['+FieldName+']' ElsE ',[' + FieldName+']' END			
		from #Fields
		where ID = @y

		
		Select @FieldListCreate = @FieldListCreate +	Case When @y = 1 then	

															CAST('['+FieldName+'] ' +	Case when DataType = 'VARCHAR' then 
																						[DataType] +'('+CAST([Length] AS varchar(20))+')'
																					else 
																						[DataType] 
																					END  AS varchar(100))
														Else	
															CAST(',[' + FieldName+']'+	Case when DataType = 'VARCHAR' then 
																						[DataType] +'('+CAST([Length] AS varchar(20))+')'
																					else 
																						[DataType] 
																					END AS varchar(100))
														END			
		from #Fields
		where ID = @y

		Set @y = @y + 1
	END

----------------------------------------------------------------------------------------------------------------------------------	
	Set @WhereClause = ''
	Set @y = 1
	truncate table #LinkedFields
	Insert Into #LinkedFields
		([LineNo],TableName,FieldName,MasterTableName,MasterFieldName)

	Select tl.[Archive Line No_]
		,tl.[SQL Master Table Name]
		,tl.[SQL Field Name]
		,tl.[SQL Master Table Name]
		,tl.[SQL Master Field Name]
	from [Archive Table Links] tl
	where tl.[Archive Batch] = @BatchName
		and  tl.[Archive Line No_] = @LineNo
	
	Select @LinksCount = Count(*) from #LinkedFields

	Set @LinkedTables = ''
	While @y <= @LinksCount begin
		If @y = 1 
			Select @LinkedTables = '	Left Outer Join ['+MasterTableName+'] m on 
			' from #LinkedFields
		where ID = @y
		
		Select @LinkedTables = @LinkedTables + Case When @y = 1 then 
												' t.['+FieldName+ '] = m.[' + [MasterFieldName] + '] '
		 ElsE 
			' and t.['+FieldName+ '] = m.[' + [MasterFieldName] + '] '
		END			
		from #LinkedFields
		where ID = @y
		
		If @y = 1 
			Select @WhereClause = 'Where m.['+MasterFieldName+'] IS NULL' 
		from #LinkedFields
		where ID = @y


		Set @y = @y + 1
	END
	
----------------------------------------------------------------------------------------------------------------------------------	


	
	Set @y = 1
	Insert Into #Where
	([LineNo],WhereField,Operator,WhereValue,WhereFieldDataType)
	Select tf.[Archive Line No_]
		,tf.[SQL Field Name]
		,CAse	When tf.[Operator] = 1 then '='
				When tf.[Operator] = 2 then '<'
				When tf.[Operator] = 3 then '<='
				When tf.[Operator] = 4 then '>'
				When tf.[Operator] = 5 then '>='
				When tf.[Operator] = 6 then '<>'
		END
		,tf.[SQL Value]
		,f.[SQL Field Type]
	from [Archive Table Filters] tf
		inner Join [Archive Fields] f on
			f.[Archive Batch] = tf.[Archive Batch]
			and f.[Archive Line No_] = tf.[Archive Line No_]
			and f.[Field No_] = tf.[Field No]
	where tf.[Filter Type] <= 2
		and tf.[Archive Batch] = @BatchName
		and  tf.[Archive Line No_]= @LineNo
		
	
	Select @WhereCount = Count(*) from #Where
	
	While @y <= @WhereCount begin
		Select @WhereClause = @WhereClause + Case When @WhereClause = '' then 
												'Where t.['+WhereField+ '] ' + [Operator] + ' '+	Case when WhereFieldDataType in ('VARCHAR','DATETIME') then 
																									'''' + WhereValue + '''' 
																								else 
																									WhereValue 
																								end
		
		 ElsE ' and t.['+WhereField+ '] ' + [Operator] + ' ' +Case when WhereFieldDataType in ('VARCHAR','DATETIME') then 
																								'''' + WhereValue + '''' 
																							else 
																								WhereValue 
																							end
		END			
		from #Where
		where ID = @y

		Set @y = @y + 1
	END
	
	TRUNCATE TABLE #TopN
	Insert Into #TopN
	(TOPN)
	Select Top(1) [Field Value]
	from [Archive Table Filters] 
	where [Filter Type] = 3
		and [Archive Batch] = @BatchName
		and  [Archive Line No_] = @LineNo
	
	Set @TopN = ''
	Select @TopN = 'TOP('+CAST(TOPN as varchar(20)) + ')' 
	from #TopN where ID = 1

	
	
	Set @SQLCreate = ''
	If NOT Exists(Select * from #DestinationExists) begin
		Print ('Create Table Required!!!!!!!!!')

		Truncate Table #ClusteredIndex

		Insert into #ClusteredIndex
		Select l.name 
		from sys.indexes i
			inner join sys.index_columns c on
				c.object_id = i.object_id
				and c.index_id = i.index_id
				inner join sys.columns l on
					l.object_id = c.object_id
					and l.column_id = c.column_id
		where is_primary_key = 1
			and i.object_id = @SQLObjectID
		
		--sELECT * FROM #ClusteredIndex

		Select @IndexFieldCount = COUNT(*) from #ClusteredIndex

		Set @SQLCreate = '
			Use ['+@DestinationDB+']

			Create table [' + @TableName +']
			('+@FieldListCreate+'
			,CONSTRAINT ['+@TableName+'$0] PRIMARY KEY CLUSTERED 
			('
			Set @z = 1
			While @z <= @IndexFieldCount begin
				SELECT @SQLCreate = Case when @z = 1 then @SQLCreate + '['+FieldName+'] ASC' ELSE @SQLCreate + ',['+FieldName+'] ASC'  END from #ClusteredIndex where ID = @z
				Set @z = @z + 1
			END
			Set @SQLCreate = @SQLCreate + ') WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]) ON [PRIMARY]
			'	
	
	END ELSE begin
		Select @DestinationObjectID = DestinationObjectID from #DestinationExists
		Truncate Table #AddFields
		
		
		--Insert into #AddFields
		Declare @SQL1 nvarchar(max)
				
		Set @SQL1 = '
		Select [SQL Table Name],[SQL Field Name],[SQL Field Type],[SQL Field Length]
		from [Archive Fields] f
		left Outer join ['+@DestinationDB+'].sys.columns s on
			s.object_id = '+cast(@DestinationObjectID as nvarchar(100))+'
			and s.name = f.[SQL Field Name] collate database_default
		where f.[SQL Table Name] = '''+@TableName+''' 
			and s.column_id is null
		'
		Insert into #AddFields
		Exec (@SQL1)

		Select @AddFieldsCount = Count(*) from #AddFields
		Select @AddFieldsCount

		Set @z = 1
		

		While @z <= @AddFieldsCount begin
			SELECT @SQLCreate = @SQLCreate + Case When @z = 1 then
'Use ['+@DestinationDB+']
ALTER TABLE ['+@DestinationDB+'].dbo.['+TableName+'] ADD [' else ',[' END +
	+[FieldName]+'] '+FieldType+ CASE	WHEN fieldtype = 'DECIMAL' then '(38,20)'
										WHEN Fieldtype <> 'DECIMAL' and Fieldlength > 0 then '(' + CAST(FieldLength as varchar(20)) + ')'
										else '' END	
				FROM #AddFields WHERE id = @Z
				Set @z = @z + 1
			
		END
	END

	
	SELECT @InsertLog =  '
	Declare @ArchiveCount int
	Select @ArchiveCount = @@RowCount

	INSERT INTO [dbo].[Archive Log]
	([Archive Batch],[Line No_],[Date],[Time],[Table No_],[Table Name],[Records Archived],[UTCDateTime])
	Select '''+@BatchName+'''
        ,'+CAST(@LineNo as varchar(20))+'
		,CAST(LEFT(CONVERT(varchar,GETDATE(),120),10) AS datetime)
		,''01/01/1754 '' + CONVERT(CHAR,GETDATE(),14)
		,'+cast([TableNo] as varchar(20)) +'
        ,'''+[TableName]+'''
        ,@ArchiveCount
		,'''+cast(GETUTCDATE() as varchar(30))+''''
	from #Tables
	where ID = @x







	Set @SQL = (Select '
Use ['+@SourceDB+'] 
INSERT INTO ['+@DestinationDB+'].dbo.[' + TableName + ']
('+@FieldListInsert+')
Select '+@TopN+' '+@FieldList+' 
from ['+@SourceDB+'].dbo.[' + TableName + '] t
'+@LinkedTables + @WhereClause + '
'from #Tables where ID = @x)
	
	Set @SQLDelete = (Select '
Use ['+@SourceDB+'] 
Delete '+@TopN+' t
from ['+@SourceDB+'].dbo.[' + TableName + '] t
'+@LinkedTables+'' + @WhereClause 
from #Tables where ID = @x)

	Print @SQLCreate
	Print @SQL
	PRINT @InsertLog
	Print @SQLDelete
	Exec(@SQLCreate) 
	
	Exec(@SQL + @InsertLog + @SQLDelete)
	Set @x = @x + 1

	
END

END