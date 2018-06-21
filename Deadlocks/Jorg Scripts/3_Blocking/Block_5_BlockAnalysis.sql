
/***  (c) 2012, STRYK System Improvement, Jörg Stryk   ***/
/***                   www.stryk.info                  ***/

-- Investigate Blocks

-- IMPORTANT NOTICE: Replace <DatabaseName> with actual name of the NAV database!

--USE [<DatabaseName>]  -- select NAV database here
--GO

DECLARE @start_date datetime, @end_date datetime

SET @start_date = '01.01.1753 00:00'  -- define start date/time-stamp
SET @end_date   = '31.12.2099 23:59'  -- define end date/time-stamp


-- Total Blocks within period
select [db], [first] = min([start_time]), [last] = max([start_time]), [count] = count(*) 
from (select distinct [db], [start_time], [waitresource], [table_name], [index_name], [blocked_login] = [loginame], [blocking_login] = [loginame 2] 
      from  ssi_BlockLog where [timestamp] between @start_date and @end_date) b1
group by [db]

-- Blocks per waitresource
SELECT [db],
       [table_name], 
       [index_name], 
       [count] = COUNT(*), 
       (select MAX([waittime]) 
        from ssi_BlockLog b2 
        where b2.[db] = b1.[db] and
              b2.[table_name] = b1.table_name and 
              isnull(b2.[index_name], '') = isnull(b1.index_name, '') and
              b2.[timestamp] between @start_date and @end_date 
       ) as [max_duration], 
       (select AVG([waittime]) 
        from ssi_BlockLog b2 
        where b2.[db] = b1.[db] and
              b2.[table_name] = b1.table_name and 
              isnull(b2.[index_name], '') = isnull(b1.index_name, '') and
              b2.[timestamp] between @start_date and @end_date
       ) as [avg_duration] 
FROM (select distinct [db],[start_time], [table_name], [index_name]
      from  ssi_BlockLog where [timestamp] between @start_date and @end_date ) b1
GROUP BY [db], [table_name], [index_name]
ORDER BY [count] DESC


-- Blocks per "Blocked User"
SELECT [db],
       [blocked_login], 
       [count] = COUNT(*), 
       (select MAX([waittime]) 
        from ssi_BlockLog b2 
        where b2.[db] = b1.[db] and
              b2.[loginame] = b1.[blocked_login] and
              b2.[timestamp] between @start_date and @end_date
       ) as [max_duration], 
       (select AVG([waittime]) 
        from ssi_BlockLog b2 
        where b2.[db] = b1.[db] and
              b2.[loginame] = b1.[blocked_login] and
              b2.[timestamp] between @start_date and @end_date
       ) as [avg_duration] 
FROM (select distinct [db], [start_time],[blocked_login] = [loginame]
      from  ssi_BlockLog where [timestamp] between @start_date and @end_date) b1
GROUP BY [db], [blocked_login]
ORDER BY [count] DESC

-- Blocks per "Blocking Login"
SELECT [db],
       [blocking_login], 
       [count] = COUNT(*), 
       (select MAX([waittime]) 
        from ssi_BlockLog b2 
        where b2.[db] = b1.[db] and
              b2.[loginame 2] = b1.[blocking_login] and
              b2.[timestamp] between @start_date and @end_date
       ) as [max_duration], 
       (select AVG([waittime]) 
        from ssi_BlockLog b2 
        where b2.[db] = b1.[db] and
              b2.[loginame 2] = b1.[blocking_login] and
              b2.[timestamp] between @start_date and @end_date
       ) as [avg_duration] 
FROM (select distinct [db], [start_time], [blocking_login] = [loginame 2]
      from  ssi_BlockLog where [timestamp] between @start_date and @end_date) b1
GROUP BY [db], [blocking_login]
ORDER BY [count] DESC


-- Blocks per Ressource, Blocked User and Blocking User
SELECT [db],
       [table_name], 
       [index_name], 
       [blocked_login], 
       [blocking_login], 
       [count] = COUNT(*), 
       (select MAX([waittime]) 
        from ssi_BlockLog b2 
        where b2.[db] = b1.[db] and
              b2.[table_name] = b1.table_name and 
              isnull(b2.[index_name], '') = isnull(b1.index_name, '') and 
              b2.[loginame]=b1.[blocked_login] and
              b2.[loginame 2]=b1.[blocking_login] and
              b2.[timestamp] between @start_date and @end_date
       )       
       as [max_duration], 
       (select AVG([waittime]) 
        from ssi_BlockLog b2 
        where b2.[db] = b1.[db] and
              b2.[table_name] = b1.table_name and 
              isnull(b2.[index_name], '') = isnull(b1.index_name, '') and
              b2.[loginame]=b1.[blocked_login] and
              b2.[loginame 2]=b1.[blocking_login] and
              b2.[timestamp] between @start_date and @end_date
       )       
       as [avg_duration] 
FROM (select distinct [db], [start_time], [table_name], [index_name], [blocked_login] = [loginame], [blocking_login] = [loginame 2] 
      from  ssi_BlockLog where [timestamp] between @start_date and @end_date) b1
GROUP BY [db], [table_name], [index_name], [blocked_login], [blocking_login]
ORDER BY [count] DESC

-- Block Buffer excerpt
select top 1000 * from ssi_BlockLog where "timestamp" between @start_date and @end_date order by "entry_no" desc
-- Blocks per hours
SELECT [db], convert(datetime, convert(datetime, left(convert(varchar(20),[start_time], 113), 14) + ':00')) as [time], [blocks_per_hour] = COUNT(*)
FROM (select distinct [db],[start_time] from  ssi_BlockLog) b1
WHERE [start_time] between @start_date and @end_date
GROUP BY [db], convert(datetime, left(convert(varchar(20),[start_time], 113), 14) + ':00')
ORDER BY [db], convert(datetime, left(convert(varchar(20),[start_time], 113), 14) + ':00')

-- Blocks per Day
SELECT [db], convert(datetime, convert(varchar(20),[start_time], 104)) as [date], [Blocks] = COUNT(*)
FROM (select distinct [db],[start_time] from  ssi_BlockLog) b1
GROUP BY [db],convert(datetime, convert(varchar(20),[start_time], 104))
ORDER BY [db],convert(datetime, convert(varchar(20),[start_time], 104)) DESC

-- affected queries
select "cmd" as "query", count(*) as "occurrence" 
from "ssi_BlockLog"
where [start_time] between @start_date and @end_date
group by "cmd"
order by count(*) desc, "cmd"

-- affected queries by start_time
select "cmd" as "query", "start_time", count(*) as "occurrence" 
from "ssi_BlockLog"
where [start_time] between @start_date and @end_date
group by "cmd", "start_time"
order by count(*) desc, "cmd", "start_time" desc