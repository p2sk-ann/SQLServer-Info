declare @total_waiting_tasks_count bigint
declare @total_wait_time_ms bigint
declare @total_max_wait_time_ms bigint
declare @total_signal_wait_time_ms bigint

declare @snapshot_time_earlier datetime
declare @snapshot_time_later datetime
set @snapshot_time_earlier = '2020-06-21 23:50:10.970' --collect_dateに存在する日時を設定（古い方）
set @snapshot_time_later = '2020-06-22 00:15:11.023' --collect_dateに存在する日時を設定（新しい方）


select
     @total_waiting_tasks_count = sum(waiting_tasks_count)
    ,@total_wait_time_ms = sum(wait_time_ms)
    ,@total_max_wait_time_ms = sum(max_wait_time_ms)
    ,@total_signal_wait_time_ms = sum(signal_wait_time_ms)
from
(
    select
         a.wait_type
        ,a.collect_date
        ,(a.waiting_tasks_count - b.waiting_tasks_count) as waiting_tasks_count
        ,(a.wait_time_ms - b.wait_time_ms) as wait_time_ms
        ,(a.max_wait_time_ms - b.max_wait_time_ms) as max_wait_time_ms
        ,(a.signal_wait_time_ms - b.signal_wait_time_ms) as signal_wait_time_ms
    from
    (
        select * from
            dm_os_wait_stats_dump
        where collect_date = @snapshot_time_later
    ) as a
    join
    (
        select * from
            dm_os_wait_stats_dump
        where collect_date = @snapshot_time_earlier
    ) as b
    on a.wait_type = b.wait_type
    where (a.waiting_tasks_count - b.waiting_tasks_count) > 1 --待ち頻度が少ないクエリを除外
) as c

select
    *
    ,(100.0 * waiting_tasks_count / (1+@total_waiting_tasks_count)) as percent_waiting_tasks_count
    ,(100.0 * wait_time_ms / (1+@total_wait_time_ms)) as percent_wait_time_ms
    ,(100.0 * max_wait_time_ms / (1+@total_max_wait_time_ms)) as percent_max_wait_time_ms
    ,(100.0 * signal_wait_time_ms / (1+@total_signal_wait_time_ms)) as percent_signal_wait_time_ms
from
(
    select
         a.wait_type
        ,a.collect_date
        ,(a.waiting_tasks_count - b.waiting_tasks_count) as waiting_tasks_count
        ,(a.wait_time_ms - b.wait_time_ms) as wait_time_ms
        ,(a.max_wait_time_ms - b.max_wait_time_ms) as max_wait_time_ms
        ,(a.signal_wait_time_ms - b.signal_wait_time_ms) as signal_wait_time_ms
    from
    (
        select * from
            dm_os_wait_stats_dump
        where collect_date = @snapshot_time_later
    ) as a
    join
    (
        select * from
            dm_os_wait_stats_dump
        where collect_date = @snapshot_time_earlier
    ) as b
    on a.wait_type = b.wait_type
    where (a.waiting_tasks_count - b.waiting_tasks_count) > 1 --待ち頻度が少ないクエリを除外
) as c
order by wait_time_ms desc
