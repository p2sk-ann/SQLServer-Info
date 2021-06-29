set transaction isolation level read uncommitted
set lock_timeout 1000
set nocount on

/*
drop table dm_db_file_space_usage_tempdb_dump
drop table dm_db_index_operational_stats_dump
drop table dm_db_index_usage_stats_dump
drop table dm_db_partition_stats_dump
drop table dm_exec_procedure_stats_dump
drop table dm_exec_query_stats_dump
drop table dm_exec_requests_dump_per_several_seconds
drop table dm_exec_requests_dump
drop table dm_io_virtual_file_stats_dump
drop table dm_os_latch_stats_dump
drop table dm_os_memory_clerks_dump
drop table dm_os_schedulers_dump
drop table dm_os_tasks_dump
drop table dm_os_wait_stats_dump
drop table dm_os_waiting_tasks_dump
drop table sys_stats_dump
drop table dm_exec_query_stats_dump_full
*/

select
getdate() as collect_date
,sum(total_page_count) * 8 / 1024.0 as sum_total_page_size_mb --tempdbのサイズ
,sum(allocated_extent_page_count) * 8 / 1024.0 as sum_allocated_extent_page_size_mb --割り当て済みのサイズ
,sum(unallocated_extent_page_count) * 8 / 1024.0 as sum_unallocated_extent_page_size_mb --未割当のサイズ
,sum(version_store_reserved_page_count) * 8 / 1024.0 as sum_version_store_reserved_page_size_mb --バージョンストアで使用しているサイズ
,sum(user_object_reserved_page_count) * 8 / 1024.0 as sum_user_object_reserved_page_size_mb --一時テーブルなど
,sum(internal_object_reserved_page_count) * 8 / 1024.0 as sum_internal_object_reserved_page_size_mb --ソートなどに使用されている領域
,sum(mixed_extent_page_count) * 8 / 1024.0 as sum_mixed_extent_page_size_mb --今は単一エクステントが基本のはず
into dm_db_file_space_usage_tempdb_dump
from tempdb.sys.dm_db_file_space_usage --現在のDBの状況が返ってくるので「tempdb.」をつける
option (maxdop 1)


--古いデータ削除用
create index IX_dm_db_file_space_usage_tempdb_dump_collect_date on dm_db_file_space_usage_tempdb_dump(collect_date)


select 
	 getdate() as collect_date
	,object_name(i.object_id) as table_name
	,i.name
	,d.*
into dm_db_index_operational_stats_dump
from sys.dm_db_index_operational_stats(db_id(), null, null, null) d
left join sys.indexes i on d.OBJECT_ID = i.OBJECT_ID
	and d.index_id = i.index_id
where 1=0

--古いデータ削除用
create index IX_dm_db_index_operational_stats_dump_collect_date on dm_db_index_operational_stats_dump(collect_date)


select
  getdate() as collect_date
  ,object_name(sys.indexes.object_id) as table_name
  ,sys.indexes.name as index_name
  ,sys.dm_db_partition_stats.row_count as row_count
  ,sys.dm_db_partition_stats.reserved_page_count * 8.0 / 1024 as size_mb
  ,type_desc
  ,sys.dm_db_index_usage_stats.*
into dm_db_index_usage_stats_dump
from
  sys.dm_db_partition_stats
left join sys.indexes on sys.dm_db_partition_stats.object_id = sys.indexes.object_id
                      and sys.dm_db_partition_stats.index_id = sys.indexes.index_id
left join sys.dm_db_index_usage_stats on sys.dm_db_partition_stats.object_id = sys.dm_db_index_usage_stats.object_id
                                      and sys.dm_db_partition_stats.index_id = sys.dm_db_index_usage_stats.index_id
                                      and sys.dm_db_index_usage_stats.database_id = db_id()
where
  1=0

--古いデータ削除用
create index IX_dm_db_index_usage_stats_dump_collect_date on dm_db_index_usage_stats_dump(collect_date)


select 
 getdate() as collect_date
,sum(used_page_count) as sum_used_page_count -- reservedの中で実際にデータが書き込まれているサイズ
,sum(reserved_page_count) as sum_reserved_page_count --確保しているエクステントのサイズ
into dm_db_partition_stats_dump
from sys.dm_db_partition_stats with(nolock)

--古いデータ削除用
create index IX_dm_db_partition_stats_dump_collect_date on dm_db_partition_stats_dump(collect_date)

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
into dm_exec_procedure_stats_dump
from
  sys.dm_exec_procedure_stats  as ps
  cross apply sys.dm_exec_sql_text(sql_handle)
  cross apply sys.dm_exec_query_plan(plan_handle)
  left join sys.objects as o on o.object_id = ps.object_id
where 1 = 0

--古いデータ削除用
create index IX_dm_exec_procedure_stats_dump_collect_date on dm_exec_procedure_stats_dump(collect_date)

set transaction isolation level read uncommitted
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
into dm_exec_query_stats_dump
from sys.dm_exec_query_stats qs
outer apply sys.dm_exec_sql_text(qs.plan_handle) as qt
where
  1=0

--古いデータ削除用
create index IX_dm_exec_query_stats_dump_collect_date on dm_exec_query_stats_dump(collect_date)

set transaction isolation level read uncommitted
select top (500)
   getdate() as collect_date
  ,der.session_id as spid
  ,der.blocking_session_id as blk_spid
  ,datediff(s, der.start_time, getdate()) as elapsed_sec
  ,db_name(der.database_id) as db_name
  ,des.host_name
  ,des.program_name
  ,der.status
  ,substring(dest.text, 1, 500) as command_text
  ,substring(replace(replace(replace(substring(dest.text, (der.statement_start_offset / 2) + 1, ((case der.statement_end_offset when - 1 then datalength(dest.text) else der.statement_end_offset end - der.statement_start_offset) / 2) + 1), char(13), ' '), char(10), ' '), char(9), ' '), 1, 500) as current_running_stmt
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
  ,dop
  ,deq.grant_time
  ,deq.granted_memory_kb
  ,deq.requested_memory_kb
  ,deq.required_memory_kb
  ,deq.used_memory_kb
  ,deq.max_used_memory_kb
  ,deq.query_cost
  ,deq.queue_id
  ,deq.wait_order
into dm_exec_requests_dump_per_several_seconds
from sys.dm_exec_requests der
join sys.dm_exec_sessions des on des.session_id = der.session_id
left join sys.dm_exec_query_memory_grants deq on deq.session_id = der.session_id
outer apply sys.dm_exec_sql_text(der.sql_handle) as dest
where des.is_user_process = 1
  and datediff(s, der.start_time, getdate()) >= 1
  and datediff(s, der.start_time, getdate()) < 30
order by datediff(s, der.start_time, getdate()) desc
option (maxdop 1)


--古いデータ削除用
create index IX_dm_exec_requests_dump_per_several_seconds_collect_date on dm_exec_requests_dump_per_several_seconds(collect_date)

select top 100
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
  ,dop
  ,deq.grant_time
  ,deq.granted_memory_kb
  ,deq.requested_memory_kb
  ,deq.required_memory_kb
  ,deq.used_memory_kb
  ,deq.max_used_memory_kb
  ,deq.query_cost
  ,deq.queue_id
  ,deq.wait_order
into dm_exec_requests_dump
from sys.dm_exec_requests der
join sys.dm_exec_sessions des on des.session_id = der.session_id
left join sys.dm_exec_query_memory_grants deq on deq.session_id = der.session_id
outer apply sys.dm_exec_sql_text(der.sql_handle) as dest
where 1 = 0

--古いデータ削除用
create index IX_dm_exec_requests_dump_collect_date on dm_exec_requests_dump(collect_date)


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
into dm_io_virtual_file_stats_dump
from sys.master_files a
join sys.dm_io_virtual_file_stats(null, null) b
on a.database_id = b.database_id and a.file_id = b.file_id
where 1=0

--古いデータ削除用
create index IX_dm_io_virtual_file_stats_dump_collect_date on dm_io_virtual_file_stats_dump(collect_date)

select 
	getdate() as collect_date
	,*
into dm_os_latch_stats_dump
from sys.dm_os_latch_stats
where 1=0

--古いデータ削除用
create index IX_dm_os_latch_stats_dump_collect_date on dm_os_latch_stats_dump(collect_date)

--サーバーで使用しているメモリの詳細な内訳
select 
getdate() as collect_date
,type, name, sum(pages_kb) as sum_pages_kb, sum(awe_allocated_kb) as sum_awe_allocated_kb
into dm_os_memory_clerks_dump
from sys.dm_os_memory_clerks with(nolock)
group by type, name
order by sum(pages_kb) desc
option (maxdop 1)

--古いデータ削除用
create index IX_dm_os_memory_clerks_collect_date on dm_os_memory_clerks_dump(collect_date)

select
    getdate() as collect_date
    ,*
into dm_os_schedulers_dump
from sys.dm_os_schedulers

--古いデータ削除用
create index IX_dm_os_schedulers_dump_collect_date on dm_os_schedulers_dump(collect_date)

select 
   getdate() as collect_date
  ,ot.session_id
  ,count(*) as current_using_cpu_count
  ,cast(count(*) * 100.0 / (
      select cpu_count
      from sys.dm_os_sys_info
      ) as numeric(4, 1)) as cpu_percentage
  ,count(*) over () as all_using_cpu_count
  ,cast(count(*) over () * 100.0 / (
      select cpu_count
      from sys.dm_os_sys_info
      ) as numeric(4, 1)) as current_cpu_percent
  ,max(es.status) as status
  ,max(host_name) as host_name
  ,max(program_name) as program_name
  ,max(text) as qery_text
into dm_os_tasks_dump
from sys.dm_os_tasks ot with (nolock)
left join sys.dm_exec_sessions es with (nolock) on ot.session_id = es.session_id
left join sys.dm_exec_requests er with (nolock) on ot.session_id = er.session_id
outer apply sys.dm_exec_sql_text(sql_handle) as dest
where task_state = 'running'
group by ot.session_id
order by count(*) desc
option (maxdop 1)

--古いデータ削除用
create index IX_dm_os_tasks_dump_collect_date on dm_os_tasks_dump(collect_date)


select getdate() as collect_date, *
into dm_os_wait_stats_dump
from sys.dm_os_wait_stats with(nolock)
where 1=0

--古いデータ削除用
create index IX_dm_os_wait_stats_dump_collect_date on dm_os_wait_stats_dump(collect_date)

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
into dm_os_waiting_tasks_dump
from sys.dm_os_waiting_tasks as wt with (nolock)
left join sys.dm_exec_requests as er with (nolock) on er.session_id = wt.session_id
left join sys.dm_exec_sessions as es with (nolock) on es.session_id = wt.session_id
outer apply sys.dm_exec_input_buffer(wt.session_id, null) as ib
where 1=0

--古いデータ削除用
create index IX_dm_os_waiting_tasks_dump_collect_date on dm_os_waiting_tasks_dump(collect_date)

select 
     getdate() as collect_date
    ,object_name(s1.object_id) as object_name
    ,s1.name as statistics_name
    ,left(colname, len(colname) - 1) as column_list
	,(case when charindex('|', left(colname, len(colname) - 1), 1) > 1 then 1 else 0 end) as multi_column_flag --1 : 複数列の統計情報
    ,stats_date(s1.object_id, s1.stats_id) as statsdate --ここで統計情報の更新時間を確認できる
into sys_stats_dump
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
where 1=0

--古いデータ削除用
create index IX_sys_stats_dump_collect_date on sys_stats_dump(collect_date)

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
into dm_exec_query_stats_dump_full
from sys.dm_exec_query_stats qs
outer apply sys.dm_exec_sql_text(qs.plan_handle) as qt
where
  1=0

--古いデータ削除用
create index IX_dm_exec_query_stats_dump_full_collect_date on dm_exec_query_stats_dump_full(collect_date)
