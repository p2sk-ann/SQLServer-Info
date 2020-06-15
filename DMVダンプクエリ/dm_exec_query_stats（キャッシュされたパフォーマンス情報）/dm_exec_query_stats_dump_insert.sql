set transaction isolation level read uncommitted

insert into dm_exec_query_stats_dump
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
  ,last_execution_time
  ,creation_time
from sys.dm_exec_query_stats qs
outer apply sys.dm_exec_sql_text(qs.sql_handle) as qt
where
   last_execution_time > dateadd(minute, -1, getdate())
or creation_time > dateadd(minute, -1, getdate())
option(maxdop 1)
