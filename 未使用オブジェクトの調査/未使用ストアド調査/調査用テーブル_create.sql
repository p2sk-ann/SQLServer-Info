--[dm_exec_procedure_stats_usage_dump]というテーブルを作成
select
  getdate() as first_insert_date,
  object_name(ps.object_id, ps.database_id) as object_name,
  db_name(ps.database_id) as database_name,
  ps.last_execution_time,
  o.modify_date as last_modify_date,
  o.create_date as create_date,
  ps.cached_time as last_cached_time,
  ps.execution_count as last_execution_count
into dm_exec_procedure_stats_usage_dump
from
  sys.dm_exec_procedure_stats  as ps
  left join sys.objects as o on o.object_id = ps.object_id
where object_name(ps.object_id, ps.database_id) is not null
and object_name(ps.object_id, ps.database_id) not like 'sp[_]MS%' --レプリ系除外
and db_name(ps.database_id) not in ('master', 'msdb', 'tempdb', 'model', 'distribution')
order by cached_time asc

--クラスタ化インデックス作成
create clustered index CIX_dm_exec_procedure_stats_usage_dump on dm_exec_procedure_stats_usage_dump(object_name, database_name)

--Unique制約作成
alter table dm_exec_procedure_stats_usage_dump add constraint UQ_dm_exec_procedure_stats_usage_dump unique (object_name, database_name)   
