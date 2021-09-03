set transaction isolation level read uncommitted

insert into dm_exec_query_optimizer_memory_gateways_dump
select getdate() as collect_date, * 
from sys.dm_exec_query_optimizer_memory_gateways
option(maxdop 1)
