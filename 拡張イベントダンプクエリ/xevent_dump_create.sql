SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT 1000

DECLARE @xe_filename nvarchar(255) = N'blocked_process_report*.xel' --modify here
DECLARE @begin_time datetime
DECLARE @end_time datetime
set @begin_time = '2021/03/11 17:40:00' --modify here
set @end_time = '2021/03/11 17:50:00' --modify here

SELECT
    event_type,
    time_stamp,
    duration_ms,
    cpu_time_ms,
    physical_reads,
    logical_reads,
    session_id,
    username,
    client_app_name,
    client_hostname,
    result,
    batch_text,
    sql_text,
    statement,
    is_headblocker,
    lock_mode,
    blocking_waitresource,
    blocking_spid,
    blocking_status,
    blocking_lastbatchstarted,
    blocking_clientapp,
    blocking_hostname,
    --blocking_query,
    (case when blocking_query like '%Object Id =%' then object_name(replace(replace(substring(blocking_query, CHARINDEX('Object Id = ', blocking_query, 1), 100), 'Object Id = ', ''), ']', '')) else blocking_query end) as blocking_query,
    blocked_waitresource,
    blocked_spid,
    blocked_status,
    blocked_lock_mode,
    blocked_lastbatchstarted,
    blocked_clientapp,
    blocked_hostname,
    --blocked_query,
    (case when blocked_query like '%Object Id =%' then object_name(replace(replace(substring(blocked_query, CHARINDEX('Object Id = ', blocked_query, 1), 100), 'Object Id = ', ''), ']', '')) else blocked_query end) as blocked_query,
    blocking_execution_stack,
    blocked_execution_stack,
    file_name
INTO xevent_dump
FROM
    (
    SELECT
        event_type,
        dateadd(HOUR, +9, time_stamp) as time_stamp,
        duration_ms,
        cpu_time_ms,
        physical_reads,
        logical_reads,
        session_id,
        username,
        client_app_name,
        client_hostname,
        result,
        batch_text,
        sql_text,
        statement,
        CASE
            WHEN blocked_process.value('(/blocked-process-report/blocking-process/process/@waitresource)[1]','varchar(100)') IS NULL THEN 1
            ELSE 0
        END AS is_headblocker,
        lock_mode,
        blocked_process.value('(/blocked-process-report/blocking-process/process/@waitresource)[1]','varchar(100)') AS blocking_waitresource,
        blocked_process.value('(/blocked-process-report/blocking-process/process/@spid)[1]','int') AS blocking_spid,
        blocked_process.value('(/blocked-process-report/blocking-process/process/@status)[1]','varchar(100)') AS blocking_status,
        blocked_process.value('(/blocked-process-report/blocking-process/process/@lastbatchstarted)[1]','varchar(100)') AS blocking_lastbatchstarted,
        blocked_process.value('(/blocked-process-report/blocking-process/process/@clientapp)[1]','varchar(100)') AS blocking_clientapp,
        blocked_process.value('(/blocked-process-report/blocking-process/process/@hostname)[1]','varchar(100)') AS blocking_hostname,
        blocked_process.value('(/blocked-process-report/blocking-process/process/inputbuf)[1]','nvarchar(max)') AS blocking_query,
        blocked_process.value('(/blocked-process-report/blocked-process/process/@waitresource)[1]','varchar(100)') as blocked_waitresource,
        blocked_process.value('(/blocked-process-report/blocked-process/process/@waittime)[1]','int') as blocked_waittime,
        blocked_process.value('(/blocked-process-report/blocked-process/process/@transactionname)[1]','varchar(100)') as blocked_transactionname,
        blocked_process.value('(/blocked-process-report/blocked-process/process/@lasttranstarted)[1]','varchar(100)') as blocked_lasttranstarted,
        blocked_process.value('(/blocked-process-report/blocked-process/process/@spid)[1]','int') AS blocked_spid,
        blocked_process.value('(/blocked-process-report/blocked-process/process/@status)[1]','varchar(100)') AS blocked_status,
        blocked_process.value('(/blocked-process-report/blocked-process/process/@lockMode)[1]','varchar(100)') AS blocked_lock_mode,
        blocked_process.value('(/blocked-process-report/blocked-process/process/@lastbatchstarted)[1]','varchar(100)') AS blocked_lastbatchstarted,
        blocked_process.value('(/blocked-process-report/blocked-process/process/@clientapp)[1]','varchar(100)') AS blocked_clientapp,
        blocked_process.value('(/blocked-process-report/blocked-process/process/@hostname)[1]','varchar(100)') AS blocked_hostname,
        blocked_process.value('(/blocked-process-report/blocked-process/process/inputbuf)[1]','nvarchar(max)') AS blocked_query,
        blocked_process.query('(/blocked-process-report/blocking-process/process/executionStack)') AS blocking_execution_stack,
        blocked_process.query('(/blocked-process-report/blocked-process/process/executionStack)') AS blocked_execution_stack,
        file_name
    FROM(
        SELECT
            object_name as event_type,
            file_name,
            event_data.value('(/event/@timestamp)[1]', 'datetime2(0)') as time_stamp,
            event_data.query('/event/data/value/blocked-process-report') as blocked_process,
            event_data.value('(/event/data[@name="duration"]/value)[1]', 'bigint') / 1000 as duration_ms,
            event_data.value('(/event/data[@name="cpu_time"]/value)[1]', 'bigint') / 1000 as cpu_time_ms,
            event_data.value('(/event/data[@name="physical_reads"]/value)[1]', 'bigint') as physical_reads,
            event_data.value('(/event/data[@name="logical_reads"]/value)[1]', 'bigint') as logical_reads,
            event_data.value('(/event/action[@name="session_id"]/value)[1]', 'bigint') as session_id,
            event_data.value('(/event/action[@name="username"]/value)[1]', 'varchar(100)') as username,
            event_data.value('(/event/action[@name="client_app_name"]/value)[1]', 'varchar(100)') as client_app_name,
            event_data.value('(/event/action[@name="client_hostname"]/value)[1]', 'varchar(100)') as client_hostname,
            event_data.value('(/event/data[@name="result"]/text)[1]', 'varchar(max)') as result,
            event_data.value('(/event/data[@name="object_name"]/value)[1]', 'varchar(100)') as object_name,
            event_data.value('(/event/data[@name="batch_text"]/value)[1]', 'varchar(max)') as batch_text,
            event_data.value('(/event/action[@name="sql_text"]/value)[1]', 'varchar(max)') as sql_text,
            event_data.value('(/event/data[@name="statement"]/value)[1]', 'varchar(max)') as statement,
            event_data.value('(/event/data[@name="lock_mode"]/text)[1]', 'varchar(20)') as lock_mode
        FROM
        (
            SELECT
                object_name,
                file_name,
                CAST(event_data AS xml) AS event_data
            FROM
                sys.fn_xe_file_target_read_file(@xe_filename, null, null, null)
        ) AS T
        WHERE dateadd(HOUR, +9, cast(event_data.value('(/event/@timestamp)[1]', 'datetime2(0)') as datetime)) between @begin_time and @end_time
    ) AS T
) AS T

--古いデータ削除用
create index IX_xevent_dump_time_stamp_event_type on xevent_dump(time_stamp, event_type)
