select getdate() as collect_date, *
into dm_os_wait_stats_dump
from sys.dm_os_wait_stats with(nolock)
where 1=0
