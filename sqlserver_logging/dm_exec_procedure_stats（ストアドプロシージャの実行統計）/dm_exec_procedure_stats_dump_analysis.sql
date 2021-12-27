set transaction isolation level read uncommitted

declare @total_execution_count float
declare @total_worker_time float
declare @total_elapsed_time float
declare @total_logical_writes float
declare @total_logical_reads float

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
     row_number() over (partition by object_name, cached_time order by execution_count desc) as rownum
    ,min(execution_count) over (partition by object_name, cached_time) as min_execution_count
    ,min(total_worker_time) over (partition by object_name, cached_time) as min_total_worker_time
    ,min(total_elapsed_time) over (partition by object_name, cached_time) as min_total_elapsed_time
    ,min(total_logical_writes) over (partition by object_name, cached_time) as min_total_logical_writes
    ,min(total_logical_reads) over (partition by object_name, cached_time) as min_total_logical_reads
    ,*
  from dm_exec_procedure_stats_dump with(nolock)
  where object_name not like 'sp[_]%' --システムストアドプロシージャを除外
  and exists ( --システムストアドプロシージャを除外
        select * from sys.objects ob with(nolock) where ob.object_id = object_id(object_name) and is_ms_shipped = 0
    )
  and collect_date between @start_at and @end_at
  and database_id = db_id()
) as a
where rownum = 1 --キャッシュアウトされていない同一データの中で最新のものだけに限定

--補助情報表示
select min(collect_date) as start_at, max(collect_date) as end_at, datediff(second, min(collect_date), max(collect_date)) as span_sec from #tmp

--該当時間帯の合計値を算出
select
   @total_execution_count = sum((case when cached_time >= @start_at then execution_count else execution_count - min_execution_count end))
  ,@total_worker_time = sum((case when cached_time >= @start_at then total_worker_time else total_worker_time - min_total_worker_time end))
  ,@total_elapsed_time = sum((case when cached_time >= @start_at then total_elapsed_time else total_elapsed_time - min_total_elapsed_time end))
  ,@total_logical_writes = sum((case when cached_time >= @start_at then total_logical_writes else total_logical_writes - min_total_logical_writes end))
  ,@total_logical_reads = sum((case when cached_time >= @start_at then total_logical_reads else total_logical_reads - min_total_logical_reads end))
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
from
(
  select
     object_name
    ,sum((case when cached_time >= @start_at then execution_count else execution_count - min_execution_count end)) as total_execution_count
    ,sum((case when cached_time >= @start_at then total_worker_time else total_worker_time - min_total_worker_time end)) as total_worker_time
    ,sum((case when cached_time >= @start_at then total_elapsed_time else total_elapsed_time - min_total_elapsed_time end)) as total_elapsed_time
    ,sum((case when cached_time >= @start_at then total_logical_writes else total_logical_writes - min_total_logical_writes end)) as total_logical_writes
    ,sum((case when cached_time >= @start_at then total_logical_reads else total_logical_reads - min_total_logical_reads end)) as total_logical_reads
  from
    #tmp
  group by
    object_name
) as a
order by
  percentage_worker_time desc --並び替えたい項目を指定

drop table #tmp
