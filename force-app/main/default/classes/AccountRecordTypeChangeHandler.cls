/*-----------------------------------------------------------------------------------------
Author:         
Company:        Neoris
Date:           17-07-2019
Description:    Controlador para el componente que maneja la conversion Business Account -> Person Account y viceversa
Test Class:     AccountRecordTypeChangeHandler_Test
History
<Date>            <Author>              <Change Description>
-----------------------------------------------------------------------------------------*/

public with sharing class AccountRecordTypeChangeHandler {
    
    @TestVisible private static final String NUMBER_OF_CONTACTS_ERROR = Label.AccRecChange_NUMBER_OF_CONTACTS_ERROR;
    @TestVisible private static final String DIFFERENT_OWNER_ERROR = Label.AccRecChange_DIFFERENT_OWNER_ERROR;
    @TestVisible private static final String PARENT_ID_ERROR = Label.AccRecChange_PARENT_ID_ERROR;
    @TestVisible private static final String REPORTS_TO_ERROR = Label.AccRecChange_REPORTS_TO_ERROR;
    @TestVisible private static final String CHILD_ACCOUNTS_ERROR = Label.AccRecChange_CHILD_ACCOUNTS_ERROR;
    @TestVisible private static final String CHILD_CONTACTS_ERROR = Label.AccRecChange_CHILD_CONTACTS_ERROR;
    
    @AuraEnabled 
    public static Boolean userHasAccess(String recordId){
        return [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE 
                UserId =: UserInfo.getUserId() AND RecordId =: recordId].HasEditAccess;
    }
    
    // Devuelve una lista de record types disponibles para el usuario.
    @AuraEnabled
    public static Map<String, String> getRecordTypes(String recordId){
        Map<String, String> returnMap = new Map<String, String>();
        Account currentAcc = [SELECT RecordTypeId, IsPersonAccount FROM Account WHERE Id =: recordId];
        
        Map<String, Schema.RecordTypeInfo> rtInfoMap = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
        
        // Si el registro es person account trae los record types de business account y viceversa.
        List<RecordType> recordTypeList = [SELECT Id, Name, DeveloperName, IsPersonType 
                                           FROM RecordType WHERE SobjectType = 'Account' 
                                           AND IsPersonType !=:  currentAcc.IsPersonAccount];
        
        for(RecordType rt : recordTypeList){
            Schema.RecordTypeInfo rtInfo = rtInfoMap.get(rt.DeveloperName);
            
            if(rtInfo.isActive() && rtInfo.isAvailable() && !rtInfo.isMaster() 
               && rtInfo.getRecordTypeId() != currentAcc.RecordTypeId){
                   returnMap.put(rtInfo.getName(), rtInfo.getRecordTypeId());
               }
            
        }
        
        return returnMap;
    }
    
    @AuraEnabled
    public static Map<String, String> checkIfPossible(String recordId){
        Map<String, String> responseMap = new Map<String, String>();
        
        Account accWithFields = [SELECT Id, Name, IsPersonAccount, OwnerId, ParentId FROM Account WHERE Id =: recordId];
        
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        
        if(accWithFields.IsPersonAccount){
            responseMap.put('success', 'success');
            
        } else {
            List<Contact> contactList = [SELECT Id, Name, OwnerId, ReportsToId FROM Contact WHERE AccountId =: recordId];
            
            if(contactList.isEmpty()){
                
                List<String> splitList = accWithFields.Name.split(' ', 2);
                String firstName = splitList.size() == 2 ? splitList[0] : accWithFields.Name;
                String lastName = splitList.size() == 2 ? splitList[1] : accWithFields.Name;
                
                Contact newContact = new Contact(FirstName = firstName, LastName = lastName, AccountId = accWithFields.Id, OwnerId = accWithFields.OwnerId);
                Database.SaveResult contactSaveResult = Database.Insert(newContact, dml);
                
                if (contactSaveResult.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully inserted contact. Contact ID: ' + contactSaveResult.getId());
                    responseMap.put('success', contactSaveResult.getId());
                    
                } else {
                    // Operation failed, so get all errors                
                    String errorMessage = 'Error Inserting the necesary contact.\n';
                    
                    for(Database.Error err : contactSaveResult.getErrors()){
                        System.debug('The following error has occurred.');
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Account fields that affected this error: ' + err.getFields());
                        errorMessage += err.getMessage() + '\n';
                    }
                    
                    responseMap.put('error', errorMessage);
                }
                
            } else if(contactList.size() > 1){
                // Each account must have one contact. It can’t have more than one.
                responseMap.put('error', NUMBER_OF_CONTACTS_ERROR);
                
            } else if(contactList.size() == 1){
                
                if(contactList[0].OwnerId != accWithFields.OwnerId){
                    // The account and contact must have the same record owner
                    responseMap.put('error', String.format(DIFFERENT_OWNER_ERROR, new List<String>{contactList[0].Name}));
                    
                } else if(String.isNotBlank(contactList[0].ReportsToId)){
                    // The Reports To field on the Contact must be blank
                    responseMap.put('error', String.format(REPORTS_TO_ERROR, new List<String>{contactList[0].Name}));
                    
                } else if([SELECT Count() FROM Contact WHERE ReportsToId =: contactList[0].Id] > 0){
                    // The Contact is not set as a Reports To for any other contacts
                    responseMap.put('error', String.format(CHILD_CONTACTS_ERROR, new List<String>{contactList[0].Name}));
                }
            }
            
            if(String.isNotBlank(accWithFields.ParentId)){
                // The Parent Account field on the Account must be blank.
                responseMap.put('error', PARENT_ID_ERROR);
            }
            
            if([SELECT Count() FROM Account WHERE ParentId =: recordId] > 0){
                // The Account is not set as a Parent Account for any other accounts.
                responseMap.put('error', CHILD_ACCOUNTS_ERROR);
            }
            
        }
        
        System.debug('responseMap: ' + responseMap);
        return responseMap;
    }
    
    @AuraEnabled
    public static Map<String, String> convertAccount(String recordId, String recordTypeId){
        Map<String, String> responseMap = new Map<String, String>();
        
        SavePoint sp = Database.setSavepoint();
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        
        Account accWithFields = [SELECT Id, PersonMailingCity, PersonMailingCountryCode, PersonMailingCountry, PersonMailingPostalCode, 
                                 PersonMailingStateCode, PersonMailingState, PersonMailingStreet, PersonEmail, PersonContactId,
                                 BillingCity, BillingCountryCode, BillingPostalCode, BillingStateCode, BillingStreet,
                                 Business_Email__c, IsPersonAccount, PersonOtherPhone, Other_Phone__c
                                 FROM Account WHERE Id =: recordId];
        
        if(accWithFields.IsPersonAccount){
            
            accWithFields.BillingCity = accWithFields.PersonMailingCity;
            accWithFields.BillingCountryCode = accWithFields.PersonMailingCountryCode;
            accWithFields.BillingCountry = accWithFields.PersonMailingCountry;
            accWithFields.BillingPostalCode = accWithFields.PersonMailingPostalCode;
            accWithFields.BillingStateCode = accWithFields.PersonMailingStateCode;
            accWithFields.BillingState = accWithFields.PersonMailingState;
            accWithFields.BillingStreet = accWithFields.PersonMailingStreet;
            accWithFields.Business_Email__c = accWithFields.PersonEmail;
            accWithFields.Other_Phone__c = accWithFields.PersonOtherPhone;
            accWithFields.Account_Classification__c = '';
            //accWithFields.Other_account_classification__c = '';
            
        } else {
            
            accWithFields.PersonMailingCity = accWithFields.BillingCity;
            accWithFields.PersonMailingCountryCode = accWithFields.BillingCountryCode;
            accWithFields.PersonMailingPostalCode = accWithFields.BillingPostalCode;
            accWithFields.PersonMailingStateCode = accWithFields.BillingStateCode;
            accWithFields.PersonMailingStreet = accWithFields.BillingStreet;
            accWithFields.PersonEmail = accWithFields.Business_Email__c;
            accWithFields.PersonOtherPhone = accWithFields.Other_Phone__c ;
            accWithFields.Account_Classification__c = 'Private Customer';
            //accWithFields.Other_account_classification__c = '';
            
        }

        Account accConvert = new Account(Id = recordId, recordTypeId = recordTypeId);
        Account firstAccUpdate = accWithFields.IsPersonAccount ? accWithFields : accConvert;
        Account secondAccUpdate = accWithFields.IsPersonAccount ? accConvert : accWithFields;
        
        Database.SaveResult firstSaveResult = Database.Update(firstAccUpdate, dml);
        
        if (firstSaveResult.isSuccess()) {
            // Operation was successful, so get the ID of the record that was processed
            System.debug('Successfully updated account. Account ID: ' + firstSaveResult.getId());
            
            Database.SaveResult secondSaveResult = Database.Update(secondAccUpdate, dml);
            
            if (secondSaveResult.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully updated account. Account ID: ' + secondSaveResult.getId());
            }
            else {
                // Operation failed, so get all errors                
                String errorMessage = '';
                for(Database.Error err : secondSaveResult.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Account fields that affected this error: ' + err.getFields());
                    errorMessage += err.getMessage() + '\n';
                }
                
                responseMap.put('error', errorMessage);
            }
            
        }
        else {
            // Operation failed, so get all errors                
            String errorMessage = '';
            for(Database.Error err : firstSaveResult.getErrors()) {
                System.debug('The following error has occurred.');                    
                System.debug(err.getStatusCode() + ': ' + err.getMessage());
                System.debug('Account fields that affected this error: ' + err.getFields());
                errorMessage += err.getMessage() + '\n';
            }
            
            responseMap.put('error', errorMessage);
        }
        
        if(responseMap.containsKey('error')){
            Database.rollback(sp);
        }
        
        System.debug('responseMap: ' + responseMap);
        return responseMap;
    }
    
}