set transaction isolation level read uncommitted
set lock_timeout 1000
set nocount on

declare @CONST_profile_name varchar(30)
declare @CONST_recipients varchar(200)
declare @CONST_subject nvarchar(500) = @@SERVERNAME + N' : DMVのダンプデータが削除しきれていない'
declare @msg nvarchar(max) = ''
declare @CrLf nvarchar(2)
SET @CrLf = nchar(13) + nchar(10)


SET @CONST_profile_name = 'profile_name_here' --modify here
SET @CONST_recipients = 'mail_address_here' --modify here


/**************************************
per minute
***************************************/
if exists (select * from sys.objects where name = 'dm_db_file_space_usage_tempdb_dump')
begin
    if exists (select * from dm_db_file_space_usage_tempdb_dump where collect_date < dateadd(day, -11, getdate()))
        set @msg = @msg + db_name() + ' : ' + 'dm_db_file_space_usage_tempdb_dump' + @CrLf
end

if exists (select * from sys.objects where name = 'dm_db_index_operational_stats_dump')
begin
    if exists (select * from dm_db_index_operational_stats_dump where collect_date < dateadd(day, -11, getdate()))
        set @msg = @msg + db_name() + ' : ' + 'dm_db_index_operational_stats_dump' + @CrLf
end

if exists (select * from sys.objects where name = 'dm_db_index_usage_stats_dump')
begin
    if exists (select * from dm_db_index_usage_stats_dump where collect_date < dateadd(day, -11, getdate()))
        set @msg = @msg + db_name() + ' : ' + 'dm_db_index_usage_stats_dump' + @CrLf
end

if exists (select * from sys.objects where name = 'dm_exec_procedure_stats_dump')
begin
    if exists (select * from dm_exec_procedure_stats_dump where collect_date < dateadd(day, -11, getdate()))
        set @msg = @msg + db_name() + ' : ' + 'dm_exec_procedure_stats_dump' + @CrLf
end

if exists (select * from sys.objects where name = 'dm_exec_query_stats_dump')
begin
    if exists (select * from dm_exec_query_stats_dump where collect_date < dateadd(day, -11, getdate()))
        set @msg = @msg + db_name() + ' : ' + 'dm_exec_query_stats_dump' + @CrLf
end

if exists (select * from sys.objects where name = 'dm_exec_requests_dump')
begin
    if exists (select * from dm_exec_requests_dump where collect_date < dateadd(day, -11, getdate()))
        set @msg = @msg + db_name() + ' : ' + 'dm_exec_requests_dump' + @CrLf
end

if exists (select * from sys.objects where name = 'dm_io_virtual_file_stats_dump')
begin
    if exists (select * from dm_io_virtual_file_stats_dump where collect_date < dateadd(day, -11, getdate()))
        set @msg = @msg + db_name() + ' : ' + 'dm_io_virtual_file_stats_dump' + @CrLf
end

if exists (select * from sys.objects where name = 'dm_os_latch_stats_dump')
begin
    if exists (select * from dm_os_latch_stats_dump where collect_date < dateadd(day, -11, getdate()))
        set @msg = @msg + db_name() + ' : ' + 'dm_os_latch_stats_dump' + @CrLf
end

if exists (select * from sys.objects where name = 'dm_os_memory_clerks_dump')
begin
    if exists (select * from dm_os_memory_clerks_dump where collect_date < dateadd(day, -11, getdate()))
        set @msg = @msg + db_name() + ' : ' + 'dm_os_memory_clerks_dump' + @CrLf
end

if exists (select * from sys.objects where name = 'dm_os_schedulers_dump')
begin
    if exists (select * from dm_os_schedulers_dump where collect_date < dateadd(day, -11, getdate()))
        set @msg = @msg + db_name() + ' : ' + 'dm_os_schedulers_dump' + @CrLf
end

if exists (select * from sys.objects where name = 'dm_os_tasks_dump')
begin
    if exists (select * from dm_os_tasks_dump where collect_date < dateadd(day, -11, getdate()))
        set @msg = @msg + db_name() + ' : ' + 'dm_os_tasks_dump' + @CrLf
end

if exists (select * from sys.objects where name = 'dm_os_wait_stats_dump')
begin
    if exists (select * from dm_os_wait_stats_dump where collect_date < dateadd(day, -11, getdate()))
        set @msg = @msg + db_name() + ' : ' + 'dm_os_wait_stats_dump' + @CrLf
end

if exists (select * from sys.objects where name = 'dm_os_waiting_tasks_dump')
begin
    if exists (select * from dm_os_waiting_tasks_dump where collect_date < dateadd(day, -11, getdate()))
        set @msg = @msg + db_name() + ' : ' + 'dm_os_waiting_tasks_dump' + @CrLf
end

if exists (select * from sys.objects where name = 'sys_stats_dump')
begin
    if exists (select * from sys_stats_dump where collect_date < dateadd(day, -11, getdate()))
        set @msg = @msg + db_name() + ' : ' + 'sys_stats_dump' + @CrLf
end

/**************************************
per hour
***************************************/
if exists (select * from sys.objects where name = 'dm_exec_query_stats_dump_full')
begin
    if exists (select * from dm_exec_query_stats_dump_full where collect_date < dateadd(day, -11, getdate()))
        set @msg = @msg + db_name() + ' : ' + 'dm_exec_query_stats_dump_full' + @CrLf
end

if exists (select * from sys.objects where name = 'xevent_dump')
begin
    if exists (select * from xevent_dump where time_stamp < dateadd(day, -11, getdate()))
        set @msg = @msg + db_name() + ' : ' + 'xevent_dump' + @CrLf
end

/**************************************
per several sec
***************************************/
if exists (select * from sys.objects where name = 'dm_exec_requests_dump_per_several_seconds')
begin
    if exists (select * from dm_exec_requests_dump_per_several_seconds where collect_date < dateadd(day, -11, getdate()))
        set @msg = @msg + db_name() + ' : ' + 'dm_exec_requests_dump_per_several_seconds' + @CrLf
end

/**************************************
per day
***************************************/
--日次でのINSERTなので余裕がある。1年間保持
if exists (select * from sys.objects where name = 'dm_db_partition_stats_dump')
begin
    if exists (select * from dm_db_partition_stats_dump where collect_date < dateadd(day, -361, getdate()))
        set @msg = @msg + db_name() + ' : ' + 'dm_db_partition_stats_dump' + @CrLf
end

--日次でのINSERTなので余裕がある。1年間保持
if exists (select * from sys.objects where name = 'dm_db_index_usage_stats_dump_full')
begin
    if exists (select * from dm_db_index_usage_stats_dump_full where collect_date < dateadd(day, -361, getdate()))
        set @msg = @msg + db_name() + ' : ' + 'dm_db_index_usage_stats_dump_full' + @CrLf
end

/**************************************
削除しきれていないテーブルがあれば通知
***************************************/
if @msg <> ''
begin
    set @msg = 'リストアップされたテーブルが、古いデータが削除しきれていません。一時的な場合は削除を、定期的に発生する場合はデータの削除処理件数を増やすなどして対応してください。テーブルごとのデータ保持期間はジョブ「zozo_DMV_Dump_Delete」を参照してください。' + @CrLf + @CrLf + @msg
    exec msdb.dbo.sp_send_dbmail @profile_name = @CONST_profile_name, @recipients = @CONST_recipients, @subject = @CONST_subject, @body = @msg
end
