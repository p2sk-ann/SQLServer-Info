set transaction isolation level read uncommitted
SET LOCK_TIMEOUT 1000

insert into dm_db_index_operational_stats_dump
select 
	 getdate() as collect_date
	,object_name(i.object_id) as table_name
	,i.name
	,d.*
from sys.dm_db_index_operational_stats(db_id(), null, null, null) d
left join sys.indexes i on d.OBJECT_ID = i.OBJECT_ID
	and d.index_id = i.index_id
option(maxdop 1)

insert into dm_db_index_usage_stats_dump
select
  getdate() as collect_date
  ,object_name(sys.indexes.object_id) as table_name
  ,sys.indexes.name as index_name
  ,sys.dm_db_partition_stats.row_count as row_count
  ,sys.dm_db_partition_stats.reserved_page_count * 8.0 / 1024 as size_mb
  ,type_desc
  ,sys.dm_db_index_usage_stats.*
from
  sys.dm_db_partition_stats
left join sys.indexes on sys.dm_db_partition_stats.object_id = sys.indexes.object_id
                      and sys.dm_db_partition_stats.index_id = sys.indexes.index_id
left join sys.dm_db_index_usage_stats on sys.dm_db_partition_stats.object_id = sys.dm_db_index_usage_stats.object_id
                                      and sys.dm_db_partition_stats.index_id = sys.dm_db_index_usage_stats.index_id
                                      and sys.dm_db_index_usage_stats.database_id = db_id()
where
     last_user_seek > dateadd(minute, -2, getdate())
  or last_user_scan > dateadd(minute, -2, getdate())
  or last_user_lookup > dateadd(minute, -2, getdate())
  or last_user_update > dateadd(minute, -2, getdate())
  or last_system_seek > dateadd(minute, -2, getdate())
  or last_system_scan > dateadd(minute, -2, getdate())
  or last_system_lookup > dateadd(minute, -2, getdate())
  or last_system_update > dateadd(minute, -2, getdate())
option(maxdop 1)

insert into dm_exec_procedure_stats_dump
select top 500
  getdate() as collect_date,
  object_name(ps.object_id, ps.database_id) as object_name,
  ps.last_execution_time,
  o.modify_date,
  ps.database_id,
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
and object_name(ps.object_id, ps.database_id) is not null
option(maxdop 1)

insert into dm_exec_query_stats_dump
select
  getdate() as collect_date
  ,qt.dbid
  --サイズが大きくなりすぎるので500文字だけ格納
  ,substring(qt.text, 1, 500) as parent_query
  --サイズが大きくなりすぎるので500文字だけ格納
  ,substring(substring(qt.text, qs.statement_start_offset / 2, (
      case 
        when qs.statement_end_offset = - 1
          then len(convert(nvarchar(max), qt.text)) * 2
        else qs.statement_end_offset
      end - qs.statement_start_offset
   ) / 2), 1, 500) as statement
  ,execution_count
  ,total_worker_time
  ,total_elapsed_time
  ,total_physical_reads
  ,total_logical_reads
  ,total_logical_writes
  ,total_dop
  ,min_dop
  ,max_dop
  ,max_worker_time
  ,max_clr_time
  ,max_elapsed_time
  ,last_execution_time
  ,last_worker_time
  ,last_clr_time
  ,last_elapsed_time
  ,plan_generation_num
  ,total_rows
  ,last_rows
  ,min_rows
  ,max_rows
  ,creation_time
  ,total_grant_kb
  ,last_grant_kb
  ,min_grant_kb
  ,max_grant_kb
  ,total_used_grant_kb
  ,last_used_grant_kb
  ,min_used_grant_kb
  ,max_used_grant_kb
  ,total_ideal_grant_kb
  ,last_ideal_grant_kb
  ,min_ideal_grant_kb
  ,max_ideal_grant_kb
  ,query_hash
  ,query_plan_hash
from sys.dm_exec_query_stats qs
outer apply sys.dm_exec_sql_text(qs.sql_handle) as qt
where
   last_execution_time > dateadd(minute, -1, getdate())
or creation_time > dateadd(minute, -1, getdate())
option(maxdop 1)

insert into dm_exec_requests_dump
select top 200
   getdate() as collect_date
  ,der.session_id as spid
  ,der.blocking_session_id as blk_spid
  ,datediff(s, der.start_time, getdate()) as elapsed_sec
  ,db_name(der.database_id) as db_name
  ,des.host_name
  ,des.program_name
  ,der.status
  ,dest.text as command_text
  ,replace(replace(replace(substring(dest.text, (der.statement_start_offset / 2) + 1, ((case der.statement_end_offset when - 1 then datalength(dest.text) else der.statement_end_offset end - der.statement_start_offset) / 2) + 1), char(13), ' '), char(10), ' '), char(9), ' ') as current_running_stmt
  ,datediff(s, der.start_time, getdate()) as time_sec
  ,wait_resource
  ,wait_type
  ,last_wait_type
  ,der.wait_time as wait_time_ms
  ,der.open_transaction_count
  ,der.command
  ,der.percent_complete
  ,der.cpu_time
  ,(case der.transaction_isolation_level when 0 then 'Unspecified' when 1 then 'ReadUncomitted' when 2 then 'ReadCommitted' when 3 then 'Repeatable' when 4 then 'Serializable' when 5 then 'Snapshot' else cast(der.transaction_isolation_level as varchar) end) as transaction_isolation_level
  ,der.granted_query_memory * 8 as granted_query_memory_kb
  ,der.reads
  ,der.writes
  ,der.logical_reads
  ,der.query_hash
  ,der.query_plan_hash
  ,des.login_time
  ,des.login_name
  ,des.last_request_start_time
  ,des.last_request_end_time
  ,des.cpu_time as session_cpu_time
  ,des.memory_usage
  ,des.total_scheduled_time
  ,des.total_elapsed_time
  ,des.reads as session_reads
  ,des.writes as session_writes
  ,des.logical_reads as session_logical_reads
  ,der.scheduler_id
from sys.dm_exec_requests der
join sys.dm_exec_sessions des on des.session_id = der.session_id
outer apply sys.dm_exec_sql_text(sql_handle) as dest
where des.is_user_process = 1
  and datediff(s, der.start_time, getdate()) >= 1
  and datediff(s, der.start_time, getdate()) < (3600 * 10)
order by datediff(s, der.start_time, getdate()) desc
option (maxdop 1)

insert into dm_io_virtual_file_stats_dump
select
	 getdate() as collect_date
	,a.database_id
	,a.file_id
	,file_guid
	,type
	,type_desc
	,data_space_id
	,name
	,physical_name
	,state
	,state_desc
	,size
	,max_size
	,growth
	,is_media_read_only
	,is_read_only
	,is_sparse
	,is_percent_growth
	,is_name_reserved
	,create_lsn
	,drop_lsn
	,read_only_lsn
	,read_write_lsn
	,differential_base_lsn
	,differential_base_guid
	,differential_base_time
	,redo_start_lsn
	,redo_start_fork_guid
	,redo_target_lsn
	,redo_target_fork_guid
	,backup_lsn
	,credential_id
	,sample_ms
	,num_of_reads
	,num_of_bytes_read
	,io_stall_read_ms
	,io_stall_queued_read_ms
	,num_of_writes
	,num_of_bytes_written
	,io_stall_write_ms
	,io_stall_queued_write_ms
	,io_stall
	,size_on_disk_bytes
	,file_handle
from sys.master_files a
join sys.dm_io_virtual_file_stats(null, null) b
on a.database_id = b.database_id and a.file_id = b.file_id
option (maxdop 1)

insert into dm_os_latch_stats_dump
select 
	getdate() as collect_date
	,*
from sys.dm_os_latch_stats
where wait_time_ms > 0
option(maxdop 1)

insert into dm_os_schedulers_dump
select
    getdate() as collect_date
    ,*
from sys.dm_os_schedulers
option (maxdop 1)

insert into dm_os_wait_stats_dump
select getdate() as collect_date, *
from sys.dm_os_wait_stats with(nolock)
where waiting_tasks_count > 0
option(maxdop 1)

insert into dm_os_waiting_tasks_dump
select top 100
   getdate() as collect_date
  ,wt.session_id
  ,es.program_name
  ,es.host_name
  ,wt.blocking_session_id
  ,er.blocking_session_id as er_blocking_session_id
  ,wt.exec_context_id
  ,er.start_time
  ,er.wait_time
  ,wt.wait_duration_ms
  ,er.status
  ,er.command
  ,wt.wait_type
  ,er.wait_type as er_wait_type
  ,er.last_wait_type
  ,wt.resource_description
  ,er.wait_resource
  ,wt.blocking_exec_context_id
  ,ib.event_info
  ,ib.event_type
  ,ib.parameters
  ,er.query_hash
  ,er.query_plan_hash
  ,er.cpu_time
  ,er.total_elapsed_time
  ,er.reads
  ,er.writes
  ,er.logical_reads
from sys.dm_os_waiting_tasks as wt with (nolock)
left join sys.dm_exec_requests as er with (nolock) on er.session_id = wt.session_id
left join sys.dm_exec_sessions as es with (nolock) on es.session_id = wt.session_id
outer apply sys.dm_exec_input_buffer(wt.session_id, null) as ib
where wt.session_id > 50
  and wt.wait_duration_ms >= 100
  and er.status <> 'background'
option (maxdop 1)

INSERT INTO dm_os_tasks_dump
SELECT 
	 getdate() as collect_date
	,ot.session_id
	,count(*) AS current_using_cpu_count
	,cast(count(*) * 100.0 / (
			SELECT cpu_count
			FROM sys.dm_os_sys_info
			) AS NUMERIC(4, 1)) AS cpu_percentage
	,count(*) OVER () AS all_using_cpu_count
	,cast(count(*) OVER () * 100.0 / (
			SELECT cpu_count
			FROM sys.dm_os_sys_info
			) AS NUMERIC(4, 1)) AS current_cpu_percent
	,max(es.STATUS) AS STATUS
	,max(host_name) AS host_name
	,max(program_name) AS program_name
	,max(TEXT) AS qery_text
FROM sys.dm_os_tasks ot WITH (NOLOCK)
LEFT JOIN sys.dm_exec_sessions es WITH (NOLOCK) ON ot.session_id = es.session_id
LEFT JOIN sys.dm_exec_requests er WITH (NOLOCK) ON ot.session_id = er.session_id
OUTER APPLY sys.dm_exec_sql_text(sql_handle) AS dest
WHERE task_state = 'RUNNING'
GROUP BY ot.session_id
ORDER BY count(*) DESC
option (maxdop 1)

insert into sys_stats_dump
select 
     getdate() as collect_date
    ,object_name(s1.object_id) as object_name
    ,s1.name as statistics_name
    ,left(colname, len(colname) - 1) as column_list
	,(case when charindex('|', left(colname, len(colname) - 1), 1) > 1 then 1 else 0 end) as multi_column_flag --1 : 複数列の統計情報
    ,stats_date(s1.object_id, s1.stats_id) as statsdate --ここで統計情報の更新時間を確認できる
from sys.stats as s1
inner join sys.stats_columns as sc on s1.object_id = sc.object_id
    and s1.stats_id = sc.stats_id and stats_column_id = 1
inner join sys.columns as c on sc.object_id = c.object_id
    and c.column_id = sc.column_id
cross apply (
    select
      c.name + ' | ' 
    from
      sys.stats as s2
    inner join sys.stats_columns as sc on s2.object_id = sc.object_id
      and s2.stats_id = sc.stats_id
    inner join sys.columns as c on sc.object_id = c.object_id
      and c.column_id = sc.column_id
    and s1.object_id = s2.object_id and s1.stats_id = s2.stats_id
	order by stats_column_id
for xml PATH('')
) as a(colname)
where stats_date(s1.object_id, s1.stats_id) > dateadd(minute, -2, getdate())
option(maxdop 1)
