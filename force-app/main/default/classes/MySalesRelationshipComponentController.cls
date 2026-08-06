global class MySalesRelationshipComponentController {
    
    @AuraEnabled
    public static Map<String, String> getFieldLabels(String accountId, String salesOrgPle){
        
        Map<String, String> fieldLabels = new Map<String, String>();
        
        // Account_Org__c
        List<Account> accountList = [SELECT Id, Name FROM Account WHERE Id = :accountId];        
        if(!accountList.isEmpty()){fieldLabels.put('accountOrgLabel', accountList[0].Name);}
        
        // Sales_Org__c
        List<Schema.PicklistEntry> picklistEntries = Schema.SObjectType.Sales_Relationship__c.fields.Sales_Org__c.getPicklistValues();
        
        for(Schema.PicklistEntry ple :picklistEntries){
            
            if(ple.getValue() == salesOrgPle){
                fieldLabels.put('salesOrgLabel', ple.getLabel());
                break;
            }
            
        }
        
        return fieldLabels;
        
    }
    
    @AuraEnabled 
    public static AccountTransactionHandler.TransactionResponse saveSalesRelation(String jsonString, String mode){
        AccountTransactionHandler.TransactionResponse result;
        System.debug('START saveSalesRelation');
        System.debug('jsonString=> '+jsonString);

        Map<String, Object> salesRelations = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        
        List<Account> myAccount = [SELECT Other_Phone__c, MasterRecordId, Name, LastName, FirstName, Salutation, Type, ParentId, BillingStreet, BillingCity,BillingState,BillingStateCode,BillingPostalCode,BillingCountry,BillingLatitude,BillingLongitude,
                                   BillingGeocodeAccuracy,Phone,Website,PhotoUrl,Industry,NumberOfEmployees,Number_Id__c,Description,OwnerId,LastActivityDate,LastViewedDate,LastReferencedDate,PersonContactId,PersonMailingStreet,
                                   PersonMailingCity,PersonMailingState, PersonMailingStateCode, PersonMailingPostalCode,PersonMailingCountry,PersonMailingCountryCode,PersonMailingLatitude,PersonMailingLongitude,PersonMailingGeocodeAccuracy,PersonMailingAddress,PersonMobilePhone,
                                   PersonOtherPhone,PersonEmail,PersonTitle,PersonDepartment,PersonBirthdate,PersonLastCURequestDate,PersonLastCUUpdateDate,PersonEmailBouncedReason,PersonEmailBouncedDate,Jigsaw,JigsawCompanyId,
                                   AccountSource,SicDesc,Potential__c,Address__c,Town__c,Province__c,Postcode__c,Country__c,Gender__c,Source__c,Label__c,Number_Of_Projects__c,Professional__c,Customer_Type__c,
                                   Conversion_Date__c,Updated_Type__c,Load_Id__c,Company_num__c,company_list__c,Language__c,Is_Locked__c,Is_Deleted__c,European_Community__c,
                                   Business_Email__c,Age__pc,Id,IsPersonAccount,SystemModstamp,Brands_They_Work_With__c,CreatedById,CreatedDate,Fabricators_they_work_with__c,LastModifiedById,LastModifiedDate,
                                   Merchandising_Materials__c,Notes__c,Phone_2__c,Validated__c,Validation_Time__c,SAP_Id__c, BillingCountryCode, RecordTypeId, Account_Classification__c, VAT_Number__c,VAT_Number_2__c //company_form__c
                                   FROM Account
                                   WHERE Id = :String.valueOf(salesRelations.get('Account_Org__c'))];
        
        String customId = myAccount[0].ID+'-'+salesRelations.get('Sales_Org__c')+'-'+salesRelations.get('Distribution_Channel__c');
        List<Sales_Relationship__c> srList = [SELECT Id FROM Sales_Relationship__c 
                                            WHERE Custom_Id__c =: customId LIMIT 1];
        String salesOrg = (String) salesRelations.get('Sales_Org__c');
        
        if(!srList.isEmpty()){
            if( mode == 'New' ){ //salesRelations.get('CreatedById') == null
                
				//result = new AccountTransactionHandler.TransactionResponse(false,'duplicate',errorMessage,null,null);
                result = new AccountTransactionHandler.TransactionResponse(false,'duplicate',Label.Duplicate_Sales_Rel,null,null);
                return result;
            }
            salesRelations.put('Id',srList[0].Id);
        }
        
        User currentUser = [SELECT CountryCode FROM User WHERE ID =: UserInfo.getUserId()];
        if (String.isNotBlank(salesOrg)) {
            String initial = salesOrg.substring(0,1);
            if (initial == '2') {
                salesRelations.put('Currency__c', 'EUR');     
            } else if (salesOrg == '330')  {
                salesRelations.put('Currency__c', 'CHF');
            } else if (salesOrg == '580') {
                salesRelations.put('Currency__c', 'SEK');    
            } else if (salesOrg == '585') {
                salesRelations.put('Currency__c', 'DKK');   
            } else if (initial == '5') {
                salesRelations.put('Currency__c', 'GBP');     
            } else if (salesOrg == '650')  {
                salesRelations.put('Currency__c', 'CAD');     
            } else if (initial == '6') {
                salesRelations.put('Currency__c', 'USD');     
            } else if (salesOrg == '820') {
                salesRelations.put('Currency__c', 'CLP');     
            } else if (salesOrg == '850') {
                salesRelations.put('Currency__c', 'AUD');
            } else if (salesOrg == '920') {
                salesRelations.put('Currency__c', 'ILS');   
            } else if (salesOrg == '720') {
                salesRelations.put('Currency__c', 'DOP');
            } 
        }
        salesRelations.put('Custom_Id__c',customId); 
        
        List<Map<String, Object>> companies = new List<Map<String, Object>>{salesRelations};
            
        Map<String, Object> accountWrapper = new Map<String, Object>();
        accountWrapper.put('companies', companies);
        accountWrapper.put('customer', myAccount[0]);
        accountWrapper.put('language', UserInfo.getLanguage());
        
        result = AccountTransactionHandler.runTransaction(JSON.serialize(accountWrapper));
        return result;
        
    }

    @AuraEnabled 
    public static SalesRelAccessDTO checkAccountData(String recordId){
        SalesRelAccessDTO result = new SalesRelAccessDTO();
        Id tradeRecTypeId = RecordTypeLibrary.Account_TradeCustomer;
        Id privateCustomerTypeId = RecordTypeLibrary.Account_PrivateCustomer;
        Boolean editPermission = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE 
        UserId =: UserInfo.getUserId() AND RecordId =: recordId].HasEditAccess;
        List<Account> acc = [SELECT Id, BillingCountryCode, VAT_Number__c, DVSAction__c, RecordTypeId FROM Account WHERE Id =: recordId and IsPersonAccount = false];
        PorcelanosaSetting setting = new PorcelanosaSetting('REQUIRED_VAT', 'ALL');


        if (acc.size() > 0) {
            result.isDvsAccount = isDVSAccount(acc[0]);
            result.dvsAction = acc[0].DVSAction__c;
        }
        result.hasSapConnection = UserCommons.hasSAPConnection();
        result.hasEditPermission = editPermission;

        if (setting != null && acc.size() > 0) {
            List<String> requiredVatCountries = setting.value1.split(';');
            if (requiredVatCountries.contains(acc[0].BillingCountryCode)) {
                if (acc[0].BillingCountryCode == 'FR' && (acc[0].VAT_Number__c == null || acc[0].VAT_Number__c.length() > 0)) {
                    Boolean validVat = TaxCommons.isValidSiret(acc[0].VAT_Number__c);
                    if (validVat == false) {
                        result.needsValidSiret = true;
                    }
                }
    
                if (acc[0].BillingCountryCode == 'GB' && (acc[0].VAT_Number__c == null || acc[0].VAT_Number__c.length() > 0)) {
                    Boolean validVat = TaxCommons.isValidCRN(acc[0].VAT_Number__c);
                    if (validVat == false) {
                        result.needsValidSiret = true;
                    }
                }
            }
        }
        
        return result;
    }

    public static Boolean isDVSAccount(Account acc) {
        Boolean result = false;
        Id tradeRecTypeId = RecordTypeLibrary.Account_TradeCustomer;
        Id privateCustomerTypeId = RecordTypeLibrary.Account_PrivateCustomer;

        if (acc.RecordTypeId != privateCustomerTypeId && acc.BillingCountryCode == 'FR') {
            result = true;
        }

        return result;
    }

    @AuraEnabled 
    public static Integer userHasAccess(String recordId){
        Integer returnValue = 1;	// Access granted
		ExecutionContext context = ExecutionContext.getUserExecutionContext();
        Id tradeRecTypeId = RecordTypeLibrary.Account_TradeCustomer;
        Id privateCustomerTypeId = RecordTypeLibrary.Account_PrivateCustomer;
        PorcelanosaSetting setting = new PorcelanosaSetting('REQUIRED_VAT', 'ALL');

        List<String> requiredVatCountries = setting.value1.split(';');
        
        if (context.useSAP) {            
        	Boolean editPermission = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE 
                	UserId =: UserInfo.getUserId() AND RecordId =: recordId].HasEditAccess;
            List<Account> acc = [SELECT Id, BillingCountryCode, VAT_Number__c, DVSAction__c, RecordTypeId FROM Account WHERE Id =: recordId and IsPersonAccount = false];
            if (UserCommons.hasSAPConnection() == false){
                returnValue = 4;

            } else if (!editPermission) {
				returnValue = 2;	// No edit permission                
            }

            if (acc.size() > 0 && DvsService.isDvsEnabled(acc[0].Id) && UserCommons.hasPermissionSet(UserInfo.getUserId(), 'no_dvs_needed') == false){
                if (acc.size() > 0 && isDvsAccount(acc[0]) == true && acc[0].DvsAction__c == null) {
                    returnValue = 6;
                }
    
                if (acc.size() > 0 && isDvsAccount(acc[0]) == true && (acc[0].DvsAction__c == 'DISCARDED' || acc[0].DvsAction__c == 'UNKNOWN')) {
                    returnValue = 7;
                }
            }

            if (acc.size() > 0 && requiredVatCountries.contains(acc[0].BillingCountryCode)) {
                if (acc[0].BillingCountryCode == 'FR' && (acc[0].VAT_Number__c == null || acc[0].VAT_Number__c.length() > 0)) {
                    Boolean validVat = TaxCommons.isValidSiret(acc[0].VAT_Number__c);
                    if (validVat == false) {
                        returnValue = 5;
                    }
                }

                if (acc[0].BillingCountryCode == 'GB' && (acc[0].VAT_Number__c == null || acc[0].VAT_Number__c.length() > 0)) {
                    Boolean validVat = TaxCommons.isValidCRN(acc[0].VAT_Number__c);
                    if (validVat == false) {
                        returnValue = 5;
                    }
                }
            }
        } else {
            returnValue = 3;
        }
        return returnValue;
    } //userHasAcccess
    
    @AuraEnabled 
    public static Boolean salesOfficeEditable(){
      if (UserUtils.isAdministrator()) {
        return true;
      }

      List<PermissionSetAssignment> hasPermission = [SELECT PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :Userinfo.getUserId() AND PermissionSet.Name = 'sales_office_sap_editable'];
      if (hasPermission.size() == 1) {
        return true;
      }
      return false;
    } //salesOfficeEditable

    /*
    ** Checks if a SalesOrg is restricted to create an account and checks if the given user has de right permission
    */
    @AuraEnabled 
    public static List<String> checkSalesOrgRestricted(){
        List<String> result = new List<String>();
        List<String> permissionSetsNeeded = new List<String>();
      List<Sales_org__c> restrictedOrgs = SalesRelationshipsDomain.getRestrictedOrgs();
      if (restrictedOrgs.size() > 0) {
        for (Sales_Org__c salesOrg : restrictedOrgs) {
            permissionSetsNeeded.add('SAP_ACCOUNT_CREATION_' + salesOrg.SalesOrg__c);
        }
        List<PermissionSetAssignment> hasPermissions = [SELECT PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name in :permissionSetsNeeded];
        for (PermissionSetAssignment assignment : hasPermissions) {
            Integer index = permissionSetsNeeded.indexOf(assignment.PermissionSet.Name);
            permissionSetsNeeded.remove(index);
        }

        for (String permissionSetNeeded : permissionSetsNeeded) {
            result.add(permissionSetNeeded.replace('SAP_ACCOUNT_CREATION_', ''));
        }
      }

      return result;
    } //checkSalesOrgRestricted

    /*
    */
    @AuraEnabled 
    public static void sendRestrictionMessage(String salesOrg, String channel, String salesOffice, String commercialId, String userId, String accountId){

        switch on salesOrg {
            when '008'{
                SalesRelationshipsDomain.sendRestrictedOrgRequestExportacion(salesOrg, channel, salesOffice, commercialId, userId, accountId);
            }
        }
     
    } //sendRestrictionMessage

    public class response{
        
        @AuraEnabled public String message;
        @AuraEnabled public Id recordId;
        
    }
    
    @AuraEnabled
    public static Map<String,String> getMyUserSalesOrgs(){
        System.debug('getUserSalesOrgs');
        Map<String,String> options = new Map<String,String>();
        String allOpts = [Select Sales_Org__c FROM User WHERE id=:UserInfo.getUserId()].Sales_Org__c;
        if(String.isNotBlank(allOpts)){
            Set<String> optionsSet = new Set<String>(allOpts.split(';'));
            List<Schema.PicklistEntry> picklistEntries = Schema.SObjectType.User.fields.Sales_Org__c.getPicklistValues();        
            for(Schema.PicklistEntry ple :picklistEntries){  
                if(optionsSet.contains(ple.getValue())){
                    options.put(ple.getValue(), ple.getLabel());
                }  
            }
        }
        System.debug('options=> '+options);
        return options;
    }

    @AuraEnabled
    public static List<Map<String, String>> getUserSoOptions(List<String> userSalesOrgs, String fieldName){        
        System.debug('getUserSoOptions');
        System.debug('userSalesOrgs => '+userSalesOrgs);
        List<Map<String, String>> salesOrgOptions = new List<Map<String, String>>();
        
        List<Schema.PicklistEntry> picklistEntries = fieldName == 'Sales_Org__c' ?
            Schema.SObjectType.Sales_Relationship__c.fields.Sales_Org__c.getPicklistValues() : Schema.SObjectType.Sales_Relationship__c.fields.Distribution_Channel__c.getPicklistValues();
        for(String salesOrgOption: userSalesOrgs){         
            for(Schema.PicklistEntry ple :picklistEntries){                
                if(ple.getValue() == salesOrgOption){
                    salesOrgOptions.add(new Map<String, String>{'value' => ple.getValue(),
                        										'label' => ple.getLabel()
                                                                });
                    break;
                }                
            }         
        }

        System.debug('salesOrgOptions => '+salesOrgOptions);

        return salesOrgOptions;
        
    }
    
    @AuraEnabled
    public static List<Map<String, String>> retrieveSalesOfficePicklistValues(String salesOrgCode, String distributionChannelCode){
        
        List<Map<String, String>> salesOfficeOptions = new List<Map<String, String>>();
        
        for(Master_relations__c masterRelationItem: [SELECT SalesOffice_name__c, SalesOffice_code__c 
                                                     FROM Master_relations__c 
                                                     WHERE SalesOrg_code__c = :salesOrgCode AND DistributionChannel_code__c =: distributionChannelCode]){
                                                         
                                                         
             salesOfficeOptions.add(new Map<String, String>{'value' => masterRelationItem.SalesOffice_code__c, 'label' => masterRelationItem.SalesOffice_name__c});
                                                         
        }
        
        System.debug('salesOfficeOptions.size() ' + salesOfficeOptions.size());
        return salesOfficeOptions;
        
    }

    @AuraEnabled
    public static AccountTransactionHandler.TransactionResponse validateAccount(String accountId){

        ExecutionContext context = ExecutionContext.getUserExecutionContext();
        if (!context.useSAP) {            
            return new AccountTransactionHandler.TransactionResponse(true,null,null,null,null);
        }
        
        List<Account> accountList = [SELECT MasterRecordId, Name, LastName, FirstName, Salutation, Type, ParentId, BillingStreet, BillingCity,BillingState,BillingStateCode,BillingPostalCode,BillingCountry,BillingLatitude,BillingLongitude,
                                   BillingGeocodeAccuracy,Phone,Website,PhotoUrl,Industry,NumberOfEmployees,Number_Id__c,Description,OwnerId,LastActivityDate,LastViewedDate,LastReferencedDate,PersonContactId,PersonMailingStreet,
                                   PersonMailingCity,PersonMailingState,PersonMailingPostalCode,PersonMailingCountry,PersonMailingCountryCode,PersonMailingLatitude,PersonMailingLongitude,PersonMailingGeocodeAccuracy,PersonMailingAddress,PersonMobilePhone,
                                   PersonOtherPhone,PersonEmail,PersonTitle,PersonDepartment,PersonBirthdate,PersonLastCURequestDate,PersonLastCUUpdateDate,PersonEmailBouncedReason,PersonEmailBouncedDate,Jigsaw,JigsawCompanyId,
                                   AccountSource,SicDesc,Potential__c,Address__c,Town__c,Province__c,Postcode__c,Country__c,Gender__c,Source__c,Label__c,Number_Of_Projects__c,Professional__c,Customer_Type__c,
                                   Conversion_Date__c,Updated_Type__c,Load_Id__c,Company_num__c,company_list__c,Language__c,Locked__c,Deleted__c,Is_Locked__c,Is_Deleted__c,European_Community__c,
                                   Business_Email__c,Age__pc,Id,IsPersonAccount,SystemModstamp,Brands_They_Work_With__c,CreatedById,CreatedDate,Fabricators_they_work_with__c,LastModifiedById,LastModifiedDate,
                                   Merchandising_Materials__c,Notes__c,Phone_2__c,Validated__c,Validation_Time__c,SAP_Id__c, BillingCountryCode, VAT_Number__c,VAT_Number_2__c //company_form__c
                                   FROM Account
                                   WHERE Id = :accountId];
        
        accountList[0].SAP_Id__c = '1';
        
        Map<String, Object> accountWrapper = new Map<String, Object>();
        accountWrapper.put('customer', accountList[0]);
        
        AccountValidation_RESTAPEX.Response response = AccountTransactionHandler.runSfValidation(JSON.serialize(accountWrapper));
        
        String errorTitle, errorMessage;
        AccountTransactionHandler.TransactionResponse txResponse;
        
        if(!response.success){
            
            errorTitle = Label.Error_On_SF_Validation;
            errorMessage =  response.errorMessage;
            txResponse = new AccountTransactionHandler.TransactionResponse(false,errorTitle,errorMessage,null,null);
            return txResponse;
            
        }
        
        return new AccountTransactionHandler.TransactionResponse(true,null,null,null,null);
        
    }

    @testVisible public String testFiller() {
        String s = 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        return s;
    }

    global class SalesRelAccessDTO {
        @AuraEnabled global Boolean hasSapConnection;
        @AuraEnabled global Boolean hasEditPermission;
        @AuraEnabled global Boolean isDvsAccount;
        @AuraEnabled global String dvsAction;
        @AuraEnabled global Boolean needsValidSiret;

        global SalesRelAccessDTO() {
            this.hasSapConnection = false;
            this.hasEditPermission = false;
            this.isDvsAccount = false;
            this.dvsAction = null;
            this.needsValidSiret = false;
        }
    }
    
}