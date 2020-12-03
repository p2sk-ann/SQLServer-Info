set transaction isolation level read uncommitted
select
  getdate() as collect_date
  ,qt.dbid
  --サイズが大きくなりすぎるので500文字だけ格納
  ,substring(qt.text, 1, 500) as parent_query
  --サイズが大きくなりすぎるので500文字だけ格納
  ,substring(substring(qt.text, qs.statement_start_offset / 2, (
      case 
        when qs.statement_end_offset = - 1
          then len(convert(nvarchar(max), qt.text)) * 2
        else qs.statement_end_offset
      end - qs.statement_start_offset
   ) / 2), 1, 500) as statement
  ,execution_count
  ,total_worker_time
  ,total_elapsed_time
  ,total_physical_reads
  ,total_logical_reads
  ,total_logical_writes
  ,total_dop
  ,min_dop
  ,max_dop
  ,max_worker_time
  ,max_clr_time
  ,max_elapsed_time
  ,last_execution_time
  ,last_worker_time
  ,last_clr_time
  ,last_elapsed_time
  ,plan_generation_num
  ,total_rows
  ,last_rows
  ,min_rows
  ,max_rows
  ,creation_time
  ,total_grant_kb
  ,last_grant_kb
  ,min_grant_kb
  ,max_grant_kb
  ,total_used_grant_kb
  ,last_used_grant_kb
  ,min_used_grant_kb
  ,max_used_grant_kb
  ,total_ideal_grant_kb
  ,last_ideal_grant_kb
  ,min_ideal_grant_kb
  ,max_ideal_grant_kb                 
into dm_exec_query_stats_dump
from sys.dm_exec_query_stats qs
outer apply sys.dm_exec_sql_text(qs.sql_handle) as qt
where
  1=0

--古いデータ削除用
create index IX_dm_exec_query_stats_dump_collect_date on dm_exec_query_stats_dump(collect_date)
