select 
	 session_id
	,dop
	,request_time
	,(case when grant_time is null then 'not granted' else 'granted' end) as grant_state
	,requested_memory_kb / 1024.0 as requested_memory_mb
	,granted_memory_kb / 1024.0 as granted_memory_mb --実際に許可されたメモリの総量
	,required_memory_kb / 1024.0 as required_memory_mb
	,used_memory_kb / 1024.0 as used_memory_mb
	,max_used_memory_kb / 1024.0 as max_used_memory_mb
	,query_cost
	,text
	,query_plan
	,request_id
	,scheduler_id
	,grant_time
	,timeout_sec
	,resource_semaphore_id
	,queue_id
	,wait_order
	,is_next_candidate
	,wait_time_ms
	,plan_handle
	,sql_handle
	,group_id
	,pool_id
	,is_small
	,ideal_memory_kb
from sys.dm_exec_query_memory_grants a
outer apply sys.dm_exec_sql_text(a.sql_handle) as sql_text
outer apply sys.dm_exec_query_plan(a.plan_handle) as query_plan
order by granted_memory_kb desc
