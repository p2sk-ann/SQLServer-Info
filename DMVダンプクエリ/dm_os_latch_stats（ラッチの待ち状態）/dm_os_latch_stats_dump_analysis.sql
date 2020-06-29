declare @total_waiting_requests_count bigint
declare @total_wait_time_ms bigint

declare @snapshot_time_earlier datetime
declare @snapshot_time_later datetime
set @snapshot_time_earlier = '2020-06-21 23:57:12.080' --collect_dateに存在する日時を設定（古い方）
set @snapshot_time_later = '2020-06-22 00:01:11.480' --collect_dateに存在する日時を設定（新しい方）


select
     @total_waiting_requests_count = sum(waiting_requests_count)
    ,@total_wait_time_ms = sum(wait_time_ms)
from
(
    select
         (a.waiting_requests_count - b.waiting_requests_count) as waiting_requests_count
        ,(a.wait_time_ms - b.wait_time_ms) as wait_time_ms
    from
    (
        select * from
            dm_os_latch_stats_dump
        where collect_date = @snapshot_time_later
    ) as a
    join
    (
        select * from
            dm_os_latch_stats_dump
        where collect_date = @snapshot_time_earlier
    ) as b
    on a.latch_class = b.latch_class
--    where (a.waiting_requests_count - b.waiting_requests_count) > 1 --少ないクエリを除外
) as c

select
    *
    ,(100.0 * waiting_requests_count / (1+@total_waiting_requests_count)) as percent_waiting_requests_count
    ,(100.0 * wait_time_ms / (1+@total_wait_time_ms)) as percent_wait_time_ms
from
(
    select
         a.collect_date
        ,a.latch_class
        ,a.max_wait_time_ms
        ,(a.waiting_requests_count - b.waiting_requests_count) as waiting_requests_count
        ,(a.wait_time_ms - b.wait_time_ms) as wait_time_ms
    from
    (
        select * from
            dm_os_latch_stats_dump
        where collect_date = @snapshot_time_later
    ) as a
    join
    (
        select * from
            dm_os_latch_stats_dump
        where collect_date = @snapshot_time_earlier
    ) as b
    on a.latch_class = b.latch_class
--    where (a.waiting_requests_count - b.waiting_requests_count) > 1 --少ないクエリを除外
) as c
order by wait_time_ms desc
