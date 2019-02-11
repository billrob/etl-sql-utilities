CREATE PROCEDURE billrob_createSchemaWithSecurity
	@schemaName varchar(255)
	,@loginName varchar(255)
AS
	IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE [Name] = @loginName)
	BEGIN
		EXEC('CREATE LOGIN [' + @loginName + '] FROM WINDOWS;')
	END

	IF NOT EXISTS(SELECT 1 FROM sys.database_principals WHERE [Name] = @loginName)
	BEGIN
		EXEC('CREATE USER [' + @loginName + '] FOR LOGIN [' + @loginName + ']')
	END

	EXEC('CREATE SCHEMA [' + @schemaName + ']')
	EXEC('GRANT EXECUTE ON SCHEMA :: [' + @schemaName + '] TO [' + @loginName + ']')
	EXEC('GRANT SELECT ON SCHEMA :: [' + @schemaName + '] TO [' + @loginName + ']')
	EXEC('GRANT INSERT ON SCHEMA :: [' + @schemaName + '] TO [' + @loginName + ']')
	EXEC('GRANT VIEW DEFINITION ON SCHEMA :: [' + @schemaName + '] TO [' + @loginName + ']')
GO

