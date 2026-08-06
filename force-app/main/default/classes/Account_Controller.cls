/**
 */
public class Account_Controller{
    @AuraEnabled 
    public static AccountTransactionHandler.TransactionResponse saveAccount(String jsonString, String recordId, Boolean nameChanged){
        
        Map<String, Object> request = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        
        Account acc = [SELECT MasterRecordId, Name, LastName, FirstName, Salutation, Type, ParentId, BillingStreet, BillingCity,BillingState,BillingStateCode,BillingPostalCode,BillingCountry,BillingCountryCode,BillingLatitude,BillingLongitude,
                       BillingGeocodeAccuracy,Phone,Website,PhotoUrl,Industry,NumberOfEmployees,Number_Id__c,Description,OwnerId,LastActivityDate,LastViewedDate,LastReferencedDate,PersonContactId,PersonMailingStreet,
                       PersonMailingCity,PersonMailingState,PersonMailingPostalCode,PersonMailingCountry,PersonMailingCountryCode,PersonMailingLatitude,PersonMailingLongitude,PersonMailingGeocodeAccuracy,PersonMailingAddress,PersonMobilePhone,
                       PersonOtherPhone,PersonEmail,PersonTitle,PersonDepartment,PersonBirthdate,PersonLastCURequestDate,PersonLastCUUpdateDate,PersonEmailBouncedReason,PersonEmailBouncedDate,Jigsaw,JigsawCompanyId,
                       AccountSource,SicDesc,Potential__c,Address__c,Town__c,Province__c,Postcode__c,Country__c,Gender__c,Source__c,Label__c,Number_Of_Projects__c,Professional__c,Customer_Type__c,
                       Conversion_Date__c,Updated_Type__c,Load_Id__c,Company_num__c,company_list__c,Language__c,Is_Locked__c,Is_Deleted__c,European_Community__c,
                       Business_Email__c,Age__pc,Id,IsPersonAccount,SystemModstamp,Brands_They_Work_With__c,CreatedById,CreatedDate,Fabricators_they_work_with__c,LastModifiedById,LastModifiedDate,
                       Merchandising_Materials__c,Notes__c,Phone_2__c,Validated__c,Validation_Time__c,SAP_Id__c, Professional_check__c, Other_Phone__c,  Account_Classification__c, VAT_Number__c,VAT_Number_2__c // company_form__c
                       FROM Account
                       WHERE Id = :recordId];
        
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Account.fields.getMap();
        
        for(String key: request.keySet()){
            // Agregado 3/7/2019
            if(key == 'PersonMailingPostalCode' || key == 'BillingPostalCode'){
                acc.put(key, StringUtils.toUpperCase((String) request.get(key)));
                
            } else {
                acc.put(key, detectDates(fieldMap, request.get(key), key) );
            }
            
            
        }

        AccountTransactionHandler.TransactionResponse result;

        Set<String> contextsWithSAP = new Set<String>();
        String errorTitle = Label.Error_On_SF_Validation;
        String errorMessage =  'Contact avec Fabrice Alberto pour modifier les données du compte';
        Boolean activateError = false;
        List<Execution_Context__mdt> contextsWithSAPList = [SELECT DeveloperName,ExtendedOpps__c,Has_SAP__c,Id,MasterLabel,OwnerAssignation__c,PriceRequest__c FROM Execution_Context__mdt WHERE Has_SAP__c = true];
        for (Execution_Context__mdt execution : contextsWithSAPList) {
            contextsWithSAP.add(execution.DeveloperName);
        }

        ExecutionContext context = ExecutionContext.getUserExecutionContext();
        if (contextsWithSAP.contains(context.MasterLabel) && UserUtils.isAdministrator() == false && acc.SAP_Id__c != null) {
            if (nameChanged == true){
                errorMessage = 'Only an admin can change the name field';
                List<Profile> profiles = [select id, name from profile where name = 'Managers' LIMIT 1];
                Map<String,Schema.RecordTypeInfo> recTypeMap = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
                String privateRecTypeId = recTypeMap.get('Private_Customer').getRecordTypeId();
                if (profiles.size() == 0 || (acc.RecordTypeId != privateRecTypeId && UserInfo.getProfileId() != profiles[0].Id)) {
                    activateError = true;
                }
            }
             if (activateError == true) {
                result = new AccountTransactionHandler.TransactionResponse(false,errorTitle,errorMessage,null,null);
                return result;
             }
        }

        if(acc.SAP_Id__c != null && UserCommons.hasSAPConnection()){
            // Si hay SapId entonces se tiene que enviar a sap.
            Map<String, Object> accountWrapper = new Map<String, Object>();
            accountWrapper.put('customer', acc);
            accountWrapper.put('language', UserInfo.getLanguage());
            
            String jsonTransaction = JSON.serialize(accountWrapper);
            // Asigna el resultado del update y limpia el mensaje de error.
            result = AccountTransactionHandler.runTransaction(jsonTransaction);
            result.errorMessage = filterErrorMessage(result.errorMessage, false);

            // Si es OK el envío a SAP y tiene el campo Dirty a true, lo cambiamos a false
            if (result.errorMessage == '' || result.errorMessage == null) {
                Account accDirty = [SELECT Id, Dirty__c FROM Account WHERE Id =: acc.id];
                accDirty.Dirty__c = false;
                update accDirty;
            }
                        
        } else {
            // Update comun.
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.allowSave = true;
            dml.DuplicateRuleHeader.runAsCurrentUser = true;
            
            Database.SaveResult sr = Database.update(acc, dml);
            if(sr.isSuccess()){
                result = new AccountTransactionHandler.TransactionResponse(true, '', 'Regular Update', String.valueOf(acc.Id), '');
            } else {
                result = new AccountTransactionHandler.TransactionResponse(false, Label.Error_On_SF_Validation, 
                                                                           filterErrorMessage( sr.getErrors()[0].getMessage() , true), String.valueOf(acc.Id), '');
            }
            
        }
        
        return result;
        
    }
    
    public static Object detectDates(Map<String, Schema.SObjectField> fieldMap, Object potentialDate, String fieldName){
        // Como los JSON que vienen de javascript no convierten las fechas al deserializarse, hay que detectar los campos 
        // que sean de tipo date o datetime para poder convertirlos.
        Object result = potentialDate;
        
        if(fieldMap != null && potentialDate != null && fieldName != null){
            Schema.SObjectField field = fieldMap.get(fieldName);
            
            if(field != null){
                String FldType = String.valueOf(field.getDescribe().getType());
                
                switch on FldType {
                    when 'DATE' {
                        result = Date.valueOf((string) potentialDate);
                    }	
                    when 'DATETIME' {
                        result = DateTime.valueOf((string) potentialDate);
                    }
                    when else {
                        result = potentialDate;
                    }
                }     
            } 
        }
        
        return result;
    }
    // Limpia mensajes de errores
    public static string filterErrorMessage(String errorMessage, Boolean regularUpdate){
        //FIELD_INTEGRITY_EXCEPTION FIELD_CUSTOM_VALIDATION_EXCEPTION
        String result = errorMessage;
        if(errorMessage != null){
            integer stringLength = errorMessage.length();
            if(regularUpdate){
                
                integer pos = errorMessage.indexOf('FIELD_INTEGRITY_EXCEPTION');
                result = pos != -1 ? errorMessage.mid(pos, stringLength) : result;
                
                pos = errorMessage.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION');
                result = pos != -1 ? errorMessage.mid(pos, stringLength) : result;
            } else {
                
                result = errorMessage.remove('FIELD_CUSTOM_VALIDATION_EXCEPTION:');
                result = result.remove('Account fields that affected this error');
            }
        }
        
        /*"Error during Salesforce Validations: FIELD_CUSTOM_VALIDATION_EXCEPTION: 
		Invalid VAT Number. Correct format: 123456789Account fields that affected this error: ()\n*/
        
        return result;
    }
    
    @AuraEnabled 
    public static Map<String, Boolean> userHasAccess(String recordId){
        Boolean canEditSapData = true;
        Account acc = new AccountsSelector().selectById(recordId);
        
        Boolean isAdmin = [SELECT Profile.Name FROM User 
                           WHERE Id =: UserInfo.getUserId()].Profile.Name == Label.System_Administrator;
        Boolean hasAccess = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE 
                UserId =: UserInfo.getUserId() AND RecordId =: recordId].HasEditAccess;
        ExecutionContext context = ExecutionContext.getUserExecutionContext();
        Boolean hasSapConnection = context.useSAP;
        Boolean accountOnSap = String.isNotBlank(acc.Sap_Id__c);
        User currentUser = [SELECT Id, Email, Execution_Context__c FROM User WHERE Id =: UserInfo.getUserId()];

        // 05-06-2023 - Ivan Losilla
        // Solo el departamento de contabilidad puede modificar cualquier campo en Salesforce
        // de los users con executioncontext de Francia

        List<GroupMember> groupMemberFR = [SELECT Id, GroupId, Group.DeveloperName, UserOrGroupId FROM GroupMember 
                                where Group.DeveloperName = 'Edit_Accounts_FR' and UserOrGroupId =: UserInfo.getUserId() LIMIT 1];

        if (currentUser.Execution_Context__c == 'FR' && isAdmin == false && groupMemberFR.size() < 1 && accountOnSap == true) {
            canEditSapData = false;
        }

        //Sólo los que pueden extender a la 008, pueden modificar datos importantes
        List<User> extendersExport = SalesRelationshipsDomain.getRestrictedOrgExtendors('008');
        if (currentUser.Execution_Context__c == 'PEXP' && isAdmin == false && accountOnSap == true) {
            canEditSapData = false;
            for (User aux : extendersExport) {
                if (aux.Id == UserInfo.getUserId()) {
                    canEditSapData = true;
                }
            }
        }
        
        return new Map<String, Boolean>{'isAdmin' => isAdmin,
                                        'hasAccess' => hasAccess,
                                        'userHasSap' => hasSapConnection,
                                        'accountOnSap' => accountOnSap,
                                        'canEditSAPData' => canEditSapData};
    }
    
    /**
     * Reads the layout of the account to rebuild the form in the custom component
     */
    @AuraEnabled 
    public static List<LayoutSection> getPageLayoutFields(String recordId, String recordTypeId){
        // Cambio 21/08/19: Se permite especificar el record type del layout que se quiere obtener.
        // Esto es para poder mostrar un layout distinto al layout actual que tiene la cuenta para el cambio record Type
        List<LayoutSection> lstSections = new List<LayoutSection>();
        
        try{
            // First, figure out if record IsPersonAccount
            Account acc = [SELECT Id, IsPersonAccount FROM Account WHERE Id = :recordId];
            String objectApiName = (acc.IsPersonAccount == true) ? 'PersonAccount' : 'Account';
            
            String layoutName = ToolingApiSOQL.getLayoutNameForCurrentUserProfile(Id.valueOf(recordId), recordTypeId);
            String objectApiNameAndLayout = objectApiName + '-' + layoutName;
            
            List<String> componentNameList = new List<String>{objectApiNameAndLayout};
                // Retrieve page layout details
                List<Metadata.Metadata> components = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, componentNameList);
            Metadata.Layout contLayout = (Metadata.Layout) components.get(0);
            
            // We are going to find the fields names and will keep them according to columns so 
            // we can show them as per page layout 
            for(Metadata.LayoutSection ls : contLayout.layoutSections){
                
                LayoutSection section = new LayoutSection(ls.label, ls.layoutColumns.size());
                
                
                List<LayoutColumn> lstColumns = new List<LayoutColumn>();
                Integer maxFieldsInColumn = 0;
                
                for(Metadata.LayoutColumn lc : ls.layoutColumns){
                    
                    LayoutColumn column = new LayoutColumn();
                    
                    // check if there are fields available in that column
                    if(lc.layoutItems != null){ 
                        
                        // Get the max number of fields in a column to preserve the alignment 
                        if(maxFieldsInColumn < lc.layoutItems.size()){
                            maxFieldsInColumn = lc.layoutItems.size();
                        }
                        
                        for(Metadata.LayoutItem li : lc.layoutItems){ 
                            // Pass the LayoutItem object in the LayoutField consturctor        
                            column.fieldList.add(new LayoutField(li));
                        }
                        
                    }
                    // No need to add a column in the section if there is no field available 
                    if(column.fieldList.size() > 0){
                        lstColumns.add(column );
                    }
                    
                }
                
                // Now, we need to arrange the fields in section so we can use them in the iteration 
                // on the component so we will have to arrange them in the order 
                if(maxFieldsInColumn > 0 ){
                    for(Integer i = 0; i < maxFieldsInColumn; i++ ){
                        for(Integer j = 0; j < lstColumns.size(); j++ ){
                            if(lstColumns[j].fieldList.size() > i ){
                                section.fieldList.add(lstColumns[j].fieldList[i] );    
                            }    
                            else{
                                section.fieldList.add(new LayoutField() );
                            }
                        }    
                    }    
                }
                
                lstSections.add(section );
                
            }
            
        }
        
        catch(Exception e ){
        }
        return lstSections;
        
    }
    
    public class LayoutSection{
        
        @AuraEnabled public String label;
        @AuraEnabled public List<LayoutField> fieldList;
        @AuraEnabled public Integer totalColumns;
        
        public LayoutSection(String label, Integer totalColumns){
            this.label = label;
            this.totalColumns = totalColumns;
            this.fieldList = new List<LayoutField>();
        }
        // Sobrecarga del operador igual de la clase
        public Boolean equals(Object obj) {
            Boolean result;
            if(obj!= null && obj instanceOf LayoutSection){
                LayoutSection lS = (LayoutSection) obj;
                result = lS.label == this.label &&
                			lS.fieldList == this.fieldList &&
                			lS.totalColumns == this.totalColumns;
            } else {
                result = false;
            }
            
            return result;
        }
        
    }
    
    private class LayoutColumn{
        
        private List<LayoutField> fieldList;
        
        public LayoutColumn(){
            this.fieldList = new List<LayoutField>();
        }
        
        /*public Boolean equals(Object obj) {
            Boolean result;
            
            if(obj!= null && obj instanceOf LayoutColumn){
                LayoutColumn lC = (LayoutColumn) obj;
                result = lC.fieldList == this.fieldList;
            }else{
                result = false;
            }
            
            return result;
        }*/
        
    }
    
    public class LayoutField{
        
        @AuraEnabled public String fieldName;
        @AuraEnabled public Boolean isRequired;
        @AuraEnabled public Boolean isReadOnly;
        
        public LayoutField(){}
        
        public LayoutField(Metadata.LayoutItem li){
            
            this.fieldName = li.field;
            if(li.behavior == Metadata.UiBehavior.Required ){
                this.isRequired = true;
            }
            else if(li.behavior == Metadata.UiBehavior.ReadOnly ){
                this.isReadOnly = true;
            }
            
        }  
        // Sobrecarga del operador igual de la clase
        public Boolean equals(Object obj) {
            Boolean result;
                if(obj!= null && obj instanceOf LayoutField){
                    LayoutField lF = (LayoutField) obj;
                    result = lF.fieldName == this.fieldName &&
                			lF.isRequired == this.isRequired &&
                			lF.isReadOnly == this.isReadOnly;
                } else {
                    result = false;
                }
                
            return result;
        }

    }
    
}