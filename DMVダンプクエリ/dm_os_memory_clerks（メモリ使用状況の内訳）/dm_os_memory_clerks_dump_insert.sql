set transaction isolation level read uncommitted

--サーバーで使用しているメモリの詳細な内訳
insert into dm_os_memory_clerks_dump
select 
	getdate() as collect_date
	,type
	,name
	,sum(pages_kb) as sum_pages_kb
	,sum(awe_allocated_kb) as sum_awe_allocated_kb
from sys.dm_os_memory_clerks with(nolock)
group by type, name
order by sum(pages_kb) desc
option (maxdop 1)
