set transaction isolation level read uncommitted
set lock_timeout 1000
 
if exists (select * from sys.objects where name = 'dm_db_index_operational_stats_dump')
begin
    delete top (100000) from dm_db_index_operational_stats_dump where collect_date < dateadd(day, -10, getdate())
end
 
if exists (select * from sys.objects where name = 'dm_db_index_usage_stats_dump')
begin
    delete top (100000) from dm_db_index_usage_stats_dump where collect_date < dateadd(day, -10, getdate())
end
 
if exists (select * from sys.objects where name = 'dm_exec_procedure_stats_dump')
begin
    delete top (100000) from dm_exec_procedure_stats_dump where collect_date < dateadd(day, -10, getdate())
end
 
if exists (select * from sys.objects where name = 'dm_exec_query_stats_dump')
begin
    delete top (100000) from dm_exec_query_stats_dump where collect_date < dateadd(day, -10, getdate())
end
 
if exists (select * from sys.objects where name = 'dm_exec_requests_dump')
begin
    delete top (100000) from dm_exec_requests_dump where collect_date < dateadd(day, -10, getdate())
end
 
if exists (select * from sys.objects where name = 'dm_os_latch_stats_dump')
begin
    delete top (100000) from dm_os_latch_stats_dump where collect_date < dateadd(day, -10, getdate())
end
 
if exists (select * from sys.objects where name = 'dm_os_wait_stats_dump')
begin
    delete top (100000) from dm_os_wait_stats_dump where collect_date < dateadd(day, -10, getdate())
end
 
if exists (select * from sys.objects where name = 'dm_os_waiting_tasks_dump')
begin
    delete top (100000) from dm_os_waiting_tasks_dump where collect_date < dateadd(day, -10, getdate())
end
 
if exists (select * from sys.objects where name = 'sys_stats_dump')
begin
    delete top (100000) from sys_stats_dump where collect_date < dateadd(day, -10, getdate())
end
 
if exists (select * from sys.objects where name = 'dm_io_virtual_file_stats_dump')
begin
    delete top (100000) from dm_io_virtual_file_stats_dump where collect_date < dateadd(day, -10, getdate())
end

if exists (select * from sys.objects where name = 'dm_os_schedulers_dump')
begin
    delete top (100000) from dm_os_schedulers_dump where collect_date < dateadd(day, -10, getdate())
end

if exists (select * from sys.objects where name = 'dm_tasks_dump')
begin
    delete top (100000) from dm_tasks_dump where collect_date < dateadd(day, -10, getdate())
end
