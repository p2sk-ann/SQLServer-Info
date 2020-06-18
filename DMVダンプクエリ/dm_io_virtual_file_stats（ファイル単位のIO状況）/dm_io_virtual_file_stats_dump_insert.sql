insert into dm_io_virtual_file_stats_dump
select
	 getdate() as collect_date
	,a.database_id
	,a.file_id
	,file_guid
	,type
	,type_desc
	,data_space_id
	,name
	,physical_name
	,state
	,state_desc
	,size
	,max_size
	,growth
	,is_media_read_only
	,is_read_only
	,is_sparse
	,is_percent_growth
	,is_name_reserved
	,create_lsn
	,drop_lsn
	,read_only_lsn
	,read_write_lsn
	,differential_base_lsn
	,differential_base_guid
	,differential_base_time
	,redo_start_lsn
	,redo_start_fork_guid
	,redo_target_lsn
	,redo_target_fork_guid
	,backup_lsn
	,credential_id
	,sample_ms
	,num_of_reads
	,num_of_bytes_read
	,io_stall_read_ms
	,io_stall_queued_read_ms
	,num_of_writes
	,num_of_bytes_written
	,io_stall_write_ms
	,io_stall_queued_write_ms
	,io_stall
	,size_on_disk_bytes
	,file_handle
from sys.master_files a
join sys.dm_io_virtual_file_stats(null, null) b
on a.database_id = b.database_id and a.file_id = b.file_id
option (maxdop 1)
