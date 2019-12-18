SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SELECT
  getdate() as collect_date
  ,qt.dbid
  ,qt.TEXT as parent_query
  ,SUBSTRING(qt.TEXT, qs.statement_start_offset / 2, (
      CASE 
        WHEN qs.statement_end_offset = - 1
          THEN LEN(CONVERT(NVARCHAR(MAX), qt.TEXT)) * 2
        ELSE qs.statement_end_offset
      END - qs.statement_start_offset
   ) / 2) as statement
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
into dm_exec_query_stats_dump
FROM sys.dm_exec_query_stats qs
OUTER APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
WHERE
  1=0
