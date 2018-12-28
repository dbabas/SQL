--List all databases with sizes

with fs
as
(
    select database_id, type, size * 8.0 / 1024 size
    from sys.master_files
)
select 
    name
    ,(select sum(size) from fs where type = 0 and fs.database_id = db.database_id) DataFileSizeMB
    ,(select sum(size) from fs where type = 1 and fs.database_id = db.database_id) LogFileSizeMB
	,(select sum(size) from fs where type = 0 and fs.database_id = db.database_id)+(select sum(size) from fs where type = 1 and fs.database_id = db.database_id) TotalMB
from sys.databases db
order by TotalMB desc