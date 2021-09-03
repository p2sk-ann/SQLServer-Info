SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

declare @start datetime, @end datetime
set @start = '2020/08/08 00:00:00'
set @end = '2020/08/08 07:00:00'

select
     a.wait_type
    ,a.collect_date
    ,(a.waiting_tasks_count - b.waiting_tasks_count) as waiting_tasks_count
    ,(a.wait_time_ms - b.wait_time_ms) as wait_time_ms
    ,(a.max_wait_time_ms - b.max_wait_time_ms) as max_wait_time_ms
    ,(a.signal_wait_time_ms - b.signal_wait_time_ms) as signal_wait_time_ms
from
(
    select *, row_number() over (partition by wait_type order by collect_date) as rownum from dm_os_wait_stats_dump
) as a
join
(
    select *, row_number() over (partition by wait_type order by collect_date) as rownum from dm_os_wait_stats_dump
) as b on a.wait_type = b.wait_type and a.rownum = b.rownum + 1
where a.collect_date between @start and @end
order by
     a.wait_type
    ,a.collect_date

