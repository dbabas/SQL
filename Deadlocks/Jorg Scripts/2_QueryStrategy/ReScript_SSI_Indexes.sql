
USE [Demo Database NAV (7-1)] -- change db name on demand
GO

SELECT object_name(sysidx.[object_id]) as [object_name], 
       sysidx.[name] as [index_name], 
       idxcol.key_columns, 
       idxcol.included_columns,
							sysidx.filter_definition,

'IF NOT EXISTS (SELECT TOP 1 NULL FROM sys.indexes (NOLOCK) WHERE object_name([object_id]) = ''' + object_name(sysidx.[object_id]) + '''  AND [name] = ''' + sysidx.[name] + ''') 
  CREATE INDEX [' + sysidx.[name] + '] ON [' + object_name(sysidx.[object_id]) + '] 
		(' + idxcol.key_columns + ')' +
  CASE WHEN idxcol.included_columns is not null THEN '
	 INCLUDE 
	 (' + idxcol.included_columns + ')' ELSE '' END + 
	 CASE WHEN sysidx.filter_definition is not null THEN '
		WHERE
		' + sysidx.filter_definition + '' ELSE '' END + '
	 WITH (MAXDOP = 64, ONLINE = OFF, DROP_EXISTING = OFF)
	 GO
		' 
	as [tsql_CREATE],

	'IF EXISTS (SELECT TOP 1 NULL FROM sys.indexes (NOLOCK) WHERE object_name([object_id]) = ''' + object_name(sysidx.[object_id]) + '''  AND [name] = ''' + sysidx.[name] + ''') 
  DROP INDEX [' + sysidx.[name] + '] ON [' + object_name(sysidx.[object_id]) + '] 
	 GO
		' 
	as [tsql_DROP]

  FROM
       sys.indexes sysidx
JOIN (
    SELECT Tab.[name] AS TableName, 
		  Ind.[name] AS IndexName, 
		  SUBSTRING ((
    SELECT ', [' + AC.name + ']'
    FROM
		  sys.[tables] AS T INNER JOIN sys.[indexes] I
		  ON T.[object_id] = I.[object_id]
					   INNER JOIN sys.[index_columns] IC
		  ON I.[object_id] = IC.[object_id] AND I.[index_id] = IC.[index_id]
					   INNER JOIN sys.[all_columns] AC
		  ON T.[object_id] = AC.[object_id] AND IC.[column_id] = AC.[column_id]
    WHERE Ind.[object_id] = I.[object_id] AND Ind.index_id = I.index_id AND IC.is_included_column = 0
    ORDER BY IC.key_ordinal
    FOR XML PATH ('')) , 3, 8000) AS key_columns,
     
		  SUBSTRING ((
    SELECT ', [' + AC.name + ']'
    FROM
		  sys.[tables] AS T INNER JOIN sys.[indexes] I
		  ON T.[object_id] = I.[object_id]
					   INNER JOIN sys.[index_columns] IC
		  ON I.[object_id] = IC.[object_id] AND I.[index_id] = IC.[index_id]
					   INNER JOIN sys.[all_columns] AC
		  ON T.[object_id] = AC.[object_id] AND IC.[column_id] = AC.[column_id]
    WHERE Ind.[object_id] = I.[object_id] AND Ind.index_id = I.index_id AND IC.is_included_column = 1
    ORDER BY IC.key_ordinal
    FOR XML PATH ('')) , 3, 8000) AS included_columns
    FROM
		  sys.[indexes] Ind INNER JOIN sys.[tables] AS Tab
		  ON Tab.[object_id] = Ind.[object_id]
					   INNER JOIN sys.[schemas] AS Sch
		  ON Sch.[schema_id] = Tab.[schema_id]

    UNION 

        SELECT Tab.[name] AS TableName, 
		  Ind.[name] AS IndexName, 
		  SUBSTRING ((
    SELECT ', [' + AC.name + ']'
    FROM
		  sys.[views] AS T INNER JOIN sys.[indexes] I
		  ON T.[object_id] = I.[object_id]
					   INNER JOIN sys.[index_columns] IC
		  ON I.[object_id] = IC.[object_id] AND I.[index_id] = IC.[index_id]
					   INNER JOIN sys.[all_columns] AC
		  ON T.[object_id] = AC.[object_id] AND IC.[column_id] = AC.[column_id]
    WHERE Ind.[object_id] = I.[object_id] AND Ind.index_id = I.index_id AND IC.is_included_column = 0
    ORDER BY IC.key_ordinal
    FOR XML PATH ('')) , 3, 8000) AS key_columns,
     
		  SUBSTRING ((
    SELECT ', [' + AC.name + ']'
    FROM
		  sys.[views] AS T INNER JOIN sys.[indexes] I
		  ON T.[object_id] = I.[object_id]
					   INNER JOIN sys.[index_columns] IC
		  ON I.[object_id] = IC.[object_id] AND I.[index_id] = IC.[index_id]
					   INNER JOIN sys.[all_columns] AC
		  ON T.[object_id] = AC.[object_id] AND IC.[column_id] = AC.[column_id]
    WHERE Ind.[object_id] = I.[object_id] AND Ind.index_id = I.index_id AND IC.is_included_column = 1
    ORDER BY IC.key_ordinal
    FOR XML PATH ('')) , 3, 8000) AS included_columns
    FROM
		  sys.[indexes] Ind INNER JOIN sys.[views] AS Tab
		  ON Tab.[object_id] = Ind.[object_id]
					   INNER JOIN sys.[schemas] AS Sch
		  ON Sch.[schema_id] = Tab.[schema_id]


) idxcol ON object_name(sysidx.[object_id]) = idxcol.TableName AND sysidx.[name] = idxcol.IndexName
	    
WHERE object_name(sysidx.[object_id]) not like 'ssi%'
  AND sysidx.[name] like 'ssi%'

ORDER BY 1,3,4