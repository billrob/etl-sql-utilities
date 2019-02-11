CREATE PROCEDURE [dbo].[billrob_RemoveBothLoadingTables]
	@loadingSchemaName varchar(8000),
	@tableName varchar(8000),
	@debug bit = 0
AS
	DECLARE @removeLoadingTableSql varchar(max)
	DECLARE @removeStageTableSql varchar(max)
	DECLARE @removeSuccessProcedureSql varchar(max)
	DECLARE @removeInitializeProcedureSql varchar(max)
	DECLARE @removeFailProcedureSql varchar(max)
	DECLARE @fullLoadingName varchar(8000) = @loadingSchemaName + '.' + @tableName
	DECLARE @fullStageName varchar(8000) = 'Stage.' + @loadingSchemaName + '_' + @tableName

	--table 1
	SET @removeLoadingTableSql = 'DROP TABLE ' + @fullLoadingName

	--table 2
	SET @removeStageTableSql = 'DROP TABLE ' + @fullStageName 

	--on init
	SET @removeInitializeProcedureSql = 'DROP PROCEDURE ' + @loadingSchemaName + '.' + @tableName + '_OnInitialize'

	--on failed
	SET @removeFailProcedureSql = 'DROP PROCEDURE ' + @loadingSchemaName + '.' + @tableName + '_OnFail'

	--on success
	SET @removeSuccessProcedureSql = 'DROP PROCEDURE ' + @loadingSchemaName + '.' + @tableName + '_OnSuccess'

	IF @debug = 1
	BEGIN
		PRINT @removeLoadingTableSql
		PRINT @removeStageTableSql
		PRINT @removeInitializeProcedureSql
		PRINT @removeFailProcedureSql
		PRINT @removeSuccessProcedureSql
		RETURN
	END

	BEGIN TRY
		EXEC(@removeLoadingTableSql)
	END TRY
	BEGIN CATCH
		PRINT @removeLoadingTableSql 
		EXEC billrob_RethrowError
		RETURN
	END CATCH
		
	BEGIN TRY
		EXEC(@removeSuccessProcedureSql)
	END TRY
	BEGIN CATCH
		PRINT @removeSuccessProcedureSql 
		EXEC billrob_RethrowError
		RETURN
	END CATCH

	BEGIN TRY
		EXEC(@removeStageTableSql)
	END TRY
	BEGIN CATCH
		PRINT @removeStageTableSql 
		EXEC billrob_RethrowError
		RETURN
	END CATCH

	BEGIN TRY
		EXEC(@removeInitializeProcedureSql)
	END TRY
	BEGIN CATCH
		PRINT @removeInitializeProcedureSql 
		EXEC billrob_RethrowError
		RETURN
	END CATCH

	BEGIN TRY
		EXEC(@removeFailProcedureSql)
	END TRY
	BEGIN CATCH
		PRINT @removeFailProcedureSql
		EXEC billrob_RethrowError
		RETURN
	END CATCH
GO
