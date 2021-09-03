set transaction isolation level read uncommitted

select 
	 getdate() as collect_date
	,sum(used_page_count) as sum_used_page_count -- reservedの中で実際にデータが書き込まれているサイズ
	,sum(reserved_page_count) as sum_reserved_page_count --確保しているエクステントのサイズ
into dm_db_partition_stats_dump
from sys.dm_db_partition_stats with(nolock)

--古いデータ削除用
create index IX_dm_db_partition_stats_dump_collect_date on dm_db_partition_stats_dump(collect_date)
