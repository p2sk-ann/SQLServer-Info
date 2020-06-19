select 
     getdate() as collect_date
    ,object_name(s1.object_id) as object_name
    ,s1.name as statistics_name
    ,left(colname, len(colname) - 1) as column_list
	,(case when charindex('|', left(colname, len(colname) - 1), 1) > 1 then 1 else 0 end) as multi_column_flag --1 : 複数列の統計情報
    ,stats_date(s1.object_id, s1.stats_id) as statsdate --ここで統計情報の更新時間を確認できる
from sys.stats as s1
inner join sys.stats_columns as sc on s1.object_id = sc.object_id
    and s1.stats_id = sc.stats_id and stats_column_id = 1
inner join sys.columns as c on sc.object_id = c.object_id
    and c.column_id = sc.column_id
cross apply (
    select
      c.name + ' | ' 
    from
      sys.stats as s2
    inner join sys.stats_columns as sc on s2.object_id = sc.object_id
      and s2.stats_id = sc.stats_id
    inner join sys.columns as c on sc.object_id = c.object_id
      and c.column_id = sc.column_id
    and s1.object_id = s2.object_id and s1.stats_id = s2.stats_id
	order by stats_column_id
for xml PATH('')
) as a(colname)
order by statistics_name
where 1=0

--古いデータ削除用
create index IX_sys_stats_dump_collect_date on sys_stats_dump(collect_date)
