set lock_timeout 1000

--dmvの中で値のリセットが可能なものたちについて、値をクリア
DBCC SQLPERF('sys.dm_os_latch_stats', CLEAR)
DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR)
DBCC SQLPERF('sys.dm_os_spinlock_stats', CLEAR)
