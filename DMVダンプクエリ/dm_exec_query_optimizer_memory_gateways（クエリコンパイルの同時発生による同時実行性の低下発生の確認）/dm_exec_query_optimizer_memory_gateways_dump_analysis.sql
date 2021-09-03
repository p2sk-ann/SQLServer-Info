set transaction isolation level read uncommitted

select * from dm_exec_query_optimizer_memory_gateways_dump with(nolock)
order by collect_date
