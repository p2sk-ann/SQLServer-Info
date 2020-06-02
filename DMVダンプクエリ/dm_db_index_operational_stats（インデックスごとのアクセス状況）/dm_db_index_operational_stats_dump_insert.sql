insert into dm_db_index_operational_stats_dump
select 
	 getdate() as collect_date
	,object_name(i.object_id) as table_name
	,i.name
	,d.*
from sys.dm_db_index_operational_stats(db_id(), null, null, null) d
left join sys.indexes i on d.OBJECT_ID = i.OBJECT_ID
	and d.index_id = i.index_id
option(maxdop 1)
