SELECT J.name AS 'Job Name'
	,cast(substring(cast(JobHist.run_duration + 1000000 AS CHAR(7)), 2, 2) AS VARCHAR(max)) + ':' + cast(substring(cast(JobHist.run_duration + 1000000 AS CHAR(7)), 4, 2) AS VARCHAR(max)) + ':' + cast(substring(cast(JobHist.run_duration + 1000000 AS CHAR(7)), 6, 2) AS VARCHAR(max)) AS 'Duration'
	,CASE 
		WHEN S.freq_type = 4
			THEN 1
		WHEN S.freq_type = 8
			THEN S.freq_interval - 2 * (S.freq_interval / 2)
		END AS 'Sun'
	,CASE 
		WHEN S.freq_type = 4
			THEN 1
		WHEN S.freq_type = 8
			THEN (S.freq_interval / 2) - 2 * (S.freq_interval / 4)
		END AS 'Mon'
	,CASE 
		WHEN S.freq_type = 4
			THEN 1
		WHEN S.freq_type = 8
			THEN (S.freq_interval / 4) - 2 * (S.freq_interval / 8)
		END AS 'Tue'
	,CASE 
		WHEN S.freq_type = 4
			THEN 1
		WHEN S.freq_type = 8
			THEN (S.freq_interval / 8) - 2 * (S.freq_interval / 16)
		END AS 'Wed'
	,CASE 
		WHEN S.freq_type = 4
			THEN 1
		WHEN S.freq_type = 8
			THEN (S.freq_interval / 16) - 2 * (S.freq_interval / 32)
		END AS 'Thu'
	,CASE 
		WHEN S.freq_type = 4
			THEN 1
		WHEN S.freq_type = 8
			THEN (S.freq_interval / 32) - 2 * (S.freq_interval / 64)
		END AS 'Fri'
	,CASE 
		WHEN S.freq_type = 4
			THEN 1
		WHEN S.freq_type = 8
			THEN (S.freq_interval / 64) - 2 * (S.freq_interval / 128)
		END AS 'Sat'
	,CASE 
		WHEN S.freq_subday_type = 1
			THEN 'Specific Time'
		WHEN S.freq_subday_type = 4
			THEN 'Every ' + cast(S.freq_subday_interval AS VARCHAR(max)) + ' Minute(s)'
		WHEN S.freq_subday_type = 8
			THEN 'Every ' + cast(S.freq_subday_interval AS VARCHAR(max)) + ' Hour(s)'
		END AS 'Frequency'
	,cast(substring(cast(S.active_start_time + 1000000 AS CHAR(7)), 2, 2) AS VARCHAR(max)) + ':' + cast(substring(cast(S.active_start_time + 1000000 AS CHAR(7)), 4, 2) AS VARCHAR(max)) + ':' + cast(substring(cast(S.active_start_time + 1000000 AS CHAR(7)), 6, 2) AS VARCHAR(max)) AS 'Start Time'
	,cast(substring(cast(S.active_end_time + 1000000 AS CHAR(7)), 2, 2) AS VARCHAR(max)) + ':' + cast(substring(cast(S.active_end_time + 1000000 AS CHAR(7)), 4, 2) AS VARCHAR(max)) + ':' + cast(substring(cast(S.active_end_time + 1000000 AS CHAR(7)), 6, 2) AS VARCHAR(max)) AS 'End Time'
	,suser_sname(J.owner_sid) AS 'Owner'
	,CASE 
		WHEN JobHist.run_status = 0
			THEN 'Failed'
		WHEN JobHist.run_status = 1
			THEN 'Succeeded'
		WHEN JobHist.run_status = 2
			THEN 'Retry'
		WHEN JobHist.run_status = 3
			THEN 'Canceled'
		WHEN JobHist.run_status = 4
			THEN 'In progress'
		ELSE 'Never'
		END AS 'Last Run Status'
	,JobHist.run_date AS 'Last Run Date'
	,cast(substring(cast(JobHist.run_time + 1000000 AS CHAR(7)), 2, 2) AS VARCHAR(max)) + ':' + cast(substring(cast(JobHist.run_time + 1000000 AS CHAR(7)), 4, 2) AS VARCHAR(max)) + ':' + cast(substring(cast(JobHist.run_time + 1000000 AS CHAR(7)), 6, 2) AS VARCHAR(max)) AS 'Last Run Time'
	,JobHist.message
	,JS.next_run_date
	,cast(substring(cast(JS.next_run_time + 1000000 AS CHAR(7)), 2, 2) AS VARCHAR(max)) + ':' + cast(substring(cast(JS.next_run_time + 1000000 AS CHAR(7)), 4, 2) AS VARCHAR(max)) + ':' + cast(substring(cast(JS.next_run_time + 1000000 AS CHAR(7)), 6, 2) AS VARCHAR(max)) AS 'Next Run Time'
	,S.name AS 'Schedule Name'
	,J.description
	,S.schedule_id AS 'Scheduler Id'
	,CASE 
		WHEN S.freq_type = 4
			THEN 'Daily'
		WHEN S.freq_type = 8
			THEN 'Weekly'
		WHEN S.freq_type = 16
			THEN 'Monthly'
		ELSE 'Others'
		END AS 'Frequency'
	,(
		SELECT email_address
		FROM msdb.dbo.sysoperators
		WHERE id = J.notify_email_operator_id
		) AS 'Notification To'
	,S.active_start_date
	,S.active_end_date
FROM msdb.dbo.sysjobschedules AS JS
INNER JOIN msdb.dbo.sysjobs AS J ON JS.job_id = J.job_id
INNER JOIN msdb.dbo.sysschedules AS S ON JS.schedule_id = S.schedule_id
LEFT OUTER JOIN (
	SELECT JH.job_id
		,JH.run_status
		,JH.run_date
		,JH.run_time
		,JH.run_duration
		,JH.message
	FROM msdb.dbo.sysjobhistory AS JH
	INNER JOIN (
		SELECT MAX(instance_id) AS instance_id
			,job_id
		FROM msdb.dbo.sysjobhistory
		GROUP BY job_id
		) AS LJHE ON JH.job_id = LJHE.job_id
		AND JH.instance_id = LJHE.instance_id
	) AS JobHist ON J.job_id = JobHist.job_id
WHERE (S.enabled = 1)
	AND (J.enabled = 1)
ORDER BY JobHist.run_date
	,JobHist.run_time