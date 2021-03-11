declare @total_execution_count bigint
declare @total_total_worker_time bigint
declare @total_total_elapsed_time bigint
declare @total_total_logical_writes bigint
declare @total_total_logical_reads bigint

declare @snapshot_time_earlier datetime
declare @snapshot_time_later datetime

select
	 @snapshot_time_earlier = min(collect_date) --collect_dateに存在する日時を設定（古い方）
	,@snapshot_time_later = max(collect_date) --collect_dateに存在する日時を設定（新しい方）
from dm_exec_query_stats_dump with(nolock)
where collect_date between '2021/1/1 00:00' and '2021/1/1 00:15'

select @snapshot_time_earlier, @snapshot_time_later

select
     @total_execution_count = sum(execution_count)
    ,@total_total_worker_time = sum(total_worker_time)
    ,@total_total_elapsed_time = sum(total_elapsed_time)
    ,@total_total_logical_writes = sum(total_logical_writes)
    ,@total_total_logical_reads = sum(total_logical_reads)
from
(
    select
         (a.execution_count - b.execution_count) as execution_count
        ,(a.total_worker_time - b.total_worker_time) as total_worker_time
        ,(a.total_elapsed_time - b.total_elapsed_time) as total_elapsed_time
        ,(a.total_logical_writes - b.total_logical_writes) as total_logical_writes
        ,(a.total_logical_reads - b.total_logical_reads) as total_logical_reads
    from
    (
        select * from
            dm_exec_procedure_stats_dump
        where collect_date = @snapshot_time_later
    ) as a
    join
    (
        select * from
            dm_exec_procedure_stats_dump
        where collect_date = @snapshot_time_earlier
    ) as b
    on a.object_name = b.object_name
--    where (a.total_worker_time - b.total_worker_time) > 1 --待ち頻度が少ないクエリを除外
) as c

select
    *
    ,(100.0 * execution_count / (1+@total_execution_count)) as percent_execution_count
    ,(100.0 * total_worker_time / (1+@total_total_worker_time)) as percent_total_worker_time
    ,(100.0 * total_elapsed_time / (1+@total_total_elapsed_time)) as percent_total_elapsed_time
    ,(100.0 * total_logical_writes / (1+@total_total_logical_writes)) as percent_total_logical_writes
    ,(100.0 * total_logical_reads / (1+@total_total_logical_reads)) as percent_total_logical_reads
from
(
    select
         a.object_name
        ,a.last_execution_time
        ,a.modify_date
        ,a.cached_time
        ,a.collect_date
        ,(a.execution_count - b.execution_count) as execution_count
        ,(a.total_worker_time - b.total_worker_time) as total_worker_time
        ,(a.total_elapsed_time - b.total_elapsed_time) as total_elapsed_time
        ,(a.total_logical_writes - b.total_logical_writes) as total_logical_writes
        ,(a.total_logical_reads - b.total_logical_reads) as total_logical_reads
        --変化があったものだけ抽出
        ,(case when a.last_worker_time <> b.last_worker_time then a.last_worker_time else null end) as changed_last_worker_time
        ,(case when a.min_worker_time <> b.min_worker_time then a.min_worker_time else null end) as changed_min_worker_time
        ,(case when a.max_worker_time <> b.max_worker_time then a.max_worker_time else null end) as changed_max_worker_time
        ,(case when a.last_elapsed_time <> b.last_elapsed_time then a.last_elapsed_time else null end) as changed_last_elapsed_time
        ,(case when a.min_elapsed_time <> b.min_elapsed_time then a.min_elapsed_time else null end) as changed_min_elapsed_time
        ,(case when a.max_elapsed_time <> b.max_elapsed_time then a.max_elapsed_time else null end) as changed_max_elapsed_time
        ,(case when a.last_logical_writes <> b.last_logical_writes then a.last_logical_writes else null end) as changed_last_logical_writes
        ,(case when a.min_logical_writes <> b.min_logical_writes then a.min_logical_writes else null end) as changed_min_logical_writes
        ,(case when a.max_logical_writes <> b.max_logical_writes then a.max_logical_writes else null end) as changed_max_logical_writes
        ,(case when a.last_logical_reads <> b.last_logical_reads then a.last_logical_reads else null end) as changed_last_logical_reads
        ,(case when a.min_logical_reads <> b.min_logical_reads then a.min_logical_reads else null end) as changed_min_logical_reads
        ,(case when a.max_logical_reads <> b.max_logical_reads then a.max_logical_reads else null end) as changed_max_logical_reads
    from
    (
        select * from
            dm_exec_procedure_stats_dump
        where collect_date = @snapshot_time_later
    ) as a
    join
    (
        select * from
            dm_exec_procedure_stats_dump
        where collect_date = @snapshot_time_earlier
    ) as b
    on a.object_name = b.object_name
--    where (a.total_worker_time - b.total_worker_time) > 1 --待ち頻度が少ないクエリを除外
) as c
order by total_worker_time desc
