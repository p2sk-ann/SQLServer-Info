declare @db_name as nvarchar(1000)
set @db_name = 'master' --未使用ストアドを取得したいDB名をセット
declare @sql nvarchar(max)

set @sql = '
select * from ' + @db_name + '.sys.objects
where name not in (select object_name from dm_exec_procedure_stats_usage_dump where database_name = ''' + @db_name + ''')
and type=''P''
'
execute(@sql)
