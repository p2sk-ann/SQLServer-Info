--https://msdn.microsoft.com/ja-jp/library/ms190486(v=sql.120).aspx
--★パブッリッシュされたデータベースごとに、待機時間、スループット、トランザクション数に関するレプリケーションの統計を返す
--パブリッシャー側ならどのDBで実行してもOK
--publisher-distributer間の情報がとれる
CREATE TABLE #replcounters_tmp (
	 databasename sysname
	,replicated_transactions int
	,replication_rate_trans_per_sec float
	,replication_latency_sec float
	,replbeginlsn binary(10)
	,replnextlsn binary(10)
	)

INSERT INTO #replcounters_tmp
exec sp_replcounters

select @@SERVERNAME as server_name, *, getdate() as registdt
into ReplicationCheck_Logreader_2
from #replcounters_tmp

truncate table #replcounters_tmp
