--■ 配信中のレプリコマンド数を抽出
--distributer - subscriber 間の未配信コマンド数を取得可能(集計期間は謎)
--エージェント、アーティクル単位で、まだサブスクライバにレプリ完了してないコマンド数が確認できる
--http://www.dbafire.com/2012/12/05/troubleshooting-sql-server-replication-delays/

--全部JOINすると何故かCPUボトルネックなプランになって長時間実行されてしまうため一時テーブルにいったんいれる
select * into #DistStat from distribution.dbo.MSdistribution_status with(nolock)

SELECT DISTINCT
	 @@SERVERNAME as server_name
	,a.article_id
	,a.Article
	,p.Publication
	,SUBSTRING(agents.[name], 16, 35) AS [Name]
	,s.agent_id
	,s.UndelivCmdsInDistDB
	,s.DelivCmdsInDistDB
	,getdate() as registDT
INTO ReplicationCheck_distributor_2
FROM  #DistStat AS s with(nolock)
INNER JOIN distribution.dbo.MSdistribution_agents AS agents with(nolock) ON agents.[id] = s.agent_id
INNER JOIN distribution.dbo.MSpublications AS p with(nolock) ON p.publication = agents.publication
INNER JOIN distribution.dbo.MSarticles AS a with(nolock) ON a.article_id = s.article_id AND p.publication_id = a.publication_id
WHERE 1 = 1
	AND s.UndelivCmdsInDistDB <> 0
	AND agents.subscriber_db NOT LIKE '%virtual%'

drop table #DistStat
