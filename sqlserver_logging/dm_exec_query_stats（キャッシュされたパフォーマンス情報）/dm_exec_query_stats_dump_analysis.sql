set transaction isolation level read uncommitted

declare @total_execution_count float
declare @total_worker_time float
declare @total_elapsed_time float
declare @total_logical_writes float
declare @total_logical_reads float
declare @total_grant_kb float
declare @total_dop float

--期間指定
declare
   @start_at datetime = '2021/12/26 23:59'
  ,@end_at datetime = '2021/12/27 00:02'

--一時テーブルに情報をダンプ
select
    *
into #tmp
from
(
  select
     row_number() over (partition by dbid, parent_query, statement, creation_time, duplication_rownum order by execution_count desc) as rownum
    ,min(execution_count) over (partition by dbid, parent_query, statement, creation_time, duplication_rownum) as min_execution_count
    ,min(total_worker_time) over (partition by dbid, parent_query, statement, creation_time, duplication_rownum) as min_total_worker_time
    ,min(total_elapsed_time) over (partition by dbid, parent_query, statement, creation_time, duplication_rownum) as min_total_elapsed_time
    ,min(total_logical_writes) over (partition by dbid, parent_query, statement, creation_time, duplication_rownum) as min_total_logical_writes
    ,min(total_logical_reads) over (partition by dbid, parent_query, statement, creation_time, duplication_rownum) as min_total_logical_reads
    ,min(total_grant_kb) over (partition by dbid, parent_query, statement, creation_time, duplication_rownum) as min_total_grant_kb
    ,min(total_dop) over (partition by dbid, parent_query, statement, creation_time, duplication_rownum) as min_total_dop
    ,*
  from
  (
    select
       *
      ,row_number() over (partition by dbid, parent_query, statement, creation_time, collect_date order by execution_count desc) as duplication_rownum --dbid, parent_query, statement, creation_time単位で全重複しちゃってる場合は、execution_countで識別する
    from dm_exec_query_stats_dump with(nolock)
    where collect_date between @start_at and @end_at
  ) as a
) as a
where rownum = 1 --キャッシュアウトされていない同一データの中で最新のものだけに限定

--補助情報表示
select min(collect_date) as start_at, max(collect_date) as end_at, datediff(second, min(collect_date), max(collect_date)) as span_sec from #tmp

--該当時間帯の合計値を算出
select
   @total_execution_count = sum((case when creation_time >= @start_at then execution_count else execution_count - min_execution_count end))
  ,@total_worker_time = sum((case when creation_time >= @start_at then total_worker_time else total_worker_time - min_total_worker_time end))
  ,@total_elapsed_time = sum((case when creation_time >= @start_at then total_elapsed_time else total_elapsed_time - min_total_elapsed_time end))
  ,@total_logical_writes = sum((case when creation_time >= @start_at then total_logical_writes else total_logical_writes - min_total_logical_writes end))
  ,@total_logical_reads = sum((case when creation_time >= @start_at then total_logical_reads else total_logical_reads - min_total_logical_reads end))
  ,@total_grant_kb = sum((case when creation_time >= @start_at then total_grant_kb else total_grant_kb - min_total_grant_kb end))  
  ,@total_dop = sum((case when creation_time >= @start_at then total_dop else total_dop - min_total_dop end))  
from
  #tmp

--該当時間帯でリソースの消費量が多い順にストアドプロシージャをリストアップ
select
  *
  ,cast(total_execution_count / @total_execution_count * 100 as numeric(4,2)) as percentage_execution_count
  ,cast(total_worker_time / @total_worker_time * 100 as numeric(4,2)) as percentage_worker_time
  ,cast(total_elapsed_time / @total_elapsed_time * 100 as numeric(4,2)) as percentage_elapsed_time
  ,cast(total_logical_writes / @total_logical_writes * 100 as numeric(4,2)) as percentage_logical_writes
  ,cast(total_logical_reads / @total_logical_reads * 100 as numeric(4,2)) as percentage_logical_reads
  ,cast(total_grant_kb / @total_grant_kb * 100 as numeric(4,2)) as percentage_grant_kb
  ,cast(total_worker_time*1.0 / (case when total_execution_count = 0 then 1 else total_execution_count end) as numeric(20,0)) as avg_worker_time
  ,cast(total_elapsed_time*1.0 / (case when total_execution_count = 0 then 1 else total_execution_count end) as numeric(20,0)) as avg_elapsed_time
  ,cast(total_logical_writes*1.0 / (case when total_execution_count = 0 then 1 else total_execution_count end) as numeric(20,0)) as avg_logical_writes
  ,cast(total_logical_reads*1.0 / (case when total_execution_count = 0 then 1 else total_execution_count end) as numeric(20,0)) as avg_logical_reads
  ,cast(total_grant_kb*1.0 / (case when total_execution_count = 0 then 1 else total_execution_count end) as numeric(20,0)) as avg_grant_kb
  ,cast(total_dop*1.0 / (case when total_execution_count = 0 then 1 else total_execution_count end) as numeric(20,1)) as avg_dop
from
(
  select
     dbid, parent_query, statement
    ,sum((case when creation_time >= @start_at then execution_count else execution_count - min_execution_count end)) as total_execution_count
    ,sum((case when creation_time >= @start_at then total_worker_time else total_worker_time - min_total_worker_time end)) as total_worker_time
    ,sum((case when creation_time >= @start_at then total_elapsed_time else total_elapsed_time - min_total_elapsed_time end)) as total_elapsed_time
    ,sum((case when creation_time >= @start_at then total_logical_writes else total_logical_writes - min_total_logical_writes end)) as total_logical_writes
    ,sum((case when creation_time >= @start_at then total_logical_reads else total_logical_reads - min_total_logical_reads end)) as total_logical_reads
    ,sum((case when creation_time >= @start_at then total_grant_kb else total_grant_kb - min_total_grant_kb end)) as total_grant_kb
    ,sum((case when creation_time >= @start_at then total_dop else total_dop - min_total_dop end)) as total_dop
  from
    #tmp
  group by
    dbid, parent_query, statement
) as a
order by
  percentage_worker_time desc --並び替えたい項目を指定

drop table #tmp
