set transaction isolation level read uncommitted

select getdate() as collect_date, * 
into dm_exec_query_optimizer_memory_gateways_dump
from sys.dm_exec_query_optimizer_memory_gateways
option(maxdop 1)

--古いデータ削除用
create index IX_dm_exec_query_optimizer_memory_gateways_dump_collect_date on dm_exec_query_optimizer_memory_gateways_dump(collect_date)
