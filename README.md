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
