--Create a lock and check its details

--Start a transaction
begin tran
update Item2
set Description='Bicycle'
where No_ = 1000

--On a different SSMS window, start a new transaction
begin tran
update Item2
set Description='Bicycle'
where No_ = 1000
rollback

--Query the sys.dm_tran_locks to see the lock details
SELECT	dtl.request_session_id,
		dtl.resource_database_id,
		dtl.resource_associated_entity_id,
		dtl.resource_type,
		dtl.resource_description,
		dtl.request_mode,
		dtl.request_status
FROM	sys.dm_tran_locks AS dtl
WHERE   dtl.request_session_id = @@SPID ;

--DO NOT FORGET to rollback the first transaction.
ROLLBACK