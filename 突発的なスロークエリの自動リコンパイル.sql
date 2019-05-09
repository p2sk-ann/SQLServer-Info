declare @CONST_profile_name varchar(30)
declare @CONST_recipients varchar(200)
declare @CONST_subject nvarchar(100) = @@SERVERNAME + N'多発したスロークエリのリコンパイル完了'
declare @msg nvarchar(max) = ''
declare @CrLf nvarchar(2)
SET @CrLf = nchar(13) + nchar(10)

SET @CONST_profile_name = '*****'
SET @CONST_recipients = '*****'

declare @recompile_threashold_cnt int = 5 --この数以上、同一クエリが実行中だったらリコンパイル
declare @recompile_threashold_sec int = 1 --何秒以上実行中のクエリを対象にするか
declare @sql_handle varbinary(64)
declare @text nvarchar(max)
declare @exec_cnt int

declare cursor_sqlhandle CURSOR FAST_FORWARD FOR
	-- 一応同時にリコンパイルするクエリは最大5個までとしておく
	select top (5)
		 sql_handle
		,max(text) as text
		,count(*) as cnt
	from
		 sys.dm_exec_requests der
	join sys.dm_exec_sessions des on des.session_id = der.session_id
	outer apply sys.dm_exec_sql_text(sql_handle) as dest
	where
		des.is_user_process = 1
	and datediff(s, der.start_time, GETDATE()) >= @recompile_threashold_sec
	and sql_handle is not null
	group by
		sql_handle
	having
		count(*) >= @recompile_threashold_cnt

open cursor_sqlhandle

fetch next from cursor_sqlhandle into @sql_handle, @text, @exec_cnt

while @@fetch_status = 0
begin
	--select @text, @exec_cnt
	set @msg = @msg + '■ クエリ(最初の2000文字)' + @CrLf + substring(@text, 1, 2000) + @CrLf + '■ 同時実行数' + @CrLf + cast(@exec_cnt as nvarchar) + @CrLf + @CrLf
	--クエリのリコンパイル
	DBCC FREEPROCCACHE(@sql_handle)

	fetch next from cursor_sqlhandle into @sql_handle, @text, @exec_cnt
end

close cursor_sqlhandle
deallocate cursor_sqlhandle

if @msg <> ''
begin
	exec msdb.dbo.sp_send_dbmail @profile_name = @CONST_profile_name, @recipients = @CONST_recipients, @subject = @CONST_subject, @body = @msg
end
