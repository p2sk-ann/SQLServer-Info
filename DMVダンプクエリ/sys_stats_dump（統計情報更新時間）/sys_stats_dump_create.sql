select object_name(s.object_id) as object_name
  ,s.name as statistics_name
  ,c.name as column_name
  ,sc.stats_column_id
  ,stats_date(s.object_id, s.stats_id) as statsdate --ここで統計情報の更新時間を確認できる
into sys_stats_dump
from sys.stats as s
inner join sys.stats_columns as sc on s.object_id = sc.object_id
  and s.stats_id = sc.stats_id
inner join sys.columns as c on sc.object_id = c.object_id
  and c.column_id = sc.column_id
where 1=0
