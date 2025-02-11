USE [EDW_STAGE]
GO
/****** Object:  StoredProcedure [dbo].[delta_import_crm_PSSCaccount2]    Script Date: 12/27/2023 9:53:20 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


----------------------------------------------------------
ALTER PROCEDURE [dbo].[delta_import_crm_PSSCaccount2]
 @load_date [smalldatetime] = NULL,
 @server [varchar](50) = 'SRV_ICRM',
 @owner [varchar](50) = 'sysdba',
 @database [varchar](50) = 'SalesLogix',
 @sourcesystem [varchar](50) = 'CRM',
 @cleanupTempTables [int] = 1,
 @debug [int] = 0,
 @min_date [datetime] = NULL
WITH EXECUTE AS CALLER
AS
/***************************************************************************************************************
* Procedure:  delta_import_crm_PSSCaccount
 * Purpose:  To import Data using a delta methodololgy
 * Author:   PSSC\mgc
 * CreateDate:  07/19/2018
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
EXEC @return_value = [dbo].delta_import_crm_PSSCaccount2
  @load_date  = @load_date,
  @server   = N'SRV_ICRM',
  @owner   = N'sysdba',
  @database  = N'SalesLogix_R',
  @sourcesystem = N'CRM',
  @debug   = 0,
  @min_date  = @min_date
SELECT 'Return Value' = @return_value

 History of modifications:

 Name					Date				Project						Remarks
MGC					12/03/2019			EDW Maintenance				Original Procedure
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
--DECLARE @sourcesystem_id int


 /**** CRM_PSSCACCOUNT ****/

SET  @countSource = 0
SET  @countDest  = 0
SELECT  @sourcesystem_id = sourcesystem_id FROM dbo.dim_SourceSystems WHERE sourcesystem = @sourcesystem


IF  @load_date IS NULL OR @load_date = ''
   SELECT @load_date = [loadDateDt] FROM [dbo].[dim_LoadDate]
SELECT @loaddttm  = [currentDttm] FROM [dbo].[dim_LoadDate]

IF  @min_date IS NULL OR @min_date = ''
 BEGIN
  IF 'ModifyDate' != 'NULL'
   SELECT @datevalue1 = max(ModifyDate) FROM dbo.CRM_PSSCACCOUNT2 WITH (NOLOCK) WHERE ModifyDate < = getdate()
  ELSE
   SELECT @datevalue1 = dateadd(yy, -30, @load_date)

  IF 'NULL' != 'NULL'
   SELECT @datevalue2 = max(getdate()) FROM dbo.CRM_PSSCACCOUNT2 WITH (NOLOCK) WHERE ModifyDate < = getdate()
  ELSE
   SELECT @datevalue2 = @datevalue1

  IF 'NULL' != 'NULL'
   SELECT @datevalue3 = max(getdate()) FROM dbo.CRM_PSSCACCOUNT2 WITH (NOLOCK) WHERE ModifyDate < = getdate()
  ELSE
   SELECT @datevalue3 = @datevalue1

  IF 'NULL' != 'NULL'
   SELECT @datevalue4 = max(getdate()) FROM dbo.CRM_PSSCACCOUNT2 WITH (NOLOCK) WHERE ModifyDate < = getdate()
  ELSE
   SELECT @datevalue4 = @datevalue1


  SELECT @min_date = DATEADD(HH, -2, COALESCE(dbo.fn_GetMaxDttm( @datevalue1, dbo.fn_GetMaxDttm( @datevalue2, dbo.fn_GetMaxDttm( @datevalue3, @datevalue4) ) ), dateadd(dd, -200, getdate())))

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



SET  @step_name  = 'CRM_PSSCACCOUNT2'
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
SET  @tbl = 'CRM_PSSCACCOUNT2'
BEGIN
   EXEC  dbo.cloneTable
      @source_server  = N'',
      @source_db   = N'EDW_STAGE',
      @source_table  = 'CRM_PSSCACCOUNT2',
      @source_owner  = 'dbo',
      @dest_db   = N'EDW_STAGE',
      @dest_Owner   = 'dbo',
      @table_suffix  = N'',
      @table_prefix  = N'XD_',
      @force_load_date = 0,
      @debug    = 0
    --SET @cmd = 'DELETE FROM dbo.CRM_PSSCACCOUNT WHERE load_date < ( SELECT max(load_date) FROM dbo.CRM_PSSCACCOUNT WITH (NOLOCK))'
    --EXECUTE (@cmd)
END



BEGIN
   EXEC  dbo.cloneTable
      @source_server  = N'',
      @source_db   = N'EDW_STAGE',
      @source_table  = 'CRM_PSSCACCOUNT2',
      @source_owner  = 'dbo',
      @dest_db   = N'EDW_STAGE',
      @dest_Owner   = 'dbo',
      @table_suffix  = N'',
      @table_prefix  = N'XA_',
      @force_load_date = 0,
      @debug    = 0
    --SET @cmd = 'DELETE FROM dbo.CRM_PSSCACCOUNT WHERE load_date < ( SELECT max(load_date) FROM dbo.CRM_PSSCACCOUNT WITH (NOLOCK))'
    --EXECUTE (@cmd)
END



EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , @@ROWCOUNT




SET  @message	= 'COUNT Records in Source'
SET  @type		= 'COUNT'
SET  @rowcount  = 0
EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , @rowcount


IF @debug = 1
BEGIN
	EXECUTE dbo.logTableCounts @servername = @server , @dbname = @database, @tablename = 'PSSCACCOUNT', @count = NULL, @desc = 'SOURCE'
	SELECT @countSource = .dbo.fn_getlastcount (@server, @database, 'PSSCACCOUNT', COALESCE(@sourcesystem_id, 0) )
END


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


SET  @cmd = 'INSERT INTO dbo.XD_CRM_PSSCACCOUNT2' + char(10)
SET  @cmd = @cmd + 'SELECT dw.*' + char(10)
SET  @cmd = @cmd + ' FROM dbo.CRM_PSSCACCOUNT2 dw' + char(10)
SET  @cmd = @cmd + ' LEFT JOIN OPENQUERY(' + @server + ', ''SELECT [ACCOUNTID]' + char(10)
SET  @cmd = @cmd + ' FROM [' + @database + '].[sysdba].[PSSCACCOUNT]'') src' + char(10)
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

SET  @cmd = 'SELECT BI_Load_Date = ''' + convert(varchar(20), @load_date) + '''
  , sourcesystem_id  = ''' + convert(varchar(20), @sourcesystem_id) + '''
  , source.*
FROM OPENQUERY(' + @server + ', ''SELECT 
	 [ACCOUNTID]
      ,[CREATEDATE]
      ,[MODIFYDATE]
	  ,[KEYACCINDOWNERID]
      ,[KEYACCBIRSTOWNERID]
      ,[KEYACCCXOWNERID]
      ,[KEYACCEPMOWNERID]
      ,[KEYACCEAMOWNERID]
      ,[KEYACCHCMOWNERID]
      ,[KEYACCINDACCCATEGORY]
      ,[KEYACCBIRSTACCCATEGORY]
      ,[KEYACCCXACCCATEGORY]
      ,[KEYACCEPMACCCATEGORY]
      ,[KEYACCEAMACCCATEGORY]
      ,[KEYACCHCMACCCATEGORY]
      ,[KEYACCINDMODIFYDATE]
      ,[KEYACCBIRSTMODIFYDATE]
      ,[KEYACCCXMODIFYDATE]
      ,[KEYACCEPMMODIFYDATE]
      ,[KEYACCEAMMODIFYDATE]
      ,[KEYACCHCMMODIFYDATE]
      ,[CSM]
      ,[STXMODIFYDATE]
      ,[KEYACCOWFMMODIFYDATE]
      ,[KEYACCWFMACCCATEGORY]
      ,[KEYACCWFMOWNERID]
      ,[KEYACCBIRSTACTIVITYDATE]
      ,[KEYACCCXACTIVITYDATE]
      ,[KEYACCEPMACTIVITYDATE]
      ,[KEYACCEAMACTIVITYDATE]
      ,[KEYACCWFMACTIVITYDATE]
      ,[KEYACCHCMACTIVITYDATE]
      ,[CUSTOMERSUCCESSMANAGERID]
      ,[ACTIVEELITESKU]
      ,[SOFTRAXSHIPTOPHONE]
      ,[SOFTRAXSHIPTOCONTACT]
      ,[SOFTRAXCONTACTEMAIL]
      ,[SOFTRAXMAINTENANCERENEWALFEE]
      ,[SUCCESSUPDATEDON]
      ,[GTNPLATFORMORG]
      ,[GTNCOUNTERPARTY]
      ,[GTNFSPACCOUNT]
      ,[KEYACCPLMOWNERID]
      ,[KEYACCTSOWNERID]
      ,[KEYACCCPQOWNERID]
      ,[KEYACCPLMACCCATEGORY]
      ,[KEYACCTSACCCATEGORY]
      ,[KEYACCCPQACCCATEGORY]
      ,[KEYACCPLMMODIFYDATE]
      ,[KEYACCTSMODIFYDATE]
      ,[KEYACCCPQMODIFYDATE]
      ,[KEYACCPLMACTIVITYDATE]
      ,[KEYACCTSACTIVITYDATE]
      ,[KEYACCCPQACTIVITYDATE]
      ,[ACCOUNTHEALTHSTATUS]
      ,[DRAGONSLAYERTARGET]
      ,[ATTENDEDPSSCUM]
      ,[COMPLETEDDRAGONSLAYERPRE]
      ,[GTNFSPPORTALACCESS]
      ,[BIRSTCSMID]
      ,[GTNBDGROUP]
      ,[KEYACCCLOVERLEAFACCCATEGORY]
      ,[KEYACCCLOVERLEAFMODIFYDATE]
      ,[KEYACCCLOVERLEAFOWNERID]
      ,[KEYACCCLOVERLEAFACTIVITYDATE]
      ,[RDCREMARKS]
      ,[RDCSENTDATE]
      ,[SENTTORDC]
      ,[SNAPSHOTDESCRIPTION]
      ,[GENERALNOTES]
      ,[VALUEANDADOPTION]
      ,[PEOPLEANDENDUSERS]
      ,[RISK]
      ,[FUTURE]
      ,[PRIMARY_INSIDE_SALES_REPID]
      ,[NOTREFERENCEABLEREASON]
      ,[REFERENCEAUDITCOMMENT]
      ,[REFERENCEAUDITSTATUS]
      ,[ISCUSTOMERREFERENCEABLE]
      ,[REFERENCEAUDITCONTACTID]
      ,[MRNREQUIRED]
      ,[RENEWALPAYMENTTERMS]
      ,[RENEWALPAYMENTMETHOD]
      ,[PLAYBOOKSSTEPNUMBER]
      ,[PLAYBOOKSPLAYINFOUPDATED]
      ,[PLAYBOOKSPLAYSTATUS]
      ,[PLAYBOOKSPLAYNAME]
      ,[NEXTCALLDATE]
      ,[DUEDILIGENCECOMPLETE]
      ,[CSREVATRISKSTATUS]
      ,[CSCUSTHEALTHREASON1]
      ,[CSCUSTHEALTHREASON2]
      ,[CSCUSTHEALTHREASON3]
      ,[CSREVATRISKHEALTHREASON1]
      ,[CSREVATRISKHEALTHREASON2]
      ,[CSREVATRISKHEALTHREASON3]
      ,[CSREVATRISKCURRENCYUSD]
      ,[CSCUSTOMERHEALTHSTATUS]
      ,[ANNUALRELATIONSHIPSURVEYDATE]
      ,[GAINSIGHTCUSTOMERID]
      ,[ABMCLUSTER]
      ,[ABMACCOUNTASSOCIATED]
      ,[ABMACCOUNT]
      ,[MQASTATUS]
      ,[MQADATE]
      ,[RISKASSESSMENTSTATUS]
      ,[COREPRODUCTWFMTALENT]
      ,[COREPRODUCTEAM]
      ,[COREPRODUCTINX]
      ,[COREPRODUCTBIRST]
      ,[PROPOSEDPARENTACCOUNT]
      ,[PROPOSEDPARENTACCTREQUESTOR]
,[TOTALMAINTENANCE]
,[TOTALSUBSCRIPTION]
,[CLOUDSCORE]
,[THREEYEARACTIVITYSCORE]
,[TERRITORYID]
,[SBITIER]
,[PRIVATEEQUITYFIRM]
,[PROPOSEDOWNER]
,[PROPOSEDOWNERREASON]
,[PROPOSEDOWNERCOMMENT]
,[PROPOSEDOWNERCREATEDBY]
,[PROPOSEDOWNERCREATEDATE]
,[AUTOFORMALIZATIONNEEDED]
,[AUTOFORMALIZATIONSTARTED]
,[AUTOFORMALIZATIONNEEDEDDATE]
,[AUTOFORMALIZATIONSTATUS]
,[AUTOFORMALIZATIONORIGINOPP]
,[FACILITYTYPE]
,[RTLS]
,[NUMBEROFCAMPUSES]
,[NUMBEROFASSETS]
,[NUMBEROFOUTPATIENTVISITS]
,[NUMBEROFSPECIALITIES]
,[MAGNETDESIGNATION]
,[AUTOFORMALIZATIONERROR]
,[AUTOFORMALIZATIONPARENTID]
,[AUTOFORMALIZLEGITDUPE]
,[AUTOFORMALIZLEGITDUPEDESC]
,[COVIDEXPOSURE]
,[PROPOSEDTERRITORY]
,[SAASEQUITY]
,[PERPETUALEQUITY]
,[NUMBERCLEVELCONTACTS]
,[MASTERAGREEMENTACCOUNT]
,[REMOVEFROMSOFTRAX]
,[PARTNERBUSINESSPLANDATE]
,[PARTNERBUSINESSPLANUSERID]
,[AOPID]
,[PSSCSUPPORTED]
,[AOPAPPROVERID]
,[FY2020CHANGE]
,[FY2020TRANSITION]
,[GTNROLE]
,[KEDPSSC2000]
,[KEDCROSSSELL]
,[OUTREACHID]
,[SYNCWITHOUTREACH]
,[ZOOMINFOID]
,[LASTSYNCDATEWITHOUTREACH]
,[SYNCTOOUTREACHERRORMESSAGE]
,[NCLBSCORE]
,[M3TENANTVALUE]
,[S3TENANTVALUE]
,[LNTENANTVALUE]
,[MAINTENANCEEXPIRATIONDATE]
,[SUBSCRIPTIONEXPIRATIONDATE]
,[PENDINGAPPROVAL]
,[FINANCEDIVISION]
,[FINANCESUBDIVISION]
,[ISHEXAGONACCOUNT]
FROM [' + @database + '].[sysdba].[PSSCACCOUNT] WITH (NOLOCK)
WHERE COALESCE(ModifyDate, getdate())  >= ''''' + convert(varchar(50), @min_date) + '''''
'' ) source'



--Insert the set of changed records into dbo.CRM_PSSCACCOUNT
INSERT INTO dbo.XA_CRM_PSSCACCOUNT2
(
   [BI_load_date]
      ,[sourcesystem_id]
      ,[ACCOUNTID]
      ,[CREATEDATE]
      ,[MODIFYDATE]
	  ,[KEYACCINDOWNERID]
      ,[KEYACCBIRSTOWNERID]
      ,[KEYACCCXOWNERID]
      ,[KEYACCEPMOWNERID]
      ,[KEYACCEAMOWNERID]
      ,[KEYACCHCMOWNERID]
      ,[KEYACCINDACCCATEGORY]
      ,[KEYACCBIRSTACCCATEGORY]
      ,[KEYACCCXACCCATEGORY]
      ,[KEYACCEPMACCCATEGORY]
      ,[KEYACCEAMACCCATEGORY]
      ,[KEYACCHCMACCCATEGORY]
      ,[KEYACCINDMODIFYDATE]
      ,[KEYACCBIRSTMODIFYDATE]
      ,[KEYACCCXMODIFYDATE]
      ,[KEYACCEPMMODIFYDATE]
      ,[KEYACCEAMMODIFYDATE]
      ,[KEYACCHCMMODIFYDATE]
      ,[CSM]
      ,[STXMODIFYDATE]
      ,[KEYACCOWFMMODIFYDATE]
      ,[KEYACCWFMACCCATEGORY]
      ,[KEYACCWFMOWNERID]
      ,[KEYACCBIRSTACTIVITYDATE]
      ,[KEYACCCXACTIVITYDATE]
      ,[KEYACCEPMACTIVITYDATE]
      ,[KEYACCEAMACTIVITYDATE]
      ,[KEYACCWFMACTIVITYDATE]
      ,[KEYACCHCMACTIVITYDATE]
      ,[CUSTOMERSUCCESSMANAGERID]
      ,[ACTIVEELITESKU]
      ,[SOFTRAXSHIPTOPHONE]
      ,[SOFTRAXSHIPTOCONTACT]
      ,[SOFTRAXCONTACTEMAIL]
      ,[SOFTRAXMAINTENANCERENEWALFEE]
      ,[SUCCESSUPDATEDON]
      ,[GTNPLATFORMORG]
      ,[GTNCOUNTERPARTY]
      ,[GTNFSPACCOUNT]
      ,[KEYACCPLMOWNERID]
      ,[KEYACCTSOWNERID]
      ,[KEYACCCPQOWNERID]
      ,[KEYACCPLMACCCATEGORY]
      ,[KEYACCTSACCCATEGORY]
      ,[KEYACCCPQACCCATEGORY]
      ,[KEYACCPLMMODIFYDATE]
      ,[KEYACCTSMODIFYDATE]
      ,[KEYACCCPQMODIFYDATE]
      ,[KEYACCPLMACTIVITYDATE]
      ,[KEYACCTSACTIVITYDATE]
      ,[KEYACCCPQACTIVITYDATE]
      ,[ACCOUNTHEALTHSTATUS]
      ,[DRAGONSLAYERTARGET]
      ,[ATTENDEDPSSCUM]
      ,[COMPLETEDDRAGONSLAYERPRE]
      ,[GTNFSPPORTALACCESS]
      ,[BIRSTCSMID]
      ,[GTNBDGROUP]
      ,[KEYACCCLOVERLEAFACCCATEGORY]
      ,[KEYACCCLOVERLEAFMODIFYDATE]
      ,[KEYACCCLOVERLEAFOWNERID]
      ,[KEYACCCLOVERLEAFACTIVITYDATE]
      ,[RDCREMARKS]
      ,[RDCSENTDATE]
      ,[SENTTORDC]
      ,[SNAPSHOTDESCRIPTION]
      ,[GENERALNOTES]
      ,[VALUEANDADOPTION]
      ,[PEOPLEANDENDUSERS]
      ,[RISK]
      ,[FUTURE]
      ,[PRIMARY_INSIDE_SALES_REPID]
      ,[NOTREFERENCEABLEREASON]
      ,[REFERENCEAUDITCOMMENT]
      ,[REFERENCEAUDITSTATUS]
      ,[ISCUSTOMERREFERENCEABLE]
      ,[REFERENCEAUDITCONTACTID]
      ,[MRNREQUIRED]
      ,[RENEWALPAYMENTTERMS]
      ,[RENEWALPAYMENTMETHOD]
      ,[PLAYBOOKSSTEPNUMBER]
      ,[PLAYBOOKSPLAYINFOUPDATED]
      ,[PLAYBOOKSPLAYSTATUS]
      ,[PLAYBOOKSPLAYNAME]
      ,[NEXTCALLDATE]
      ,[DUEDILIGENCECOMPLETE]
      ,[CSREVATRISKSTATUS]
      ,[CSCUSTHEALTHREASON1]
      ,[CSCUSTHEALTHREASON2]
      ,[CSCUSTHEALTHREASON3]
      ,[CSREVATRISKHEALTHREASON1]
      ,[CSREVATRISKHEALTHREASON2]
      ,[CSREVATRISKHEALTHREASON3]
      ,[CSREVATRISKCURRENCYUSD]
      ,[CSCUSTOMERHEALTHSTATUS]
      ,[ANNUALRELATIONSHIPSURVEYDATE]
      ,[GAINSIGHTCUSTOMERID]
      ,[ABMCLUSTER]
      ,[ABMACCOUNTASSOCIATED]
      ,[ABMACCOUNT]
      ,[MQASTATUS]
      ,[MQADATE]
      ,[RISKASSESSMENTSTATUS]
      ,[COREPRODUCTWFMTALENT]
      ,[COREPRODUCTEAM]
      ,[COREPRODUCTINX]
      ,[COREPRODUCTBIRST]
      ,[PROPOSEDPARENTACCOUNT]
      ,[PROPOSEDPARENTACCTREQUESTOR]
	  ,[TOTALMAINTENANCE]
	,[TOTALSUBSCRIPTION]
	,[CLOUDSCORE]
	,[THREEYEARACTIVITYSCORE]
	,[TERRITORYID]
	,[SBITIER]
	,[PRIVATEEQUITYFIRM]
	,[PROPOSEDOWNER]
	,[PROPOSEDOWNERREASON]
	,[PROPOSEDOWNERCOMMENT]
	,[PROPOSEDOWNERCREATEDBY]
	,[PROPOSEDOWNERCREATEDATE]
	,[AUTOFORMALIZATIONNEEDED]
	,[AUTOFORMALIZATIONSTARTED]
	,[AUTOFORMALIZATIONNEEDEDDATE]
	,[AUTOFORMALIZATIONSTATUS]
	,[AUTOFORMALIZATIONORIGINOPP]
	,[FACILITYTYPE]
	,[RTLS]
	,[NUMBEROFCAMPUSES]
	,[NUMBEROFASSETS]
	,[NUMBEROFOUTPATIENTVISITS]
	,[NUMBEROFSPECIALITIES]
	,[MAGNETDESIGNATION]
	,[AUTOFORMALIZATIONERROR]
	,[AUTOFORMALIZATIONPARENTID]
	,[AUTOFORMALIZLEGITDUPE]
	,[AUTOFORMALIZLEGITDUPEDESC]
	,[COVIDEXPOSURE]
	,[PROPOSEDTERRITORY]
	,[SAASEQUITY]
	,[PERPETUALEQUITY]
	,[NUMBERCLEVELCONTACTS]
	,[MASTERAGREEMENTACCOUNT]
	,[REMOVEFROMSOFTRAX]
	,[PARTNERBUSINESSPLANDATE]
	,[PARTNERBUSINESSPLANUSERID]
	,[AOPID]
	,[PSSCSUPPORTED]
	,[AOPAPPROVERID]
	,[FY2020CHANGE]
	,[FY2020TRANSITION]
	,[GTNROLE]
	,[KEDPSSC2000]
	,[KEDCROSSSELL]
	,[OUTREACHID]
	,[SYNCWITHOUTREACH]
	,[ZOOMINFOID]
	,[LASTSYNCDATEWITHOUTREACH]
	,[SYNCTOOUTREACHERRORMESSAGE]
	,[NCLBSCORE]
	,[M3TENANTVALUE]
	,[S3TENANTVALUE]
	,[LNTENANTVALUE]
	,[MAINTENANCEEXPIRATIONDATE]
	,[SUBSCRIPTIONEXPIRATIONDATE]
	,[PENDINGAPPROVAL]
	,[FINANCEDIVISION]
	,[FINANCESUBDIVISION]
	,[ISHEXAGONACCOUNT]
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
 FROM dbo.CRM_PSSCACCOUNT2 base WITH (NOLOCK)
 INNER JOIN dbo.XD_CRM_PSSCACCOUNT2 keys WITH (NOLOCK)
  ON base.[ACCOUNTID] = keys.[ACCOUNTID]


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
 FROM dbo.CRM_PSSCACCOUNT2 base WITH (NOLOCK)
 INNER JOIN dbo.XA_CRM_PSSCACCOUNT2 keys WITH (NOLOCK)
  ON base.[ACCOUNTID] = keys.[ACCOUNTID]


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

--UPDATE dbo.CRM_PSSCACCOUNT
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


INSERT INTO dbo.CRM_PSSCACCOUNT2
SELECT new_recs.*
FROM dbo.XA_CRM_PSSCACCOUNT2 new_recs WITH (NOLOCK)
--WHERE load_date  = @load_date


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
FROM dbo.CRM_PSSCACCOUNT2 WITH (NOLOCK)


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

   SET  @cmd = 'SELECT BI_Load_Date = ''' + convert(varchar(20), @load_date) + '''
  , sourcesystem_id  = ''' + convert(varchar(20), @sourcesystem_id) + '''
  , source.*
   FROM OPENQUERY( ' + @server + ', ''SELECT
         [ACCOUNTID]
      ,[CREATEDATE]
      ,[MODIFYDATE]
	  ,[KEYACCINDOWNERID]
      ,[KEYACCBIRSTOWNERID]
      ,[KEYACCCXOWNERID]
      ,[KEYACCEPMOWNERID]
      ,[KEYACCEAMOWNERID]
      ,[KEYACCHCMOWNERID]
      ,[KEYACCINDACCCATEGORY]
      ,[KEYACCBIRSTACCCATEGORY]
      ,[KEYACCCXACCCATEGORY]
      ,[KEYACCEPMACCCATEGORY]
      ,[KEYACCEAMACCCATEGORY]
      ,[KEYACCHCMACCCATEGORY]
      ,[KEYACCINDMODIFYDATE]
      ,[KEYACCBIRSTMODIFYDATE]
      ,[KEYACCCXMODIFYDATE]
      ,[KEYACCEPMMODIFYDATE]
      ,[KEYACCEAMMODIFYDATE]
      ,[KEYACCHCMMODIFYDATE]
      ,[CSM]
      ,[STXMODIFYDATE]
      ,[KEYACCOWFMMODIFYDATE]
      ,[KEYACCWFMACCCATEGORY]
      ,[KEYACCWFMOWNERID]
      ,[KEYACCBIRSTACTIVITYDATE]
      ,[KEYACCCXACTIVITYDATE]
      ,[KEYACCEPMACTIVITYDATE]
      ,[KEYACCEAMACTIVITYDATE]
      ,[KEYACCWFMACTIVITYDATE]
      ,[KEYACCHCMACTIVITYDATE]
      ,[CUSTOMERSUCCESSMANAGERID]
      ,[ACTIVEELITESKU]
      ,[SOFTRAXSHIPTOPHONE]
      ,[SOFTRAXSHIPTOCONTACT]
      ,[SOFTRAXCONTACTEMAIL]
      ,[SOFTRAXMAINTENANCERENEWALFEE]
      ,[SUCCESSUPDATEDON]
      ,[GTNPLATFORMORG]
      ,[GTNCOUNTERPARTY]
      ,[GTNFSPACCOUNT]
      ,[KEYACCPLMOWNERID]
      ,[KEYACCTSOWNERID]
      ,[KEYACCCPQOWNERID]
      ,[KEYACCPLMACCCATEGORY]
      ,[KEYACCTSACCCATEGORY]
      ,[KEYACCCPQACCCATEGORY]
      ,[KEYACCPLMMODIFYDATE]
      ,[KEYACCTSMODIFYDATE]
      ,[KEYACCCPQMODIFYDATE]
      ,[KEYACCPLMACTIVITYDATE]
      ,[KEYACCTSACTIVITYDATE]
      ,[KEYACCCPQACTIVITYDATE]
      ,[ACCOUNTHEALTHSTATUS]
      ,[DRAGONSLAYERTARGET]
      ,[ATTENDEDPSSCUM]
      ,[COMPLETEDDRAGONSLAYERPRE]
      ,[GTNFSPPORTALACCESS]
      ,[BIRSTCSMID]
      ,[GTNBDGROUP]
      ,[KEYACCCLOVERLEAFACCCATEGORY]
      ,[KEYACCCLOVERLEAFMODIFYDATE]
      ,[KEYACCCLOVERLEAFOWNERID]
      ,[KEYACCCLOVERLEAFACTIVITYDATE]
      ,[RDCREMARKS]
      ,[RDCSENTDATE]
      ,[SENTTORDC]
      ,[SNAPSHOTDESCRIPTION]
      ,[GENERALNOTES]
      ,[VALUEANDADOPTION]
      ,[PEOPLEANDENDUSERS]
      ,[RISK]
      ,[FUTURE]
      ,[PRIMARY_INSIDE_SALES_REPID]
      ,[NOTREFERENCEABLEREASON]
      ,[REFERENCEAUDITCOMMENT]
      ,[REFERENCEAUDITSTATUS]
      ,[ISCUSTOMERREFERENCEABLE]
      ,[REFERENCEAUDITCONTACTID]
      ,[MRNREQUIRED]
      ,[RENEWALPAYMENTTERMS]
      ,[RENEWALPAYMENTMETHOD]
      ,[PLAYBOOKSSTEPNUMBER]
      ,[PLAYBOOKSPLAYINFOUPDATED]
      ,[PLAYBOOKSPLAYSTATUS]
      ,[PLAYBOOKSPLAYNAME]
      ,[NEXTCALLDATE]
      ,[DUEDILIGENCECOMPLETE]
      ,[CSREVATRISKSTATUS]
      ,[CSCUSTHEALTHREASON1]
      ,[CSCUSTHEALTHREASON2]
      ,[CSCUSTHEALTHREASON3]
      ,[CSREVATRISKHEALTHREASON1]
      ,[CSREVATRISKHEALTHREASON2]
      ,[CSREVATRISKHEALTHREASON3]
      ,[CSREVATRISKCURRENCYUSD]
      ,[CSCUSTOMERHEALTHSTATUS]
      ,[ANNUALRELATIONSHIPSURVEYDATE]
      ,[GAINSIGHTCUSTOMERID]
      ,[ABMCLUSTER]
      ,[ABMACCOUNTASSOCIATED]
      ,[ABMACCOUNT]
      ,[MQASTATUS]
      ,[MQADATE]
      ,[RISKASSESSMENTSTATUS]
      ,[COREPRODUCTWFMTALENT]
      ,[COREPRODUCTEAM]
      ,[COREPRODUCTINX]
      ,[COREPRODUCTBIRST]
      ,[PROPOSEDPARENTACCOUNT]
      ,[PROPOSEDPARENTACCTREQUESTOR]
	  ,[TOTALMAINTENANCE]
,[TOTALSUBSCRIPTION]
,[CLOUDSCORE]
,[THREEYEARACTIVITYSCORE]
,[TERRITORYID]
,[SBITIER]
,[PRIVATEEQUITYFIRM]
,[PROPOSEDOWNER]
,[PROPOSEDOWNERREASON]
,[PROPOSEDOWNERCOMMENT]
,[PROPOSEDOWNERCREATEDBY]
,[PROPOSEDOWNERCREATEDATE]
,[AUTOFORMALIZATIONNEEDED]
,[AUTOFORMALIZATIONSTARTED]
,[AUTOFORMALIZATIONNEEDEDDATE]
,[AUTOFORMALIZATIONSTATUS]
,[AUTOFORMALIZATIONORIGINOPP]
,[FACILITYTYPE]
,[RTLS]
,[NUMBEROFCAMPUSES]
,[NUMBEROFASSETS]
,[NUMBEROFOUTPATIENTVISITS]
,[NUMBEROFSPECIALITIES]
,[MAGNETDESIGNATION]
,[AUTOFORMALIZATIONERROR]
,[AUTOFORMALIZATIONPARENTID]
,[AUTOFORMALIZLEGITDUPE]
,[AUTOFORMALIZLEGITDUPEDESC]
,[COVIDEXPOSURE]
,[PROPOSEDTERRITORY]
,[SAASEQUITY]
,[PERPETUALEQUITY]
,[NUMBERCLEVELCONTACTS]
,[KEDCROSSSELL]
,[KEDPSSC2000]

,[NCLBSCORE]
,[M3TENANTVALUE]
,[S3TENANTVALUE]
,[LNTENANTVALUE]

    FROM [' + @database + '].[sysdba].[PSSCACCOUNT] src  WITH (NOLOCK)'') source
    LEFT JOIN dbo.CRM_PSSCACCOUNT2 base WITH (NOLOCK)
    ON source.[ACCOUNTID] = base.[ACCOUNTID]
    
    
    
    
    
    
    
    AND base.sourcesystem_id  = ''' + convert(varchar(50), @sourcesystem_id) + '''
    WHERE base.[ACCOUNTID] IS NULL'
    /*INSERT INTO dbo.CRM_PSSCACCOUNT
    (
      [BK_Hash] 
      ,[loadDttm] 
      ,[load_date] 
      ,[sourcesystem_id] 
      ,[ACCOUNTID] 
      ,[CREATEUSER] 
      ,[CREATEDATE] 
      ,[MODIFYUSER] 
      ,[MODIFYDATE] 
      ,[SALESFORCEID] 
      ,[ISDELETED] 
      ,[DELETEDDATE] 
      ,[PHOTOURL] 
      ,[ISPARTNERPORTALAUTHROIZED] 
      ,[ALLIANCEAGREEMENT] 
      ,[ALLIANCETYPE] 
      ,[AUDITINGINPROGRESS] 
      ,[ACCOUNTCLASS] 
      ,[IPNPARTNERCHANNELTIER] 
      ,[LASTACTIVITYDATE] 
      ,[LASTCALLACTIVITYDATE] 
      ,[DECISIONLOCATION] 
      ,[FORMALIZATIONDATE] 
      ,[NAHEALTHCARE] 
      ,[INBOUNDINTEGRATIONERROR] 
      ,[LASTDATEVERIFIED] 
      ,[MAINTENANCESTATUS] 
      ,[HCMTEAMCOMMENTS] 
      ,[OUTOFBUSINESS] 
      ,[OUTBOUNDINTEGRATIONERROR] 
      ,[SOFTRAXID] 
      ,[SOFTRAXCOUNTRY] 
      ,[SUBINDUSTRY] 
      ,[SUBREGION] 
      ,[HEATID] 
      ,[SFDCUNIQUEID] 
      ,[ACCOUNTVALIDATED] 
      ,[DEFAULTPARTNERTYPE] 
      ,[SOFTRAXIDUSEDESCRIPTION] 
      ,[PSSCAQUISITIONS] 
      ,[EMAILDOMAIN] 
      ,[SOFTRAXCURRENCY] 
      ,[SECCODEID] 
      ,[OWNER_LINE_OF_BUSINESS] 
      ,[OWNERSUBLINEOFBUSINESS] 
      ,[APACSTRATEGIC] 
      ,[LOCAL_SIC_DESCRIPTION] 
      ,[TOTAL_GLOBAL_EMPLOYEES] 
      ,[PO_REQUIRED] 
      ,[CONTRACTUALLY_NONREFERENCABLE] 
      ,[IS_ANALYSTMEDIA] 
      ,[IS_PSSC_COMPETITOR] 
      ,[IS_PSSC_CONSULTANT] 
      ,[IS_UNIVERSITY] 
      ,[KEY_ACCOUNT_LINE_OF_BUSINESS] 
      ,[KEY_ACCOUNT] 
      ,[KEY_TARGET_ACCOUNT_LOB] 
      ,[FORMERCUSTOMER] 
      ,[PRIMARY_INSIDE_SALES_REPID] 
      ,[STX_CUST_CD] 
      ,[STX_CUS_GRP_CD] 
      ,[STX_CUS_GRP] 
      ,[STX_CUSTOMER_CATEGORY] 
      ,[STX_CUSTOMER_NUMBER] 
      ,[STX_FORMALIZE] 
      ,[EDU_ALLIANCE_PRGM] 
      ,[EUVAT_REGNUMBER] 
      ,[KEYACCOUNTNOTES] 
      ,[INDUSTRY_OVERRIDE] 
      ,[SUBINDUSTRY_OVERRIDE] 
      ,[SICCODEOVERRIDE] 
      ,[KEY_ACCOUNT_DELIST_REASON] 
      ,[FORMERPARTNER] 
      ,[LICENSE_COMMISSIONMARGIN] 
      ,[NUMBER_PSSC_CUSTOMERS] 
      ,[PARTNER_GROUPS] 
      ,[PARTNER_INDUSTRY_FOCUS] 
      ,[PARTNER_INDUSTRY_SUB_FOCUS] 
      ,[PARTNER_STATUS] 
      ,[PARTNER_TYPES] 
      ,[PUBLIC_SECTOR_AGREEMENT] 
      ,[SELLTHROUGH_AGREEMENT] 
      ,[SUPPORT_COMMISSIONMARGIN] 
      ,[PUBLIC_SECTOR_TIER] 
      ,[TOTAL_REVENUE_GROWTH] 
      ,[ALLIANCE_PARTNER] 
      ,[ENABLE_PARTNER_AUTHORIZATIONS] 
      ,[SELECTION_CONSULTANT] 
      ,[SIGNED_NDA] 
      ,[NUMBER_OF_SIGNED_SFDC_LICENSES] 
      ,[CRM_PARTNER] 
      ,[AGREEMENTDATE] 
      ,[ALLIANCEAGREEMENTTYPE] 
      ,[ALLIANCE_PTNR_AGRMENT] 
      ,[ALLIANCE_PRTNR_GRP] 
      ,[ALLIANCEREGIONS] 
      ,[ANCILLARYAGREEMENTS] 
      ,[BUSINESSPLANDATE] 
      ,[BUS_PLAN_REN_DATE] 
      ,[CHANNELAGREEMENT] 
      ,[CLOUDSUITECERTIFIED] 
      ,[ICS_SCV_AGR_TYP] 
      ,[ICS_SVC_CR_PTNR_AGRM] 
      ,[ICS_SVC_PTNR_LVL] 
      ,[MINORITY_FIRM] 
      ,[PARTNER_PROGRAM_TYPE] 
      ,[OVER60DAYSPASTDUEAR] 
      ,[CREDITLIMIT] 
      ,[CREDITLIMITCURRENCY] 
      ,[AVAILABLECREDITLIMIT] 
      ,[TOTALAR] 
      ,[FISCALYEAR] 
      ,[GLOBALREVENUE] 
      ,[PUB_STD_ENRL] 
      ,[PUB_POP] 
      ,[MFG_AFTER_MKT_SVC] 
      ,[MFG_AUTOMOTIVE_TIER] 
      ,[MFG_NO_SITES] 
      ,[MFG_OEM_CUST_SUP] 
      ,[MFG_PIM_MFG_TYPE] 
      ,[MFG_PRIM_SVC_TYPE] 
      ,[MFG_REG_COMP_STNDS] 
      ,[MFG_NO_ENGINEERS] 
      ,[MFG_MANUFACTURER] 
      ,[MFG_ISMFGLOC] 
      ,[ICS_ACCOUNT_TYPE] 
      ,[ICS_OWNER] 
      ,[ICS_SEG] 
      ,[ICS_REV_IND] 
      ,[ICS_REV_SCTR] 
      ,[ICS_REV_IND_OVREX] 
      ,[ICS_REV_IND_OVR] 
      ,[ICS_SLS_OWNR_OVREX] 
      ,[ICS_SLS_OWNR_OVR] 
      ,[HSP_HOTEL_CHAIN] 
      ,[HSP_HOTEL_CODE] 
      ,[HSP_MANAGEMENT] 
      ,[HSP_NO_HOTELS] 
      ,[HSP_NO_ROOMS] 
      ,[HSP_PRICE_POINT] 
      ,[HCR_NO_OF_BEDS] 
      ,[HCM_ACCT_DEFN] 
      ,[HCM_ACCOUNT_TIER] 
      ,[GT_NEXUS_ACC_TYP] 
      ,[GT_NEXUS_ACT_OPP] 
      ,[GT_NEXUS_OPP_VALUE] 
      ,[GT_NEXS_ACT_OID] 
      ,[FAS_BUSINESS_MODEL] 
      ,[FAS_MULTIBRAND] 
      ,[FAS_OWN_RETAIL_STORES] 
      ,[FAS_RET_SUP_TO] 
      ,[FAS_NO_OF_STORES] 
      ,[FAS_IS_FASH_BUS] 
      ,[EQP_DEALER] 
      ,[EQP_NO_OF_BRANCHES] 
      ,[EQP_OEM_COMP_REP] 
      ,[EQP_RENTAL] 
      ,[EQP_TRD_GRP_MEMB] 
      ,[EQP_SERVICE_PROVIDER] 
      ,[EQP_NO_OF_WAREHOUSES] 
      ,[EQP_NO_OF_TRUCKS] 
      ,[FIN_INTERNATIONAL_LOCS] 
      ,[FIN_MULT_LOB] 
      ,[FIN_MULT_REGREPORTNEEDS] 
      ,[EMEA_OPP_OWNR] 
      ,[EMEA_STRAT_ACCT] 
      ,[ROE_OVR] 
      ,[ROE_OVR_EXPL] 
      ,[NA_PUB_SECT] 
      ,[LOB_OVR] 
      ,[JOC_COMPANY] 
      ,[APAC_NAMED_ACCT] 
      ,[HOSPITALITY] 
      ,[NA_MEDIA_ENTR] 
      ,[NA_RETAIL] 
      ,[FIN_SVCS_IN_ACCT] 
      ,[NA_BANKING] 
      ,[PRF_SRVC_IND_ACCT] 
      ,[EMEA_STRAT_ACCT_OWNR] 
      ,[ROE_LINE_OF_BUS] 
      ,[CONTRACTVEHICLE] 
      ,[ICS_CORE_PTNR_AGRM] 
      ,[SOFTRAXMODIFIEDDATE] 
      ,[SOFTRAXSTATE] 
      ,[SYNCHRONIZEWITHSOFTRAX] 
      ,[DATAMANAGEMENT] 
      ,[HC_LIFESCIENCESELIGIBLE] 
      ,[ACTIVE_ONMFGPRIMARYPRODUCT] 
      ,[LOCALIZEDADDRESSLINES] 
      ,[LOCALIZEDCITY] 
      ,[LOCALIZEDCOUNTRY] 
      ,[LOCALIZEDCOUNTY] 
      ,[LOCALIZEDPOSTALCODE] 
      ,[LOCALIZEDSTATE] 
      ,[ACTIVEOPPCOUNT] 
      ,[LASTPURCHASEDATE] 
      ,[KEYACCOUNTPROSPECTREP] 
      ,[ACCTPLANCLDEXECSPONSOR] 
      ,[ACCTPLANCLDCUSTOMEREXEC] 
      ,[ACCTPLANCLDFEEDBACK2SPONSOR] 
      ,[ACCTPLANCLDROADBLOCKS] 
      ,[ACCTPLANCLDCUSTOMERSTATUS] 
      ,[ACCTPLANCLDLICENSEGMID] 
      ,[ACCTPLANCLDSDMID] 
      ,[ACCTPLANCLDCSMID] 
      ,[ACCTPLANCLDPRODUCTS] 
      ,[ACCTPLANCLDACV] 
      ,[ACCTPLANCLDTARGETDATE] 
      ,[ACCTPLANCLDMEETCADESTFLG] 
      ,[ACCTPLANCLDINITIALCONTFLG] 
      ,[ACCTPLANCLDWAVE1FLG] 
      ,[ACCOUNTCOMPETITOR1NAME] 
      ,[ACCOUNTCOMPETITOR2NAME] 
      ,[SUBSCRIPTIONSTATUS] 
      ,[ACCTPLANGOALSOBJFD2] 
      ,[ACCTPLANBUSSEGMENTS1] 
      ,[ACCTPLANREGPRECOVERAGE1] 
      ,[ACCTPLANANNUALREVENUE1] 
      ,[ACCTPLANCURYEARPERFTREND1] 
      ,[ACCTPLANMAJORPSSCSOLFP1] 
      ,[ACCTPLANMAJORCOMPSOLFP1] 
      ,[ACCTPLANGOALSOBJFD1] 
      ,[ACCTPLANBUSSEGMENTS2] 
      ,[ACCTPLANREGPRECOVERAGE2] 
      ,[ACCTPLANANNUALREVENUE2] 
      ,[ACCTPLANCURYEARPERFTREND2] 
      ,[ACCTPLANMAJORPSSCSOLFP2] 
      ,[ACCTPLANMAJORCOMPSOLFP2] 
      ,[SUBSCRIPTIONMAINTSTATUS] 
      ,[ACCTPLANCLDWAVE2FLG] 
      ,[ACCTPLANCLDFIELDREFSTATUS] 
      ,[PREVIOUSYEARGLOBALREVENUE] 
      ,[UNIQUEID] 
      ,[ACCTPLANMANAGERSIGNOFF] 
      ,[ACCOUNTPLANREQUIREDSERVICES] 
      ,[ACCOUNTPLANREQUIREDLICENSE] 
      ,[ACCOUNTPLANLASTMODIFEDUSER] 
      ,[ACCOUNTPLANLASTMODIFIED] 
      ,[ACCOUNTPLANSIGNOFFMANAGER] 
      ,[ACCOUNTPLANSIGNOFFMGRSERVICE] 
      ,[ACCOUNTPLANSIGNOFFMGRSERVICEDATE] 
      ,[PARTNERREPMAILONOPINFLUENCE] 
      ,[ACTIVEONSRVPRIMARYPRODUCT] 
      ,[PRIMARYPARTNERID] 
      ,[ISPRIMARYDUPMASTERACCOUNT] 
      ,[PRIMARYDUPMASTERACCOUNTID] 
      ,[ALLOWUPDATEONDUPLICATE] 
      ,[PRIMARYPARTNERNAME] 
      ,[HEALTHCARESEGMENTATION] 
      ,[GTNSAM] 
      ,[GTNBDM] 
      ,[GTNGAM] 
      ,[GTNSC] 
      ,[UPGRADEXISTARGET] 
      ,[UPGRADEXCURPRIMARYPRODUCT] 
      ,[UPGRADEXCURRELEASEINUSE] 
      ,[UPGRADEXUPGRADESTATUS] 
      ,[UPGRADEXSTARTYEAR] 
      ,[UPGRADEXUPGRADECOMMENTS] 
      ,[UPGRADEXDEPLOYMENTPREF] 
      ,[SREXECSPONSORACCOUNT] 
      ,[SREXECUTIVESPONSOR] 
      ,[VPSPONSOR] 
      ,[CUSTOMEREXECUTIVESPONSOR] 
      ,[CUSTOMERROADMAPCOMPLETE] 
      ,[CUSTOMER360REVCOMPLETE] 
      ,[CUSTOMER360REVCOMPLETEDATE] 
      ,[CUSTOMERROADMAPCOMPLETEDATE] 
      ,[CUSTOMERBIANNUALMTGDATE] 
      ,[EXECSPONSORCLIENTSTATUS] 
      ,[EXECSPONSORATRISKREASON] 
      ,[EXECSPONSORSTRESSEDREASON] 
      ,[EXECSPONSORADVOCATETYPE] 
      ,[EXECSPONSORPRODUCTLINE] 
      ,[EXECSPONSORPOTENTIALISSUES] 
      ,[EXECSPONSORREQUIRED] 
      ,[KEYACCINDOWNERID] 
      ,[KEYACCBIRSTOWNERID] 
      ,[KEYACCCXOWNERID] 
      ,[KEYACCEPMOWNERID] 
      ,[KEYACCEAMOWNERID] 
      ,[KEYACCHCMOWNERID] 
      ,[KEYACCINDACCCATEGORY] 
      ,[KEYACCBIRSTACCCATEGORY] 
      ,[KEYACCCXACCCATEGORY] 
      ,[KEYACCEPMACCCATEGORY] 
      ,[KEYACCEAMACCCATEGORY] 
      ,[KEYACCHCMACCCATEGORY] 
      ,[KEYACCINDMODIFYDATE] 
      ,[KEYACCBIRSTMODIFYDATE] 
      ,[KEYACCCXMODIFYDATE] 
      ,[KEYACCEPMMODIFYDATE] 
      ,[KEYACCEAMMODIFYDATE] 
      ,[KEYACCHCMMODIFYDATE] 
      ,[CSM] 
      ,[STXMODIFYDATE] 
      ,[KEYACCOWFMMODIFYDATE] 
      ,[KEYACCWFMACCCATEGORY] 
      ,[KEYACCWFMOWNERID] 
      ,[KEYACCBIRSTACTIVITYDATE] 
      ,[KEYACCCXACTIVITYDATE] 
      ,[KEYACCEPMACTIVITYDATE] 
      ,[KEYACCEAMACTIVITYDATE] 
      ,[KEYACCWFMACTIVITYDATE] 
      ,[KEYACCHCMACTIVITYDATE] 
      ,[CUSTOMERSUCCESSMANAGERID] 
      ,[ACTIVEELITESKU] 
      ,[SOFTRAXSHIPTOPHONE] 
      ,[SOFTRAXSHIPTOCONTACT] 
      ,[SOFTRAXCONTACTEMAIL] 
      ,[SOFTRAXMAINTENANCERENEWALFEE] 
      ,[SUCCESSUPDATEDON] 
      ,[GTNPLATFORMORG] 
      ,[GTNCOUNTERPARTY] 
      ,[GTNFSPACCOUNT] 
      ,[KEYACCPLMOWNERID] 
      ,[KEYACCTSOWNERID] 
      ,[KEYACCCPQOWNERID] 
      ,[KEYACCPLMACCCATEGORY] 
      ,[KEYACCTSACCCATEGORY] 
      ,[KEYACCCPQACCCATEGORY] 
      ,[KEYACCPLMMODIFYDATE] 
      ,[KEYACCTSMODIFYDATE] 
      ,[KEYACCCPQMODIFYDATE] 
      ,[KEYACCPLMACTIVITYDATE] 
      ,[KEYACCTSACTIVITYDATE] 
      ,[KEYACCCPQACTIVITYDATE] 
	  ,[TOTALMAINTENANCE]
,[TOTALSUBSCRIPTION]
,[CLOUDSCORE]
,[THREEYEARACTIVITYSCORE]
,[TERRITORYID]
,[SBITIER]
,[PRIVATEEQUITYFIRM]
,[PROPOSEDOWNER]
,[PROPOSEDOWNERREASON]
,[PROPOSEDOWNERCOMMENT]
,[PROPOSEDOWNERCREATEDBY]
,[PROPOSEDOWNERCREATEDATE]
,[AUTOFORMALIZATIONNEEDED]
,[AUTOFORMALIZATIONSTARTED]
,[AUTOFORMALIZATIONNEEDEDDATE]
,[AUTOFORMALIZATIONSTATUS]
,[AUTOFORMALIZATIONORIGINOPP]
,[FACILITYTYPE]
,[RTLS]
,[NUMBEROFCAMPUSES]
,[NUMBEROFASSETS]
,[NUMBEROFOUTPATIENTVISITS]
,[NUMBEROFSPECIALITIES]
,[MAGNETDESIGNATION]
,[AUTOFORMALIZATIONERROR]
,[AUTOFORMALIZATIONPARENTID]
,[AUTOFORMALIZLEGITDUPE]
,[AUTOFORMALIZLEGITDUPEDESC]
,[COVIDEXPOSURE]
,[PROPOSEDTERRITORY]
,[SAASEQUITY]
,[PERPETUALEQUITY]
,[NUMBERCLEVELCONTACTS]

,[NCLBSCORE]
,[M3TENANTVALUE]
,[S3TENANTVALUE]
,[LNTENANTVALUE]
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
  DROP TABLE dbo.XA_CRM_PSSCACCOUNT2
 END TRY
 BEGIN CATCH
  PRINT 'Unable to drop table XA_CRM_PSSCACCOUNT'
 END CATCH


 BEGIN TRY
  DROP TABLE dbo.XD_CRM_PSSCACCOUNT2
 END TRY
 BEGIN CATCH
  PRINT 'Unable to drop table XD_CRM_PSSCACCOUNT'
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


IF @debug = 1
BEGIN
	EXECUTE dbo.logTableCounts @servername = @@SERVERNAME, @dbname = 'EDW_STAGE', @tableName = 'XA_CRM_PSSCACCOUNT2', @count = @countDelta, @desc = 'DELTA', @load_date = @load_date
	EXECUTE dbo.logTableCounts @servername = @server, @dbname = @database , @tableName = 'PSSCACCOUNT',@count = @countSource, @desc = 'SOURCE', @load_date = @load_date
	EXECUTE dbo.logTableCounts @servername = @@SERVERNAME, @dbname = 'EDW_STAGE', @tableName = 'CRM_PSSCACCOUNT2', @count = @countDest, @desc = 'FINAL', @load_date = @load_date
END


EXEC @log_value = dbo.logProcessActivity
        @log_value
      , @proc_name
      , @step_name
      , @message
      , @type
      , @rowcount

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






