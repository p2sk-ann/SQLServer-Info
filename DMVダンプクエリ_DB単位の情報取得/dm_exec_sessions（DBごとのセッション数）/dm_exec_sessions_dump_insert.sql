insert into dm_exec_sessions_dump
select 
	 getdate() as collect_date
	,database_id
	,db_name(database_id) as db_name
	,count(*) as session_count
from sys.dm_exec_sessions
group by database_id
order by count(*) desc
