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
  ,der.granted_query_memory * 8 as granted_query_memory_kb
into dm_exec_requests_dump
from sys.dm_exec_requests der
join sys.dm_exec_sessions des on des.session_id = der.session_id
outer apply sys.dm_exec_sql_text(sql_handle) as dest
where 1 = 0
