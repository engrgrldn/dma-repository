USE [EDW_STAGE]
GO
/****** Object:  StoredProcedure [dbo].[delta_import_softrax9_sxcu_cust]    Script Date: 12/27/2023 9:41:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----------------------------------------------------------
ALTER PROCEDURE [dbo].[delta_import_softrax9_sxcu_cust]
	@load_date [smalldatetime] = NULL,
	@server [varchar](50) = 'SRV_STX',
	@owner [varchar](50) = 'dbo',
	@database [varchar](50) = 'SOFTRAX_REPL',
	@cleanupTempTables [int] = 1,
	@debug [int] = 0,
	@min_date [datetime] = NULL
WITH EXECUTE AS CALLER
AS
/***************************************************************************************************************
*	Procedure:		delta_import_softrax9_sxcu_cust
 *	Purpose:		To import Data using a delta methodololgy
 *	Author:			EDWAWSAdmin
 *	CreateDate:		07/20/2020
 *	Modifications:
 *	Date			Author			Purpose
 *	
 *	
 *
 *	--TESTING SCRIPTS:
--EXECUTE
DECLARE	@load_date	smalldatetime; SELECT @load_date = [loadDateDt] FROM [dbo].[dim_LoadDate]
DECLARE	@min_date	datetime; SET @min_date = convert(datetime, convert(varchar(30), dateadd(yy, -30, @load_date), 101))
DECLARE	@return_value int
EXEC	@return_value = [dbo].delta_import_softrax9_sxcu_cust
		@load_date		= @load_date,
		@server			= N'SRV_STX',
		@owner			= N'dbo',
		@database		= N'SOFTRAX_REPL',
		@debug			= 0,
		@min_date		= @min_date
SELECT	'Return Value' = @return_value
 
 *
 ***************************************************************************************************************/
SET NOCOUNT ON
--DECLARE	@load_date	smalldatetime; DECLARE	@min_date datetime
DECLARE	@countSource	int
DECLARE	@countDest		int
DECLARE	@countDelta		int
DECLARE	@cmd			varchar(max)
DECLARE @rowcount		int;
DECLARE @log_v_main		int;
DECLARE	@log_value		int;
DECLARE	@log_step		int;
DECLARE	@message		varchar(50);
DECLARE	@type			varchar(50);
DECLARE	@proc_name		varchar(50);
DECLARE	@step_name		varchar(50);
DECLARE	@tbl			varchar(128)
DECLARE @destDB			varchar(128)
DECLARE @dateValue1			datetime
DECLARE @dateValue2			datetime
DECLARE @dateValue3			datetime
DECLARE @dateValue4			datetime
DECLARE @loaddttm			datetime2

SET		@destDB			= db_name()


SET		@proc_name		= OBJECT_NAME(@@PROCID)

SET		@step_name		= 'PROCEDURE'
SET		@message		= 'PROCEDURE'
SET		@type			= 'PROCEDURE'
SET		@rowcount		= 0
EXEC	@log_v_main = dbo.logProcessActivity
						  @log_v_main
						, @proc_name
						, @step_name
						, @message
						, @type
						, @rowcount
SET		@step_name		= 'SETUP'
SET		@message		= 'SETUP'
SET		@type			= 'SETUP'
SET		@rowcount		= 0
EXEC	@log_value = dbo.logProcessActivity
						  @log_value
						, @proc_name
						, @step_name
						, @message
						, @type
						, @rowcount

--Set the load_date, min_date and delta date where not set
--DECLARE @log_value int; DECLARE @proc_name sysname; DECLARE @step_name varchar(256); DECLARE @message varchar(256); DECLARE @type varchar(256); DECLARE @rowcount int', 1'
--DECLARE @countSource int; DECLARE @countDest int; DECLARE @load_date smalldatetime; DECLARE @min_date datetime; DECLARE @log_step varchar(256); DECLARE @cmd varchar(max)


 /**** SOFTRAX9_SXCU_CUST ****/

SET		@countSource	= 0
SET		@countDest		= 0


IF		@load_date IS NULL OR @load_date = ''
			SELECT	@load_date = [loadDateDt] FROM [dbo].[dim_LoadDate]
SELECT	@loaddttm		= [currentDttm] FROM [dbo].[dim_LoadDate]

IF  @min_date IS NULL OR @min_date = ''
	BEGIN
		IF 'getdate()' != 'NULL'
			SELECT @datevalue1 = max(getdate()) FROM EDW_STAGE.dbo.SOFTRAX9_SXCU_CUST WITH (NOLOCK) WHERE  getdate() < = getdate()
		ELSE
			SELECT @datevalue1 = dateadd(yy, -30, @load_date)

		IF 'NULL' != 'NULL'
			SELECT @datevalue2 = max(getdate()) FROM EDW_STAGE.dbo.SOFTRAX9_SXCU_CUST WITH (NOLOCK) WHERE  getdate() < = getdate()
		ELSE
			SELECT @datevalue2 = @datevalue1

		IF 'NULL' != 'NULL'
			SELECT @datevalue3 = max(getdate()) FROM EDW_STAGE.dbo.SOFTRAX9_SXCU_CUST WITH (NOLOCK) WHERE  getdate() < = getdate()
		ELSE
			SELECT @datevalue3 = @datevalue1

		IF 'NULL' != 'NULL'
			SELECT @datevalue4 = max(getdate()) FROM EDW_STAGE.dbo.SOFTRAX9_SXCU_CUST WITH (NOLOCK) WHERE  getdate() < = getdate()
		ELSE
			SELECT @datevalue4 = @datevalue1


		SELECT @min_date = DATEADD(dd, -500, COALESCE(dbo.fn_GetMaxDttm( @datevalue1, dbo.fn_GetMaxDttm( @datevalue2, dbo.fn_GetMaxDttm( @datevalue3, @datevalue4) ) ), dateadd(dd, -500, getdate())))

	END

EXEC	@log_value = dbo.logProcessActivity
						  @log_value
						, @proc_name
						, @step_name
						, @message
						, @type
						, @rowcount

/***************************************************************************************************************/
/***************************************************************************************************************/



SET		@step_name		= 'SOFTRAX9_SXCU_CUST'
SET		@message		= 'Clear Records'
SET		@type			= 'DELETE'
SET		@rowcount		= 0
EXEC	@log_value = dbo.logProcessActivity
						  @log_value
						, @proc_name
						, @step_name
						, @message
						, @type
						, @rowcount


--CREATE the delta table in local db if it does not exist
SET		@tbl = 'SOFTRAX9_SXCU_CUST'
BEGIN
			EXEC	 dbo.cloneTable
						@source_server		= N'',
						@source_db			= N'EDW_STAGE',
						@source_table		= 'SOFTRAX9_SXCU_CUST',
						@dest_db			= N'EDW_STAGE',
						@table_suffix		= N'',
						@table_prefix		= N'XD_',
						@force_load_date	= 0,
						@debug				= 0
				--SET	@cmd = 'DELETE FROM EDW_STAGE.dbo.SOFTRAX9_SXCU_CUST WHERE load_date < ( SELECT max(load_date) FROM EDW_STAGE.dbo.SOFTRAX9_SXCU_CUST WITH (NOLOCK))'
				--EXECUTE	(@cmd)
END



BEGIN
			EXEC	 dbo.cloneTable
						@source_server		= N'',
						@source_db			= N'EDW_STAGE',
						@source_table		= 'SOFTRAX9_SXCU_CUST',
						@dest_db			= N'EDW_STAGE',
						@table_suffix		= N'',
						@table_prefix		= N'XA_',
						@force_load_date	= 0,
						@debug				= 0
				--SET	@cmd = 'DELETE FROM EDW_STAGE.dbo.SOFTRAX9_SXCU_CUST WHERE load_date < ( SELECT max(load_date) FROM EDW_STAGE.dbo.SOFTRAX9_SXCU_CUST WITH (NOLOCK))'
				--EXECUTE	(@cmd)
END



EXEC	@log_value = dbo.logProcessActivity
						  @log_value
						, @proc_name
						, @step_name
						, @message
						, @type
						, @@ROWCOUNT




SET		@message		= 'COUNT Records in Source'
SET		@type			= 'COUNT'
SET		@rowcount		= 0
EXEC	@log_value = dbo.logProcessActivity
						  @log_value
						, @proc_name
						, @step_name
						, @message
						, @type
						, @rowcount

IF @debug = 1
BEGIN
	EXECUTE dbo.logTableCounts @servername = @server , @dbname = @database, @tablename = 'SXCU_CUST', @count = NULL, @desc = 'SOURCE'
END


EXEC	@log_value = dbo.logProcessActivity
						  @log_value
						, @proc_name
						, @step_name
						, @message
						, @type
						, @countSource


SET		@message		= 'Delete Records that were removed from the source'
SET		@type			= 'COUNT'
SET		@rowcount		= 0
EXEC	@log_value = dbo.logProcessActivity
						  @log_value
						, @proc_name
						, @step_name
						, @message
						, @type
						, @rowcount


SET		@cmd = 'INSERT INTO XD_SOFTRAX9_SXCU_CUST' + char(10)
SET		@cmd = @cmd + 'SELECT	dw.*' + char(10)
SET		@cmd = @cmd + '	FROM	SOFTRAX9_SXCU_CUST dw' + char(10)
SET		@cmd = @cmd + '	LEFT JOIN OPENQUERY(' + @server + ', ''SELECT [sxcu_pk]' + char(10)







SET		@cmd = @cmd + '	FROM [' + @database + '].[dbo].[SXCU_CUST]'') src' + char(10)
SET		@cmd = @cmd + '	ON		src.[sxcu_pk]	= dw.[sxcu_pk]' + char(10)







SET		@cmd = @cmd + '	WHERE	src.[sxcu_pk]	IS NULL' + char(10)

EXECUTE (@cmd)


EXEC	@log_value = dbo.logProcessActivity
						  @log_value
						, @proc_name
						, @step_name
						, @message
						, @type
						, @countSource


SET		@message		= 'INSERT Records in Delta table'
SET		@type			= 'INSERT'
SET		@rowcount		= 0
EXEC	@log_value = dbo.logProcessActivity
						  @log_value
						, @proc_name
						, @step_name
						, @message
						, @type
						, @rowcount

			SET		@cmd = 'SELECT BI_Load_Date = ''' + convert(varchar(20), @load_date) + '''
								,	LoadDTTM	= '''  + convert(varchar(40), @loaddttm) + '''
		,	source.*
FROM	OPENQUERY(' + @server + ', ''SELECT 
	 [sxcu_pk]		
	, [s2_location]		= LEFT(LTRIM(RTRIM([s2_location])),10)
	, [cus_grp_cd]		= LEFT(LTRIM(RTRIM([cus_grp_cd])),6)
	, [cus_cd]		= LEFT(LTRIM(RTRIM([cus_cd])),10)
	, [cu_busname]		= LEFT(LTRIM(RTRIM([cu_busname])),40)
	, [cu_cnctname]		= LEFT(LTRIM(RTRIM([cu_cnctname])),40)
FROM [' + @database + '].[dbo].[SXCU_CUST] WITH (NOLOCK)
WHERE	getdate() >= ''''' + convert(varchar(20), @min_date) + '''''



''	) source'


--Insert the set of changed records into dbo.SOFTRAX9_SXCU_CUST
INSERT INTO dbo.XA_SOFTRAX9_SXCU_CUST
(
	  [BI_load_date]
	, [BI_loadDttm]
	, [sxcu_pk]
	, [s2_location]
	, [cus_grp_cd]
	, [cus_cd]
	, [cu_busname]
	, [cu_cnctname]
	)
EXECUTE (@cmd)


SET		@rowcount	= @@ROWCOUNT
SET		@countDelta = @rowcount

EXEC	@log_value = dbo.logProcessActivity
						  @log_value
						, @proc_name
						, @step_name
						, @message
						, @type
						, @rowcount





--Delete records no longer in the source system


SET		@message		= 'Clear Records in EDW_STAGE'
SET		@type			= 'DELETE'
SET		@rowcount		= 0
EXEC	@log_value = dbo.logProcessActivity
						  @log_value
						, @proc_name
						, @step_name
						, @message
						, @type
						, @rowcount

DELETE FROM base
	FROM EDW_STAGE.dbo.SOFTRAX9_SXCU_CUST base WITH (NOLOCK)
	INNER JOIN dbo.XD_SOFTRAX9_SXCU_CUST keys WITH (NOLOCK)
		ON	base.[sxcu_pk]	= keys.[sxcu_pk]









EXEC	@log_value = dbo.logProcessActivity
						  @log_value
						, @proc_name
						, @step_name
						, @message
						, @type
						, @@ROWCOUNT


SET		@message		= 'Clear Records in EDW_STAGE'
SET		@type			= 'DELETE'
SET		@rowcount		= 0
EXEC	@log_value = dbo.logProcessActivity
						  @log_value
						, @proc_name
						, @step_name
						, @message
						, @type
						, @rowcount

DELETE FROM base
	FROM EDW_STAGE.dbo.SOFTRAX9_SXCU_CUST base WITH (NOLOCK)
	INNER JOIN dbo.XA_SOFTRAX9_SXCU_CUST keys WITH (NOLOCK)
		ON	base.[sxcu_pk]	= keys.[sxcu_pk]









EXEC	@log_value = dbo.logProcessActivity
						  @log_value
						, @proc_name
						, @step_name
						, @message
						, @type
						, @@ROWCOUNT


--Update the load_date for all reamining records


SET		@message		= 'LOAD DATE ON EDW_STAGE'
SET		@type			= 'UPDATE'
SET		@rowcount		= 0
EXEC	@log_value = dbo.logProcessActivity
						  @log_value
						, @proc_name
						, @step_name
						, @message
						, @type
						, @rowcount

--UPDATE	EDW_STAGE.dbo.SOFTRAX9_SXCU_CUST
--SET		load_date		= @load_date
--WHERE	load_date		!= @load_date


EXEC	@log_value = dbo.logProcessActivity
						  @log_value
						, @proc_name
						, @step_name
						, @message
						, @type
						, @@ROWCOUNT


--Insert the records from the delta table


SET		@message		= 'New Records in EDW_STAGE'
SET		@type			= 'INSERT'
SET		@rowcount		= 0
EXEC	@log_value = dbo.logProcessActivity
						  @log_value
						, @proc_name
						, @step_name
						, @message
						, @type
						, @rowcount

INSERT INTO EDW_STAGE.dbo.SOFTRAX9_SXCU_CUST
SELECT	new_recs.*
FROM	dbo.XA_SOFTRAX9_SXCU_CUST new_recs WITH (NOLOCK)

SET		@rowcount=@@ROWCOUNT

EXEC	@log_value = dbo.logProcessActivity
						  @log_value
						, @proc_name
						, @step_name
						, @message
						, @type
						, @rowcount

-- Get a count of records in the EDW_STAGE table
SET		@message		= 'Count Records in EDW_STAGE'
SET		@type			= 'COUNT'
EXEC	@log_value = dbo.logProcessActivity
						  @log_value
						, @proc_name
						, @step_name
						, @message
						, @type
						, 0

SELECT	@countDest		= count(*)
FROM	EDW_STAGE.dbo.SOFTRAX9_SXCU_CUST WITH (NOLOCK)

EXEC	@log_value = dbo.logProcessActivity
						  @log_value
						, @proc_name
						, @step_name
						, @message
						, @type
						, @countDest



-- Section to catch any missing records (in the event of an empty table or gap in loading times )
/******************************************************************************************************************************/


SET		@message		= 'ADD Missing Records'
SET		@type			= 'INSERT'
SET		@rowcount		= 0
EXEC	@log_step = dbo.logProcessActivity
						  @log_step
						, @proc_name
						, @step_name
						, @message
						, @type
						, @rowcount


IF @countSource		> @countDest
BEGIN --Add Missing Records

			SET		@rowcount	= 0

			SET		@message		= 'Discover Missing Records'
			SET		@type			= 'INSERT'
			SET		@rowcount		= 0
			EXEC	@log_value = dbo.logProcessActivity
									  @log_value
									, @proc_name
									, @step_name
									, @message
									, @type
									, @rowcount




			EXEC	@log_value = dbo.logProcessActivity
									  @log_value
									, @proc_name
									, @step_name
									, @message
									, @type
									, @rowcount


			SET		@message		= 'Add Missing Records in EDW_STAGE'
			SET		@type			= 'INSERT'
			SET		@rowcount		= 0
			EXEC	@log_value = dbo.logProcessActivity
									  @log_value
									, @proc_name
									, @step_name
									, @message
									, @type
									, @rowcount


			BEGIN

				-- Insert anything new into the EXT OP table that's come up

			SET		@cmd = 'SELECT BI_Load_Date = ''' + convert(varchar(40), @loaddttm) + '''
								,	LoadDTTM	= '''  + convert(varchar(20), @load_date) + '''
								,	 source.*
			FROM	OPENQUERY( ' + @server + ', ''SELECT
							  [sxcu_pk]		
							  , [s2_location]		= LEFT(LTRIM(RTRIM([s2_location])),10)
							  , [cus_grp_cd]		= LEFT(LTRIM(RTRIM([cus_grp_cd])),6)
							  , [cus_cd]		= LEFT(LTRIM(RTRIM([cus_cd])),10)
							  , [cu_busname]		= LEFT(LTRIM(RTRIM([cu_busname])),40)
							  , [cu_cnctname]		= LEFT(LTRIM(RTRIM([cu_cnctname])),40)
				FROM [' + @database + '].[dbo].[SXCU_CUST] src  WITH (NOLOCK)'') source
				LEFT JOIN EDW_STAGE.dbo.SOFTRAX9_SXCU_CUST base WITH (NOLOCK)
				ON source.[sxcu_pk] = base.[sxcu_pk]
				
				
				
				
				
				
				
				WHERE base.[sxcu_pk] IS NULL'
				/*INSERT INTO EDW_STAGE.dbo.SOFTRAX9_SXCU_CUST
				(
						[BI_load_date] 
						,[BI_loadDttm] 
						,[sxcu_pk] 
						,[s2_location] 
						,[cus_grp_cd] 
						,[cus_cd] 
						,[cu_busname] 
						,[cu_cnctname] 
				)
				--EXECUTE (@cmd)*/

				SET		@rowcount	= @@ROWCOUNT

				EXEC	@log_value = dbo.logProcessActivity
										  @log_value
										, @proc_name
										, @step_name
										, @message
										, @type
										, @rowcount

			END

END --Add Missing Records

SET		@message		= 'ADD Missing Records'
SET		@type			= 'INSERT'
EXEC	@log_step		= dbo.logProcessActivity
						  @log_step
						, @proc_name
						, @step_name
						, @message
						, @type
						, @rowcount


/******************************************************************************************************************************/


SET		@message		= 'Drop Temporary Tables '
SET		@type			= 'INSERT'
SET		@rowcount		= 0
EXEC	@log_value = dbo.logProcessActivity
						  @log_value
						, @proc_name
						, @step_name
						, @message
						, @type
						, @rowcount


IF @cleanupTempTables > 0
BEGIN --Temp Table Cleanup
	BEGIN TRY
		DROP TABLE XA_SOFTRAX9_SXCU_CUST
	END TRY
	BEGIN CATCH
		PRINT 'Unable to drop table XA_SOFTRAX9_SXCU_CUST'
	END CATCH


	BEGIN TRY
		DROP TABLE XD_SOFTRAX9_SXCU_CUST
	END TRY
	BEGIN CATCH
		PRINT 'Unable to drop table XD_SOFTRAX9_SXCU_CUST'
	END CATCH
END --Temp Table Cleanup


EXEC	@log_value = dbo.logProcessActivity
						  @log_value
						, @proc_name
						, @step_name
						, @message
						, @type
						, @rowcount




SET		@message		= 'Count Records for Comparison'
SET		@type			= 'COUNT'
SET		@rowcount		= 0
EXEC	@log_value = dbo.logProcessActivity
						  @log_value
						, @proc_name
						, @step_name
						, @message
						, @type
						, @rowcount

IF @debug = 1
BEGIN
	EXECUTE dbo.logTableCounts @servername = @@SERVERNAME, @dbname = 'EDW_STAGE', @tableName = 'XA_SOFTRAX9_SXCU_CUST', @count = @countDelta, @desc = 'DELTA', @load_date = @load_date
	EXECUTE dbo.logTableCounts @servername = @server, @dbname = @database , @tableName = 'SXCU_CUST',@count = @countSource, @desc = 'SOURCE', @load_date = @load_date
	EXECUTE dbo.logTableCounts @servername = @@SERVERNAME, @dbname = 'EDW_STAGE', @tableName = 'SOFTRAX9_SXCU_CUST', @count = @countDest, @desc = 'FINAL', @load_date = @load_date
END


EXEC	@log_value = dbo.logProcessActivity
						  @log_value
						, @proc_name
						, @step_name
						, @message
						, @type
						, @rowcount


SET		@proc_name		= OBJECT_NAME(@@PROCID)

SET		@step_name		= 'PROCEDURE'
SET		@message		= 'PROCEDURE'
SET		@type			= 'PROCEDURE'
SET		@rowcount		= 0
EXEC	@log_v_main = dbo.logProcessActivity
						  @log_v_main
						, @proc_name
						, @step_name
						, @message
						, @type
						, @rowcount
