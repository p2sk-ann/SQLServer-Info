SELECT object_name(s.object_id) AS object_name
  ,s.NAME AS statistics_name
  ,c.NAME AS column_name
  ,sc.stats_column_id
  ,STATS_DATE(s.object_id, s.stats_id) as statsdate --ここで統計情報の更新時間を確認できる
into sys_stats_dump
FROM sys.stats AS s
INNER JOIN sys.stats_columns AS sc ON s.object_id = sc.object_id
  AND s.stats_id = sc.stats_id
INNER JOIN sys.columns AS c ON sc.object_id = c.object_id
  AND c.column_id = sc.column_id
WHERE 1=0
