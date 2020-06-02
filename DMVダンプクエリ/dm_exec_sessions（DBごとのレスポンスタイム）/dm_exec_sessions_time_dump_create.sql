select
	 getdate() as collect_date
	,database_id
	,db_name(database_id) as database_name
	,datediff(MILLISECOND, last_request_start_time, last_request_end_time) as elapsed_time_ms
	,count(*) as cnt
into #dm_exec_sessions_time_dump
from sys.dm_exec_sessions
where last_request_start_time is not null
	and last_request_end_time is not null
	and datediff(ms, last_request_start_time, last_request_end_time) >= 0
	and db_name(database_id) not in ('master', 'msdb', 'tempdb', 'distribution', 'model')
group by
	database_id, datediff(MILLISECOND, last_request_start_time, last_request_end_time)
having 1=0
