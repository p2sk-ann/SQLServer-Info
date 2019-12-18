declare @sum_worker_time bigint
declare @sum_execution_count bigint
declare @sum_elapsed_time bigint
declare @sum_logical_reads bigint

declare @snapshot_time_earlier datetime
declare @snapshot_time_later datetime
set @snapshot_time_earlier = '2019-12-13 04:42:02.390' --collect_dateに存在する日時を設定（古い方）
set @snapshot_time_later = '2019-12-13 04:43:01.243' --collect_dateに存在する日時を設定（新しい方）

select
    @sum_worker_time = sum(total_worker_time),
    @sum_execution_count = sum(execution_count),
    @sum_elapsed_time = sum(total_elapsed_time),
    @sum_logical_reads = sum(total_logical_reads)
from
(
    select
         dbid
        ,parent_query
        ,statement
        ,creation_time
        ,last_execution_time
        --(@snapshot_time_later - @snapshot_time_earlier)の時間間隔における実行時間やCPU時間に変換
        ,execution_count * (datediff(millisecond, @snapshot_time_earlier, @snapshot_time_later) / datediff(millisecond, creation_time, last_execution_time)) as execution_count
        ,total_worker_time * (datediff(millisecond, @snapshot_time_earlier, @snapshot_time_later) / datediff(millisecond, creation_time, last_execution_time)) as total_worker_time
        ,total_elapsed_time * (datediff(millisecond, @snapshot_time_earlier, @snapshot_time_later) / datediff(millisecond, creation_time, last_execution_time)) as total_elapsed_time
        ,total_logical_reads * (datediff(millisecond, @snapshot_time_earlier, @snapshot_time_later) / datediff(millisecond, creation_time, last_execution_time)) as total_logical_reads
        ,total_dop
        ,min_dop
        ,max_dop
    from dm_exec_query_stats_dump
    where creation_time >= @snapshot_time_earlier
    and collect_date = @snapshot_time_later
    and execution_count > 1 --実行頻度が少ないクエリを除外

    union

    select
         a.dbid
        ,a.parent_query
        ,a.statement
        ,a.creation_time
        ,a.last_execution_time
        ,(a.execution_count - b.execution_count) as execution_count
        ,(a.total_worker_time - b.total_worker_time) as total_worker_time
        ,(a.total_elapsed_time - b.total_elapsed_time) as total_elapsed_time
        ,(a.total_logical_reads - b.total_logical_reads) as total_logical_reads
        ,(a.total_dop - b.total_dop) as total_dop
        ,a.min_dop
        ,a.max_dop
    from
    (
        select * from
            dm_exec_query_stats_dump
        where collect_date = @snapshot_time_later
        and creation_time < @snapshot_time_earlier and last_execution_time >= @snapshot_time_earlier
    ) as a
    join
    (
        select * from
            dm_exec_query_stats_dump
        where collect_date = @snapshot_time_earlier
        and creation_time < @snapshot_time_earlier and last_execution_time >= @snapshot_time_earlier
    ) as b
    on a.parent_query = b.parent_query and a.statement = b.statement and a.creation_time = b.creation_time
    where (a.execution_count - b.execution_count) > 1 --実行頻度が少ないクエリを除外
) as c

select
    *
    ,total_worker_time / execution_count as avg_worker_time
    ,total_elapsed_time / execution_count as avg_elapsed_time
    ,total_worker_time*100.0 / @sum_worker_time as percentage_worker_time
    ,total_elapsed_time*100.0 / @sum_elapsed_time as percentage_elapsed_time
    ,execution_count*100.0 / @sum_execution_count as percentage_execution_count
    ,total_logical_reads*100.0 / @sum_logical_reads as percentage_logical_reads
from
(
    select
         dbid
        ,parent_query
        ,statement
        ,creation_time
        ,last_execution_time
        ,execution_count * (datediff(millisecond, @snapshot_time_earlier, @snapshot_time_later) / datediff(millisecond, creation_time, last_execution_time)) as execution_count
        ,total_worker_time * (datediff(millisecond, @snapshot_time_earlier, @snapshot_time_later) / datediff(millisecond, creation_time, last_execution_time)) as total_worker_time
        ,total_elapsed_time * (datediff(millisecond, @snapshot_time_earlier, @snapshot_time_later) / datediff(millisecond, creation_time, last_execution_time)) as total_elapsed_time
        ,total_logical_reads * (datediff(millisecond, @snapshot_time_earlier, @snapshot_time_later) / datediff(millisecond, creation_time, last_execution_time)) as total_logical_reads
        ,total_dop
        ,min_dop
        ,max_dop
    from dm_exec_query_stats_dump
    where creation_time >= @snapshot_time_earlier
    and collect_date = @snapshot_time_later
    and execution_count > 1 --実行頻度が少ないクエリを除外

    union

    select
         a.dbid
        ,a.parent_query
        ,a.statement
        ,a.creation_time
        ,a.last_execution_time
        ,(a.execution_count - b.execution_count) as execution_count
        ,(a.total_worker_time - b.total_worker_time) as total_worker_time
        ,(a.total_elapsed_time - b.total_elapsed_time) as total_elapsed_time
        ,(a.total_logical_reads - b.total_logical_reads) as total_logical_reads
        ,(a.total_dop - b.total_dop) as total_dop
        ,a.min_dop
        ,a.max_dop
    from
    (
        select * from
            dm_exec_query_stats_dump
        where collect_date = @snapshot_time_later
        and creation_time < @snapshot_time_earlier and last_execution_time >= @snapshot_time_earlier
    ) as a
    join
    (
        select * from
            dm_exec_query_stats_dump
        where collect_date = @snapshot_time_earlier
        and creation_time < @snapshot_time_earlier and last_execution_time >= @snapshot_time_earlier
    ) as b
    on a.parent_query = b.parent_query and a.statement = b.statement and a.creation_time = b.creation_time
    where (a.execution_count - b.execution_count) > 1 --実行頻度が少ないクエリを除外
) as c
order by total_worker_time desc
