insert into dm_exec_procedure_stats_dump
select top 500
  getdate() as collect_date,
  object_name(ps.object_id, ps.database_id) as object_name,
  ps.last_execution_time,
  o.modify_date,
  ps.cached_time,
  ps.execution_count,
  ps.total_worker_time,
  ps.last_worker_time,
  ps.min_worker_time,
  ps.max_worker_time,
  ps.total_elapsed_time,
  ps.last_elapsed_time,
  ps.min_elapsed_time,
  ps.max_elapsed_time,
  ps.total_logical_writes,
  ps.last_logical_writes,
  ps.min_logical_writes,
  ps.max_logical_writes,
  ps.total_logical_reads,
  ps.last_logical_reads,
  ps.min_logical_reads,
  ps.max_logical_reads,
  ps.plan_handle,
  ps.sql_handle,
  ps.object_id
from
  sys.dm_exec_procedure_stats  as ps
  cross apply sys.dm_exec_sql_text(sql_handle)
  cross apply sys.dm_exec_query_plan(plan_handle)
  left join sys.objects as o on o.object_id = ps.object_id
where last_execution_time >= dateadd(minute, -1, getdate())
option(maxdop 1)
