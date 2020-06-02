insert into dm_os_latch_stats_dump
select 
	getdate() as collect_date
	,*
from sys.dm_os_latch_stats
where wait_time_ms > 0
option(maxdop 1)
