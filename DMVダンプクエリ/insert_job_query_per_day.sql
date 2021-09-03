set transaction isolation level read uncommitted
set lock_timeout 1000
set nocount on

insert into dm_db_partition_stats_dump
select 
 getdate() as collect_date
,sum(used_page_count) as sum_used_page_count -- reservedの中で実際にデータが書き込まれているサイズ
,sum(reserved_page_count) as sum_reserved_page_count --確保しているエクステントのサイズ
from sys.dm_db_partition_stats with(nolock)
option (maxdop 1)

insert into dm_db_index_usage_stats_dump_full
select
  getdate() as collect_date
  ,object_name(sys.indexes.object_id) as table_name
  ,sys.indexes.name as index_name
  ,sys.dm_db_partition_stats.row_count as row_count
  ,sys.dm_db_partition_stats.reserved_page_count * 8.0 / 1024 as size_mb
  ,type_desc
  ,sys.dm_db_index_usage_stats.*
from
  sys.dm_db_partition_stats
left join sys.indexes on sys.dm_db_partition_stats.object_id = sys.indexes.object_id
                      and sys.dm_db_partition_stats.index_id = sys.indexes.index_id
left join sys.dm_db_index_usage_stats on sys.dm_db_partition_stats.object_id = sys.dm_db_index_usage_stats.object_id
                                      and sys.dm_db_partition_stats.index_id = sys.dm_db_index_usage_stats.index_id
                                      and sys.dm_db_index_usage_stats.database_id = db_id()
option(maxdop 1)
