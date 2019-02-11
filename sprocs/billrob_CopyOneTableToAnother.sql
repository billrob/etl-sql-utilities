IF object_id('billrob_CopyOneTableToAnother') IS NULL
BEGIN
    EXEC ('CREATE PROCEDURE billrob_CopyOneTableToAnother AS SELECT 1')
END

GO

ALTER PROCEDURE [dbo].[billrob_CopyOneTableToAnother]
	@sourceTableSchema varchar(max),
	@sourceTableName varchar(max),
	@destinationTableSchema varchar(max),
	@destinationTableName varchar(max),
	@whereClause VARCHAR(MAX) = null,
	@distinct BIT = 0,
	@skipExtendedProperties BIT = 0,
	@debug BIT = 0
AS
BEGIN

	DECLARE @sourceTable varchar(max) = @sourceTableSchema + '.' + @sourceTableName
	DECLARE @destinationTable varchar(max) = @destinationTableSchema + '.' + @destinationTableName

	--get list of columns in comma list, then remove last comma
	DECLARE @columnList VARCHAR(MAX)
	SELECT @columnList = STUFF((SELECT ' [' + Name + '],' FROM sys.columns WHERE is_identity = 0 AND object_id = object_id(@destinationTable) FOR XML PATH('') ),1,1,'') + ' '
	SET @columnList = SUBSTRING(@columnList,  1, LEN(@columnList)-1)

	DECLARE @sql VARCHAR(MAX)
	SET @sql = '
	INSERT INTO ' + @destinationTable + ' (' + @columnList + ')
	SELECT '
	
	IF @distinct = 1
	BEGIN
		SET @sql = @sql + ' DISTINCT '
	END
	
	SET @sql = @sql + @columnList + ' FROM ' + @sourceTable + ' '
	

	IF @whereClause IS NOT NULL
	BEGIN
		SET @sql = @sql + '
		WHERE ' + @whereClause--REPLACE(, '''', '''''')
	END
	
	IF @debug = 1
	BEGIN
		PRINT(@sql)
	END
	ELSE
	BEGIN
		EXEC(@sql)
	END
	
	IF @skipExtendedProperties = 0
	BEGIN
	
		DECLARE @sourceLoadDate varchar(max)

		--always put the last load date.		
		DECLARE @justNowLoadDate varchar(100)
		SELECT @justNowLoadDate = CONVERT(varchar, GetDate(), 20)

		EXEC billrob_AddExtendedTableProperty
			@name = N'BillRob-Load-Date', 
			@value = @justNowLoadDate,
			@destinationShema = @destinationTableSchema,
			@destinationTable = @destinationTableName
		
		SELECT @sourceLoadDate = CONVERT(varchar(max), value) FROM sys.extended_properties prop
			INNER JOIN sys.objects obj ON prop.major_id = obj.object_id
			INNER JOIN sys.schemas sch ON sch.schema_id = obj.schema_id
			WHERE 
				obj.name = @sourceTableName
				and prop.name = 'billrob-source-load-date'
				AND sch.name = @sourceTableSchema
				
		IF @sourceLoadDate IS NOT NULL
		BEGIN
			EXEC billrob_AddExtendedTableProperty
				@name = N'BillRob-Source-Load-Date', 
				@value = @sourceLoadDate,
				@destinationShema = @destinationTableSchema,
				@destinationTable = @destinationTableName
		END
			ELSE	
				raiserror(50301, 16, 1)
					return					
	END
END

GO
