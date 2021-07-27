declare @ServerName varchar(10)
set @ServerName = '***' --modify here

MERGE INTO ReplicationCheck_Logreader_1
USING (
	SELECT publisher_database_id
		,datepart(year, EntryTime) AS Year
		,datepart(month, EntryTime) AS Month
		,datepart(day, EntryTime) AS Day
		,datepart(hh, EntryTime) AS Hour
		,datepart(mi, EntryTime) AS Minute --時間単位にしたいときはコメントアウト
		,isnull(sum(CommandCount), 0) AS CommandCountPerTimeUnit
		,isnull(sum(TransactionCount), 0) AS TransactionCountPerTimeUnit
		,isnull(sum(DataLengthBytes), 0) AS DataLengthBytesPerTimeUnit
		,article
		,publication
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
) AS B
ON (
		_server_name = @ServerName
	and _publisher_database_id = B.publisher_database_id
	and _Year = B.Year
	and _Month = B.Month
	and _Day = B.Day
	and _Hour = B.Hour
	and _Minute = B.Minute
	and _article = B.article
	and _publication = B.publication
)
--既に登録されている場合は更新
WHEN MATCHED THEN
	UPDATE SET
		_CommandCountPerTimeUnit = B.CommandCountPerTimeUnit,
		_TransactionCountPerTimeUnit = B.TransactionCountPerTimeUnit,
		_DataLengthBytesPerTimeUnit = B.DataLengthBytesPerTimeUnit
--登録されていない場合は新規登録
WHEN NOT MATCHED THEN
	INSERT (_server_name, _publisher_database_id, _Year, _Month, _Day, _Hour, _Minute, _CommandCountPerTimeUnit, _TransactionCountPerTimeUnit, _DataLengthBytesPerTimeUnit, _article, _publication, _registDT)
	VALUES (@ServerName, B.publisher_database_id, B.Year, B.Month, B.Day, B.Hour, B.Minute, B.CommandCountPerTimeUnit, B.TransactionCountPerTimeUnit, B.DataLengthBytesPerTimeUnit, B.article, B.publication, getdate());
