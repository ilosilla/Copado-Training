/*-----------------------------------------------------------------------------------------
Author:         Juan Manuel Martinez
Company:        Neoris
Date:           17-05-2019
Description:    Se encarga del envio automatico de accounts a SAP
Test Class:     Automatic_AccountSendToSAPTest
History
<Date>            <Author>              <Change Description>

-----------------------------------------------------------------------------------------*/
global class Automatic_AccountSendToSAP {
    private static final Integer chunckSize = 4; // Cuantos registros se van a procesar por metodo futuro.
    
    // Divide una lista en pedazos y los manda a metodos futuros.
    public static void ManageSendToSap(List<Id> salesRelIdList){ 
        Integer num = salesRelIdList.size() / chunckSize;
        
        if( num == 0 ){
            SendToSAP_Future(salesRelIdList);
            
        } else {
            
            for(Integer j=0; j<num; j++){
                List<Id> listToSend = new List<Id>();
                
                for(Integer i=j*chunckSize; i<(j*chunckSize+chunckSize); i++){
                    listToSend.add(salesRelIdList[i]);
                }
                
                SendToSAP_Future(listToSend);
            }
            
            List<Id> listToSend = new List<Id>();
            
            for(Integer i=num*chunckSize; i<salesRelIdList.size(); i++){
                listToSend.add(salesRelIdList[i]);
            }
            
            if(!listToSend.isEmpty()){
                SendToSAP_Future(listToSend);
            }
            
        }
    }
    
    @future(callout=true)
    public static void SendToSAP_Future(List<Id> salesRelIdList){
        // Los metodos futuros son para las automatizaciones.
        // El componente de errores de automatizaciones llama directamente a SendToSAP
        SendToSAP(salesRelIdList);
    }
    
    public static void SendToSAP(List<Id> salesRelIdList){
        
        List<Sales_Relationship__c> salesRelListToUpdate = new List<Sales_Relationship__c>();
        
        // Trae los registros enteros de las Sales Rel a enviar
        List<Sales_Relationship__c> salesRelList = [SELECT Id, Name, Account_Org__c, Custom_Id__c, Currency__c, Commercial__c, Distribution_Channel__c, Sales_Office__c,
                                                    Sales_Org__c, Relationship__c FROM Sales_Relationship__c WHERE Id IN: salesRelIdList];
        
        Id userId = UserInfo.getUserId();
        // Calcula el timeout que va a tener cada llamada dependiendo de la cantidad de registros que se procesan.
        // Cada llamada para obtener tokens utiliza el timeout por default de 10 segundos.
        // Cada envio de una sales rel se le asigna un timeout igual a el limite de salesforce menos los timeouts de los tokens divididos en partes iguales.
        Integer timeOut = ((118 - 10 * salesRelIdList.size()) / salesRelIdList.size()) * 1000;
        System.debug('timeOut: ' + timeOut);
        
        if(!salesRelList.isEmpty()){
            
            Set<Id> accIds = new Set<Id>();
            for(Sales_Relationship__c salesRel : salesRelList){
                accIds.add(salesRel.Account_Org__c);
            }
            
            // Trae los registros completos de las cuentas que acompañan las Sales Rel.
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
            
            List<AccountToSAP_Wrapper> wrapperList = new List<AccountToSAP_Wrapper>();
            EmailTemplate emailTemplate; String groupName; Id chatterGroupId;
            
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
            List<FeedItem> postToInsert = new List<FeedItem>();
            List<CustomNotification> customNotifList = new List<CustomNotification>();
            
            try{
                // El nombre del grupo de notificaciones de SAP esta guardado en un registro de Custom Metadata de tipo Sap_Errors_Group_Config__mdt
                groupName = Test.isRunningTest() ? 'test group name' : [SELECT Group_Name__c FROM Sap_Errors_Group_Config__mdt 
                                                                        WHERE DeveloperName = 'Porcelanosa_Group'].Group_Name__c;
                
                chatterGroupId = [SELECT Id FROM CollaborationGroup WHERE Name =: groupName].Id;
                emailTemplate = [SELECT Id, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'SAP_Error_Message_Template_GB'];
                
            } catch(Exception ex){
                System.debug('Error retrieving the Collaborative Group: ' + ex.getMessage());
            }
            
            for(Sales_Relationship__c salesRel : salesRelList){
                // Se envian las request de a una y se generan las notificaciones dependiendo del resultado.
                Map<String, Object> resultMap = SendRequest(accMap.get(salesRel.Account_Org__c), salesRel, timeOut);
                
                if((String) resultMap.get('status') == 'Error'){
                    String errorMessage = (String) resultMap.get('errorMessage');
                    salesRel.Error_Message__c = errorMessage;
                    salesRel.Sap_Status__c = (String) resultMap.get('status');
                    
                    salesRelListToUpdate.add(salesRel);
                    
                    AutomatismsNotifications.generateNotifications(chatterGroupId, userId, emailTemplate, 
                                                                   salesRel, errorMessage, postToInsert,
                                                                   emailList, customNotifList);
                    
                } else {
                    // Almacena las cuentas y sales rel que hay que actualizar.
                    wrapperList.add((AccountToSAP_Wrapper) resultMap.get('accountToSapWrapper'));
                    
                }
                
            }
            
            // Actualiza los registros con los resultados de las llamadas exitosas.
            for(AccountToSAP_Wrapper accountWrapper : wrapperList){
                
                Map<String,String> upsertResults = AccountValidation_RESTAPEX.executeUpsert(accountWrapper);
                
                if(String.isNotBlank(upsertResults.get('errorMessage'))){
                    
                    String errorMessage = Label.Unexpected_Error + '<p>&nbsp;</p>' + upsertResults.get('errorMessage');
                    
                     AutomatismsNotifications.generateNotifications(chatterGroupId, userId, emailTemplate, 
                                                                   accountWrapper.companies[0], errorMessage, postToInsert,
                                                                   emailList, customNotifList);
                    
                } else {
                    
                    customNotifList.add(AutomatismsNotifications.createAutomationNotification(userId, accountWrapper.companies[0], true));
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
             
            AutomatismsNotifications.insertFeedItems(postToInsert);
            AutomatismsNotifications.sendCustomNotifications(customNotifList);
            AutomatismsNotifications.sendEmails(emailList);
            
        }
        
    }
    
    public static Map<String, Object> SendRequest(Account acc, Sales_Relationship__c salesRel, Integer timeOut){
        // Vacia la variable estatica de SAPWS_Utility
        SAPWS_Utility.accountWrapper = null;
        Map<String, Object> resultMap = new Map<String, Object>();
        
        List<Map<String, Object>> companies = new List<Map<String, Object>>{salesRel.getPopulatedFieldsAsMap()};
        
        Map<String, Object> accountWrapper = new Map<String, Object>();
        accountWrapper.put('companies', companies);
        accountWrapper.put('customer', acc);
        accountWrapper.put('language', UserInfo.getLanguage());
        
        System.debug('accountWrapper ' + JSON.serialize(accountWrapper));
        
        SAPWS_Utility.SapResponse response = AccountTransactionHandler.runSAPValidation(JSON.serialize(accountWrapper), timeOut);
        System.debug('Automatic Account Handler Response: ' + response);
        
        if(!response.success){
			// Formatea el mensaje de error agregando etiquetas HTML para poder mostrar espacios en los post y componentes lightning.
            String errorMessage = response.message + ':<p></p>';
            if(response.details != null){
                for( SAPWS_Utility.Detail detail : response.details ){
                    errorMessage += detail.message + ' (' + detail.code + ').<p></p>';
                }
            }
            
            resultMap.put('status', 'Error');
            resultMap.put('errorMessage', errorMessage);
            
        }else{
            
            AccountTransactionHandler.TransactionResponse txResponse;
            AccountToSAP_Wrapper accountToSapWrapper = SAPWS_Utility.getAccountWrapper(JSON.serialize(accountWrapper));
            
            if(String.isBlank(accountToSapWrapper.customer.Sap_Id__c)){
                AccountToSAP_Wrapper responseSapWrapper = (AccountToSAP_Wrapper) JSON.deserialize(response.json, AccountToSAP_Wrapper.class);
                accountToSapWrapper.customer.Sap_Id__c = responseSapWrapper.customer.Sap_Id__c;
            }
            
            accountToSapWrapper.companies[0].Sap_Status__c = 'Success';
            accountToSapWrapper.companies[0].Error_Message__c = null;
            
            resultMap.put('status', 'Success');
            resultMap.put('accountToSapWrapper', accountToSapWrapper);
            
        }
        
        return resultMap;
    }
    
}