USE [master]
GO
DECLARE @server_name nvarchar(100)
DECLARE @datasrc_name nvarchar(100)
set @server_name = N'link_server_name'
set @datasrc_name = N'datasrc_name'

EXEC master.dbo.sp_addlinkedserver @server = @server_name, @srvproduct=N'', @provider=N'SQLOLEDB', @datasrc=@datasrc_name

EXEC master.dbo.sp_serveroption @server=@server_name, @optname=N'collation compatible', @optvalue=N'false'

EXEC master.dbo.sp_serveroption @server=@server_name, @optname=N'data access', @optvalue=N'true'

EXEC master.dbo.sp_serveroption @server=@server_name, @optname=N'dist', @optvalue=N'false'

EXEC master.dbo.sp_serveroption @server=@server_name, @optname=N'pub', @optvalue=N'false'

EXEC master.dbo.sp_serveroption @server=@server_name, @optname=N'rpc', @optvalue=N'false'

EXEC master.dbo.sp_serveroption @server=@server_name, @optname=N'rpc out', @optvalue=N'false'

EXEC master.dbo.sp_serveroption @server=@server_name, @optname=N'sub', @optvalue=N'false'

EXEC master.dbo.sp_serveroption @server=@server_name, @optname=N'connect timeout', @optvalue=N'0'

EXEC master.dbo.sp_serveroption @server=@server_name, @optname=N'collation name', @optvalue=null

EXEC master.dbo.sp_serveroption @server=@server_name, @optname=N'lazy schema validation', @optvalue=N'false'

EXEC master.dbo.sp_serveroption @server=@server_name, @optname=N'query timeout', @optvalue=N'0'

EXEC master.dbo.sp_serveroption @server=@server_name, @optname=N'use remote collation', @optvalue=N'true'

EXEC master.dbo.sp_serveroption @server=@server_name, @optname=N'remote proc transaction promotion', @optvalue=N'true'

--「ログインの現在のセキュリティコンテキストを使用する」場合はこっち
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname = @server_name, @locallogin = NULL , @useself = N'True'

--「このセキュリティコンテキストを使用する」場合はこっち。ログイン名とパスワードも入力
--EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname = @server_name, @locallogin = NULL , @useself = N'False', @rmtuser = N'login_name', @rmtpassword = N'password'
