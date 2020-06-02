select 
	getdate() as collect_date
	,*
into dm_os_latch_stats_dump
from sys.dm_os_latch_stats
where 1=0
