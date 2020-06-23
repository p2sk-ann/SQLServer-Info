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
    set @sql = @sql + ' declare @alert_rate float '
    set @sql = @sql + ' set @alert_rate = 0.8 '

    set @sql = @sql + ' SELECT '
    set @sql = @sql + '     T.name as table_name, '
    set @sql = @sql + '     IDENT_CURRENT(T.name) as current_identity_value, '
    set @sql = @sql + '     C.name as column_name, '
    set @sql = @sql + '     Y.name as type_name, '
    set @sql = @sql + '     C.increment_value, '
    set @sql = @sql + '     C.precision '
    set @sql = @sql + '     ,IDENT_CURRENT(T.name) / (case '
    set @sql = @sql + '                                 when Y.name = ''tinyint'' then 255 '
    set @sql = @sql + '                                 when Y.name = ''smallint'' then 32767 '
    set @sql = @sql + '                                 when Y.name = ''int'' then 2147483647 '
    set @sql = @sql + '                                 when Y.name = ''bigint'' then 9223372036854775807 '
    set @sql = @sql + '                                 when Y.name = ''decimal'' then (POWER(CAST(10 AS float), C.precision - 1)) '
    set @sql = @sql + '                                 when Y.name = ''numeric'' then (POWER(CAST(10 AS float), C.precision - 1)) '
    set @sql = @sql + '                                 else 1 '
    set @sql = @sql + '                             end) as threshold_rate '
    set @sql = @sql + ' FROM '
    set @sql = @sql + '      sys.tables AS T '
    set @sql = @sql + ' JOIN sys.identity_columns AS C ON C.object_id = T.object_id '
    set @sql = @sql + ' JOIN sys.types AS Y ON Y.system_type_id = C.system_type_id AND Y.user_type_id = C.user_type_id '
    set @sql = @sql + ' WHERE '
    set @sql = @sql + '     T.type = ''U'' '
    set @sql = @sql + ' and IDENT_CURRENT(T.name) / (case '
    set @sql = @sql + '                                 when Y.name = ''tinyint'' then 255 '
    set @sql = @sql + '                                 when Y.name = ''smallint'' then 32767 '
    set @sql = @sql + '                                 when Y.name = ''int'' then 2147483647 '
    set @sql = @sql + '                                 when Y.name = ''bigint'' then 9223372036854775807 '
    set @sql = @sql + '                                 when Y.name = ''decimal'' then (POWER(CAST(10 AS float), C.precision - 1)) '
    set @sql = @sql + '                                 when Y.name = ''numeric'' then (POWER(CAST(10 AS float), C.precision - 1)) '
    set @sql = @sql + '                                 else 1 '
    set @sql = @sql + '                             end) > @alert_rate '
    set @sql = @sql + ' ORDER BY '
    set @sql = @sql + '     T.name, C.column_id '

    -- useと実行したい処理を同一コンテキスト内で実行
    execute sp_executesql @sql

FETCH NEXT FROM CMyCursor INTO
    @Database
END

CLOSE CMyCursor
DEALLOCATE CMyCursor
