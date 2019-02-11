CREATE PROCEDURE [dbo].[billrob_AddExtendedTableProperty]
	@destinationShema varchar(8000),
	@destinationTable varchar(8000),
	@value varchar(8000) = null,
	@name varchar(8000) = 'BillRob-Source-Load-Date',
	@sourceLoadDate dateTime = null
AS
BEGIN
	IF @sourceLoadDate IS NOT NULL AND @value IS NOT NULL
	BEGIN
		RAISERROR('Cannot set both the @value and @sourceLoadDate.', 17, 17)		
	END
	
	--do the auto date stuff.
	IF @value IS NULL
	BEGIN
		IF @sourceLoadDate IS NULL
		BEGIN
			SELECT @sourceLoadDate = GETDATE()
		END
		SET @value = CONVERT(varchar, @sourceLoadDate, 20)
	END
	
	--be sure it is a date.
	IF @name = 'BillRob-Source-Load-Date'
	BEGIN
		BEGIN TRY
			BEGIN TRANSACTION
				DECLARE @CheckDate datetime
				SELECT @CheckDate = CONVERT(datetime, @value, 20)
			COMMIT
		END TRY
		BEGIN CATCH
			ROLLBACK
			RAISERROR('The BillRob-Source-Load-Date is being set, but does not appear to be a date.  Please set the @name property to something different.', 17, 17)
		END CATCH
	END 
	BEGIN TRY
		EXEC sp_dropextendedproperty 
			@name = @name,
			@level0type = N'SCHEMA', @level0name = @destinationShema,
			@level1type = N'TABLE',  @level1name = @destinationTable
	END TRY
	BEGIN CATCH
	END CATCH
	
	EXEC sys.sp_addextendedproperty 
		@name = @name,
		@value = @value,
		@level0type = N'SCHEMA', @level0name = @destinationShema,
		@level1type = N'TABLE',  @level1name = @destinationTable
END

GO