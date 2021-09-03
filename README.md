# SQLServer-Info
このリポジトリは、SQL Serverに関する様々な情報を収取するためのクエリをまとめています。

# License
このリポジトリはMITライセンスのもとで公開しています。

# How to use sqlserver_logging directory
### ディレクトリ構成
各ディレクトリごとに、1種類の情報を収集、解析するためのクエリをまとめています。（「使用例」ディレクトリ以外）
![image](https://user-images.githubusercontent.com/36248899/132019713-8927121c-8d39-47a3-a053-e8687b7eb6b9.png)

### ディレクトリ内のファイル構成
各ディレクトリの中には、3種類のサフィックスがついたファイルがあります。

![image](https://user-images.githubusercontent.com/36248899/132018271-986bce52-d69f-4fb9-82db-465c6e60b5d7.png)

- xxx_create.sql
  - ダンプ用のテーブルを作成するクエリ。一度だけ実行すればOK
- xxx_insert.sql
  - ダンプ用テーブルにクエリ実行結果をINSERTしていくためのクエリ。1分間など定期的な間隔で実行する
- xxx_analysis.sql
  - ダンプしたテーブルから、特定の時間帯の情報を取得するためのクエリサンプル

#### xxx_analysis.sqlについて
解析用のクエリは2パターンあります。

① 指定した時間帯の情報をそのまま表示するパターン

例えばsys.dm_exec_requestsのダンプ用テーブル「dm_exec_requests_dump」では、「指定した期間の中で1秒以上実行中だったクエリ」を取得したいので、WHERE句でcollect_date（取得日時）を指定すれば該当時間帯のデータをそのまま表示することで解析できます。

```sql
select * from dm_exec_requests_dump
where collect_date between '2021-09-01 10:00' and '2021-09-01 10:30'
order by collect_date
```

② 累積値になっているデータを集計して表示するパターン

例えばsys.dm_dm_exec_procedure_statsのダンプ用テーブル「dm_exec_procedure_stats_dump」では、各ダンプは「キャッシュされてから、ダンプしたタイミングまでの各ストアドプロシージャのパフォーマンス統計の累積値」しか分からないため、そのまま表示するのではなく集計して結果を表示します。
また、2点間の時間帯における、各カラム値の合計を100%としたときに、各値が全体の何％を占めるかまで算出しています。そのため、「2021/09/01 12:00-12:05の5分間では、XXXというストアドプロシージャが全体のCPU使用時間の9割を占めていた」といった、そのタイミングで特定リソースへ負荷を大きくかけていたクエリの特定も可能です。

```sql
set transaction isolation level read uncommitted

declare @total_execution_count float
declare @total_worker_time float
declare @total_elapsed_time float
declare @total_logical_writes float
declare @total_logical_reads float

--期間指定
declare
   @start_at datetime = '2021/08/24 21:00'
  ,@end_at datetime = '2021/08/24 22:00'

--一時テーブルに情報をダンプ
select
	*
into #tmp
from
(
  select
     row_number() over (partition by object_name, cached_time order by execution_count desc) as rownum
    ,min(execution_count) over (partition by object_name, cached_time) as min_execution_count
    ,min(total_worker_time) over (partition by object_name, cached_time) as min_total_worker_time
    ,min(total_elapsed_time) over (partition by object_name, cached_time) as min_total_elapsed_time
    ,min(total_logical_writes) over (partition by object_name, cached_time) as min_total_logical_writes
    ,min(total_logical_reads) over (partition by object_name, cached_time) as min_total_logical_reads
    ,*
  from dm_exec_procedure_stats_dump with(nolock)
  where object_name not like 'sp[_]%' --システムストアドプロシージャを除外
  and exists ( --システムストアドプロシージャを除外
        select * from sys.objects ob with(nolock) where ob.object_id = object_id(object_name) and is_ms_shipped = 0
    )
  and collect_date between @start_at and @end_at
  and database_id = db_id()
) as a
where rownum = 1 --キャッシュアウトされていない同一データの中で最新のものだけに限定

--該当時間帯の合計値を算出
select
   @total_execution_count = sum((case when cached_time >= @start_at then execution_count else execution_count - min_execution_count end))
  ,@total_worker_time = sum((case when cached_time >= @start_at then total_worker_time else total_worker_time - min_total_worker_time end))
  ,@total_elapsed_time = sum((case when cached_time >= @start_at then total_elapsed_time else total_elapsed_time - min_total_elapsed_time end))
  ,@total_logical_writes = sum((case when cached_time >= @start_at then total_logical_writes else total_logical_writes - min_total_logical_writes end))
  ,@total_logical_reads = sum((case when cached_time >= @start_at then total_logical_reads else total_logical_reads - min_total_logical_reads end))
from
  #tmp

--該当時間帯でリソースの消費量が多い順にストアドプロシージャをリストアップ
select
  *
  ,cast(total_execution_count / @total_execution_count * 100 as numeric(4,2)) as percentage_execution_count
  ,cast(total_worker_time / @total_worker_time * 100 as numeric(4,2)) as percentage_worker_time
  ,cast(total_elapsed_time / @total_elapsed_time * 100 as numeric(4,2)) as percentage_elapsed_time
  ,cast(total_logical_writes / @total_logical_writes * 100 as numeric(4,2)) as percentage_logical_writes
  ,cast(total_logical_reads / @total_logical_reads * 100 as numeric(4,2)) as percentage_logical_reads
from
(
  select
     object_name
    ,sum((case when cached_time >= @start_at then execution_count else execution_count - min_execution_count end)) as total_execution_count
    ,sum((case when cached_time >= @start_at then total_worker_time else total_worker_time - min_total_worker_time end)) as total_worker_time
    ,sum((case when cached_time >= @start_at then total_elapsed_time else total_elapsed_time - min_total_elapsed_time end)) as total_elapsed_time
    ,sum((case when cached_time >= @start_at then total_logical_writes else total_logical_writes - min_total_logical_writes end)) as total_logical_writes
    ,sum((case when cached_time >= @start_at then total_logical_reads else total_logical_reads - min_total_logical_reads end)) as total_logical_reads
  from
    #tmp
  group by
    object_name
) as a
order by
  percentage_worker_time desc --並び替えたい項目を指定

drop table #tmp
```

### 「使用例」ディレクトリのファイル構成
「使用例」ディレクトリには、SQL Serverのジョブで定期実行することを想定したサンプルクエリが入っています。そのままお使いいただけます。
「per_day」などのサフィックスは、推奨する実行頻度です。

- clear_job_query_per_day.sql
  - DMVの情報の中で値をリセットできる情報をリセットするクエリ。1日1回を推奨。
- create_table_query_only_once.sql
  - ダンプ用のテーブルを一通り作成するクエリ。1回だけ実行すればOK。
- delete_check_job_query_per_day.sql
  - 期限切れのデータの削除漏れを検知するクエリ。1日1回を推奨。
- delete_job_query_per_hour.sql
  - 期限切れデータを削除するクエリ。1時間に1回程度を推奨。
- insert_job_query_per_day.sql
  - ダンプ用テーブルへデータをINSERTするクエリ。1日1回を推奨。
- insert_job_query_per_hour.sql
  - ダンプ用テーブルへデータをINSERTするクエリ。1時間に1回を推奨。
- insert_job_query_per_minute.sql
  - ダンプ用テーブルへデータをINSERTするクエリ。1分に1回を推奨。
- insert_job_query_per_several_sec.sql
  - ダンプ用テーブルへデータをINSERTするクエリ。数秒に1回を推奨。
