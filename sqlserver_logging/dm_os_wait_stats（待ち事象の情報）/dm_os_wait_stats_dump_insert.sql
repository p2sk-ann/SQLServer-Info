insert into dm_os_wait_stats_dump
select getdate() as collect_date, *
from sys.dm_os_wait_stats with(nolock)
where waiting_tasks_count > 0
option(maxdop 1)
