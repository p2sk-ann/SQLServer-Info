insert into dm_db_file_space_usage_tempdb_dump
select
	 getdate() as collect_date
	,sum(total_page_count) * 8 / 1024.0 as sum_total_page_size_mb --tempdbのサイズ
	,sum(allocated_extent_page_count) * 8 / 1024.0 as sum_allocated_extent_page_size_mb --割り当て済みのサイズ
	,sum(unallocated_extent_page_count) * 8 / 1024.0 as sum_unallocated_extent_page_size_mb --未割当のサイズ
	,sum(version_store_reserved_page_count) * 8 / 1024.0 as sum_version_store_reserved_page_size_mb --バージョンストアで使用しているサイズ
	,sum(user_object_reserved_page_count) * 8 / 1024.0 as sum_user_object_reserved_page_size_mb --一時テーブルなど
	,sum(internal_object_reserved_page_count) * 8 / 1024.0 as sum_internal_object_reserved_page_size_mb --ソートなどに使用されている領域
	,sum(mixed_extent_page_count) * 8 / 1024.0 as sum_mixed_extent_page_size_mb --今は単一エクステントが基本のはず
from tempdb.sys.dm_db_file_space_usage --現在のDBの状況が返ってくるので「tempdb.」をつける
option(maxdop 1)
