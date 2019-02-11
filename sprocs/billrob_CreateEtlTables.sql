CREATE PROCEDURE [dbo].[billrob_CreateEtlTables]
	@loadingSchemaName varchar(8000),
	@tableName varchar(8000),
	@createTableBody varchar(8000),
	@debug bit = 0
AS
	DECLARE @createLoadingTableSql varchar(max)
	DECLARE @createStageTableSql varchar(max)
	DECLARE @createSuccessProcedureSql varchar(max)
	DECLARE @createInitializeProcedureSql varchar(max)
	DECLARE @createFailProcedureSql varchar(max)
	DECLARE @fullLoadingName varchar(8000) = @loadingSchemaName + '.' + @tableName
	DECLARE @fullStageName varchar(8000) = 'Stage.' + @loadingSchemaName + '_' + @tableName

	--table 1
	SET @createLoadingTableSql = 'CREATE TABLE ' + @fullLoadingName + '('
	+ @createTableBody
	+ ')'

	--table 2
	SET @createStageTableSql = 'CREATE TABLE ' + @fullStageName + '('
	+ @createTableBody
	+ ')'

	--on init
	SET @createInitializeProcedureSql = 'CREATE PROCEDURE ' + @loadingSchemaName + '.' + @tableName + '_OnInitialize
	WITH EXECUTE AS owner
	AS
		TRUNCATE TABLE ' + @fullLoadingName + '
	'

	--on failed
	SET @createFailProcedureSql = 'CREATE PROCEDURE ' + @loadingSchemaName + '.' + @tableName + '_OnFail
	WITH EXECUTE AS owner
	AS
	'

	--on success
	SET @createSuccessProcedureSql = 'CREATE PROCEDURE ' + @loadingSchemaName + '.' + @tableName + '_OnSuccess
	WITH EXECUTE AS owner
	AS
		DECLARE @sourceLoadDate datetime2 = Getdate()

		--set extended property with source load date
		EXEC billrob_AddExtendedTableProperty 
			@destinationShema = ''' + @loadingSchemaName + ''', 
			@destinationTable = ''' + @tableName + ''', 
			@name = ''BillRob-Source-Load-Date'',
			@sourceLoadDate = @sourceLoadDate

		--now truncate    
		TRUNCATE TABLE ' + @fullStageName + '

		--copy from one to the other.
		EXEC billrob_CopyOneTableToAnother 
			@sourceTableSchema = ''' + @loadingSchemaName + ''',
			@sourceTableName = ''' + @tableName + ''',
			@destinationTableSchema = ''Stage'',
			@destinationTableName = ''' + @loadingSchemaName + '_' + @tableName + ''''

	IF @debug = 1
	BEGIN
		PRINT @createLoadingTableSql
		PRINT @createStageTableSql
		PRINT @createSuccessProcedureSql
		PRINT @createInitializeProcedureSql
		PRINT @createFailProcedureSql
		RETURN
	END

	BEGIN TRY
		EXEC(@createLoadingTableSql)
	END TRY
	BEGIN CATCH
		PRINT @createLoadingTableSql 
		EXEC billrob_RethrowError
		RETURN
	END CATCH
		
	BEGIN TRY
		EXEC(@createSuccessProcedureSql)
	END TRY
	BEGIN CATCH
		PRINT @createSuccessProcedureSql 
		EXEC billrob_RethrowError
		RETURN
	END CATCH

	BEGIN TRY
		EXEC(@createStageTableSql)
	END TRY
	BEGIN CATCH
		PRINT @createStageTableSql 
		EXEC billrob_RethrowError
		RETURN
	END CATCH

	BEGIN TRY
		EXEC(@createInitializeProcedureSql)
	END TRY
	BEGIN CATCH
		PRINT @createInitializeProcedureSql 
		EXEC billrob_RethrowError
		RETURN
	END CATCH

	BEGIN TRY
		EXEC(@createFailProcedureSql)
	END TRY
	BEGIN CATCH
		PRINT @createFailProcedureSql
		EXEC billrob_RethrowError
		RETURN
	END CATCH
GO