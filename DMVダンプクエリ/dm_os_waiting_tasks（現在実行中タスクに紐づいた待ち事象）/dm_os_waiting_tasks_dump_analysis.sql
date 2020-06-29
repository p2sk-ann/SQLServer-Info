select * from dm_os_waiting_tasks_dump
where collect_date = '2020-06-29 17:54:11.870'
order by start_time, blocking_exec_context_id
