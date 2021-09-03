set transaction isolation level read uncommitted

select * from dm_db_partition_stats_dump with(nolock)
order by collect_date
