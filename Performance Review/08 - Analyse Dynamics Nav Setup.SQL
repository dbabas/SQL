SET NOCOUNT ON

DECLARE @temp SQL_VARIANT
DECLARE @temp1 NVARCHAR(300)
DECLARE @DatabaseSetting TABLE (
	ID INT IDENTITY
	,Property VARCHAR(max)
	,Value SQL_VARIANT
	,Comment VARCHAR(max)
	);

INSERT INTO @DatabaseSetting
VALUES (
	'Database Name'
	,DB_NAME()
	,''
	)

DECLARE @SQL NVARCHAR(max)
DECLARE @ParmDefinition NVARCHAR(max)

-------- Get Navision Version --------
IF EXISTS (
		SELECT *
		FROM sys.columns
		WHERE [object_id] = object_id('$ndo$dbproperty')
			AND [name] = 'databaseversionno'
		)
BEGIN
	SET @SQL = 'Select @temp1_OUT = [databaseversionno] from [$ndo$dbproperty]'
	SET @ParmDefinition = '@temp1_OUT nvarchar(30) OUTPUT';

	EXECUTE sp_executesql @SQL
		,@ParmDefinition
		,@temp1_OUT = @temp1 OUTPUT

	SET @temp = (
			SELECT CASE 
					WHEN @temp1 BETWEEN 1
							AND 4
						THEN 'V2.50'
					WHEN @temp1 BETWEEN 5
							AND 6
						THEN 'V2.60'
					WHEN @temp1 BETWEEN 7
							AND 11
						THEN 'V3.00'
					WHEN @temp1 BETWEEN 12
							AND 13
						THEN 'V3.10'
					WHEN @temp1 BETWEEN 14
							AND 14
						THEN 'V3.60'
					WHEN @temp1 BETWEEN 15
							AND 18
						THEN 'V3.70'
					WHEN @temp1 BETWEEN 20
							AND 50
						THEN 'V4.00'
					WHEN @temp1 BETWEEN 60
							AND 63
						THEN 'V4 SP3'
					WHEN @temp1 BETWEEN 80
							AND 82
						THEN 'V5'
					WHEN @temp1 BETWEEN 93
							AND 105
						THEN 'V5 SP1'
					WHEN @temp1 BETWEEN 120
							AND 140
						THEN 'NAV2009'
					WHEN @temp1 BETWEEN 150
							AND 150
						THEN 'NAV2009 SP1'
					WHEN @temp1 BETWEEN 60200
							AND 60200
						THEN 'NAV2009 R2'
					ELSE 'Unknown Version ' + @temp1
					END AS NAVVersion
			)

	INSERT INTO @DatabaseSetting
	VALUES (
		'Executable Version'
		,@temp
		,''
		)

	INSERT INTO @DatabaseSetting
	VALUES (
		'Build'
		,'<Get the build number by running Dynamics Nav Client>'
		,''
		)
END

------ End of Navision Version -------
IF EXISTS (
		SELECT *
		FROM sys.columns
		WHERE [object_id] = object_id('$ndo$dbproperty')
			AND [name] = 'securityoption'
		)
BEGIN
	SET @SQL = 'Select @temp1_OUT = [securityoption] from [$ndo$dbproperty]'
	SET @ParmDefinition = '@temp1_OUT nvarchar(30) OUTPUT';

	EXECUTE sp_executesql @SQL
		,@ParmDefinition
		,@temp1_OUT = @temp1 OUTPUT

	INSERT INTO @DatabaseSetting
	VALUES (
		'Security Model'
		,CASE 
			WHEN @temp1 = 0
				THEN 'Standard'
			ELSE 'Enhanced'
			END
		,CASE 
			WHEN @temp1 <> 0
				THEN 'Security Model should be set to standard for better performance'
			ELSE ''
			END
		)
END

IF EXISTS (
		SELECT *
		FROM sys.columns
		WHERE [object_id] = object_id('$ndo$dbproperty')
			AND [name] = 'diagnostics'
		)
BEGIN
	SET @SQL = 'Select @temp1_OUT = [diagnostics] from [$ndo$dbproperty]'
	SET @ParmDefinition = '@temp1_OUT nvarchar(30) OUTPUT';

	EXECUTE sp_executesql @SQL
		,@ParmDefinition
		,@temp1_OUT = @temp1 OUTPUT

	INSERT INTO @DatabaseSetting
	VALUES (
		'Diagnostics Value'
		,@temp1
		,''
		)
END

IF EXISTS (
		SELECT *
		FROM sys.columns
		WHERE [object_id] = object_id('$ndo$dbproperty')
			AND [name] = 'quickfind'
		)
BEGIN
	SET @SQL = 'Select @temp1_OUT = [quickfind] from [$ndo$dbproperty]'
	SET @ParmDefinition = '@temp1_OUT nvarchar(30) OUTPUT';

	EXECUTE sp_executesql @SQL
		,@ParmDefinition
		,@temp1_OUT = @temp1 OUTPUT

	INSERT INTO @DatabaseSetting
	VALUES (
		'Find As You Type'
		,CASE 
			WHEN @temp1 = 0
				THEN 'No'
			ELSE 'Yes'
			END
		,''
		)
END

IF EXISTS (
		SELECT *
		FROM sys.columns
		WHERE [object_id] = object_id('$ndo$dbproperty')
			AND [name] = 'checkcodepage'
		)
BEGIN
	SET @SQL = 'Select @temp1_OUT = [checkcodepage] from [$ndo$dbproperty]'
	SET @ParmDefinition = '@temp1_OUT nvarchar(30) OUTPUT';

	EXECUTE sp_executesql @SQL
		,@ParmDefinition
		,@temp1_OUT = @temp1 OUTPUT

	INSERT INTO @DatabaseSetting
	VALUES (
		'Validate Code Page'
		,CASE 
			WHEN @temp1 = 0
				THEN 'No'
			ELSE 'Yes'
			END
		,''
		)
END

IF EXISTS (
		SELECT *
		FROM sys.columns
		WHERE [object_id] = object_id('$ndo$dbproperty')
			AND [name] = 'locktimeout'
		)
BEGIN
	SET @SQL = 'Select @temp1_OUT = [locktimeout] from [$ndo$dbproperty]'
	SET @ParmDefinition = '@temp1_OUT nvarchar(30) OUTPUT';

	EXECUTE sp_executesql @SQL
		,@ParmDefinition
		,@temp1_OUT = @temp1 OUTPUT

	INSERT INTO @DatabaseSetting
	VALUES (
		'Lock Time Out'
		,CASE 
			WHEN @temp1 = 0
				THEN 'No'
			ELSE 'Yes'
			END
		,CASE 
			WHEN @temp1 = 0
				THEN 'Consider turning this back on'
			ELSE ''
			END
		)
END

IF EXISTS (
		SELECT *
		FROM sys.columns
		WHERE [object_id] = object_id('$ndo$dbproperty')
			AND [name] = 'locktimeoutperiod'
		)
BEGIN
	SET @SQL = 'Select @temp1_OUT = [locktimeoutperiod] from [$ndo$dbproperty]'
	SET @ParmDefinition = '@temp1_OUT nvarchar(30) OUTPUT';

	EXECUTE sp_executesql @SQL
		,@ParmDefinition
		,@temp1_OUT = @temp1 OUTPUT

	INSERT INTO @DatabaseSetting
	VALUES (
		'Lock Time Out Duration (Sec)'
		,@temp1
		,CASE 
			WHEN @temp1 <> 10
				THEN 'Verification required - Non standard setting in use'
			ELSE ''
			END
		)
END

IF EXISTS (
		SELECT *
		FROM sys.columns
		WHERE [object_id] = object_id('$ndo$dbproperty')
			AND [name] = 'hardrowlock'
		)
BEGIN
	SET @SQL = 'Select @temp1_OUT = [hardrowlock] from [$ndo$dbproperty]'
	SET @ParmDefinition = '@temp1_OUT nvarchar(30) OUTPUT';

	EXECUTE sp_executesql @SQL
		,@ParmDefinition
		,@temp1_OUT = @temp1 OUTPUT

	INSERT INTO @DatabaseSetting
	VALUES (
		'Always rowlock'
		,CASE 
			WHEN @temp1 = 0
				THEN 'No'
			ELSE 'Yes'
			END
		,CASE 
			WHEN @temp1 <> 0
				THEN 'Turn this setting OFF for better performance'
			ELSE ''
			END
		)
END

IF EXISTS (
		SELECT *
		FROM sys.columns
		WHERE [object_id] = object_id('$ndo$dbproperty')
			AND [name] = 'bufferedrows'
		)
BEGIN
	SET @SQL = 'Select @temp1_OUT = [bufferedrows] from [$ndo$dbproperty]'
	SET @ParmDefinition = '@temp1_OUT nvarchar(30) OUTPUT';

	EXECUTE sp_executesql @SQL
		,@ParmDefinition
		,@temp1_OUT = @temp1 OUTPUT

	INSERT INTO @DatabaseSetting
	VALUES (
		'Caching Record Set'
		,@temp1
		,CASE 
			WHEN @temp1 < 500
				THEN 'Increase this value to at least 500'
			ELSE ''
			END
		)
END

IF EXISTS (
		SELECT *
		FROM sys.columns
		WHERE [object_id] = object_id('$ndo$dbproperty')
			AND [name] = 'enabledforserver'
		)
BEGIN
	SET @SQL = 'Select @temp1_OUT = [enabledforserver] from [$ndo$dbproperty]'
	SET @ParmDefinition = '@temp1_OUT nvarchar(30) OUTPUT';

	EXECUTE sp_executesql @SQL
		,@ParmDefinition
		,@temp1_OUT = @temp1 OUTPUT

	INSERT INTO @DatabaseSetting
	VALUES (
		'Enabled for NAV Server'
		,CASE 
			WHEN @temp1 = 0
				THEN 'No'
			ELSE 'Yes'
			END
		,''
		)
END

SELECT Property
	,Value
	,Comment AS Comments
FROM @DatabaseSetting