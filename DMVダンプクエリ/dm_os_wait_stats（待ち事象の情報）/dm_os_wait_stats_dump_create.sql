select getdate() as collect_date, *
into dm_os_wait_stats_dump
from sys.dm_os_wait_stats with(nolock)
where 1=0

--古いデータ削除用
create index IX_dm_os_wait_stats_dump_collect_date on dm_os_wait_stats_dump(collect_date)
