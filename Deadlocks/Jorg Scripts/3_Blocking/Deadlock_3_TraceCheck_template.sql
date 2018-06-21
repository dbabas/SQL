

USE [NAV_403_PTB]
GO

-- truncate table ssi_DeadlockTrace

exec ssi_dlg_trace_check 
  @tracefile = 'C:\Users\jstryk\Desktop\WEILING\PTB_Log\ssi_Deadlock_Trace.trc',
  @append = 0  -- no append, overwrite
go

--exec ssi_dlg_trace_check 
--  @tracefile = 'E:\PTB_Log\ssi_Deadlock_Trace_20140518_121130.trc',
--  @append = 1  -- append
--go

select distinct [VictimLoginName], [LiveLoginName], count(*) [Count] from ssi_DeadlockTrace (nolock)
group by [VictimLoginName], [LiveLoginName]
order by 3 desc
go

select distinct [VictimLoginName], count(*) [Count] from ssi_DeadlockTrace (nolock)
group by [VictimLoginName]
order by 2 desc
go

select distinct q.[ObjName], sum(q.[Count]) [Count] 
from
    (select distinct [VictimObjName] [ObjName], count(*) [Count] from ssi_DeadlockTrace (nolock)
    group by [VictimObjName]
    union
    select distinct [LiveObjName] [ObjName], count(*) [Count] from ssi_DeadlockTrace (nolock)
    group by [LiveObjName]) q
group by q.[ObjName]
order by 2 desc
go

select distinct q.[Query], sum(q.[Count]) [Count] 
from
    (select distinct [VictimExecStack] [Query], count(*) [Count] from ssi_DeadlockTrace (nolock)
    group by [VictimExecStack]
    union
    select distinct [LiveExecStack] [Query], count(*) [Count] from ssi_DeadlockTrace (nolock)
    group by [LiveExecStack]) q
group by q.[Query]
order by 2 desc
go

select distinct q.[Query], sum(q.[Count]) [Count] 
from
    (select distinct [VictimInputBuffer] [Query], count(*) [Count] from ssi_DeadlockTrace (nolock)
    group by [VictimInputBuffer]
    union
    select distinct [LiveInputBuffer] [Query], count(*) [Count] from ssi_DeadlockTrace (nolock)
    group by [LiveInputBuffer]) q
group by q.[Query]
order by 2 desc
go
SELECT * FROM ssi_DeadlockTrace (nolock) order by entry_no
GO
