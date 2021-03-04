insert into dm_db_partition_stats_dump
select 
 getdate() as collect_date
,sum(used_page_count) as sum_used_page_count -- reservedの中で実際にデータが書き込まれているサイズ
,sum(reserved_page_count) as sum_reserved_page_count --確保しているエクステントのサイズ
from sys.dm_db_partition_stats with(nolock)
option (maxdop 1)
