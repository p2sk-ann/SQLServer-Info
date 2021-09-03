set transaction isolation level read uncommitted
set lock_timeout 1000

/**************************************
per minute
***************************************/
if exists (select * from sys.objects where name = 'dm_db_file_space_usage_tempdb_dump')
begin
    delete top (100000) from dm_db_file_space_usage_tempdb_dump where collect_date < dateadd(day, -10, getdate())
end

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

if exists (select * from sys.objects where name = 'dm_io_virtual_file_stats_dump')
begin
    delete top (100000) from dm_io_virtual_file_stats_dump where collect_date < dateadd(day, -10, getdate())
end

if exists (select * from sys.objects where name = 'dm_os_latch_stats_dump')
begin
    delete top (100000) from dm_os_latch_stats_dump where collect_date < dateadd(day, -10, getdate())
end

if exists (select * from sys.objects where name = 'dm_os_memory_clerks_dump')
begin
    delete top (100000) from dm_os_memory_clerks_dump where collect_date < dateadd(day, -10, getdate())
end

if exists (select * from sys.objects where name = 'dm_os_schedulers_dump')
begin
    delete top (100000) from dm_os_schedulers_dump where collect_date < dateadd(day, -10, getdate())
end

if exists (select * from sys.objects where name = 'dm_os_tasks_dump')
begin
    delete top (100000) from dm_os_tasks_dump where collect_date < dateadd(day, -10, getdate())
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

/**************************************
per hour
***************************************/
if exists (select * from sys.objects where name = 'dm_exec_query_stats_dump_full')
begin
    delete top (100000) from dm_exec_query_stats_dump_full where collect_date < dateadd(day, -10, getdate())
end

if exists (select * from sys.objects where name = 'xevent_dump')
begin
    delete top (100000) from xevent_dump where time_stamp < dateadd(day, -10, getdate())
end

/**************************************
per several sec
***************************************/
if exists (select * from sys.objects where name = 'dm_exec_requests_dump_per_several_seconds')
begin
    delete top (100000) from dm_exec_requests_dump_per_several_seconds where collect_date < dateadd(day, -10, getdate())
end

/**************************************
per day
***************************************/
--日次でのINSERTなので余裕がある。1年間保持
if exists (select * from sys.objects where name = 'dm_db_partition_stats_dump')
begin
    delete top (100000) from dm_db_partition_stats_dump where collect_date < dateadd(day, -360, getdate())
end

--日次でのINSERTなので余裕がある。1年間保持
if exists (select * from sys.objects where name = 'dm_db_index_usage_stats_dump_full')
begin
    delete top (100000) from dm_db_index_usage_stats_dump_full where collect_date < dateadd(day, -360, getdate())
end
