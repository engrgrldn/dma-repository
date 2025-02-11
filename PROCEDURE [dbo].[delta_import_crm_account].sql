USE [EDW_STAGE]
GO
/****** Object:  StoredProcedure [dbo].[delta_import_crm_account]    Script Date: 12/27/2023 9:30:21 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
----------------------------------------------------------
ALTER PROCEDURE [dbo].[delta_import_crm_account]
 @load_date [smalldatetime] = NULL,
 @server [varchar](50) = 'SRV_ICRM',
 @owner [varchar](50) = 'sysdba',
 @database [varchar](50) = 'Saleslogix',
 @sourcesystem [varchar](50) = 'CRM',
 @cleanupTempTables [int] = 1,
 @debug [int] = 0,
 @min_date [datetime] = NULL
WITH EXECUTE AS CALLER
AS
/***************************************************************************************************************
* Procedure:  delta_import_crm_account
 * Purpose:  To import Data using a delta methodololgy
 * Author:   EDWAWSAdmin
 * CreateDate:  07/15/2019
 * Modifications:
 * Date   Author   Purpose
 * 
 * 
 *
 * --TESTING SCRIPTS:
--EXECUTE
DECLARE @load_date smalldatetime; SELECT @load_date = [loadDateDt] FROM [dbo].[dim_LoadDate]
DECLARE @min_date datetime; SET @min_date = convert(datetime, convert(varchar(30), dateadd(yy, -30, @load_date), 101))
DECLARE @return_value int
EXEC @return_value = [dbo].delta_import_crm_account
  @load_date  = @load_date,
  @server   = N'SRV_ICRM',
  @owner   = N'sysdba',
  @database  = N'Saleslogix',
  @sourcesystem = N'CRM',
  @debug   = 0,
  @min_date  = @min_date
SELECT 'Return Value' = @return_value
 
 *
 ***************************************************************************************************************/
SET NOCOUNT ON
--DECLARE @load_date smalldatetime; DECLARE @min_date datetime
DECLARE @sourcesystem_id int
DECLARE @countSource int
DECLARE @countDest  int
DECLARE @countDelta  int
DECLARE @cmd   varchar(max)
DECLARE @rowcount  int;
DECLARE @log_v_main  int;
DECLARE @log_value  int;
DECLARE @log_step  int;
DECLARE @message  varchar(50);
DECLARE @type   varchar(50);
DECLARE @proc_name  varchar(50);
DECLARE @step_name  varchar(50);
DECLARE @tbl   varchar(128)
DECLARE @destDB   varchar(128)
DECLARE @dateValue1   datetime
DECLARE @dateValue2   datetime
DECLARE @dateValue3   datetime
DECLARE @dateValue4   datetime
DECLARE @loaddttm   datetime2

SET  @destDB   = db_name()


SET  @proc_name  = OBJECT_NAME(@@PROCID)

SET  @step_name  = 'PROCEDURE'
SET  @message  = 'PROCEDURE'
SET  @type   = 'PROCEDURE'
SET  @rowcount  = 0
EXEC @log_v_main = dbo.logProcessActivity
        @log_v_main
      , @proc_name
      , @step_name
      , @message
      , @type
      , @rowcount
SET  @step_name  = 'SETUP'
SET  @message  = 'SETUP'
SET  @type   = 'SETUP'
SET  @rowcount  = 0
EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , @rowcount

--Set the load_date, sourcesystem_id, min_date and delta date where not set
--DECLARE @log_value int; DECLARE @proc_name sysname; DECLARE @step_name varchar(256); DECLARE @message varchar(256); DECLARE @type varchar(256); DECLARE @rowcount int', 1'
--DECLARE @countSource int; DECLARE @countDest int; DECLARE @load_date smalldatetime; DECLARE @min_date datetime; DECLARE @log_step varchar(256); DECLARE @cmd varchar(max)
--DECLARE @sourcesystem varchar(200)


 /**** CRM_ACCOUNT ****/

SET  @countSource = 0
SET  @countDest  = 0
SELECT  @sourcesystem_id = sourcesystem_id FROM dbo.dim_SourceSystems WHERE sourcesystem = @sourcesystem


IF  @load_date IS NULL OR @load_date = ''
   SELECT @load_date = [loadDateDt] FROM [dbo].[dim_LoadDate]
SELECT @loaddttm  = [currentDttm] FROM [dbo].[dim_LoadDate]

IF  @min_date IS NULL OR @min_date = ''
 BEGIN
  IF 'ModifyDate' != 'NULL'
   SELECT @datevalue1 = max(ModifyDate) FROM dbo.CRM_ACCOUNT WITH (NOLOCK) WHERE  ModifyDate < = getdate()
  ELSE
   SELECT @datevalue1 = dateadd(yy, -30, @load_date)

  IF 'NULL' != 'NULL'
   SELECT @datevalue2 = max(getdate()) FROM dbo.CRM_ACCOUNT WITH (NOLOCK) WHERE  ModifyDate < = getdate()
  ELSE
   SELECT @datevalue2 = @datevalue1

  IF 'NULL' != 'NULL'
   SELECT @datevalue3 = max(getdate()) FROM dbo.CRM_ACCOUNT WITH (NOLOCK) WHERE  ModifyDate < = getdate()
  ELSE
   SELECT @datevalue3 = @datevalue1

  IF 'NULL' != 'NULL'
   SELECT @datevalue4 = max(getdate()) FROM dbo.CRM_ACCOUNT WITH (NOLOCK) WHERE  ModifyDate < = getdate()
  ELSE
   SELECT @datevalue4 = @datevalue1


  SELECT @min_date = DATEADD(dd, -3, COALESCE(dbo.fn_GetMaxDttm( @datevalue1, dbo.fn_GetMaxDttm( @datevalue2, dbo.fn_GetMaxDttm( @datevalue3, @datevalue4) ) ), dateadd(dd, -200, getdate())))

 END

EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , @rowcount

/***************************************************************************************************************/
/***************************************************************************************************************/



SET  @step_name  = 'CRM_ACCOUNT'
SET  @message  = 'Clear Records'
SET  @type   = 'DELETE'
SET  @rowcount  = 0
EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , @rowcount


--CREATE the delta table in local db if it does not exist
SET  @tbl = 'CRM_ACCOUNT'
BEGIN
   EXEC  dbo.cloneTable
      @source_server  = N'',
      @source_db   = N'EDW_STAGE',
      @source_table  = 'CRM_ACCOUNT',
      @dest_db   = N'EDW_STAGE',
      @table_suffix  = N'',
      @table_prefix  = N'XD_',
      @force_load_date = 0,
      @debug    = 0
    --SET @cmd = 'DELETE FROM dbo.CRM_ACCOUNT WHERE load_date < ( SELECT max(load_date) FROM dbo.CRM_ACCOUNT WITH (NOLOCK))'
    --EXECUTE (@cmd)
END



BEGIN
   EXEC  dbo.cloneTable
      @source_server  = N'',
      @source_db   = N'EDW_STAGE',
      @source_table  = 'CRM_ACCOUNT',
      @dest_db   = N'EDW_STAGE',
      @table_suffix  = N'',
      @table_prefix  = N'XA_',
      @force_load_date = 0,
      @debug    = 0
    --SET @cmd = 'DELETE FROM dbo.CRM_ACCOUNT WHERE load_date < ( SELECT max(load_date) FROM dbo.CRM_ACCOUNT WITH (NOLOCK))'
    --EXECUTE (@cmd)
END



EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , @@ROWCOUNT




SET  @message  = 'COUNT Records in Source'
SET  @type   = 'COUNT'
SET  @rowcount  = 0
EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , @rowcount

EXECUTE dbo.logTableCounts @servername = @server , @dbname = @database, @tablename = 'ACCOUNT', @count = NULL, @desc = 'SOURCE'
       , @sourcesystem_id = @sourcesystem_id


EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , @countSource


SET  @message  = 'Delete Records that were removed from the source'
SET  @type   = 'COUNT'
SET  @rowcount  = 0
EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , @rowcount


SET  @cmd = 'INSERT INTO XD_CRM_ACCOUNT' + char(10)
SET  @cmd = @cmd + 'SELECT dw.*' + char(10)
SET  @cmd = @cmd + ' FROM CRM_ACCOUNT dw' + char(10)
SET  @cmd = @cmd + ' LEFT JOIN OPENQUERY(' + @server + ', ''SELECT [ACCOUNTID]' + char(10)







SET  @cmd = @cmd + ' FROM [' + @database + '].[sysdba].[ACCOUNT]'') src' + char(10)
SET  @cmd = @cmd + ' ON  src.[ACCOUNTID] = dw.[ACCOUNTID]' + char(10)







SET  @cmd = @cmd + ' WHERE src.[ACCOUNTID] IS NULL' + char(10)

EXECUTE (@cmd)


EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , @countSource


SET  @message  = 'INSERT Records in Delta table'
SET  @type   = 'INSERT'
SET  @rowcount  = 0
EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , @rowcount

SET  @cmd = 'SELECT BI_Load_Date   = ''' + convert(varchar(40), @loaddttm) + '''
  , sourcesystem_id  = ''' + convert(varchar(20), @sourcesystem_id) + '''
  , source.*
FROM OPENQUERY(' + @server + ', ''SELECT 
  [ACCOUNTID]  = LEFT(LTRIM(RTRIM([ACCOUNTID])),12)
 , [TYPE]  = LEFT(LTRIM(RTRIM([TYPE])),64)
 , [ACCOUNT]  = LEFT(LTRIM(RTRIM([ACCOUNT])),255)
 , [DIVISION]  = LEFT(LTRIM(RTRIM([DIVISION])),64)
 , [SICCODE]  = LEFT(LTRIM(RTRIM([SICCODE])),64)
 , [PARENTID]  = LEFT(LTRIM(RTRIM([PARENTID])),12)
 , [DESCRIPTION]  = LEFT(LTRIM(RTRIM([DESCRIPTION])),128)
 , [ADDRESSID]  = LEFT(LTRIM(RTRIM([ADDRESSID])),12)
 , [SHIPPINGID]  = LEFT(LTRIM(RTRIM([SHIPPINGID])),12)
 , [REGION]  = LEFT(LTRIM(RTRIM([REGION])),64)
 , [MAINPHONE]  = LEFT(LTRIM(RTRIM([MAINPHONE])),32)
 , [ALTERNATEPHONE]  = LEFT(LTRIM(RTRIM([ALTERNATEPHONE])),32)
 , [FAX]  = LEFT(LTRIM(RTRIM([FAX])),32)
 , [TOLLFREE]  = LEFT(LTRIM(RTRIM([TOLLFREE])),32)
 , [TOLLFREE2]  = LEFT(LTRIM(RTRIM([TOLLFREE2])),32)
 , [OTHERPHONE1]  = LEFT(LTRIM(RTRIM([OTHERPHONE1])),32)
 , [OTHERPHONE2]  = LEFT(LTRIM(RTRIM([OTHERPHONE2])),32)
 , [OTHERPHONE3]  = LEFT(LTRIM(RTRIM([OTHERPHONE3])),32)
 , [EMAIL]  = LEFT(LTRIM(RTRIM([EMAIL])),128)
 , [EMAILTYPE]  = LEFT(LTRIM(RTRIM([EMAILTYPE])),64)
 , [WEBADDRESS]  = LEFT(LTRIM(RTRIM([WEBADDRESS])),128)
 , [SECCODEID]  = LEFT(LTRIM(RTRIM([SECCODEID])),12)
 , [REVENUE]  
 , [EMPLOYEES]  
 , [INDUSTRY]  = LEFT(LTRIM(RTRIM([INDUSTRY])),64)
 , [CREDITRATING]  = LEFT(LTRIM(RTRIM([CREDITRATING])),64)
 , [NOTES]  
 , [STATUS]  = LEFT(LTRIM(RTRIM([STATUS])),64)
 , [ACCOUNTMANAGERID]  = LEFT(LTRIM(RTRIM([ACCOUNTMANAGERID])),12)
 , [REGIONALMANAGERID]  = LEFT(LTRIM(RTRIM([REGIONALMANAGERID])),12)
 , [DIVISIONALMANAGERID]  = LEFT(LTRIM(RTRIM([DIVISIONALMANAGERID])),12)
 , [NATIONALACCOUNT]  = LEFT(LTRIM(RTRIM([NATIONALACCOUNT])),1)
 , [TARGETACCOUNT]  = LEFT(LTRIM(RTRIM([TARGETACCOUNT])),1)
 , [TERRITORY]  = LEFT(LTRIM(RTRIM([TERRITORY])),64)
 , [CREATEUSER]  = LEFT(LTRIM(RTRIM([CREATEUSER])),12)
 , [MODIFYUSER]  = LEFT(LTRIM(RTRIM([MODIFYUSER])),12)
 , [CREATEDATE]  
 , [MODIFYDATE]  
 , [ACCOUNT_UC]  = LEFT(LTRIM(RTRIM([ACCOUNT_UC])),255)
 , [AKA]  = LEFT(LTRIM(RTRIM([AKA])),64)
 , [CURRENCYCODE]  = LEFT(LTRIM(RTRIM([CURRENCYCODE])),64)
 , [INTERNALACCOUNTNO]  = LEFT(LTRIM(RTRIM([INTERNALACCOUNTNO])),32)
 , [EXTERNALACCOUNTNO]  = LEFT(LTRIM(RTRIM([EXTERNALACCOUNTNO])),32)
 , [PARENTACCOUNTNO]  = LEFT(LTRIM(RTRIM([PARENTACCOUNTNO])),32)
 , [ALTERNATEKEYPREFIX]  = LEFT(LTRIM(RTRIM([ALTERNATEKEYPREFIX])),64)
 , [ALTERNATEKEYSUFFIX]  = LEFT(LTRIM(RTRIM([ALTERNATEKEYSUFFIX])),64)
 , [DEFAULTTICKETSECCODEID]  = LEFT(LTRIM(RTRIM([DEFAULTTICKETSECCODEID])),12)
 , [NOTIFYDEFECTS]  = LEFT(LTRIM(RTRIM([NOTIFYDEFECTS])),1)
 , [NOTIFYONCLOSE]  = LEFT(LTRIM(RTRIM([NOTIFYONCLOSE])),1)
 , [NOTIFYONSTATUS]  = LEFT(LTRIM(RTRIM([NOTIFYONSTATUS])),1)
 , [SHORTNOTES]  = LEFT(LTRIM(RTRIM([SHORTNOTES])),255)
 , [USERFIELD1]  = LEFT(LTRIM(RTRIM([USERFIELD1])),80)
 , [USERFIELD2]  = LEFT(LTRIM(RTRIM([USERFIELD2])),80)
 , [USERFIELD3]  = LEFT(LTRIM(RTRIM([USERFIELD3])),80)
 , [USERFIELD4]  = LEFT(LTRIM(RTRIM([USERFIELD4])),80)
 , [USERFIELD5]  = LEFT(LTRIM(RTRIM([USERFIELD5])),80)
 , [USERFIELD6]  = LEFT(LTRIM(RTRIM([USERFIELD6])),80)
 , [USERFIELD7]  = LEFT(LTRIM(RTRIM([USERFIELD7])),80)
 , [USERFIELD8]  = LEFT(LTRIM(RTRIM([USERFIELD8])),80)
 , [USERFIELD9]  = LEFT(LTRIM(RTRIM([USERFIELD9])),80)
 , [USERFIELD10]  = LEFT(LTRIM(RTRIM([USERFIELD10])),80)
 , [CAMPAIGNID]  = LEFT(LTRIM(RTRIM([CAMPAIGNID])),12)
 , [DONOTSOLICIT]  = LEFT(LTRIM(RTRIM([DONOTSOLICIT])),1)
 , [SCORE]  = LEFT(LTRIM(RTRIM([SCORE])),32)
 , [TICKER]  = LEFT(LTRIM(RTRIM([TICKER])),16)
 , [SUBTYPE]  = LEFT(LTRIM(RTRIM([SUBTYPE])),64)
 , [LEADSOURCEID]  = LEFT(LTRIM(RTRIM([LEADSOURCEID])),12)
 , [IMPORTSOURCE]  = LEFT(LTRIM(RTRIM([IMPORTSOURCE])),24)
 , [ENGINEERID]  = LEFT(LTRIM(RTRIM([ENGINEERID])),12)
 , [SALESENGINEERID]  = LEFT(LTRIM(RTRIM([SALESENGINEERID])),12)
 , [RELATIONSHIP]  
 , [LASTHISTORYBY]  = LEFT(LTRIM(RTRIM([LASTHISTORYBY])),12)
 , [LASTHISTORYDATE]  
 , [BUSINESSDESCRIPTION]  = LEFT(LTRIM(RTRIM([BUSINESSDESCRIPTION])),2000)
 , [WEBADDRESS2]  = LEFT(LTRIM(RTRIM([WEBADDRESS2])),128)
 , [WEBADDRESS3]  = LEFT(LTRIM(RTRIM([WEBADDRESS3])),128)
 , [WEBADDRESS4]  = LEFT(LTRIM(RTRIM([WEBADDRESS4])),128)
 , [GLOBALSYNCID]  = LEFT(LTRIM(RTRIM([GLOBALSYNCID])),36)
 , [APPID]  = LEFT(LTRIM(RTRIM([APPID])),12)
 , [TICK]  
 , [LASTERPSYNCUPDATE]  
 , [PRIMARYOPERATINGCOMPID]  = LEFT(LTRIM(RTRIM([PRIMARYOPERATINGCOMPID])),12)
 , [PROMOTEDTOACCOUNTING]  = LEFT(LTRIM(RTRIM([PROMOTEDTOACCOUNTING])),1)
 , [CREATESOURCE]  = LEFT(LTRIM(RTRIM([CREATESOURCE])),64)
 , [ERPEXTID]  = LEFT(LTRIM(RTRIM([ERPEXTID])),100)
 , [ERPCUSTTYPE]  = LEFT(LTRIM(RTRIM([ERPCUSTTYPE])),64)
 , [ERPCARRIERNAME]  = LEFT(LTRIM(RTRIM([ERPCARRIERNAME])),64)
 , [ERPINCOTERM]  = LEFT(LTRIM(RTRIM([ERPINCOTERM])),64)
 , [ERPTERRITORY]  = LEFT(LTRIM(RTRIM([ERPTERRITORY])),64)
 , [ERPPREFERENCE]  = LEFT(LTRIM(RTRIM([ERPPREFERENCE])),1)
 , [ERPINTERNALCUST]  = LEFT(LTRIM(RTRIM([ERPINTERNALCUST])),64)
 , [ERPLOGICALID]  = LEFT(LTRIM(RTRIM([ERPLOGICALID])),255)
 , [ERPTAXID]  = LEFT(LTRIM(RTRIM([ERPTAXID])),64)
 , [ERPPAYMENTTERM]  = LEFT(LTRIM(RTRIM([ERPPAYMENTTERM])),64)
 , [ERPSTATUSDATE]  
 , [ERPACCOUNTINGID]  = LEFT(LTRIM(RTRIM([ERPACCOUNTINGID])),22)
 , [ERPPAYMENTMETHOD]  = LEFT(LTRIM(RTRIM([ERPPAYMENTMETHOD])),64)
 , [ERPVARIATIONID]  = LEFT(LTRIM(RTRIM([ERPVARIATIONID])),22)
 , [ERPBUYERCONTACTID]  = LEFT(LTRIM(RTRIM([ERPBUYERCONTACTID])),12)
 , [ERPUNIQUEID]  = LEFT(LTRIM(RTRIM([ERPUNIQUEID])),377)
 , [ERPDEFAULTWAREHOUSEID]  = LEFT(LTRIM(RTRIM([ERPDEFAULTWAREHOUSEID])),12)
 , [ERPSHIPLINECOMPLETE]  = LEFT(LTRIM(RTRIM([ERPSHIPLINECOMPLETE])),1)
 , [ERPSHIPORDERCOMPLETE]  = LEFT(LTRIM(RTRIM([ERPSHIPORDERCOMPLETE])),1)
 , [ERPSICCODE]  = LEFT(LTRIM(RTRIM([ERPSICCODE])),64)
 , [ERPSTATUS]  = LEFT(LTRIM(RTRIM([ERPSTATUS])),64)
 , [CARRIERID]  = LEFT(LTRIM(RTRIM([CARRIERID])),12)
 , [SYNCSTATUS]  = LEFT(LTRIM(RTRIM([SYNCSTATUS])),64)
 , [LOCALIZED_ACCOUNT_NAME]  = LEFT(LTRIM(RTRIM([LOCALIZED_ACCOUNT_NAME])),255)
 , [PSSC_LAWSON_ID]  = LEFT(LTRIM(RTRIM([PSSC_LAWSON_ID])),255)
 , [PSSC_ESALES_ID]  = LEFT(LTRIM(RTRIM([PSSC_ESALES_ID])),255)
 , [PSSC_OWNER_ROLE]  = LEFT(LTRIM(RTRIM([PSSC_OWNER_ROLE])),1300)
 , [PSSC_SFDC_ACCOUNTID]  = LEFT(LTRIM(RTRIM([PSSC_SFDC_ACCOUNTID])),1300)
 , [SFDCINTERNALID]  = LEFT(LTRIM(RTRIM([SFDCINTERNALID])),18)
 , [ISDELETED]  = LEFT(LTRIM(RTRIM([ISDELETED])),1)
 , [DELETEDDATE]  
 , [FAMILYID]  = LEFT(LTRIM(RTRIM([FAMILYID])),12)
 , [AVENTIONID]  = LEFT(LTRIM(RTRIM([AVENTIONID])),36)
 , [MARKETOID]  
 , [DQMATCHPARENTID]  = LEFT(LTRIM(RTRIM([DQMATCHPARENTID])),12)
 , [DQMATCHSTATUS]  = LEFT(LTRIM(RTRIM([DQMATCHSTATUS])),64)
 , [MARKETOSTATUS]  = LEFT(LTRIM(RTRIM([MARKETOSTATUS])),12)
 , [MARKETOOPERATION]  = LEFT(LTRIM(RTRIM([MARKETOOPERATION])),12)
 , [MARKETOSYNCMESSAGE]  
 , [ERPNOTES]  
 , [ISNORMALIZED]  = LEFT(LTRIM(RTRIM([ISNORMALIZED])),1)
 , [MARKETOLASTACTION]  = LEFT(LTRIM(RTRIM([MARKETOLASTACTION])),12)
 , [ADDRESSCHANGEDATE]  
 , [PSSCPARENTACCOUNTID]  = LEFT(LTRIM(RTRIM([PSSCPARENTACCOUNTID])),12)
FROM [' + @database + '].[sysdba].[ACCOUNT] WITH (NOLOCK)
WHERE COALESCE(ModifyDate, getdate())  >= ''''' + convert(varchar(20), @min_date) + '''''



'' ) source'


--Insert the set of changed records into dbo.CRM_ACCOUNT
INSERT INTO dbo.XA_CRM_ACCOUNT
(
   [BI_load_date]
 , [sourcesystem_id]
 , [ACCOUNTID]
 , [TYPE]
 , [ACCOUNT]
 , [DIVISION]
 , [SICCODE]
 , [PARENTID]
 , [DESCRIPTION]
 , [ADDRESSID]
 , [SHIPPINGID]
 , [REGION]
 , [MAINPHONE]
 , [ALTERNATEPHONE]
 , [FAX]
 , [TOLLFREE]
 , [TOLLFREE2]
 , [OTHERPHONE1]
 , [OTHERPHONE2]
 , [OTHERPHONE3]
 , [EMAIL]
 , [EMAILTYPE]
 , [WEBADDRESS]
 , [SECCODEID]
 , [REVENUE]
 , [EMPLOYEES]
 , [INDUSTRY]
 , [CREDITRATING]
 , [NOTES]
 , [STATUS]
 , [ACCOUNTMANAGERID]
 , [REGIONALMANAGERID]
 , [DIVISIONALMANAGERID]
 , [NATIONALACCOUNT]
 , [TARGETACCOUNT]
 , [TERRITORY]
 , [CREATEUSER]
 , [MODIFYUSER]
 , [CREATEDATE]
 , [MODIFYDATE]
 , [ACCOUNT_UC]
 , [AKA]
 , [CURRENCYCODE]
 , [INTERNALACCOUNTNO]
 , [EXTERNALACCOUNTNO]
 , [PARENTACCOUNTNO]
 , [ALTERNATEKEYPREFIX]
 , [ALTERNATEKEYSUFFIX]
 , [DEFAULTTICKETSECCODEID]
 , [NOTIFYDEFECTS]
 , [NOTIFYONCLOSE]
 , [NOTIFYONSTATUS]
 , [SHORTNOTES]
 , [USERFIELD1]
 , [USERFIELD2]
 , [USERFIELD3]
 , [USERFIELD4]
 , [USERFIELD5]
 , [USERFIELD6]
 , [USERFIELD7]
 , [USERFIELD8]
 , [USERFIELD9]
 , [USERFIELD10]
 , [CAMPAIGNID]
 , [DONOTSOLICIT]
 , [SCORE]
 , [TICKER]
 , [SUBTYPE]
 , [LEADSOURCEID]
 , [IMPORTSOURCE]
 , [ENGINEERID]
 , [SALESENGINEERID]
 , [RELATIONSHIP]
 , [LASTHISTORYBY]
 , [LASTHISTORYDATE]
 , [BUSINESSDESCRIPTION]
 , [WEBADDRESS2]
 , [WEBADDRESS3]
 , [WEBADDRESS4]
 , [GLOBALSYNCID]
 , [APPID]
 , [TICK]
 , [LASTERPSYNCUPDATE]
 , [PRIMARYOPERATINGCOMPID]
 , [PROMOTEDTOACCOUNTING]
 , [CREATESOURCE]
 , [ERPEXTID]
 , [ERPCUSTTYPE]
 , [ERPCARRIERNAME]
 , [ERPINCOTERM]
 , [ERPTERRITORY]
 , [ERPPREFERENCE]
 , [ERPINTERNALCUST]
 , [ERPLOGICALID]
 , [ERPTAXID]
 , [ERPPAYMENTTERM]
 , [ERPSTATUSDATE]
 , [ERPACCOUNTINGID]
 , [ERPPAYMENTMETHOD]
 , [ERPVARIATIONID]
 , [ERPBUYERCONTACTID]
 , [ERPUNIQUEID]
 , [ERPDEFAULTWAREHOUSEID]
 , [ERPSHIPLINECOMPLETE]
 , [ERPSHIPORDERCOMPLETE]
 , [ERPSICCODE]
 , [ERPSTATUS]
 , [CARRIERID]
 , [SYNCSTATUS]
 , [LOCALIZED_ACCOUNT_NAME]
 , [PSSC_LAWSON_ID]
 , [PSSC_ESALES_ID]
 , [PSSC_OWNER_ROLE]
 , [PSSC_SFDC_ACCOUNTID]
 , [SFDCINTERNALID]
 , [ISDELETED]
 , [DELETEDDATE]
 , [FAMILYID]
 , [AVENTIONID]
 , [MARKETOID]
 , [DQMATCHPARENTID]
 , [DQMATCHSTATUS]
 , [MARKETOSTATUS]
 , [MARKETOOPERATION]
 , [MARKETOSYNCMESSAGE]
 , [ERPNOTES]
 , [ISNORMALIZED]
 , [MARKETOLASTACTION]
 , [ADDRESSCHANGEDATE]
 , [PSSCPARENTACCOUNTID]
 )
EXECUTE (@cmd)


SET  @rowcount = @@ROWCOUNT
SET  @countDelta = @rowcount

EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , @rowcount





--Delete records no longer in the source system


SET  @message  = 'Clear Records in EDW_STAGE'
SET  @type   = 'DELETE'
SET  @rowcount  = 0
EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , @rowcount

DELETE FROM base
 FROM dbo.CRM_ACCOUNT base WITH (NOLOCK)
 INNER JOIN dbo.XD_CRM_ACCOUNT keys WITH (NOLOCK)
  ON base.[ACCOUNTID] = keys.[ACCOUNTID]







  AND keys.sourcesystem_id  = base.sourcesystem_id
  AND keys.sourcesystem_id  = @sourcesystem_id


EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , @@ROWCOUNT


SET  @message  = 'Clear Records in EDW_STAGE'
SET  @type   = 'DELETE'
SET  @rowcount  = 0
EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , @rowcount

DELETE FROM base
 FROM dbo.CRM_ACCOUNT base WITH (NOLOCK)
 INNER JOIN dbo.XA_CRM_ACCOUNT keys WITH (NOLOCK)
  ON base.[ACCOUNTID] = keys.[ACCOUNTID]







  AND keys.sourcesystem_id  = base.sourcesystem_id
  AND keys.sourcesystem_id  = @sourcesystem_id


EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , @@ROWCOUNT


--Update the load_date for all reamining records


SET  @message  = 'LOAD DATE ON EDW_STAGE'
SET  @type   = 'UPDATE'
SET  @rowcount  = 0
EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , @rowcount

--UPDATE dbo.CRM_ACCOUNT
--SET  load_date  = @load_date
--WHERE load_date  != @load_date


EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , @@ROWCOUNT


--Insert the records from the delta table


SET  @message  = 'New Records in EDW_STAGE'
SET  @type   = 'INSERT'
SET  @rowcount  = 0
EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , @rowcount

INSERT INTO dbo.CRM_ACCOUNT
SELECT new_recs.*
FROM dbo.XA_CRM_ACCOUNT new_recs WITH (NOLOCK)
--WHERE load_date  = @load_date
--AND new_recs.sourcesystem_id  = @sourcesystem_id

SET  @rowcount=@@ROWCOUNT

EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , @rowcount

-- Get a count of records in the EDW_STAGE table
SET  @message  = 'Count Records in EDW_STAGE'
SET  @type   = 'COUNT'
EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , 0

SELECT @countDest  = count(*)
FROM dbo.CRM_ACCOUNT WITH (NOLOCK)
WHERE sourcesystem_id  = @sourcesystem_id

EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , @countDest



-- Section to catch any missing records (in the event of an empty table or gap in loading times )
/******************************************************************************************************************************/


SET  @message  = 'ADD Missing Records'
SET  @type   = 'INSERT'
SET  @rowcount  = 0
EXEC @log_step = dbo.logProcessActivity
        @log_step
      , @proc_name
      , @step_name
      , @message
      , @type
      , @rowcount


IF @countSource  > @countDest
BEGIN --Add Missing Records

   SET  @rowcount = 0

   SET  @message  = 'Discover Missing Records'
   SET  @type   = 'INSERT'
   SET  @rowcount  = 0
   EXEC @log_value = dbo.logProcessActivity
           @log_value
         , @proc_name
         , @step_name
         , @message
         , @type
         , @rowcount




   EXEC @log_value = dbo.logProcessActivity
           @log_value
         , @proc_name
         , @step_name
         , @message
         , @type
         , @rowcount


   SET  @message  = 'Add Missing Records in EDW_STAGE'
   SET  @type   = 'INSERT'
   SET  @rowcount  = 0
   EXEC @log_value = dbo.logProcessActivity
           @log_value
         , @proc_name
         , @step_name
         , @message
         , @type
         , @rowcount


   BEGIN

    -- Insert anything new into the EXT OP table that's come up

   SET  @cmd = 'SELECT BI_Load_Date = ''' + convert(varchar(40), @loaddttm) + '''
        , sourcesystem_id  = ''' + convert(varchar(20), @sourcesystem_id) + '''
        ,  source.*
   FROM OPENQUERY( ' + @server + ', ''SELECT
         [ACCOUNTID]  = LEFT(LTRIM(RTRIM([ACCOUNTID])),12)
         , [TYPE]  = LEFT(LTRIM(RTRIM([TYPE])),64)
         , [ACCOUNT]  = LEFT(LTRIM(RTRIM([ACCOUNT])),255)
         , [DIVISION]  = LEFT(LTRIM(RTRIM([DIVISION])),64)
         , [SICCODE]  = LEFT(LTRIM(RTRIM([SICCODE])),64)
         , [PARENTID]  = LEFT(LTRIM(RTRIM([PARENTID])),12)
         , [DESCRIPTION]  = LEFT(LTRIM(RTRIM([DESCRIPTION])),128)
         , [ADDRESSID]  = LEFT(LTRIM(RTRIM([ADDRESSID])),12)
         , [SHIPPINGID]  = LEFT(LTRIM(RTRIM([SHIPPINGID])),12)
         , [REGION]  = LEFT(LTRIM(RTRIM([REGION])),64)
         , [MAINPHONE]  = LEFT(LTRIM(RTRIM([MAINPHONE])),32)
         , [ALTERNATEPHONE]  = LEFT(LTRIM(RTRIM([ALTERNATEPHONE])),32)
         , [FAX]  = LEFT(LTRIM(RTRIM([FAX])),32)
         , [TOLLFREE]  = LEFT(LTRIM(RTRIM([TOLLFREE])),32)
         , [TOLLFREE2]  = LEFT(LTRIM(RTRIM([TOLLFREE2])),32)
         , [OTHERPHONE1]  = LEFT(LTRIM(RTRIM([OTHERPHONE1])),32)
         , [OTHERPHONE2]  = LEFT(LTRIM(RTRIM([OTHERPHONE2])),32)
         , [OTHERPHONE3]  = LEFT(LTRIM(RTRIM([OTHERPHONE3])),32)
         , [EMAIL]  = LEFT(LTRIM(RTRIM([EMAIL])),128)
         , [EMAILTYPE]  = LEFT(LTRIM(RTRIM([EMAILTYPE])),64)
         , [WEBADDRESS]  = LEFT(LTRIM(RTRIM([WEBADDRESS])),128)
         , [SECCODEID]  = LEFT(LTRIM(RTRIM([SECCODEID])),12)
         , [REVENUE]  
         , [EMPLOYEES]  
         , [INDUSTRY]  = LEFT(LTRIM(RTRIM([INDUSTRY])),64)
         , [CREDITRATING]  = LEFT(LTRIM(RTRIM([CREDITRATING])),64)
         , [NOTES]  
         , [STATUS]  = LEFT(LTRIM(RTRIM([STATUS])),64)
         , [ACCOUNTMANAGERID]  = LEFT(LTRIM(RTRIM([ACCOUNTMANAGERID])),12)
         , [REGIONALMANAGERID]  = LEFT(LTRIM(RTRIM([REGIONALMANAGERID])),12)
         , [DIVISIONALMANAGERID]  = LEFT(LTRIM(RTRIM([DIVISIONALMANAGERID])),12)
         , [NATIONALACCOUNT]  = LEFT(LTRIM(RTRIM([NATIONALACCOUNT])),1)
         , [TARGETACCOUNT]  = LEFT(LTRIM(RTRIM([TARGETACCOUNT])),1)
         , [TERRITORY]  = LEFT(LTRIM(RTRIM([TERRITORY])),64)
         , [CREATEUSER]  = LEFT(LTRIM(RTRIM([CREATEUSER])),12)
         , [MODIFYUSER]  = LEFT(LTRIM(RTRIM([MODIFYUSER])),12)
         , [CREATEDATE]  
         , [MODIFYDATE]  
         , [ACCOUNT_UC]  = LEFT(LTRIM(RTRIM([ACCOUNT_UC])),255)
         , [AKA]  = LEFT(LTRIM(RTRIM([AKA])),64)
         , [CURRENCYCODE]  = LEFT(LTRIM(RTRIM([CURRENCYCODE])),64)
         , [INTERNALACCOUNTNO]  = LEFT(LTRIM(RTRIM([INTERNALACCOUNTNO])),32)
         , [EXTERNALACCOUNTNO]  = LEFT(LTRIM(RTRIM([EXTERNALACCOUNTNO])),32)
         , [PARENTACCOUNTNO]  = LEFT(LTRIM(RTRIM([PARENTACCOUNTNO])),32)
         , [ALTERNATEKEYPREFIX]  = LEFT(LTRIM(RTRIM([ALTERNATEKEYPREFIX])),64)
         , [ALTERNATEKEYSUFFIX]  = LEFT(LTRIM(RTRIM([ALTERNATEKEYSUFFIX])),64)
         , [DEFAULTTICKETSECCODEID]  = LEFT(LTRIM(RTRIM([DEFAULTTICKETSECCODEID])),12)
         , [NOTIFYDEFECTS]  = LEFT(LTRIM(RTRIM([NOTIFYDEFECTS])),1)
         , [NOTIFYONCLOSE]  = LEFT(LTRIM(RTRIM([NOTIFYONCLOSE])),1)
         , [NOTIFYONSTATUS]  = LEFT(LTRIM(RTRIM([NOTIFYONSTATUS])),1)
         , [SHORTNOTES]  = LEFT(LTRIM(RTRIM([SHORTNOTES])),255)
         , [USERFIELD1]  = LEFT(LTRIM(RTRIM([USERFIELD1])),80)
         , [USERFIELD2]  = LEFT(LTRIM(RTRIM([USERFIELD2])),80)
         , [USERFIELD3]  = LEFT(LTRIM(RTRIM([USERFIELD3])),80)
         , [USERFIELD4]  = LEFT(LTRIM(RTRIM([USERFIELD4])),80)
         , [USERFIELD5]  = LEFT(LTRIM(RTRIM([USERFIELD5])),80)
         , [USERFIELD6]  = LEFT(LTRIM(RTRIM([USERFIELD6])),80)
         , [USERFIELD7]  = LEFT(LTRIM(RTRIM([USERFIELD7])),80)
         , [USERFIELD8]  = LEFT(LTRIM(RTRIM([USERFIELD8])),80)
         , [USERFIELD9]  = LEFT(LTRIM(RTRIM([USERFIELD9])),80)
         , [USERFIELD10]  = LEFT(LTRIM(RTRIM([USERFIELD10])),80)
         , [CAMPAIGNID]  = LEFT(LTRIM(RTRIM([CAMPAIGNID])),12)
         , [DONOTSOLICIT]  = LEFT(LTRIM(RTRIM([DONOTSOLICIT])),1)
         , [SCORE]  = LEFT(LTRIM(RTRIM([SCORE])),32)
         , [TICKER]  = LEFT(LTRIM(RTRIM([TICKER])),16)
         , [SUBTYPE]  = LEFT(LTRIM(RTRIM([SUBTYPE])),64)
         , [LEADSOURCEID]  = LEFT(LTRIM(RTRIM([LEADSOURCEID])),12)
         , [IMPORTSOURCE]  = LEFT(LTRIM(RTRIM([IMPORTSOURCE])),24)
         , [ENGINEERID]  = LEFT(LTRIM(RTRIM([ENGINEERID])),12)
         , [SALESENGINEERID]  = LEFT(LTRIM(RTRIM([SALESENGINEERID])),12)
         , [RELATIONSHIP]  
         , [LASTHISTORYBY]  = LEFT(LTRIM(RTRIM([LASTHISTORYBY])),12)
         , [LASTHISTORYDATE]  
         , [BUSINESSDESCRIPTION]  = LEFT(LTRIM(RTRIM([BUSINESSDESCRIPTION])),2000)
         , [WEBADDRESS2]  = LEFT(LTRIM(RTRIM([WEBADDRESS2])),128)
         , [WEBADDRESS3]  = LEFT(LTRIM(RTRIM([WEBADDRESS3])),128)
         , [WEBADDRESS4]  = LEFT(LTRIM(RTRIM([WEBADDRESS4])),128)
         , [GLOBALSYNCID]  = LEFT(LTRIM(RTRIM([GLOBALSYNCID])),36)
         , [APPID]  = LEFT(LTRIM(RTRIM([APPID])),12)
         , [TICK]  
         , [LASTERPSYNCUPDATE]  
         , [PRIMARYOPERATINGCOMPID]  = LEFT(LTRIM(RTRIM([PRIMARYOPERATINGCOMPID])),12)
         , [PROMOTEDTOACCOUNTING]  = LEFT(LTRIM(RTRIM([PROMOTEDTOACCOUNTING])),1)
         , [CREATESOURCE]  = LEFT(LTRIM(RTRIM([CREATESOURCE])),64)
         , [ERPEXTID]  = LEFT(LTRIM(RTRIM([ERPEXTID])),100)
         , [ERPCUSTTYPE]  = LEFT(LTRIM(RTRIM([ERPCUSTTYPE])),64)
         , [ERPCARRIERNAME]  = LEFT(LTRIM(RTRIM([ERPCARRIERNAME])),64)
         , [ERPINCOTERM]  = LEFT(LTRIM(RTRIM([ERPINCOTERM])),64)
         , [ERPTERRITORY]  = LEFT(LTRIM(RTRIM([ERPTERRITORY])),64)
         , [ERPPREFERENCE]  = LEFT(LTRIM(RTRIM([ERPPREFERENCE])),1)
         , [ERPINTERNALCUST]  = LEFT(LTRIM(RTRIM([ERPINTERNALCUST])),64)
         , [ERPLOGICALID]  = LEFT(LTRIM(RTRIM([ERPLOGICALID])),255)
         , [ERPTAXID]  = LEFT(LTRIM(RTRIM([ERPTAXID])),64)
         , [ERPPAYMENTTERM]  = LEFT(LTRIM(RTRIM([ERPPAYMENTTERM])),64)
         , [ERPSTATUSDATE]  
         , [ERPACCOUNTINGID]  = LEFT(LTRIM(RTRIM([ERPACCOUNTINGID])),22)
         , [ERPPAYMENTMETHOD]  = LEFT(LTRIM(RTRIM([ERPPAYMENTMETHOD])),64)
         , [ERPVARIATIONID]  = LEFT(LTRIM(RTRIM([ERPVARIATIONID])),22)
         , [ERPBUYERCONTACTID]  = LEFT(LTRIM(RTRIM([ERPBUYERCONTACTID])),12)
         , [ERPUNIQUEID]  = LEFT(LTRIM(RTRIM([ERPUNIQUEID])),377)
         , [ERPDEFAULTWAREHOUSEID]  = LEFT(LTRIM(RTRIM([ERPDEFAULTWAREHOUSEID])),12)
         , [ERPSHIPLINECOMPLETE]  = LEFT(LTRIM(RTRIM([ERPSHIPLINECOMPLETE])),1)
         , [ERPSHIPORDERCOMPLETE]  = LEFT(LTRIM(RTRIM([ERPSHIPORDERCOMPLETE])),1)
         , [ERPSICCODE]  = LEFT(LTRIM(RTRIM([ERPSICCODE])),64)
         , [ERPSTATUS]  = LEFT(LTRIM(RTRIM([ERPSTATUS])),64)
         , [CARRIERID]  = LEFT(LTRIM(RTRIM([CARRIERID])),12)
         , [SYNCSTATUS]  = LEFT(LTRIM(RTRIM([SYNCSTATUS])),64)
         , [LOCALIZED_ACCOUNT_NAME]  = LEFT(LTRIM(RTRIM([LOCALIZED_ACCOUNT_NAME])),255)
         , [PSSC_LAWSON_ID]  = LEFT(LTRIM(RTRIM([PSSC_LAWSON_ID])),255)
         , [PSSC_ESALES_ID]  = LEFT(LTRIM(RTRIM([PSSC_ESALES_ID])),255)
         , [PSSC_OWNER_ROLE]  = LEFT(LTRIM(RTRIM([PSSC_OWNER_ROLE])),1300)
         , [PSSC_SFDC_ACCOUNTID]  = LEFT(LTRIM(RTRIM([PSSC_SFDC_ACCOUNTID])),1300)
         , [SFDCINTERNALID]  = LEFT(LTRIM(RTRIM([SFDCINTERNALID])),18)
         , [ISDELETED]  = LEFT(LTRIM(RTRIM([ISDELETED])),1)
         , [DELETEDDATE]  
         , [FAMILYID]  = LEFT(LTRIM(RTRIM([FAMILYID])),12)
         , [AVENTIONID]  = LEFT(LTRIM(RTRIM([AVENTIONID])),36)
         , [MARKETOID]  
         , [DQMATCHPARENTID]  = LEFT(LTRIM(RTRIM([DQMATCHPARENTID])),12)
         , [DQMATCHSTATUS]  = LEFT(LTRIM(RTRIM([DQMATCHSTATUS])),64)
         , [MARKETOSTATUS]  = LEFT(LTRIM(RTRIM([MARKETOSTATUS])),12)
         , [MARKETOOPERATION]  = LEFT(LTRIM(RTRIM([MARKETOOPERATION])),12)
         , [MARKETOSYNCMESSAGE]  
         , [ERPNOTES]  
         , [ISNORMALIZED]  = LEFT(LTRIM(RTRIM([ISNORMALIZED])),1)
         , [MARKETOLASTACTION]  = LEFT(LTRIM(RTRIM([MARKETOLASTACTION])),12)
         , [ADDRESSCHANGEDATE]  
         , [PSSCPARENTACCOUNTID]  = LEFT(LTRIM(RTRIM([PSSCPARENTACCOUNTID])),12)
    FROM [' + @database + '].[sysdba].[ACCOUNT] src  WITH (NOLOCK)'') source
    LEFT JOIN dbo.CRM_ACCOUNT base WITH (NOLOCK)
    ON source.[ACCOUNTID] = base.[ACCOUNTID]
    
    
    
    
    
    
    
    AND base.sourcesystem_id  = ''' + convert(varchar(20), @sourcesystem_id) + '''
    WHERE base.[ACCOUNTID] IS NULL'
    /*INSERT INTO dbo.CRM_ACCOUNT
    (
      [BI_load_date] 
      ,[sourcesystem_id] 
      ,[ACCOUNTID] 
      ,[TYPE] 
      ,[ACCOUNT] 
      ,[DIVISION] 
      ,[SICCODE] 
      ,[PARENTID] 
      ,[DESCRIPTION] 
      ,[ADDRESSID] 
      ,[SHIPPINGID] 
      ,[REGION] 
      ,[MAINPHONE] 
      ,[ALTERNATEPHONE] 
      ,[FAX] 
      ,[TOLLFREE] 
      ,[TOLLFREE2] 
      ,[OTHERPHONE1] 
      ,[OTHERPHONE2] 
      ,[OTHERPHONE3] 
      ,[EMAIL] 
      ,[EMAILTYPE] 
      ,[WEBADDRESS] 
      ,[SECCODEID] 
      ,[REVENUE] 
      ,[EMPLOYEES] 
      ,[INDUSTRY] 
      ,[CREDITRATING] 
      ,[NOTES] 
      ,[STATUS] 
      ,[ACCOUNTMANAGERID] 
      ,[REGIONALMANAGERID] 
      ,[DIVISIONALMANAGERID] 
      ,[NATIONALACCOUNT] 
      ,[TARGETACCOUNT] 
      ,[TERRITORY] 
      ,[CREATEUSER] 
      ,[MODIFYUSER] 
      ,[CREATEDATE] 
      ,[MODIFYDATE] 
      ,[ACCOUNT_UC] 
      ,[AKA] 
      ,[CURRENCYCODE] 
      ,[INTERNALACCOUNTNO] 
      ,[EXTERNALACCOUNTNO] 
      ,[PARENTACCOUNTNO] 
      ,[ALTERNATEKEYPREFIX] 
      ,[ALTERNATEKEYSUFFIX] 
      ,[DEFAULTTICKETSECCODEID] 
      ,[NOTIFYDEFECTS] 
      ,[NOTIFYONCLOSE] 
      ,[NOTIFYONSTATUS] 
      ,[SHORTNOTES] 
      ,[USERFIELD1] 
      ,[USERFIELD2] 
      ,[USERFIELD3] 
      ,[USERFIELD4] 
      ,[USERFIELD5] 
      ,[USERFIELD6] 
      ,[USERFIELD7] 
      ,[USERFIELD8] 
      ,[USERFIELD9] 
      ,[USERFIELD10] 
      ,[CAMPAIGNID] 
      ,[DONOTSOLICIT] 
      ,[SCORE] 
      ,[TICKER] 
      ,[SUBTYPE] 
      ,[LEADSOURCEID] 
      ,[IMPORTSOURCE] 
      ,[ENGINEERID] 
      ,[SALESENGINEERID] 
      ,[RELATIONSHIP] 
      ,[LASTHISTORYBY] 
      ,[LASTHISTORYDATE] 
      ,[BUSINESSDESCRIPTION] 
      ,[WEBADDRESS2] 
      ,[WEBADDRESS3] 
      ,[WEBADDRESS4] 
      ,[GLOBALSYNCID] 
      ,[APPID] 
      ,[TICK] 
      ,[LASTERPSYNCUPDATE] 
      ,[PRIMARYOPERATINGCOMPID] 
      ,[PROMOTEDTOACCOUNTING] 
      ,[CREATESOURCE] 
      ,[ERPEXTID] 
      ,[ERPCUSTTYPE] 
      ,[ERPCARRIERNAME] 
      ,[ERPINCOTERM] 
      ,[ERPTERRITORY] 
      ,[ERPPREFERENCE] 
      ,[ERPINTERNALCUST] 
      ,[ERPLOGICALID] 
      ,[ERPTAXID] 
      ,[ERPPAYMENTTERM] 
      ,[ERPSTATUSDATE] 
      ,[ERPACCOUNTINGID] 
      ,[ERPPAYMENTMETHOD] 
      ,[ERPVARIATIONID] 
      ,[ERPBUYERCONTACTID] 
      ,[ERPUNIQUEID] 
      ,[ERPDEFAULTWAREHOUSEID] 
      ,[ERPSHIPLINECOMPLETE] 
      ,[ERPSHIPORDERCOMPLETE] 
      ,[ERPSICCODE] 
      ,[ERPSTATUS] 
      ,[CARRIERID] 
      ,[SYNCSTATUS] 
      ,[LOCALIZED_ACCOUNT_NAME] 
      ,[PSSC_LAWSON_ID] 
      ,[PSSC_ESALES_ID] 
      ,[PSSC_OWNER_ROLE] 
      ,[PSSC_SFDC_ACCOUNTID] 
      ,[SFDCINTERNALID] 
      ,[ISDELETED] 
      ,[DELETEDDATE] 
      ,[FAMILYID] 
      ,[AVENTIONID] 
      ,[MARKETOID] 
      ,[DQMATCHPARENTID] 
      ,[DQMATCHSTATUS] 
      ,[MARKETOSTATUS] 
      ,[MARKETOOPERATION] 
      ,[MARKETOSYNCMESSAGE] 
      ,[ERPNOTES] 
      ,[ISNORMALIZED] 
      ,[MARKETOLASTACTION] 
      ,[ADDRESSCHANGEDATE] 
      ,[PSSCPARENTACCOUNTID] 
    )
    --EXECUTE (@cmd)*/

    SET  @rowcount = @@ROWCOUNT

    EXEC @log_value = dbo.logProcessActivity
            @log_value
          , @proc_name
          , @step_name
          , @message
          , @type
          , @rowcount

   END

END --Add Missing Records

SET  @message  = 'ADD Missing Records'
SET  @type   = 'INSERT'
EXEC @log_step  = dbo.logProcessActivity
        @log_step
      , @proc_name
      , @step_name
      , @message
      , @type
      , @rowcount


/******************************************************************************************************************************/


SET  @message  = 'Drop Temporary Tables '
SET  @type   = 'INSERT'
SET  @rowcount  = 0
EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , @rowcount


IF @cleanupTempTables > 0
BEGIN --Temp Table Cleanup
 BEGIN TRY
  DROP TABLE XA_CRM_ACCOUNT
 END TRY
 BEGIN CATCH
  PRINT 'Unable to drop table XA_CRM_ACCOUNT'
 END CATCH


 BEGIN TRY
  DROP TABLE XD_CRM_ACCOUNT
 END TRY
 BEGIN CATCH
  PRINT 'Unable to drop table XD_CRM_ACCOUNT'
 END CATCH
END --Temp Table Cleanup


EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , @rowcount




SET  @message  = 'Count Records for Comparison'
SET  @type   = 'COUNT'
SET  @rowcount  = 0
EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , @rowcount

EXECUTE dbo.logTableCounts @servername = @@SERVERNAME, @dbname = 'EDW_STAGE', @tableName = 'XA_CRM_ACCOUNT', @count = @countDelta, @desc = 'DELTA', @load_date = @load_date
   , @sourcesystem_id = @sourcesystem_id
EXECUTE dbo.logTableCounts @servername = @server, @dbname = @database , @tableName = 'ACCOUNT',@count = @countSource, @desc = 'SOURCE', @load_date = @load_date
   , @sourcesystem_id = @sourcesystem_id
EXECUTE dbo.logTableCounts @servername = @@SERVERNAME, @dbname = 'EDW_STAGE', @tableName = 'CRM_ACCOUNT', @count = @countDest, @desc = 'FINAL', @load_date = @load_date
   , @sourcesystem_id = @sourcesystem_id


EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , @rowcount


SET  @proc_name  = OBJECT_NAME(@@PROCID)

SET  @step_name  = 'PROCEDURE'
SET  @message  = 'PROCEDURE'
SET  @type   = 'PROCEDURE'
SET  @rowcount  = 0
EXEC @log_v_main = dbo.logProcessActivity
        @log_v_main
      , @proc_name
      , @step_name
      , @message
      , @type
      , @rowcount
