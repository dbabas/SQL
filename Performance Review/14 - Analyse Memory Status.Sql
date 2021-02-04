SET NOCOUNT ON

DECLARE @MemoryValue TABLE (
	ID INT IDENTITY
	,Property VARCHAR(max)
	,Value VARCHAR(max)
	,Comments VARCHAR(max)
	);

IF (@@microsoftversion / 0x1000000) & 0xFF > 9
BEGIN
	INSERT INTO @MemoryValue (
		Property
		,Value
		,Comments
		)
	SELECT 'Total Physical Memory (MB)'
		,total_physical_memory_kb / 1024
		,''
	FROM sys.dm_os_sys_memory

	INSERT INTO @MemoryValue (
		Property
		,Value
		,Comments
		)
	SELECT 'Available Physical Memory (MB)'
		,available_physical_memory_kb / 1024
		,''
	FROM sys.dm_os_sys_memory

	INSERT INTO @MemoryValue (
		Property
		,Value
		,Comments
		)
	SELECT 'Locked Pages in Memory (MB)'
		,locked_page_allocations_kb / 1024
		,''
	FROM sys.dm_os_process_memory

	INSERT INTO @MemoryValue (
		Property
		,Value
		,Comments
		)
	SELECT 'System Cache (MB)'
		,system_cache_kb / 1024
		,''
	FROM sys.dm_os_sys_memory

	INSERT INTO @MemoryValue (
		Property
		,Value
		,Comments
		)
	SELECT 'Kernel pool (MB)'
		,(kernel_paged_pool_kb + kernel_nonpaged_pool_kb) / 1024
		,''
	FROM sys.dm_os_sys_memory

	INSERT INTO @MemoryValue (
		Property
		,Value
		,Comments
		)
	SELECT 'Total Page File (MB)'
		,total_page_file_kb / 1024
		,''
	FROM sys.dm_os_sys_memory

	INSERT INTO @MemoryValue (
		Property
		,Value
		,Comments
		)
	SELECT 'Available Page File (MB)'
		,available_page_file_kb / 1024
		,''
	FROM sys.dm_os_sys_memory

	INSERT INTO @MemoryValue (
		Property
		,Value
		,Comments
		)
	SELECT 'System Memory State'
		,system_memory_state_desc
		,''
	FROM sys.dm_os_sys_memory

	SELECT Property
		,Value
		,Comments
	FROM @MemoryValue
END

------------------- Analyse Memory by Memory Clerk ---------------------------
SELECT name AS 'Name'
	,TYPE AS 'Type'
	,SUM(pages_kb) / 1024 'Internal MemUse (MB)'
	,Sum(virtual_memory_reserved_kb) / 1024 AS 'Virtual Memory Reserved (MB)'
FROM sys.dm_os_memory_clerks
GROUP BY TYPE
	,name
HAVING (SUM(pages_kb) / 1024 > 0)
	OR (Sum(virtual_memory_reserved_kb) / 1024 > 0)
ORDER BY SUM(pages_kb) DESC
	------------------------------------------------------------------------------