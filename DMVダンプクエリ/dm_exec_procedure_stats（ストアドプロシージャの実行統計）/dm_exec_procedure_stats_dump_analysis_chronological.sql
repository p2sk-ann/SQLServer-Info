declare @start datetime, @end datetime
set @start = '2020/10/13 00:00:00'
set @end = '2020/10/23 00:00:00'

select
     a.object_name
    ,a.collect_date
    ,case when (a.execution_count - b.execution_count) = 0 then 0 else (a.total_worker_time - b.total_worker_time) - (a.execution_count - b.execution_count) end as avg_worker_time
    ,(a.execution_count - b.execution_count) as execution_count
    ,(a.total_worker_time - b.total_worker_time) as total_worker_time
    ,a.last_worker_time
    ,a.min_worker_time
    ,a.max_worker_time
    ,(a.total_elapsed_time - b.total_elapsed_time) as total_elapsed_time
    ,a.last_elapsed_time
    ,a.min_elapsed_time
    ,a.max_elapsed_time
    ,(a.total_logical_writes - b.total_logical_writes) as total_logical_writes
    ,a.last_logical_writes
    ,a.min_logical_writes
    ,a.max_logical_writes
    ,(a.total_logical_reads - b.total_logical_reads) as total_logical_reads
    ,a.last_logical_reads
    ,a.min_logical_reads
    ,a.max_logical_reads
from
(
    select *, row_number() over (partition by object_name order by collect_date) as rownum from dm_exec_procedure_stats_dump
) as a
join
(
    select *, row_number() over (partition by object_name order by collect_date) as rownum from dm_exec_procedure_stats_dump
) as b on a.object_name = b.object_name and a.rownum = b.rownum + 1 and a.cached_time = b.cached_time
where a.collect_date between @start and @end
order by
     a.object_name
    ,a.collect_date
