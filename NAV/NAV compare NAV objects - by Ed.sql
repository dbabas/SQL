---------------------------------
-- this script is used to show object differences between two NAV databases
-- 
-- replace database_you_want_as_uat_dev with the DEV or UAT database, 3 occurences
-- replace database_you_want_as_live with the LIVE databse
---------------------------------



select t.[Diference], count(*) 'Count'
from (
select UAT.[Type] 'Type UAT'
, case UAT.[Type] when 0 then 'Table Data' when 1 then 'Table' when 2 then '' when 3 then 'Report' when 4 then '' when 5 then 'Codeunit' when 6 then 'XMLport' when 7 then 'MenuSuite' when 8 then 'Page' when 9 then 'Query' when 10 then 'System' end 'DS UAT Type' 
, UAT.ID 'ID UAT' , UAT.Name 'NAME UAT', UAT.Date 'Date UAT', UAT.Time 'Time UAT', UAT.[BLOB Size] 'BLOB Size UAT', UAT.[Version List] 'Version List UAT'
,LIVE.[Type] 'Type LIVE' , LIVE.ID 'ID LIVE' , LIVE.Name 'NAME LIVE', LIVE.Date 'Date LIVE', LIVE.Time 'Time LIVE', LIVE.[BLOB Size] 'BLOB Size LIVE', LIVE.[Version List] 'Version List LIVE'
, case when LIVE.[Type] is null then 'Dont Exist' 
when UAT.Name <> LIVE.Name then 'Name Diff'
when  UAT.Date < LIVE.Date then 'Date UAT Older'
when  UAT.Date > LIVE.Date then 'Date LIVE Older'  
when UAT.Time < LIVE.Time then 'Time UAT Older'
when UAT.Time > LIVE.Time then 'Time LIVE Older'
when  UAT.[BLOB Size] > LIVE.[BLOB Size] then 'BLOB Size UAT Greater'
when  UAT.[BLOB Size] < LIVE.[BLOB Size] then 'BLOB Size LIVE Greater'
when UAT.[Version List] <> LIVE.[Version List] then 'Version List Diff' 
 end 'Diference'
from [database_you_want_as_uat_dev].[dbo].[Object] UAT
left join  [database_you_want_as_live].[dbo].[Object] LIVE on
	UAT.[Type] = LIVE.[Type] and UAT.ID = LIVE.ID
Where UAT.[Type] <> 0 and (LIVE.[Type] is null
or UAT.Name <> LIVE.Name
or UAT.Date <> LIVE.Date or UAT.Time <> LIVE.Time)
	) t
group by t.Diference
order by t.Diference


select t.[Type UAT], t.[DS UAT Type] , t.[Diference], count(*) 'Count'
from (
select UAT.[Type] 'Type UAT'
, case UAT.[Type] when 0 then 'Table Data' when 1 then 'Table' when 2 then '' when 3 then 'Report' when 4 then '' when 5 then 'Codeunit' when 6 then 'XMLport' when 7 then 'MenuSuite' when 8 then 'Page' when 9 then 'Query' when 10 then 'System' end 'DS UAT Type' 
, UAT.ID 'ID UAT' , UAT.Name 'NAME UAT', UAT.Date 'Date UAT', UAT.Time 'Time UAT', UAT.[BLOB Size] 'BLOB Size UAT', UAT.[Version List] 'Version List UAT'
,LIVE.[Type] 'Type LIVE' , LIVE.ID 'ID LIVE' , LIVE.Name 'NAME LIVE', LIVE.Date 'Date LIVE', LIVE.Time 'Time LIVE', LIVE.[BLOB Size] 'BLOB Size LIVE', LIVE.[Version List] 'Version List LIVE'
, case when LIVE.[Type] is null then 'Dont Exist' 
when UAT.Name <> LIVE.Name then 'Name Diff'
when  UAT.Date < LIVE.Date then 'Date UAT Older'
when  UAT.Date > LIVE.Date then 'Date LIVE Older'  
when UAT.Time < LIVE.Time then 'Time UAT Older'
when UAT.Time > LIVE.Time then 'Time LIVE Older'
when  UAT.[BLOB Size] > LIVE.[BLOB Size] then 'BLOB Size UAT Greater'
when  UAT.[BLOB Size] < LIVE.[BLOB Size] then 'BLOB Size LIVE Greater'
when UAT.[Version List] <> LIVE.[Version List] then 'Version List Diff' 
 end 'Diference'
from [database_you_want_as_uat_dev].[dbo].[Object] UAT
left join  [database_you_want_as_live].[dbo].[Object] LIVE on
	UAT.[Type] = LIVE.[Type] and UAT.ID = LIVE.ID
Where UAT.[Type] <> 0 and (LIVE.[Type] is null
or UAT.Name <> LIVE.Name
or UAT.Date <> LIVE.Date or UAT.Time <> LIVE.Time)
	) t
group by   t.[Type UAT], t.[DS UAT Type], t.Diference
order by t.[Type UAT], t.Diference



select UAT.[Type] 'Type UAT' 
, case UAT.[Type] when 0 then 'Table Data' when 1 then 'Table' when 2 then '' when 3 then 'Report' when 4 then '' when 5 then 'Codeunit' when 6 then 'XMLport' when 7 then 'MenuSuite' when 8 then 'Page' when 9 then 'Query' when 10 then 'System' end 'DS UAT Type'
--Table Data,Table,,Report,,Codeunit,XMLport,MenuSuite,Page,Query,System
, UAT.ID 'ID UAT' , UAT.Name 'NAME UAT'
, UAT.Date 'Date UAT', UAT.Time 'Time UAT'
, convert(varchar(10), UAT.Date, 105) + ' ' + SUBSTRING(convert(varchar(25), UAT.Time, 121) ,12,12) 'DateTime UAT'
, UAT.[BLOB Size] 'BLOB Size UAT', UAT.[Version List] 'Version List UAT'
,LIVE.[Type] 'Type LIVE' , LIVE.ID 'ID LIVE' , LIVE.Name 'NAME LIVE'
, LIVE.Date 'Date LIVE', LIVE.Time 'Time LIVE'
, convert(varchar(10), LIVE.Date, 105) + ' ' + SUBSTRING(convert(varchar(25), LIVE.Time, 121) ,12,12) 'DateTime LIVE'
, LIVE.[BLOB Size] 'BLOB Size LIVE', LIVE.[Version List] 'Version List LIVE'
, case when LIVE.[Type] is null then 'Dont Exist' 
when UAT.Name <> LIVE.Name then 'Name Diff'
when  UAT.Date < LIVE.Date then 'Date UAT Older'
when  UAT.Date > LIVE.Date then 'Date LIVE Older'  
when UAT.Time < LIVE.Time then 'Time UAT Older'
when UAT.Time > LIVE.Time then 'Time LIVE Older'
when  UAT.[BLOB Size] > LIVE.[BLOB Size] then 'BLOB Size UAT Greater'
when  UAT.[BLOB Size] < LIVE.[BLOB Size] then 'BLOB Size LIVE Greater'
when UAT.[Version List] <> LIVE.[Version List] then 'Version List Diff' 
 end 'Diference'

from [database_you_want_as_uat_dev].[dbo].[Object] UAT
left join  [database_you_want_as_live].[dbo].[Object] LIVE on
	UAT.[Type] = LIVE.[Type] and UAT.ID = LIVE.ID
Where UAT.[Type] <> 0 and (LIVE.[Type] is null
or UAT.Name <> LIVE.Name
or UAT.Date <> LIVE.Date or UAT.Time <> LIVE.Time
)