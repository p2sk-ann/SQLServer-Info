declare @start datetime, @end datetime
set @start = '2020/06/21 23:30:00'
set @end = '2020/06/22 00:30:00'

select
     a.table_name
    ,a.name
    ,a.collect_date
    ,(a.leaf_insert_count - b.leaf_insert_count) as leaf_insert_count
    ,(a.leaf_update_count - b.leaf_update_count) as leaf_update_count
    ,(a.leaf_delete_count - b.leaf_delete_count) as leaf_delete_count
    ,(a.leaf_ghost_count - b.leaf_ghost_count) as leaf_ghost_count
    ,(a.nonleaf_insert_count - b.nonleaf_insert_count) as nonleaf_insert_count
    ,(a.nonleaf_update_count - b.nonleaf_update_count) as nonleaf_update_count
    ,(a.nonleaf_delete_count - b.nonleaf_delete_count) as nonleaf_delete_count
    ,(a.leaf_allocation_count - b.leaf_allocation_count) as leaf_allocation_count
    ,(a.nonleaf_allocation_count - b.nonleaf_allocation_count) as nonleaf_allocation_count
    ,(a.leaf_page_merge_count - b.leaf_page_merge_count) as leaf_page_merge_count
    ,(a.nonleaf_page_merge_count - b.nonleaf_page_merge_count) as nonleaf_page_merge_count
    ,(a.range_scan_count - b.range_scan_count) as range_scan_count
    ,(a.singleton_lookup_count - b.singleton_lookup_count) as singleton_lookup_count
    ,(a.forwarded_fetch_count - b.forwarded_fetch_count) as forwarded_fetch_count
    ,(a.lob_fetch_in_pages - b.lob_fetch_in_pages) as lob_fetch_in_pages
    ,(a.lob_fetch_in_bytes - b.lob_fetch_in_bytes) as lob_fetch_in_bytes
    ,(a.lob_orphan_create_count - b.lob_orphan_create_count) as lob_orphan_create_count
    ,(a.lob_orphan_insert_count - b.lob_orphan_insert_count) as lob_orphan_insert_count
    ,(a.row_lock_count - b.row_lock_count) as row_lock_count
    ,(a.row_lock_wait_count - b.row_lock_wait_count) as row_lock_wait_count
    ,(a.row_lock_wait_in_ms - b.row_lock_wait_in_ms) as row_lock_wait_in_ms
    ,(a.page_lock_count - b.page_lock_count) as page_lock_count
    ,(a.page_lock_wait_count - b.page_lock_wait_count) as page_lock_wait_count
    ,(a.page_lock_wait_in_ms - b.page_lock_wait_in_ms) as page_lock_wait_in_ms
    ,(a.index_lock_promotion_attempt_count - b.index_lock_promotion_attempt_count) as index_lock_promotion_attempt_count
    ,(a.index_lock_promotion_count - b.index_lock_promotion_count) as index_lock_promotion_count
    ,(a.page_latch_wait_count - b.page_latch_wait_count) as page_latch_wait_count
    ,(a.page_latch_wait_in_ms - b.page_latch_wait_in_ms) as page_latch_wait_in_ms
    ,(a.page_io_latch_wait_count - b.page_io_latch_wait_count) as page_io_latch_wait_count
    ,(a.tree_page_latch_wait_count - b.tree_page_latch_wait_count) as tree_page_latch_wait_count
    ,(a.tree_page_latch_wait_in_ms - b.tree_page_latch_wait_in_ms) as tree_page_latch_wait_in_ms
    ,(a.tree_page_io_latch_wait_count - b.tree_page_io_latch_wait_count) as tree_page_io_latch_wait_count
    ,(a.tree_page_io_latch_wait_in_ms - b.tree_page_io_latch_wait_in_ms) as tree_page_io_latch_wait_in_ms
    ,(a.row_overflow_fetch_in_pages - b.row_overflow_fetch_in_pages) as row_overflow_fetch_in_pages
    ,(a.row_overflow_fetch_in_bytes - b.row_overflow_fetch_in_bytes) as row_overflow_fetch_in_bytes
    ,(a.column_value_push_off_row_count - b.column_value_push_off_row_count) as column_value_push_off_row_count
    ,(a.column_value_pull_in_row_count - b.column_value_pull_in_row_count) as column_value_pull_in_row_count
    ,(a.page_compression_attempt_count - b.page_compression_attempt_count) as page_compression_attempt_count
    ,(a.page_compression_success_count - b.page_compression_success_count) as page_compression_success_count
from
(
    select *, row_number() over (partition by table_name, name order by collect_date) as rownum from dm_db_index_operational_stats_dump
) as a
join
(
    select *, row_number() over (partition by table_name, name order by collect_date) as rownum from dm_db_index_operational_stats_dump
) as b on a.table_name = b.table_name and a.name = b.name and a.rownum = b.rownum + 1
where a.collect_date between @start and @end
order by
     a.table_name
    ,a.name
    ,a.collect_date
