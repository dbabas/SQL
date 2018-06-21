
/***  (c) 2012, STRYK System Improvement, Jörg Stryk   ***/
/***                   www.stryk.info                  ***/

-- Create Block-Detection Table

-- IMPORTANT NOTICE: Replace <DatabaseName> with actual name of the NAV database!

USE [<DatabaseName>]  -- select NAV database here
GO

CREATE TABLE [dbo].[ssi_BlockLog]
 (
  [entry_no] bigint identity constraint [ssi_BlockLog$pk_ci] primary key clustered,
  [timestamp] datetime,
  [db] varchar(128) collate database_default,
  [waitresource] varchar(128),
  [table_name] varchar(128) collate database_default,
  [index_name] varchar(128) collate database_default,
  [start_time] datetime,
  [waittime] bigint,
  [lastwaittype] varchar(128),
  [spid] int,
  [loginame] varchar(128) collate database_default,
  [hostname] varchar(128) collate database_default,
  [program_name] varchar(128) collate database_default,
  [cmd] nvarchar(max) collate database_default,
  [query_plan] xml,
  [status] varchar(128) collate database_default,
  [cpu] bigint,
  [lock_timeout] int,
  [blocked by] int,
  [loginame 2] varchar(128) collate database_default,
  [hostname 2] varchar(128) collate database_default,
  [program_name 2] varchar(128) collate database_default,
  [cmd 2] nvarchar(max) collate database_default,
  [query_plan 2] xml,
  [status 2] varchar(128) collate database_default,
  [cpu 2] bigint 
  )
GO

CREATE INDEX [$1] ON [dbo].[ssi_BlockLog]
([start_time], [table_name], [index_name])
GO
CREATE INDEX [$2] ON [dbo].[ssi_BlockLog]
([loginame], [loginame 2])
GO

