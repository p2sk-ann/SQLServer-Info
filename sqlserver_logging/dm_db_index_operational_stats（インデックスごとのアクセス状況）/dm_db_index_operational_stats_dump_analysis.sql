declare @total_leaf_insert_count bigint
declare @total_leaf_update_count bigint
declare @total_leaf_delete_count bigint
declare @total_leaf_ghost_count bigint
declare @total_nonleaf_insert_count bigint
declare @total_nonleaf_update_count bigint
declare @total_nonleaf_delete_count bigint
declare @total_leaf_allocation_count bigint
declare @total_nonleaf_allocation_count bigint
declare @total_leaf_page_merge_count bigint
declare @total_nonleaf_page_merge_count bigint
declare @total_range_scan_count bigint
declare @total_singleton_lookup_count bigint
declare @total_forwarded_fetch_count bigint
declare @total_lob_fetch_in_pages bigint
declare @total_lob_fetch_in_bytes bigint
declare @total_lob_orphan_create_count bigint
declare @total_lob_orphan_insert_count bigint
declare @total_row_lock_count bigint
declare @total_row_lock_wait_count bigint
declare @total_row_lock_wait_in_ms bigint
declare @total_page_lock_count bigint
declare @total_page_lock_wait_count bigint
declare @total_page_lock_wait_in_ms bigint
declare @total_index_lock_promotion_attempt_count bigint
declare @total_index_lock_promotion_count bigint
declare @total_page_latch_wait_count bigint
declare @total_page_latch_wait_in_ms bigint
declare @total_page_io_latch_wait_count bigint
declare @total_page_io_latch_wait_in_ms bigint
declare @total_tree_page_latch_wait_count bigint
declare @total_tree_page_latch_wait_in_ms bigint
declare @total_tree_page_io_latch_wait_count bigint
declare @total_tree_page_io_latch_wait_in_ms bigint
declare @total_row_overflow_fetch_in_pages bigint
declare @total_row_overflow_fetch_in_bytes bigint
declare @total_column_value_push_off_row_count bigint
declare @total_column_value_pull_in_row_count bigint
declare @total_page_compression_attempt_count bigint
declare @total_page_compression_success_count bigint

declare @snapshot_time_earlier datetime
declare @snapshot_time_later datetime
set @snapshot_time_earlier = '2020-06-07 23:55:11.917' --collect_dateに存在する日時を設定（古い方）
set @snapshot_time_later = '2020-06-08 00:00:11.487' --collect_dateに存在する日時を設定（新しい方）

select
     @total_leaf_insert_count = sum(leaf_insert_count)
    ,@total_leaf_update_count = sum(leaf_update_count)
    ,@total_leaf_delete_count = sum(leaf_delete_count)
    ,@total_leaf_ghost_count = sum(leaf_ghost_count)
    ,@total_nonleaf_insert_count = sum(nonleaf_insert_count)
    ,@total_nonleaf_update_count = sum(nonleaf_update_count)
    ,@total_nonleaf_delete_count = sum(nonleaf_delete_count)
    ,@total_leaf_allocation_count = sum(leaf_allocation_count)
    ,@total_nonleaf_allocation_count = sum(nonleaf_allocation_count)
    ,@total_leaf_page_merge_count = sum(leaf_page_merge_count)
    ,@total_nonleaf_page_merge_count = sum(nonleaf_page_merge_count)
    ,@total_range_scan_count = sum(range_scan_count)
    ,@total_singleton_lookup_count = sum(singleton_lookup_count)
    ,@total_forwarded_fetch_count = sum(forwarded_fetch_count)
    ,@total_lob_fetch_in_pages = sum(lob_fetch_in_pages)
    ,@total_lob_fetch_in_bytes = sum(lob_fetch_in_bytes)
    ,@total_lob_orphan_create_count = sum(lob_orphan_create_count)
    ,@total_lob_orphan_insert_count = sum(lob_orphan_insert_count)
    ,@total_row_lock_count = sum(row_lock_count)
    ,@total_row_lock_wait_count = sum(row_lock_wait_count)
    ,@total_row_lock_wait_in_ms = sum(row_lock_wait_in_ms)
    ,@total_page_lock_count = sum(page_lock_count)
    ,@total_page_lock_wait_count = sum(page_lock_wait_count)
    ,@total_page_lock_wait_in_ms = sum(page_lock_wait_in_ms)
    ,@total_index_lock_promotion_attempt_count = sum(index_lock_promotion_attempt_count)
    ,@total_index_lock_promotion_count = sum(index_lock_promotion_count)
    ,@total_page_latch_wait_count = sum(page_latch_wait_count)
    ,@total_page_latch_wait_in_ms = sum(page_latch_wait_in_ms)
    ,@total_page_io_latch_wait_count = sum(page_io_latch_wait_count)
    ,@total_page_io_latch_wait_in_ms = sum(page_io_latch_wait_in_ms)
    ,@total_tree_page_latch_wait_count = sum(tree_page_latch_wait_count)
    ,@total_tree_page_latch_wait_in_ms = sum(tree_page_latch_wait_in_ms)
    ,@total_tree_page_io_latch_wait_count = sum(tree_page_io_latch_wait_count)
    ,@total_tree_page_io_latch_wait_in_ms = sum(tree_page_io_latch_wait_in_ms)
    ,@total_row_overflow_fetch_in_pages = sum(row_overflow_fetch_in_pages)
    ,@total_row_overflow_fetch_in_bytes = sum(row_overflow_fetch_in_bytes)
    ,@total_column_value_push_off_row_count = sum(column_value_push_off_row_count)
    ,@total_column_value_pull_in_row_count = sum(column_value_pull_in_row_count)
    ,@total_page_compression_attempt_count = sum(page_compression_attempt_count)
    ,@total_page_compression_success_count = sum(page_compression_success_count)
from
(
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
        ,(a.page_io_latch_wait_in_ms - b.page_io_latch_wait_in_ms) as page_io_latch_wait_in_ms
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
        select * from
            dm_db_index_operational_stats_dump
        where collect_date = @snapshot_time_later
    ) as a
    join
    (
        select * from
            dm_db_index_operational_stats_dump
        where collect_date = @snapshot_time_earlier
    ) as b
    on a.table_name = b.table_name and a.name = b.name
) as c

select
    *
    ,(100.0 * leaf_insert_count / (1+@total_leaf_insert_count)) as percent_leaf_insert_count
    ,(100.0 * leaf_update_count / (1+@total_leaf_update_count)) as percent_leaf_update_count
    ,(100.0 * leaf_delete_count / (1+@total_leaf_delete_count)) as percent_leaf_delete_count
    ,(100.0 * leaf_ghost_count / (1+@total_leaf_ghost_count)) as percent_leaf_ghost_count
    ,(100.0 * nonleaf_insert_count / (1+@total_nonleaf_insert_count)) as percent_nonleaf_insert_count
    ,(100.0 * nonleaf_update_count / (1+@total_nonleaf_update_count)) as percent_nonleaf_update_count
    ,(100.0 * nonleaf_delete_count / (1+@total_nonleaf_delete_count)) as percent_nonleaf_delete_count
    ,(100.0 * leaf_allocation_count / (1+@total_leaf_allocation_count)) as percent_leaf_allocation_count
    ,(100.0 * nonleaf_allocation_count / (1+@total_nonleaf_allocation_count)) as percent_nonleaf_allocation_count
    ,(100.0 * leaf_page_merge_count / (1+@total_leaf_page_merge_count)) as percent_leaf_page_merge_count
    ,(100.0 * nonleaf_page_merge_count / (1+@total_nonleaf_page_merge_count)) as percent_nonleaf_page_merge_count
    ,(100.0 * range_scan_count / (1+@total_range_scan_count)) as percent_range_scan_count
    ,(100.0 * singleton_lookup_count / (1+@total_singleton_lookup_count)) as percent_singleton_lookup_count
    ,(100.0 * forwarded_fetch_count / (1+@total_forwarded_fetch_count)) as percent_forwarded_fetch_count
    ,(100.0 * lob_fetch_in_pages / (1+@total_lob_fetch_in_pages)) as percent_lob_fetch_in_pages
    ,(100.0 * lob_fetch_in_bytes / (1+@total_lob_fetch_in_bytes)) as percent_lob_fetch_in_bytes
    ,(100.0 * lob_orphan_create_count / (1+@total_lob_orphan_create_count)) as percent_lob_orphan_create_count
    ,(100.0 * lob_orphan_insert_count / (1+@total_lob_orphan_insert_count)) as percent_lob_orphan_insert_count
    ,(100.0 * row_lock_count / (1+@total_row_lock_count)) as percent_row_lock_count
    ,(100.0 * row_lock_wait_count / (1+@total_row_lock_wait_count)) as percent_row_lock_wait_count
    ,(100.0 * row_lock_wait_in_ms / (1+@total_row_lock_wait_in_ms)) as percent_row_lock_wait_in_ms
    ,(100.0 * page_lock_count / (1+@total_page_lock_count)) as percent_page_lock_count
    ,(100.0 * page_lock_wait_count / (1+@total_page_lock_wait_count)) as percent_page_lock_wait_count
    ,(100.0 * page_lock_wait_in_ms / (1+@total_page_lock_wait_in_ms)) as percent_page_lock_wait_in_ms
    ,(100.0 * index_lock_promotion_attempt_count / (1+@total_index_lock_promotion_attempt_count)) as percent_index_lock_promotion_attempt_count
    ,(100.0 * index_lock_promotion_count / (1+@total_index_lock_promotion_count)) as percent_index_lock_promotion_count
    ,(100.0 * page_latch_wait_count / (1+@total_page_latch_wait_count)) as percent_page_latch_wait_count
    ,(100.0 * page_latch_wait_in_ms / (1+@total_page_latch_wait_in_ms)) as percent_page_latch_wait_in_ms
    ,(100.0 * page_io_latch_wait_count / (1+@total_page_io_latch_wait_count)) as percent_page_io_latch_wait_count
    ,(100.0 * page_io_latch_wait_in_ms / (1+@total_page_io_latch_wait_in_ms)) as percent_page_io_latch_wait_in_ms
    ,(100.0 * tree_page_latch_wait_count / (1+@total_tree_page_latch_wait_count)) as percent_tree_page_latch_wait_count
    ,(100.0 * tree_page_latch_wait_in_ms / (1+@total_tree_page_latch_wait_in_ms)) as percent_tree_page_latch_wait_in_ms
    ,(100.0 * tree_page_io_latch_wait_count / (1+@total_tree_page_io_latch_wait_count)) as percent_tree_page_io_latch_wait_count
    ,(100.0 * tree_page_io_latch_wait_in_ms / (1+@total_tree_page_io_latch_wait_in_ms)) as percent_tree_page_io_latch_wait_in_ms
    ,(100.0 * row_overflow_fetch_in_pages / (1+@total_row_overflow_fetch_in_pages)) as percent_row_overflow_fetch_in_pages
    ,(100.0 * row_overflow_fetch_in_bytes / (1+@total_row_overflow_fetch_in_bytes)) as percent_row_overflow_fetch_in_bytes
    ,(100.0 * column_value_push_off_row_count / (1+@total_column_value_push_off_row_count)) as percent_column_value_push_off_row_count
    ,(100.0 * column_value_pull_in_row_count / (1+@total_column_value_pull_in_row_count)) as percent_column_value_pull_in_row_count
    ,(100.0 * page_compression_attempt_count / (1+@total_page_compression_attempt_count)) as percent_page_compression_attempt_count
    ,(100.0 * page_compression_success_count / (1+@total_page_compression_success_count)) as percent_page_compression_success_count
from
(
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
        ,(a.page_io_latch_wait_in_ms - b.page_io_latch_wait_in_ms) as page_io_latch_wait_in_ms
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
        select * from
            dm_db_index_operational_stats_dump
        where collect_date = @snapshot_time_later
    ) as a
    join
    (
        select * from
            dm_db_index_operational_stats_dump
        where collect_date = @snapshot_time_earlier
    ) as b
    on a.table_name = b.table_name and a.name = b.name
--    where (a.leaf_insert_count - b.leaf_insert_count) > 1 --insert頻度が少ないクエリを除外
) as c
order by leaf_insert_count desc
