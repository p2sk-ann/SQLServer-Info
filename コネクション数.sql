SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SELECT
	 DB_NAME(dbid) as dbname
	,COUNT(*) as connection_count
FROM sys.sysprocesses
GROUP BY
	DB_NAME(dbid)
