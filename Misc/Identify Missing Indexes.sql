SELECT *
FROM
	(SELECT (user_seeks + user_scans) * avg_total_user_cost * (avg_user_impact * 0.01) AS
		index_advantage, migs.*
		FROM sys.dm_db_missing_index_group_stats migs) AS migs_adv
	JOIN sys.dm_db_missing_index_groups AS mig
		ON migs_adv.group_handle = mig.index_group_handle
	JOIN sys.dm_db_missing_index_details AS mid
		ON mig.index_handle = mid.index_handle
ORDER BY migs_adv.index_advantage DESC