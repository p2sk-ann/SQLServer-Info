SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
select
    distinct 
    (SELECT text FROM sys.dm_exec_sql_text(sql_handle)) as txt,
    request_session_id as spid,
    (SELECT count(*) FROM sys.sysprocesses with(nolock) WHERE blocked = request_session_id) as blocked_process_cnt
from
     sys.dm_tran_locks with(nolock)
join master..sysprocesses with(nolock) on request_session_id = spid
where
  not (resource_type = 'DATABASE' and request_mode = 'S')
  and open_tran > 0
  and status = 'sleeping'
  and datediff(SECOND, last_batch, getdate()) > 5
order by
  blocked_process_cnt desc
