

SET NOCOUNT ON
set dateformat ymd

Declare @DateFilter datetime
Set @DateFilter = '2000-01-01'

------ To Find most blocking query ----------------------------------------------

SELECT	Sum(Leader.[Blocked User Count]) as [Blocked User Count],Count([Entry No]) as [Blocking Instances],
	[Blocker SQL],Sum(Waittime) as Waittime,
	Max([Batch No]) as [Last Batch No] 
From ZZ_BlockingLog INNER JOIN
(	Select MIN([Entry No]) AS [First Entry],Count (Distinct [Spid]) AS [Blocked User Count] from ZZ_BlockingLog  
	Where [Timestamp] > @DateFilter
	--Where [Entry No] > 10000
	--Where [Batch No] between 1738 and 1759
	GROUP BY [Batch No]  
) AS Leader
On Leader.[First Entry] = ZZ_BlockingLog.[Entry No]
Group By [Blocker SQL]
Order By [Blocked User Count] Desc

----------------------------------------------------------------------------------

------ To See the leading Blocking Leader by Blocked Resource --------------------

SELECT [Blocker Name],
	Count(*) as [Block Count (Samples)] from ZZ_BlockingLog INNER JOIN
(Select [Batch No], MIN([Entry No]) AS [First Entry] from ZZ_BlockingLog
Where [Timestamp] > @DateFilter
--Where [Batch No] between 1738 and 1759
GROUP BY [Batch No]) AS Leader
On Leader.[First Entry] = ZZ_BlockingLog.[Entry No]
Group By [Blocker Name] 
Order by [Block Count (Samples)] Desc


SELECT [Waitresource Name] as [Wait Resource Name],
	Count(*) as [Block Count (Samples)] from ZZ_BlockingLog INNER JOIN
(Select [Batch No], MIN([Entry No]) AS [First Entry] from ZZ_BlockingLog
Where [Timestamp] > @DateFilter
--Where [Batch No] between 1738 and 1759
GROUP BY [Batch No]) AS Leader
On Leader.[First Entry] = ZZ_BlockingLog.[Entry No]
Group By [Waitresource Name] 
Order by [Block Count (Samples)] Desc

SELECT [Waitresource Name] as [Wait Resource Name (All)],
	Count(*) as [Block Count (Samples)] 
From ZZ_BlockingLog
Where [Timestamp] > @DateFilter
--Where [Batch No] between 1738 and 1759
Group By [Waitresource Name] 
Order by [Block Count (Samples)] Desc

----------------------------------------------------------------------------------

----------------------- To See the leading Blocked Users -------------------------

SELECT [Name] as [Blocked User Name],
	Count(*) as [Block Count (Samples)] 
From ZZ_BlockingLog
Where [Timestamp] > @DateFilter
--Where [Batch No] between 1738 and 1759
Group By [Name]
Order by [Block Count (Samples)] Desc

----------------------------------------------------------------------------------

----------------------- To Analyse batch by batch -------------------------
/*
SELECT Leader.[Blocked User Count],* from ZZ_BlockingLog INNER JOIN
(	Select MIN([Entry No]) AS [First Entry],Count (Distinct [Spid]) AS [Blocked User Count] 
	From ZZ_BlockingLog 
	Where [Timestamp] > @DateFilter
	--Where [Entry No] > 10000
	--Where [Batch No] between 29 and 56
	GROUP BY [Batch No]
) AS Leader
On Leader.[First Entry] = ZZ_BlockingLog.[Entry No]
Order by [Batch No]
*/
----------------------------------------------------------------------------------

------ To Find out How long Each Blocking has happened & the number of it --------------------------------------

SET NOCOUNT ON
Declare @BlockingSummary Table ([Start BatchNo] int,[End BatchNo] int,[Start Time] datetime,[End Time] datetime,[Block Duration] bigint,[Waitresource] varchar(128),[Blocker Name] varchar(128),[Blocker Host] varchar(128),[WaitresourceName] varchar(128),[User BlockTime] bigint,[Blocked User Count] decimal(38,2)) 
Declare @BatchNo_Curs int,@StartTime_Curs datetime,@Waitresource_Curs varchar(128),@Waittime_Curs bigint,@BlockerName_Curs varchar(128),@BlockerHost_Curs varchar(128)
Declare @StartBatchNo int,@EndBatchNo int,@StartTime datetime,@EndTime datetime,@BlockDuration bigint,@Waitresource varchar(128),@BlockerName varchar(128),@BlockerHost varchar(128)
Declare @BlockDuration2 bigint,@UserBlockTime bigint,@BlockedUserCount int
Declare @WaitresourceName_Curs varchar(128),@WaitresourceName varchar(128)

Declare BlockingSummary_Curs CURSOR FAST_FORWARD FOR 
SELECT Leader.[Batch No],[Timestamp],[Waitresource],[Waittime],[Blocker Name],[Blocker Hostname],[Waitresource Name] from ZZ_BlockingLog 
INNER JOIN
(Select [Batch No], MIN([Entry No]) AS [First Entry] from ZZ_BlockingLog  
Where [Timestamp] > @DateFilter
GROUP BY [Batch No]) AS Leader
On Leader.[First Entry] = ZZ_BlockingLog.[Entry No]
Order by [Entry No]

Set @Waitresource = ''
Set @BlockerName = ''
Set @BlockDuration = 0

Open BlockingSummary_Curs
FETCH NEXT FROM BlockingSummary_Curs INTO @BatchNo_Curs,@StartTime_Curs,@Waitresource_Curs,@Waittime_Curs,@BlockerName_Curs,@BlockerHost_Curs,@WaitresourceName_Curs
WHILE @@FETCH_STATUS = 0
BEGIN
	
	if (@WaitresourceName_Curs <> @WaitresourceName) or (@BlockerName_Curs <> @BlockerName) /* or (@BlockDuration > @Waittime_Curs) */ or (@StartTime_Curs > @EndTime + '00:02:30.000')
	Begin
		if @BlockerName <> ''
		Begin
			Set @BlockDuration2 = Datepart(hour,@EndTime  - @StartTime)*3600 + Datepart(minute,@EndTime  - @StartTime)*60 + Datepart(second,@EndTime  - @StartTime)
			Set @UserBlockTime = (Select Sum(BlockTime) From (Select Max(Waittime)/1000 as BlockTime From ZZ_BlockingLog with(index(IDX_BatchNo))
     					      Where [Batch No] between @StartBatchNo and @EndBatchNo
     					      Group By [Name],[Spid],[LastBatch]) as Detail
					     )
			Set @BlockedUserCount = (Select Count(Distinct [Name]) from ZZ_BlockingLog with(index(IDX_BatchNo))
			where [Batch No] between @StartBatchNo and @EndBatchNo)

			if @BlockDuration/1000 > @BlockDuration2
				Set @BlockDuration2 = @BlockDuration/1000 
			Insert into @BlockingSummary Select @StartBatchNo,@EndBatchNo,@StartTime,@EndTime,@BlockDuration2,@Waitresource,@BlockerName,@BlockerHost,@WaitresourceName,@UserBlockTime,@BlockedUserCount

		End
		Set @StartBatchNo = @BatchNo_Curs
		Set @StartTime = @StartTime_Curs
		Set @Waitresource = @Waitresource_Curs
		Set @BlockerName = @BlockerName_Curs
		Set @BlockerHost = @BlockerHost_Curs
		Set @EndBatchNo = @BatchNo_Curs
		Set @EndTime = @StartTime_Curs	
		Set @WaitresourceName = @WaitresourceName_Curs	
	End
	Else
    	Begin
		Set @EndBatchNo = @BatchNo_Curs
		Set @EndTime = @StartTime_Curs	
	End
	
	Set @BlockDuration = @Waittime_Curs

	FETCH NEXT FROM BlockingSummary_Curs INTO @BatchNo_Curs,@StartTime_Curs,@Waitresource_Curs,@Waittime_Curs,@BlockerName_Curs,@BlockerHost_Curs,@WaitresourceName_Curs
END

Set @BlockDuration2 = Datepart(hour,@EndTime  - @StartTime)*3600 + Datepart(minute,@EndTime  - @StartTime)*60 + Datepart(second,@EndTime  - @StartTime)
Set @UserBlockTime = (Select Sum(BlockTime) From (Select Max(Waittime)/1000 as BlockTime From ZZ_BlockingLog with(index(IDX_BatchNo))
     		      Where [Batch No] between @StartBatchNo and @EndBatchNo
     		      Group By [Name],[Spid],[LastBatch]) as Detail
		     )
Set @BlockedUserCount = (Select Count(Distinct [Name]) from ZZ_BlockingLog with(index(IDX_BatchNo))
			             where [Batch No] between @StartBatchNo and @EndBatchNo)

if @BlockDuration/1000 > @BlockDuration2
	Set @BlockDuration2 = @BlockDuration/1000 
Insert into @BlockingSummary Select @StartBatchNo,@EndBatchNo,@StartTime,@EndTime,@BlockDuration2,@Waitresource,@BlockerName,@BlockerHost,@WaitresourceName,@UserBlockTime,@BlockedUserCount

Close BlockingSummary_Curs
DEALLOCATE BlockingSummary_Curs

--------- Analyse the figures by Day with moving averages ----------

Declare @BlockCounts Table([Entry No] BIGINT IDENTITY,[Date] datetime,[Average Block Duration (sec)] int,[Block Count] int,[Total Block Duration (sec)] int,[Total User Block Time (sec)] int,[Average User Block Time (sec)] int,[Average User Block Count] decimal(38,2))
Insert Into @BlockCounts([Date],[Average Block Duration (sec)],[Block Count],[Total Block Duration (sec)],[Total User Block Time (sec)],[Average User Block Time (sec)],[Average User Block Count])

Select 	LEFT(CONVERT(varchar,[Start Time],120),10) as [Date],
	Avg([Block Duration]) as [Average Block Duration (sec)],	
	Count(*) as [Block Count],
	Sum([Block Duration]) as [Total Block Duration (sec)],
	Sum([User BlockTime]) as [Total User BlockTime (sec)],
	Avg([User BlockTime]) as [Average User BlockTime (sec)],
	Avg([Blocked User Count]) as [Average User Block Count]
From @BlockingSummary
Group By LEFT(CONVERT(varchar,[Start Time],120),10)
Order by [Date]

Select LEFT(CONVERT(varchar,[Date],120),10) as [Date],
	[Average Block Duration (sec)],
	[Block Count],
	[Total Block Duration (sec)],
	[Average User Block Time (sec)],
	[Total User Block Time (sec)],
	[Average User Block Count],
	Case When [Entry No] < 7 Then
		(	SELECT Cast(Round(Avg([Average Block Duration (sec)]),2) as numeric(20,2)) 
			FROM @BlockCounts AS Ave 
			Where	Ave.[Date] <= Main.[Date] and Ave.[Date] > DATEADD(dd,-7,Main.[Date])) 
	Else
		(	SELECT Cast(Round(Sum([Average Block Duration (sec)])/7,2) as numeric(20,2)) 
			FROM @BlockCounts AS Ave 
			Where	Ave.[Date] <= Main.[Date] and Ave.[Date] > DATEADD(dd,-7,Main.[Date])) End AS [Average Block Duration (sec) (1W)],

	Case When [Entry No] < 7 Then
		(	SELECT Cast(Round(Avg([Block Count]),2) as numeric(20,2)) 
			FROM @BlockCounts AS Ave 
			Where	Ave.[Date] <= Main.[Date] and Ave.[Date] > DATEADD(dd,-7,Main.[Date])) 
	Else
		(	SELECT Cast(Round(Sum([Block Count])/7,2) as numeric(20,2)) 
			FROM @BlockCounts AS Ave 
			Where	Ave.[Date] <= Main.[Date] and Ave.[Date] > DATEADD(dd,-7,Main.[Date])) End AS [Block Count (1W)],

	Case When [Entry No] < 7 Then
		(	SELECT Cast(Round(Avg([Total Block Duration (sec)]),2) as numeric(20,2)) 
			FROM @BlockCounts AS Ave 
			Where	Ave.[Date] <= Main.[Date] and Ave.[Date] > DATEADD(dd,-7,Main.[Date])) 
	Else
		(	SELECT Cast(Round(Sum([Total Block Duration (sec)])/7,2) as numeric(20,2)) 
			FROM @BlockCounts AS Ave 
			Where	Ave.[Date] <= Main.[Date] and Ave.[Date] > DATEADD(dd,-7,Main.[Date])) End AS [Total Block Duration (sec) (1W)],

	Case When [Entry No] < 7 Then
		(	SELECT Cast(Round(Avg([Average User Block Time (sec)]),2) as numeric(20,2)) 
			FROM @BlockCounts AS Ave 
			Where	Ave.[Date] <= Main.[Date] and Ave.[Date] > DATEADD(dd,-7,Main.[Date])) 
	Else
		(	SELECT Cast(Round(Sum([Average User Block Time (sec)])/7,2) as numeric(20,2)) 
			FROM @BlockCounts AS Ave 
			Where	Ave.[Date] <= Main.[Date] and Ave.[Date] > DATEADD(dd,-7,Main.[Date])) End AS [Average User Block Time (sec) (1W)],
	
	Case When [Entry No] < 7 Then
		(	SELECT Cast(Round(Avg([Total User Block Time (sec)]),2) as numeric(20,2)) 
			FROM @BlockCounts AS Ave 
			Where	Ave.[Date] <= Main.[Date] and Ave.[Date] > DATEADD(dd,-7,Main.[Date])) 
	Else
		(	SELECT Cast(Round(Sum([Total User Block Time (sec)])/7,2) as numeric(20,2)) 
			FROM @BlockCounts AS Ave 
			Where	Ave.[Date] <= Main.[Date] and Ave.[Date] > DATEADD(dd,-7,Main.[Date])) End AS [Total User Block Time (sec) (1W)],

	Case When [Entry No] < 7 Then
		(	SELECT Cast(Round(Avg([Average User Block Count]),2) as numeric(20,2)) 
			FROM @BlockCounts AS Ave 
			Where	Ave.[Date] <= Main.[Date] and Ave.[Date] > DATEADD(dd,-7,Main.[Date])) 
	Else
		(	SELECT Cast(Round(Sum([Average User Block Count])/7,2) as numeric(20,2)) 
			FROM @BlockCounts AS Ave 
			Where	Ave.[Date] <= Main.[Date] and Ave.[Date] > DATEADD(dd,-7,Main.[Date])) End AS [Average User Block Count (1W)]
From @BlockCounts as Main

Select [Start BatchNo],[End BatchNo],LEFT(CONVERT(varchar,[Start Time],120),10)as [Start Date],CONVERT(varchar, [Start Time],8) as [Start Time],
	CONVERT(varchar, [End Time],8) as [End Time],[Block Duration],[Waitresource],[Blocker Name],[Blocker Host],[WaitresourceName],[User BlockTime],[Blocked User Count], 
	SUBSTRING(
		(Select Distinct COALESCE(','+Name,'') From ZZ_BlockingLog with(index(IDX_BatchNo))
			where [Batch No] between BS.[Start BatchNo] and BS.[End BatchNo]
			For Xml Path('')
		),2,100000)As 'Blocked Users',
	SUBSTRING(
		(Select Distinct COALESCE(','+[Waitresource Name],'') From ZZ_BlockingLog with(index(IDX_BatchNo))
			where [Batch No] between BS.[Start BatchNo] and BS.[End BatchNo]
			For Xml Path('')
		),2,100000)As 'All Waitresource Name'
From @BlockingSummary as BS