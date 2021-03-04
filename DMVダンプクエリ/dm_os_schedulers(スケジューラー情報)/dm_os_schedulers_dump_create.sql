set transaction isolation level read uncommitted

select
    getdate() as collect_date
    ,*
into dm_os_schedulers_dump
from sys.dm_os_schedulers

--古いデータ削除用
create index IX_dm_os_schedulers_dump_collect_date on dm_os_schedulers_dump(collect_date)
