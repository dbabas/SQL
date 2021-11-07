EXECUTE dbo.IndexOptimize
@Databases= 'NAV_LIVE',
@FragmentationMedium = 'INDEX_REORGANIZE',
@FragmentationHigh = 'INDEX_REBUILD_ONLINE',
@FragmentationLevel1  = 5,
@FragmentationLevel2  = 30,
@PageCountLevel  = 1000,
@MaxDOP  = 2,
@FillFactor  = 90,
@UpdateStatistics = 'Y',
@LogToTable  = 'N',
@Execute = 'Y'


--Rebuild or reorganize all indexes with fragmentation on the table Production.Product in the database AdventureWorks
EXECUTE dbo.IndexOptimize
@Databases = 'AdventureWorks',
@FragmentationLow = NULL,
@FragmentationMedium = 'INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
@FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
@FragmentationLevel1 = 5,
@FragmentationLevel2 = 30,
@Indexes = 'AdventureWorks.Production.Product'

--Rebuild or reorganize all indexes with fragmentation except indexes on the table Production.Product in the database AdventureWorks
EXECUTE dbo.IndexOptimize
@Databases = 'USER_DATABASES',
@FragmentationLow = NULL,
@FragmentationMedium = 'INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
@FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
@FragmentationLevel1 = 5,
@FragmentationLevel2 = 30,
@Indexes = 'ALL_INDEXES, -AdventureWorks.Production.Product'