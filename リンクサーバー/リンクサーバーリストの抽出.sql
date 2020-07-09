--レプリ等で追加されたものは除外し、手動で作成したものだけをリストアップ
select name as remote_server_name
from sys.servers
where is_system = 0
	and is_publisher = 0
	and is_subscriber = 0
	and is_distributor = 0
	and is_linked = 1
