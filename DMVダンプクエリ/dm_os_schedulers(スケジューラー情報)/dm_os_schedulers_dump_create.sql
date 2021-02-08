set transaction isolation level read uncommitted

select
    getdate() as collect_date
    ,*
into dm_os_schedulers_dump
from sys.dm_os_schedulers
