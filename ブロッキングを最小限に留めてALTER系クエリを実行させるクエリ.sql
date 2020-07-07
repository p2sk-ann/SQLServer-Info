set transaction isolation level read uncommitted
set nocount on

declare @tblname varchar(255) = 'table_name'
declare @parameter nvarchar(max)

-- @tblnameと@tblnameを参照しているVIEWを含むクエリが実行されているかの確認SQLを作成
;with objectlist as(
-- 該当オブジェクトを参照しているテーブル
select
    1 as level,
    d.referenced_id as parent_object_id,
    d.referenced_entity_name as parent_object_name,
    d.referencing_id as child_object_id,
    object_name(d.referencing_id) as child_object_name,
    o.type
from
    sys.sql_expression_dependencies as d with(nolock)
    inner join sys.objects as o with(nolock)
    on  d.referencing_id = o.object_id
    and o.type in('v')
where
    d.referenced_id = object_id(@tblname)
union all
select
    level + 1,
    c.referenced_id,
    c.referenced_entity_name,
    c.referencing_id,
    object_name(c.referencing_id) as object_name,
    o.type
from
    sys.sql_expression_dependencies as c with(nolock)
    inner join sys.objects as o with(nolock)
    on  c.referencing_id = o.object_id
    and o.type in('v')
    inner join objectlist
    on objectlist.child_object_id = c.referenced_id
)
select
    @parameter = ' and (' + 'text like ''%' + @tblname + '[^0-9|a-z|_-]%'' or ' + stuff(name,1,4,'') + ')'
from
(
    select
        coalesce(' or text like ''%' + child_object_name + '[^0-9|a-z|_-]%''','')
    from
        objectlist
    order by level asc
    for xml path('')
) as t(name)
option(maxdop 1)

declare @sql nvarchar(max) = '
select top (1) 1
from
    sys.dm_exec_requests  as er
    cross apply (select * from sys.dm_exec_cursors(er.session_id)) as a
    outer apply sys.dm_exec_sql_text(er.sql_handle) as st
    left join sys.dm_exec_sessions as es
        on er.session_id = es.session_id
where
    st.text is not null
    and er.session_id <> @@spid
    --and datediff(s, er.start_time, getdate()) >= 1 --1秒以上実行中のものに限定
'

if @parameter is null
begin
    set @parameter = ' and (' + 'text like ''%' + @tblname + '[^0-9|a-z|_-]%'')'
end
create table #tbl (val int)
--print (@sql + @parameter)


-- 該当テーブルのカーソルがオープンしてない＆ブロッキングが起きないタイミングをみつけてALTERを実行
set lock_timeout 200
declare @msg varchar(4000)

while(0=0)
begin
    begin try
    insert into #tbl
    execute (@sql + @parameter)
    if (select count(*) from #tbl) > 0
    begin
	    set @msg = format(getdate(),'yyyy-mm-dd hh:mm:ss')  + ' : ' + @tblname + ' : open cursor exists.'
		raiserror(@msg,0,0) with nowait
        waitfor delay '00:00:01'
        truncate table #tbl
    end
    else
    begin
        exec ('alter table ' + @tblname + ' enable change_tracking')
        set @msg =  format(getdate(),'yyyy-mm-dd hh:mm:ss')  + ' : ' + @tblname + ' : success'
        raiserror(@msg,0,0) with nowait
        break
    end
    end try
    begin catch
        set @msg = format(getdate(),'yyyy-mm-dd hh:mm:ss')  + ' : ' + @tblname + ' : ' + cast(error_number() as varchar(100))+ ' : ' + error_message()
        raiserror(@msg,0,0) with nowait
        -- ロックタイムアウトした場合以外 (1222) は通常のエラーなのでループを抜ける
        if error_number() <> 1222
        begin
            break
        end
        waitfor delay '00:00:01'
    end catch
end

drop table #tbl
