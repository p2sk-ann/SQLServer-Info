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
