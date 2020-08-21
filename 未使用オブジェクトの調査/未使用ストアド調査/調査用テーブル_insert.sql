set nocount on
merge dm_exec_procedure_stats_usage_dump as target
using (
	select
	  getdate() as first_insert_date,
	  object_name(ps.object_id, ps.database_id) as object_name,
	  db_name(ps.database_id) as database_name,
	  ps.last_execution_time,
	  o.modify_date,
	  o.create_date,
	  ps.cached_time,
	  ps.execution_count
	from
	  sys.dm_exec_procedure_stats  as ps
	  left join sys.objects as o on o.object_id = ps.object_id
	where object_name(ps.object_id, ps.database_id) is not null
	and object_name(ps.object_id, ps.database_id) not like 'sp[_]MS%' --レプリ系除外
) as source
on target.object_name = source.object_name
when matched then
	update set last_execution_time = source.last_execution_time
			  ,last_modify_date = source.modify_date
			  ,create_date = source.create_date --alterでなくdrop+createされるケースを考慮
			  ,last_cached_time = source.cached_time
			  ,last_execution_count = source.execution_count
when not matched then
	insert (first_insert_date, object_name, database_name, last_execution_time, last_modify_date, create_date, last_cached_time, last_execution_count)
	values (source.first_insert_date, source.object_name, source.database_name, source.last_execution_time, source.modify_date, source.create_date, source.cached_time, source.execution_count)
option (maxdop 1) 
;
