declare @total_num_of_reads bigint
declare @total_num_of_bytes_read bigint
declare @total_io_stall_read_ms bigint
declare @total_io_stall_queued_read_ms bigint
declare @total_num_of_writes bigint
declare @total_num_of_bytes_written bigint
declare @total_io_stall_write_ms bigint
declare @total_io_stall_queued_write_ms bigint
declare @total_io_stall bigint
declare @total_size_on_disk_bytes bigint

declare @snapshot_time_earlier datetime
declare @snapshot_time_later datetime
set @snapshot_time_earlier = '2020-06-21 23:57:10.313' --collect_dateに存在する日時を設定（古い方）
set @snapshot_time_later = '2020-06-22 00:01:10.027' --collect_dateに存在する日時を設定（新しい方）


select
     @total_num_of_reads = sum(num_of_reads)
    ,@total_num_of_bytes_read = sum(num_of_bytes_read)
    ,@total_io_stall_read_ms = sum(io_stall_read_ms)
    ,@total_io_stall_queued_read_ms = sum(io_stall_queued_read_ms)
    ,@total_num_of_writes = sum(num_of_writes)
    ,@total_num_of_bytes_written = sum(num_of_bytes_written)
    ,@total_io_stall_write_ms = sum(io_stall_write_ms)
    ,@total_io_stall_queued_write_ms = sum(io_stall_queued_write_ms)
    ,@total_io_stall = sum(io_stall)
    ,@total_size_on_disk_bytes = sum(size_on_disk_bytes)
from
(
    select
         (a.num_of_reads - b.num_of_reads) as num_of_reads
        ,(a.num_of_bytes_read - b.num_of_bytes_read) as num_of_bytes_read
        ,(a.io_stall_read_ms - b.io_stall_read_ms) as io_stall_read_ms
        ,(a.io_stall_queued_read_ms - b.io_stall_queued_read_ms) as io_stall_queued_read_ms
        ,(a.num_of_writes - b.num_of_writes) as num_of_writes
        ,(a.num_of_bytes_written - b.num_of_bytes_written) as num_of_bytes_written
        ,(a.io_stall_write_ms - b.io_stall_write_ms) as io_stall_write_ms
        ,(a.io_stall_queued_write_ms - b.io_stall_queued_write_ms) as io_stall_queued_write_ms
        ,(a.io_stall - b.io_stall) as io_stall
        ,(a.size_on_disk_bytes - b.size_on_disk_bytes) as size_on_disk_bytes
    from
    (
        select * from
            dm_io_virtual_file_stats_dump
        where collect_date = @snapshot_time_later
    ) as a
    join
    (
        select * from
            dm_io_virtual_file_stats_dump
        where collect_date = @snapshot_time_earlier
    ) as b
    on a.database_id = b.database_id and a.file_id = b.file_id and a.physical_name = b.physical_name
) as c

select
    *
    ,(100.0 * num_of_reads / (1+@total_num_of_reads)) as percent_num_of_reads
    ,(100.0 * num_of_bytes_read / (1+@total_num_of_bytes_read)) as percent_num_of_bytes_read
    ,(100.0 * io_stall_read_ms / (1+@total_io_stall_read_ms)) as percent_io_stall_read_ms
    ,(100.0 * io_stall_queued_read_ms / (1+@total_io_stall_queued_read_ms)) as percent_io_stall_queued_read_ms
    ,(100.0 * num_of_writes / (1+@total_num_of_writes)) as percent_num_of_writes
    ,(100.0 * num_of_bytes_written / (1+@total_num_of_bytes_written)) as percent_num_of_bytes_written
    ,(100.0 * io_stall_write_ms / (1+@total_io_stall_write_ms)) as percent_io_stall_write_ms
    ,(100.0 * io_stall_queued_write_ms / (1+@total_io_stall_queued_write_ms)) as percent_io_stall_queued_write_ms
    ,(100.0 * io_stall / (1+@total_io_stall)) as percent_io_stall
    ,(100.0 * size_on_disk_bytes / (1+@total_size_on_disk_bytes)) as percent_size_on_disk_bytes
from
(
    select
         a.collect_date
        ,a.type_desc
        ,a.data_space_id
        ,a.name
        ,a.physical_name
        ,a.size_on_disk_bytes as current_size_on_disk_bytes
        ,(a.num_of_reads - b.num_of_reads) as num_of_reads
        ,(a.num_of_bytes_read - b.num_of_bytes_read) as num_of_bytes_read
        ,(a.io_stall_read_ms - b.io_stall_read_ms) as io_stall_read_ms
        ,(a.io_stall_queued_read_ms - b.io_stall_queued_read_ms) as io_stall_queued_read_ms
        ,(a.num_of_writes - b.num_of_writes) as num_of_writes
        ,(a.num_of_bytes_written - b.num_of_bytes_written) as num_of_bytes_written
        ,(a.io_stall_write_ms - b.io_stall_write_ms) as io_stall_write_ms
        ,(a.io_stall_queued_write_ms - b.io_stall_queued_write_ms) as io_stall_queued_write_ms
        ,(a.io_stall - b.io_stall) as io_stall
        ,(a.size_on_disk_bytes - b.size_on_disk_bytes) as size_on_disk_bytes
    from
    (
        select * from
            dm_io_virtual_file_stats_dump
        where collect_date = @snapshot_time_later
    ) as a
    join
    (
        select * from
            dm_io_virtual_file_stats_dump
        where collect_date = @snapshot_time_earlier
    ) as b
    on a.database_id = b.database_id and a.file_id = b.file_id and a.physical_name = b.physical_name
) as c
order by num_of_bytes_read desc
