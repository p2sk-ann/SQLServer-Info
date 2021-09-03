set transaction isolation level read uncommitted

select * from dm_os_tasks_dump
order by collect_date
