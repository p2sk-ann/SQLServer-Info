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
