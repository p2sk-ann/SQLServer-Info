set transaction isolation level read uncommitted

select * from dm_os_memory_clerks_dump with(nolock)
order by collect_date
