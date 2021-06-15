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
