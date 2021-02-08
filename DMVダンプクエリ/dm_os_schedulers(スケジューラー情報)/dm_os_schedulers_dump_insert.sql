set transaction isolation level read uncommitted

insert into dm_os_schedulers_dump
select
    getdate() as collect_date
    ,*
from sys.dm_os_schedulers
