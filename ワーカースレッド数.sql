SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SELECT
  (SELECT
    max_workers_count
  FROM
    sys.dm_os_sys_info
  ) as max_workers_count
,
  (SELECT
    sum(current_workers_count) as current_workers_count
  FROM
    sys.dm_os_schedulers
  WHERE
    scheduler_id < 256
  ) as current_workers_count