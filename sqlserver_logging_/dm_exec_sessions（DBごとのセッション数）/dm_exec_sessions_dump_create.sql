select 
	 getdate() as collect_date
	,database_id
	,db_name(database_id) as db_name
	,count(*) as session_count
into dm_exec_sessions_dump
from sys.dm_exec_sessions
group by database_id
having 1=0
