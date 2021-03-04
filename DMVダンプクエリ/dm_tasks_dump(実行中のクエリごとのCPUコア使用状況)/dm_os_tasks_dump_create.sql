SELECT ot.session_id
	,count(*) AS current_using_cpu_count
	,cast(count(*) * 100.0 / (
			SELECT cpu_count
			FROM sys.dm_os_sys_info
			) AS NUMERIC(4, 1)) AS cpu_percentage
	,count(*) OVER () AS all_using_cpu_count
	,cast(count(*) OVER () * 100.0 / (
			SELECT cpu_count
			FROM sys.dm_os_sys_info
			) AS NUMERIC(4, 1)) AS current_cpu_percent
	,max(es.STATUS) AS STATUS
	,max(host_name) AS host_name
	,max(program_name) AS program_name
	,max(TEXT) AS qery_text
INTO dm_os_tasks_dump
FROM sys.dm_os_tasks ot WITH (NOLOCK)
LEFT JOIN sys.dm_exec_sessions es WITH (NOLOCK) ON ot.session_id = es.session_id
LEFT JOIN sys.dm_exec_requests er WITH (NOLOCK) ON ot.session_id = er.session_id
OUTER APPLY sys.dm_exec_sql_text(sql_handle) AS dest
WHERE task_state = 'RUNNING'
GROUP BY ot.session_id
ORDER BY count(*) DESC
