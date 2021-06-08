set transaction isolation level read uncommitted

declare @estimate_mode bit = 0 --1:estimation on / 0:estimation off

declare @sum_worker_time bigint
declare @sum_execution_count bigint
declare @sum_elapsed_time bigint
declare @sum_logical_reads bigint
declare @sum_grant_kb bigint

declare @snapshot_time_earlier datetime
declare @snapshot_time_later datetime

select
	 @snapshot_time_earlier = min(collect_date) --collect_dateに存在する日時を設定（古い方）
	,@snapshot_time_later = max(collect_date) --collect_dateに存在する日時を設定（新しい方）
from dm_exec_query_stats_dump with(nolock)
where collect_date between '2021/06/07 09:00' and '2021/06/07 10:00'

select @snapshot_time_earlier, @snapshot_time_later

select
    @sum_worker_time = sum(total_worker_time),
    @sum_execution_count = sum(execution_count),
    @sum_elapsed_time = sum(total_elapsed_time),
    @sum_logical_reads = sum(total_logical_reads),
    @sum_grant_kb = sum(total_grant_kb)
from
(
    select
         dbid
        ,parent_query
        ,statement
        ,creation_time
        ,last_execution_time
        --@estimate_mode=1なら、(@snapshot_time_later - @snapshot_time_earlier)の時間間隔における実行時間やCPU時間に変換
        --@estimate_mode=0なら、そのままの値
        ,execution_count * (case when @estimate_mode = 1 then (datediff(millisecond, @snapshot_time_earlier, @snapshot_time_later) / datediff(millisecond, creation_time, last_execution_time)) else 1 end) as execution_count
        ,total_worker_time * (case when @estimate_mode = 1 then (datediff(millisecond, @snapshot_time_earlier, @snapshot_time_later) / datediff(millisecond, creation_time, last_execution_time)) else 1 end) as total_worker_time
        ,total_elapsed_time * (case when @estimate_mode = 1 then (datediff(millisecond, @snapshot_time_earlier, @snapshot_time_later) / datediff(millisecond, creation_time, last_execution_time)) else 1 end) as total_elapsed_time
        ,total_logical_reads * (case when @estimate_mode = 1 then (datediff(millisecond, @snapshot_time_earlier, @snapshot_time_later) / datediff(millisecond, creation_time, last_execution_time)) else 1 end) as total_logical_reads
        ,total_grant_kb * (case when @estimate_mode = 1 then (datediff(millisecond, @snapshot_time_earlier, @snapshot_time_later) / datediff(millisecond, creation_time, last_execution_time)) else 1 end) as total_grant_kb
        ,total_dop
        ,min_dop
        ,max_dop
        ,(case when @estimate_mode = 1 then 'estimated' else 'raw' end) as type -- estimated:推定した値 / raw:生データ。ただし計測期間の中でコンパイル or 再コンパイルされている / calculated:計測基幹のstart/endの差分を計算した値
    from dm_exec_query_stats_dump
    where creation_time >= @snapshot_time_earlier
    and collect_date = @snapshot_time_later
    and execution_count > 1 --実行頻度が少ないクエリを除外
    and datediff(millisecond, creation_time, last_execution_time) > 0

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
        ,(a.total_grant_kb - b.total_grant_kb) as total_grant_kb
        ,(a.total_dop - b.total_dop) as total_dop
        ,a.min_dop
        ,a.max_dop
        ,'calculated' as type
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
    ,total_grant_kb / execution_count as avg_grant_kb
    ,total_worker_time*100.0 / @sum_worker_time as percentage_worker_time
    ,total_elapsed_time*100.0 / @sum_elapsed_time as percentage_elapsed_time
    ,execution_count*100.0 / @sum_execution_count as percentage_execution_count
    ,total_logical_reads*100.0 / @sum_logical_reads as percentage_logical_reads
    ,total_grant_kb*100.0 / @sum_grant_kb as percentage_grant_kb
from
(
    select
         dbid
        ,parent_query
        ,statement
        ,creation_time
        ,last_execution_time
        ,execution_count * (case when @estimate_mode = 1 then (datediff(millisecond, @snapshot_time_earlier, @snapshot_time_later) / datediff(millisecond, creation_time, last_execution_time)) else 1 end) as execution_count
        ,total_worker_time * (case when @estimate_mode = 1 then (datediff(millisecond, @snapshot_time_earlier, @snapshot_time_later) / datediff(millisecond, creation_time, last_execution_time)) else 1 end) as total_worker_time
        ,total_elapsed_time * (case when @estimate_mode = 1 then (datediff(millisecond, @snapshot_time_earlier, @snapshot_time_later) / datediff(millisecond, creation_time, last_execution_time)) else 1 end) as total_elapsed_time
        ,total_logical_reads * (case when @estimate_mode = 1 then (datediff(millisecond, @snapshot_time_earlier, @snapshot_time_later) / datediff(millisecond, creation_time, last_execution_time)) else 1 end) as total_logical_reads
        ,total_grant_kb * (case when @estimate_mode = 1 then (datediff(millisecond, @snapshot_time_earlier, @snapshot_time_later) / datediff(millisecond, creation_time, last_execution_time)) else 1 end) as total_grant_kb
        ,total_dop
        ,min_dop
        ,max_dop
        ,(case when @estimate_mode = 1 then 'estimated' else 'raw' end) as type -- estimated:推定した値 / raw:生データ。ただし計測期間の中でコンパイル or 再コンパイルされている / calculated:計測基幹のstart/endの差分を計算した値
    from dm_exec_query_stats_dump
    where creation_time >= @snapshot_time_earlier
    and collect_date = @snapshot_time_later
    and execution_count > 1 --実行頻度が少ないクエリを除外
    and datediff(millisecond, creation_time, last_execution_time) > 0

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
        ,(a.total_grant_kb - b.total_grant_kb) as total_grant_kb
        ,(a.total_dop - b.total_dop) as total_dop
        ,a.min_dop
        ,a.max_dop
        ,'calculated' as type
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
order by percentage_worker_time desc
