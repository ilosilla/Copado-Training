/**
* @author Ivan Losilla
* @date November 2020
* @group Triggers
*/
public class AccountTriggerHandler extends BaseTriggerHandler {
 
    public override void beforeDelete(List<SObject> oldItems) {
        for (Account acc : (List<Account>) oldItems) {
            if (acc.SAP_Id__c != null) {
                acc.addError(Label.Account_Cant_delete);
            }
        }
    }

    public override void beforeUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {
        Boolean userHasSap = UserCommons.hasSAPConnection();
        PorcelanosaSetting setting;
        try {
            setting = new PorcelanosaSetting('REQUIRED_VAT', 'ALL');
        } catch (Exception ex) {
            setting = null;
        }

        for (Account acc : (List<Account>) newItems) {
            changesBefore(acc);
            checkVAT(acc, setting);
            setRegisterUniqueId(acc);

            // If any of the Synced SAP fields change, set Dirty to True if the Account is on SAP
            if (String.isNotBlank(acc.Sap_Id__c) && AccountSyncEvaluator.syncToSAP(acc, (Account)oldItems.get(acc.Id)) == true) {
                acc.Dirty__c = true;
            }

            if (String.isNotBlank(acc.Sap_Id__c) && userHasSap == false && test.isrunningtest() == false ) {
                acc.addError(Label.Account_no_editable_context);
            }
        }
    }

    public override void beforeInsert(List<SObject> newItems) {
        Boolean isAdmin = UserUtils.isAdministrator();
        PorcelanosaSetting setting;
        try {
            setting = new PorcelanosaSetting('REQUIRED_VAT', 'ALL');
        } catch (Exception ex) {
            setting = null;
        }

        for (Account acc : (List<Account>) newItems) {
            changesBefore(acc);
            checkVAT(acc, setting);
            setRegisterUniqueId(acc);
        }
    }

    public override void afterUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {
        ExecutionContext context = ExecutionContext.getUserExecutionContext();
        List<Sales_Relationship__c> listSalesRel = new List<Sales_Relationship__c>();
        Set<Id> contactIds = new Set<Id>();

        if (UserCommons.hasSAPConnection()) {
            listSalesRel = createDefaultSalesRelations((List<Account>) newItems, (Map<Id, Account>)oldItems);
            sendSalesRelToSap(listSalesRel);
        }

        for (Account acc : (List<Account>) newItems) {
            if (acc.IsPersonAccount == true) {
                contactIds.add(acc.PersonContactId);
            }
        }
    }
    
    public override void afterInsert(List<SObject> newItems) {
        Boolean isAdmin = UserUtils.isAdministrator();
        List<Sales_Relationship__c> listSalesRel = new List<Sales_Relationship__c>();
        Set<Id> accIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();

        for (Account acc : (List<Account>) newItems) {
            accIds.add(acc.Id);
        }
        
        if (isAdmin == false && UserCommons.hasSAPConnection()) {
            listSalesRel = createDefaultSalesRelations((List<Account>) newItems, new Map<Id,Account>());
            sendSalesRelToSap(listSalesRel);
        }
        createAutomaticOpps((List<Account>) newItems);
        sendInvalidAccountsMail(accIds);
    }
    
    /********************************       Private Methods      *********************************/
    @future
    private static void sendInvalidAccountsMail(Set<Id> accIds) {
        List<Account> newItemsData = new List<Account>();

        newItemsData = AccountUtil.getData(accIds);
        AccountMails.alertNotValidCreation(newItemsData);
    }

    private static void setRegisterUniqueId(Account acc) {
        String domain = acc.F_Domain__c;
        String postal;

        try {
            if (acc.IsPersonAccount) {
                postal = acc.PersonMailingPostalCode;
            } else {
                postal = acc.BillingPostalCode;
            }
    
            if (!String.isBlank(domain) && !String.isBlank(postal)) {
                String cleanDomain = domain.trim().replaceAll('\\s+', '').toUpperCase();
                String cleanPostal = postal.trim().replaceAll('\\s+', '').toUpperCase();
                String postal3 = cleanPostal.length() > 3 ? cleanPostal.substring(0, 3) : cleanPostal;

                // Obtener el país para decidir la lógica
                String country = acc.BillingCountryCode; // O PersonMailingCountry si es PersonAccount
                if (acc.IsPersonAccount) {
                    country = acc.PersonMailingCountryCode;
                }

                if (country == 'US' || country == 'CA') {
                    acc.RegisterUniqueId__c = cleanDomain + ':' + postal3;
                } else {
                    // Lógica normal (todo el código postal)
                    acc.RegisterUniqueId__c = cleanDomain + ':' + cleanPostal;
                }
            } else {
                acc.RegisterUniqueId__c = null;
            }
        } catch (Exception ex) {
            acc.RegisterUniqueId__c = null;
        }
    }

    // Chequea que el vat sea correcto, si no es vacío
    private void checkVAT(Account acc, PorcelanosaSetting settingsRequiredVat) {
        Boolean validVat = true;
        Boolean validate = false;

        if (settingsRequiredVat == null) {
            return;
        }

        List<String> requiredVatCountries = settingsRequiredVat.value1.split(';');

        if (acc.IsPersonAccount == false && requiredVatCountries.contains(acc.BillingCountryCode)) {
            // France
            if (acc.BillingCountryCode == 'FR') {
                if (String.isNotBlank(acc.Vat_number__c)){
                    validate = true;
                }

                if (validate) {
                    validVat = TaxCommons.isValidSiret(acc.VAT_Number__c);
                    if (validVat == true) {
                        acc.VAT_Number_2__c = TaxCommons.getSirenFromSiret(acc.VAT_Number__c);
                    } else {
                        acc.addError(Label.Not_valid_vat);
                    }
                }
            }

            if (acc.BillingCountryCode == 'GB') {
                if (String.isNotBlank(acc.Vat_number__c)) {
                    validVat = TaxCommons.isValidCRN(acc.VAT_Number__c);
                    if (validVat == false && test.isRunningTest() == false) {
                        acc.addError(Label.Not_valid_vat);
                    }
                }

                if (String.isNotBlank(acc.Vat_number_2__c)){
                    validVat = TaxCommons.isValidUKVAT(acc.Vat_number_2__c);
                    if (validVat == false && test.isRunningTest() == false) {
                        acc.addError(Label.Not_valid_vat_2);
                    }
                }
            }
        }
    }

    private void createAutomaticOpps(List<Account> newItems) {
        Id tradeRecTypeId = RecordTypeLibrary.Account_TradeCustomer;
        List<Opportunity> listAutomaticOpps = new List<Opportunity>();

        for (Account acc : newItems) {
            if(acc.RecordTypeId == tradeRecTypeId && acc.Account_Classification__c == 'National House Builders') {
                listAutomaticOpps.add( SalesRelationshipUtils.createAutomaticOpportunity(acc) );
            }
        }
        upsert listAutomaticOpps;
    }

    private void sendSalesRelToSap(List<Sales_Relationship__c> listSalesRel) {
        List<Id> salesRelIdList = new List<Id>();
        if (listSalesRel.isEmpty() == false) {
            for( Sales_Relationship__c salesRel : listSalesRel ){
                salesRelIdList.add(salesRel.Id);
            }

            Automatic_AccountSendToSAP.ManageSendToSap(salesRelIdList);
        }
    }

    private void changesBefore(Account acc) {
        if (Trigger.isInsert) {
            acc.Last_Activity_Date__c = System.now(); 
        }

        if(acc.IsPersonAccount){
            acc.PersonMailingPostalCode = StringUtils.toUpperCase(acc.PersonMailingPostalCode);
            acc.Salutation = AccountUtil.mapSalutation(acc.Salutation);
            acc.Firstname = StringUtils.toUpperCase(acc.Firstname);
            acc.Lastname = StringUtils.toUpperCase(acc.Lastname);
        } else {
            acc.BillingPostalCode = StringUtils.toUpperCase(acc.BillingPostalCode);
            acc.name = StringUtils.toUpperCase(acc.name);
        }
    }

    private List<Sales_Relationship__c> createDefaultSalesRelations(List<Account> newAccounts, Map<Id, Account> oldAccounts) {
        Boolean isAdmin = UserUtils.isAdministrator();
        Id privateRecTypeId = RecordTypeLibrary.Account_PrivateCustomer;
        List<Sales_Relationship__c> salesRelsToInsert = new List<Sales_Relationship__c>();
        Set<Id> accOwnerIds = new Set<Id>();
        Set<Id> newAccIds = new Set<Id>();
        Map<Id,User> accOwnerMap = new Map<Id, User>();
        List<Sales_Relationship__c> salesRelList = new List<Sales_Relationship__c>();
        User triggerUser = [SELECT Id, ProfileId, CountryCode, Default_Sales_Organization__c, Distribution_channel_default__c, Sales_Office__c
                            FROM User WHERE Id =: UserInfo.getUserId()];
        
        // Si la organización tiene restricción, no se crea por defecto la Sales Relationship
        Boolean isRestrictedOrg = SalesRelationshipsDomain.isRestrictedOrg(triggerUser.Default_Sales_Organization__c);
        if (isRestrictedOrg) {
            return salesRelList;
        }

        for(Account acc : newAccounts ){
            accOwnerIds.add( acc.OwnerId );
            newAccIds.add( acc.Id );
        }
        
        salesRelList = [SELECT Id, Account_Org__c, Name, Custom_Id__c, Sales_Org__c, Distribution_Channel__c, CreatedBy.CountryCode
        FROM Sales_Relationship__c WHERE Account_Org__c IN: newAccIds];
        accOwnerMap = new Map<Id, User>([SELECT Id, CountryCode, Default_Sales_Organization__c, Distribution_channel_default__c,
        Sales_Office__c, ProfileId FROM User WHERE Id IN :accOwnerIds]);
                            
        for (Account acc : newAccounts) {
            User newAccOwner = accOwnerMap.get(acc.OwnerId);
            Boolean salesRelAlreadyExist = false;
            if (Trigger.isInsert && acc.RecordTypeId == privateRecTypeId && isAdmin == false) {
                    salesRelsToInsert.add(SalesRelationshipUtils.createDefaultSalesRelations(acc, triggerUser, 'New Account'));
            }

            // Changed owner
            if (Trigger.isUpdate && acc.RecordTypeId ==  privateRecTypeId && acc.SAP_Id__c != null && acc.OwnerId != oldAccounts.get(acc.Id).OwnerId && isAdmin == false && newAccOwner != null){
                for(Sales_Relationship__c salesRel : salesRelList){
                    if(salesRel.Account_Org__c == acc.Id && salesRel.Distribution_Channel__c == newAccOwner.Distribution_channel_default__c && salesRel.Sales_Org__c == newAccOwner.Default_Sales_Organization__c){
                        salesRelAlreadyExist = true;
                        break;
                    }
                }

                // The default Sales Relation doesn't exist
                if( salesRelAlreadyExist == false ){
                    salesRelsToInsert.add(SalesRelationshipUtils.createDefaultSalesRelations(acc, newAccOwner, 'Change Account Owner'));
                }
            }
        }

        upsert salesRelsToInsert;

        return salesRelsToInsert;
    }
}