SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @xe_filename nvarchar(255) = N'blocked_process_report_name*.xel' --modify here
DECLARE @begin_time datetime
DECLARE @end_time datetime
set @begin_time = '2020/06/23 17:00:00' --modify here
set @end_time = '2020/06/23 18:00:00' --modify here

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
    blocking_client_app,
    --blocking_query,
    (case when blocking_query like '%Object Id =%' then object_name(replace(replace(substring(blocking_query, CHARINDEX('Object Id = ', blocking_query, 1), 100), 'Object Id = ', ''), ']', '')) else blocking_query end) as blocking_query,
    waitresource,
    blocked_spid,
    blocked_client_app,
    --blocked_query,
    (case when blocked_query like '%Object Id =%' then object_name(replace(replace(substring(blocked_query, CHARINDEX('Object Id = ', blocked_query, 1), 100), 'Object Id = ', ''), ']', '')) else blocked_query end) as blocked_query,
    event_data
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
        blocked_process.value('(/blocked-process-report/blocking-process/process/@client_app)[1]','varchar(100)') AS blocking_client_app,
        blocked_process.value('(/blocked-process-report/blocking-process/process/inputbuf)[1]','nvarchar(max)') AS blocking_query,
        blocked_process.value('(/blocked-process-report/blocked-process/process/@waitresource)[1]','varchar(100)') as waitresource,
        blocked_process.value('(/blocked-process-report/blocked-process/process/@spid)[1]','int') AS blocked_spid,
        blocked_process.value('(/blocked-process-report/blocked-process/process/@client_app)[1]','varchar(100)') AS blocked_client_app,
        blocked_process.value('(/blocked-process-report/blocked-process/process/inputbuf)[1]','nvarchar(max)') AS blocked_query,
        event_data
    FROM(
        SELECT
            object_name as event_type,
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
            event_data.value('(/event/data[@name="lock_mode"]/text)[1]', 'varchar(20)') as lock_mode,
            event_data
        FROM
        (
            SELECT
                object_name,
                CAST(event_data AS xml) AS event_data
            FROM
                sys.fn_xe_file_target_read_file(@xe_filename, null, null, null)
        ) AS T
        WHERE dateadd(HOUR, +9, cast(event_data.value('(/event/@timestamp)[1]', 'datetime2(0)') as datetime)) between @begin_time and @end_time
    ) AS T
) AS T
ORDER BY time_stamp
