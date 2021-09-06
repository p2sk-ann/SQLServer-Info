set transaction isolation level read uncommitted

select * from dm_exec_requests_dump
where collect_date between '2020-06-29 17:00' and '2020-06-29 18:00'
