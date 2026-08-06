/**
* @author Ivan Losilla
* @date September 2022
* @group Scripts
* @description Gets the Sales Rel with an Error and sends everything to SAP again, included the Account.
* - Creates the account on SAP if it didn't exist
* - Updates the info on SAP if the account already exists on SAP
*/
global class ScriptSendAccountsToSAPFusionPart2 implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{
    private Boolean isTest = true;
    global ScriptSendAccountsToSAPFusionPart2(Boolean isTestParam) {
        this.isTest = isTestParam;
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Account_Org__c,B2BEnabled__c,Business_Unit__c,Bzirk__c,Commercial__c,Commission_Agent__c,CreatedById,Currency__c,Custom_Id__c,Distribution_Channel__c,Email__c,Error_Message__c,Id,Is_Locked__c,Locked__c,Name,Notes__c,Phone__c,Reason_of_creation__c,RecordTypeId,Relationship__c,Sales_Office__c,Sales_Org__c,SAP_Id__c,Sap_Status__c FROM Sales_Relationship__c WHERE sap_status__c = \'Error\'';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Sales_Relationship__c> scope) {
            sendToSAP(scope);
    }
    
    global void finish(Database.BatchableContext bc){
    }

    private void sendToSAP(List<Sales_Relationship__c> scope) {
        Set<Id> accIds = new Set<Id>();
        System.debug('Sales Reals ----------');
        for (Sales_Relationship__c salesRelAux : scope) {
            System.debug(salesRelAux);
            accIds.add(salesRelAux.Account_Org__c);
        }

        if (this.isTest == false) {
            Map<Id, Account> accMap = new Map<Id, Account>([SELECT Account_Classification__c, MasterRecordId, Name, LastName, FirstName, Salutation, Type, ParentId, BillingStreet, BillingCity,BillingState,BillingStateCode,BillingPostalCode,BillingCountry,BillingLatitude,BillingLongitude,
                                                                BillingGeocodeAccuracy,Phone,Website,PhotoUrl,Industry,NumberOfEmployees,Number_Id__c,Description,OwnerId,LastActivityDate,LastViewedDate,LastReferencedDate,PersonContactId,PersonMailingStreet,
                                                                PersonMailingCity,PersonMailingState, PersonMailingStateCode, PersonMailingPostalCode,PersonMailingCountry,PersonMailingCountryCode,PersonMailingLatitude,PersonMailingLongitude,PersonMailingGeocodeAccuracy,PersonMailingAddress,PersonMobilePhone,
                                                                PersonOtherPhone,PersonEmail,PersonTitle,PersonDepartment,PersonBirthdate,PersonLastCURequestDate,PersonLastCUUpdateDate,PersonEmailBouncedReason,PersonEmailBouncedDate,Jigsaw,JigsawCompanyId,
                                                                AccountSource,SicDesc,Potential__c,Address__c,Town__c,Province__c,Postcode__c,Country__c,Gender__c,Source__c,Label__c,Number_Of_Projects__c,Professional__c,Customer_Type__c,
                                                                Conversion_Date__c,Updated_Type__c,Load_Id__c,Company_num__c,company_list__c,Language__c,Is_Locked__c,Is_Deleted__c,European_Community__c,
                                                                Business_Email__c,Age__pc,Id,IsPersonAccount,SystemModstamp,Brands_They_Work_With__c,CreatedById,CreatedDate,Fabricators_they_work_with__c,LastModifiedById,LastModifiedDate,
                                                                Merchandising_Materials__c,Notes__c,Phone_2__c,Validated__c,Validation_Time__c,SAP_Id__c, BillingCountryCode, RecordTypeId, Other_Phone__c, VAT_Number__c,VAT_Number_2__c //company_form__c
                                                                FROM Account
                                                                WHERE Id IN: accIds]);
    
            Integer timeOut = ((118 - 10 * scope.size()) / scope.size()) * 1000;
            List<Sales_Relationship__c> salesRelListToUpdate = new List<Sales_Relationship__c>();
            List<AccountToSAP_Wrapper> wrapperList = new List<AccountToSAP_Wrapper>();

            for (Sales_Relationship__c salesRelAux : scope) {
                Map<String, Object> resultMap = Automatic_AccountSendToSAP.SendRequest(accMap.get(salesRelAux.Account_Org__c), salesRelAux, timeOut);
                    
                System.debug('-------- Error Sales Rels -------');
                if((String) resultMap.get('status') == 'Error'){
                    String errorMessage = (String) resultMap.get('errorMessage');
                    System.debug(errorMessage);
                    salesRelAux.Error_Message__c = errorMessage;
                    salesRelAux.Sap_Status__c = (String) resultMap.get('status');
                    salesRelListToUpdate.add(salesRelAux);
                    
                } else {
                    wrapperList.add((AccountToSAP_Wrapper) resultMap.get('accountToSapWrapper'));
                }
            }

            // Actualiza los registros con los resultados de las llamadas exitosas.
            for(AccountToSAP_Wrapper accountWrapper : wrapperList){
                Map<String,String> upsertResults = AccountValidation_RESTAPEX.executeUpsert(accountWrapper);

                if(String.isNotBlank(upsertResults.get('errorMessage'))){
                    String errorMessage = Label.Unexpected_Error + '<p>&nbsp;</p>' + upsertResults.get('errorMessage');
                     System.debug(errorMessage);
                }
            }
    
            // Actualiza las Sales Rels con los errores que se produjeron en las llamadas.
            if(!salesRelListToUpdate.isEmpty()){
                    
                Database.SaveResult[] srList = Database.Update(salesRelListToUpdate, false);
                
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {        
                        System.debug('Successfully Updated Sales Rel with ID: ' + sr.getId());
                    }
                    else {
                        System.debug('The following error has occurred updating the Sales Rel.');
                        
                        for(Database.Error err : sr.getErrors()) {
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Fields that affected this error: ' + err.getFields());
                        }
                    }
                }
            }
        }
        
    }
}