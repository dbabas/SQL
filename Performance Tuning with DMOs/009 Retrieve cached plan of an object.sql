--Example on how to get the cached plan of an object (stored procedure).
--You can save the query_plan with a .sqlplan extension to open it with SSMS 

CREATE PROCEDURE ShowQueryText --if you run this example don't forget to remove the created stored procedure once you have completed it.
AS
    SELECT TOP 10
            object_id ,
            name
    FROM    sys.objects ;
   SELECT TOP 10
            object_id ,
            name
    FROM    sys.objects ;
    SELECT TOP 10
            object_id ,
            name
    FROM    sys.procedures ;
GO
EXEC dbo.ShowQueryText ;
GO
SELECT  deqp.dbid ,
        deqp.objectid ,
        deqp.encrypted ,
        deqp.query_plan
FROM    sys.dm_exec_query_stats deqs
        CROSS APPLY sys.dm_exec_query_plan(deqs.plan_handle) AS deqp
WHERE   objectid = OBJECT_ID('ShowQueryText', 'p') ;
GO

--DROP PROCEDURE ShowQueryText;
--GO

---------------------------------------------
SELECT  deqs.plan_handle ,
        deqs.sql_handle ,
        execText.text
FROM    sys.dm_exec_query_stats deqs
        CROSS APPLY sys.dm_exec_sql_text(deqs.plan_handle) AS execText
WHERE   execText.text LIKE '%CREATE PROCEDURE ShowQueryText%'


---------------------------------------------
--One line for each statement in the batch but same plan for all of them
SELECT  CHAR(13) + CHAR(10)
        + CASE WHEN deqs.statement_start_offset = 0
                    AND deqs.statement_end_offset = -1
               THEN '-- see objectText column--'
               ELSE '-- query --' + CHAR(13) + CHAR(10)
                    + SUBSTRING(execText.text, deqs.statement_start_offset / 2,
                                ( ( CASE WHEN deqs.statement_end_offset = -1
                                         THEN DATALENGTH(execText.text)
                                         ELSE deqs.statement_end_offset
                                    END ) - deqs.statement_start_offset ) / 2)
          END AS queryText ,
        deqp.query_plan
FROM    sys.dm_exec_query_stats deqs
        CROSS APPLY sys.dm_exec_sql_text(deqs.plan_handle) AS execText
        CROSS APPLY sys.dm_exec_query_plan(deqs.plan_handle) deqp
WHERE   deqp.objectid = OBJECT_ID('ShowQueryText', 'p') ;
GO

------------------------------------------------
--Returns the specific plan for each statement in the batch
SELECT  deqp.dbid ,
        deqp.objectid ,
        CAST(detqp.query_plan AS XML) AS singleStatementPlan ,
        deqp.query_plan AS batch_query_plan ,
        --this won't actually work in all cases because nominal plans aren't
        -- cached, so you won't see a plan for waitfor if you uncomment it
        ROW_NUMBER() OVER ( ORDER BY Statement_Start_offset )
		AS query_position ,
        CASE WHEN deqs.statement_start_offset = 0
                  AND deqs.statement_end_offset = -1
             THEN '-- see objectText column--'
             ELSE '-- query --' + CHAR(13) + CHAR(10)
                  + SUBSTRING(execText.text, deqs.statement_start_offset / 2, ( ( CASE WHEN deqs.statement_end_offset = -1
                                       THEN DATALENGTH(execText.text)
                                       ELSE deqs.statement_end_offset
                                  END ) - deqs.statement_start_offset ) / 2)
        END AS queryText
FROM    sys.dm_exec_query_stats deqs
        CROSS APPLY sys.dm_exec_text_query_plan(deqs.plan_handle,
                                                deqs.statement_start_offset,
                                                deqs.statement_end_offset)
                                                                     AS detqp
        CROSS APPLY sys.dm_exec_query_plan(deqs.plan_handle) AS deqp
        CROSS APPLY sys.dm_exec_sql_text(deqs.plan_handle) AS execText
WHERE   deqp.objectid = OBJECT_ID('ShowQueryText', 'p') ;
GO