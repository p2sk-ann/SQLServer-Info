-- 存在しないログインでマッピングを作ることで、特定のログインがリンクサーバーを使用できなくする
select 
  --このEXECクエリを実行
  'EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname = N''' + remote_server_name + ''', @locallogin = N''' + name + ''', @useself = N''False'', @rmtuser = N''none'', @rmtpassword = N''''' as query
	,*
from sys.server_principals with (nolock)
cross join (
  --リンクサーバーリスト
	select name as remote_server_name
	from sys.servers
	where is_system = 0
		and is_publisher = 0
		and is_subscriber = 0
		and is_distributor = 0
		and is_linked = 1
	) as a
where type = 'S'
	and name = 'login_name_here'
	and is_disabled = 0
order by query
