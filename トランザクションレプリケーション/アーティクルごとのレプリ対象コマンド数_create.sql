SELECT @@servername as _server_name
	,publisher_database_id as _publisher_database_id
	,datepart(year, EntryTime) AS _Year
	,datepart(month, EntryTime) AS _Month
	,datepart(day, EntryTime) AS _Day
	,datepart(hh, EntryTime) AS _Hour
	,datepart(mi, EntryTime) AS _Minute --時間単位にしたいときはコメントアウト
	,isnull(sum(CommandCount), 0) AS _CommandCountPerTimeUnit
	,isnull(sum(TransactionCount), 0) AS _TransactionCountPerTimeUnit
	,isnull(sum(DataLengthBytes), 0) AS _DataLengthBytesPerTimeUnit
	,article as _article
	,publication as  _publication
	,getdate() as _registDT
INTO ReplicationCheck_Logreader_1
FROM (
	SELECT t.publisher_database_id
		,t.xact_seqno
		,max(t.entry_time) AS EntryTime
		,count(c.xact_seqno) AS CommandCount
		,count(DISTINCT c.xact_seqno) AS TransactionCount
		,sum(datalength(c.command)) AS DataLengthBytes
		,art.article
		,pub.publication
	FROM distribution.dbo.MSrepl_commands c WITH (NOLOCK)
	INNER JOIN distribution.dbo.MSarticles art WITH (NOLOCK) ON art.article_id = c.article_id
	INNER JOIN distribution.dbo.MSpublications pub WITH (NOLOCK) ON art.publication_id = pub.publication_id
	INNER JOIN distribution.dbo.msrepl_transactions t WITH (NOLOCK) ON t.publisher_database_id = c.publisher_database_id
		AND t.xact_seqno = c.xact_seqno
	GROUP BY t.publisher_database_id
		,art.article
		,pub.publication
		,t.xact_seqno
) AS AAA
GROUP BY publisher_database_id
	,datepart(year, EntryTime)
	,datepart(month, EntryTime)
	,datepart(day, EntryTime)
	,datepart(hh, EntryTime)
	,datepart(mi, EntryTime) --時間単位にしたいときはコメントアウト
	,publication
	,article
