DECLARE
     @Database sysname
    ,@sql nvarchar(2000)

DECLARE
    CMyCursor CURSOR FAST_FORWARD FOR
        SELECT
            name
        FROM
            master.sys.databases WITH(NOLOCK)
        WHERE
        -- システムDBおよびディストリビューションDB除外、かつオンラインのDBに限定
            Cast(CASE WHEN name IN ('master', 'model', 'msdb', 'tempdb') THEN 1 ELSE is_distributor END As bit) = 0
        AND state = 0

OPEN CMyCursor
FETCH NEXT FROM CMyCursor INTO
    @Database

-- DB単位のループ
WHILE @@fetch_status = 0
BEGIN

    set @sql = ''
    -- useを使う必要があるが、use単体でexecuteすると実行後にコンテキストが現在のDBに戻ってしまう。そのため丸ごと動的SQLで実行する
    set @sql = @sql + ' USE ' + CAST(@Database AS NVARCHAR(100)) + ';'

    -- ここにDBごとに実行したい処理を書く
    set @sql = @sql + 'if exists(select * from sys.all_objects with(nolock) where name = ''syspublications'')'
    set @sql = @sql + 'select '
    set @sql = @sql + '	distinct  '
    set @sql = @sql + '	 pub.name Publication '
    set @sql = @sql + '	 ,db_name() as PublisherDB '
    set @sql = @sql + '	,sub.dest_db SubscriberDB '
    set @sql = @sql + '	,case when subscription_type = 1 then ''Pull'' else ''Push'' end as SubscriptionType '
    set @sql = @sql + 'from dbo.syspublications as pub '
    set @sql = @sql + 'inner join dbo.sysarticles as art on art.pubid = pub.pubid '
    set @sql = @sql + 'inner join dbo.syssubscriptions as sub on art.artid = sub.artid '

    -- useと実行したい処理を同一コンテキスト内で実行
    execute sp_executesql @sql

FETCH NEXT FROM CMyCursor INTO
    @Database
END

CLOSE CMyCursor
DEALLOCATE CMyCursor
