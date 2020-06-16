declare @total_user_seeks bigint
declare @total_user_scans bigint
declare @total_user_lookups bigint
declare @total_user_updates bigint
declare @total_system_seeks bigint
declare @total_system_scans bigint
declare @total_system_lookups bigint
declare @total_system_updates bigint

declare @snapshot_time_earlier datetime
declare @snapshot_time_later datetime
set @snapshot_time_earlier = '2020-06-16 04:00:13.313' --collect_dateに存在する日時を設定（古い方）
set @snapshot_time_later = '2020-06-16 06:03:11.833' --collect_dateに存在する日時を設定（新しい方）

select
     @total_user_seeks = sum(user_seeks)
    ,@total_user_scans = sum(user_scans)
    ,@total_user_lookups = sum(user_lookups)
    ,@total_user_updates = sum(user_updates)
    ,@total_system_seeks = sum(system_seeks)
    ,@total_system_scans = sum(system_scans)
    ,@total_system_lookups = sum(system_lookups)
    ,@total_system_updates = sum(system_updates)
from
(
    select
         a.table_name
        ,a.index_name
        ,a.collect_date
        ,a.row_count
        ,a.size_mb
        ,a.type_desc
        ,(a.user_seeks - b.user_seeks) as user_seeks
        ,(a.user_scans - b.user_scans) as user_scans
        ,(a.user_lookups - b.user_lookups) as user_lookups
        ,(a.user_updates - b.user_updates) as user_updates
        ,(a.system_seeks - b.system_seeks) as system_seeks
        ,(a.system_scans - b.system_scans) as system_scans
        ,(a.system_lookups - b.system_lookups) as system_lookups
        ,(a.system_updates - b.system_updates) as system_updates
    from
    (
        select * from
            dm_db_index_usage_stats_dump
        where collect_date = @snapshot_time_later
    ) as a
    join
    (
        select * from
            dm_db_index_usage_stats_dump
        where collect_date = @snapshot_time_earlier
    ) as b
    on a.table_name = b.table_name and a.index_name = b.index_name
) as c

select
    *
    ,(100.0 * user_seeks / (1+@total_user_seeks)) as percent_user_seeks
    ,(100.0 * user_scans / (1+@total_user_scans)) as percent_user_scans
    ,(100.0 * user_lookups / (1+@total_user_lookups)) as percent_user_lookups
    ,(100.0 * user_updates / (1+@total_user_updates)) as percent_user_updates
    ,(100.0 * system_seeks / (1+@total_system_seeks)) as percent_system_seeks
    ,(100.0 * system_scans / (1+@total_system_scans)) as percent_system_scans
    ,(100.0 * system_lookups / (1+@total_system_lookups)) as percent_system_lookups
    ,(100.0 * system_updates / (1+@total_system_updates)) as percent_system_updates
from
(
    select
         a.table_name
        ,a.index_name
        ,a.collect_date
        ,a.row_count
        ,a.size_mb
        ,a.type_desc
        ,(a.user_seeks - b.user_seeks) as user_seeks
        ,(a.user_scans - b.user_scans) as user_scans
        ,(a.user_lookups - b.user_lookups) as user_lookups
        ,(a.user_updates - b.user_updates) as user_updates
        ,(a.system_seeks - b.system_seeks) as system_seeks
        ,(a.system_scans - b.system_scans) as system_scans
        ,(a.system_lookups - b.system_lookups) as system_lookups
        ,(a.system_updates - b.system_updates) as system_updates
    from
    (
        select * from
            dm_db_index_usage_stats_dump
        where collect_date = @snapshot_time_later
    ) as a
    join
    (
        select * from
            dm_db_index_usage_stats_dump
        where collect_date = @snapshot_time_earlier
    ) as b
    on a.table_name = b.table_name and a.index_name = b.index_name
--    where (a.user_scans - b.user_scans) > 1 --scan頻度が少ないクエリを除外
) as c
order by user_scans desc
