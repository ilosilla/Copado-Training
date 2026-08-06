public class SalesRelationshipTriggerHandler extends BaseTriggerHandler {
    public override void beforeInsert(List<SObject> newItems) {
        User triggerUser = [SELECT Id, ProfileId, CountryCode, Default_Sales_Organization__c, Distribution_channel_default__c, Sales_Office__c
                            FROM User WHERE Id =: UserInfo.getUserId()];

        for (Sales_Relationship__c sRel : (List<Sales_Relationship__c>) newItems) {
            sRel.Custom_Id__c = sRel.Account_Org__c + '-' + sRel.Sales_Org__c + '-' + sRel.Distribution_Channel__c;

            sRel.Name = SalesRelationshipUtils.getSalesRelName(sRel, triggerUser.CountryCode);
            if (!String.isBlank(sRel.Currency__c)) {
                sRel.CurrencyIsoCode = sRel.Currency__c;
            }
        }
    }

    public override void beforeUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {
        Map<Id,Sales_Relationship__c> oldItemsTransformed = (Map<Id,Sales_Relationship__c>) oldItems;
        for (Sales_Relationship__c sRel : (List<Sales_Relationship__c>) newItems) {
            if( sRel.Sap_Status__c != oldItemsTransformed.get(sRel.Id).Sap_Status__c && sRel.Sap_Status__c == 'Success'){
                sRel.Error_Message__c = null;
            }
            if (!String.isBlank(sRel.Currency__c)) {
                sRel.CurrencyIsoCode = sRel.Currency__c;
            }
        }
    }

    public override void afterInsert(List<SObject> newItems) {
        insertAutomaticOpportunities((List<Sales_Relationship__c>) newItems);
        platformEventNew((List<Sales_Relationship__c>) newItems);
       
    }

    
    /******************************** Private Methods ************************************/

    public static void UpdateOwner(List<String> salesRelIds){        
        List<Sales_Relationship__c> sRelsData = [SELECT Id, Account_Org__c, Sales_Office__c,Sales_Org__c,Account_Org__r.Owner.Profile.Name
                                            FROM Sales_Relationship__c
                                            WHERE Id IN : salesRelIds];        
        System.debug(sRelsData);
        Set<String> accIds = new Set<String>();
        Set<String> salesOffices = new Set<String>();
        Set<String> salesOrgs = new Set<String>();       
        for (Sales_Relationship__c sRel : sRelsData) {
            salesOffices.add(sRel.Sales_Office__c);
            accIds.add(sRel.Account_Org__c);
            salesOrgs.add(sRel.Sales_Org__c);            
        }

        List<RegionalSettings__mdt> rlist = [Select reassignOwner__c,SalesOrganization__c From RegionalSettings__mdt Where SalesOrganization__c IN :salesOrgs];
        if (rlist.isEmpty() == false) {
            Map<String, RegionalSettings__mdt> salesOrgsStatus = new Map<String, RegionalSettings__mdt>();

            for (RegionalSettings__mdt r : rlist) {
                salesOrgsStatus.put(r.SalesOrganization__c, r);
            }

            List<User> users = [SELECT Id, Sales_Office__c
                                FROM User
                                WHERE Sales_Office__c IN : salesOffices
                                AND IsActive = true];
            
            Map<String, List<User>> salesOfficeUsers = new Map<String, List<User>>();
            for (User u : users) {
                if (salesOfficeUsers.containsKey(u.Sales_Office__c) == false) {
                    salesOfficeUsers.put(u.Sales_Office__c, new List<User>{u});
                } else {
                    List<User> usersList = salesOfficeUsers.get(u.Sales_Office__c);
                    usersList.add(u);
                    salesOfficeUsers.put(u.Sales_Office__c, usersList);
                }
            }

            Map<String, Account> accsMap = new Map<String, Account>();
            List<Account> accounts = [SELECT Id, OwnerId FROM Account WHERE Id IN : accIds];

            for (Account acc : accounts) {
                accsMap.put(acc.Id, acc);
            }

            for (Sales_Relationship__c sRel : sRelsData) {     
                if(sRel.Account_Org__r.Owner.Profile.Name =='Porcelanosa Administrator' 
                    || sRel.Account_Org__r.Owner.Profile.Name =='System Administrator' 
                    || sRel.Account_Org__r.Owner.Profile.Name =='API Only')
                {
                    if (salesOrgsStatus.containsKey(sRel.Sales_Org__c) && salesOrgsStatus.get(sRel.Sales_Org__c).reassignOwner__c ==true) {
                        List<User> Owners = salesOfficeUsers.get(sRel.Sales_Office__c);
                        if (accsMap.containsKey(sRel.Account_Org__c)) {                   
                            Account acc = accsMap.get(sRel.Account_Org__c);
                            Integer randomIndex = (Integer) Math.floor(Math.random() * Owners.size());
                            User OwnerRandom = Owners[randomIndex];                        
                            acc.OwnerId = OwnerRandom.Id;                        
                            accsMap.put(sRel.Account_Org__c, acc);
                        }
                    }
                }
                
            }
            // Actualizar en Salesforce
            update accsMap.values();
        }
        
        
    }

    private void insertAutomaticOpportunities(List<Sales_Relationship__c> newItems){
        Set<Id> accIds = new Set<Id>();
        Id resellerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Third_party_Retailer_Reseller').getRecordTypeId();
        Id fabricatorRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Fabricator').getRecordTypeId();
        Id tradeRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Trade_and_Specificators').getRecordTypeId();
        Id oppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Automatic_Opportunity').getRecordTypeId();
        List<Opportunity> oppsToInsert = new List<Opportunity>();
        Set<Id> oppsToInsertAccountsId = new Set<Id>();
        Map<Id, Account> mapAccounts = new Map<Id, Account>();
        Map<Id, Opportunity> mapAutomaticOpps = new Map<Id, Opportunity>();

        for(Sales_Relationship__c salesRel : newItems){
            accIds.add(salesRel.Account_Org__c);
        }
        
        // Cuentas de las sales rel
        mapAccounts = new Map<Id,Account>([SELECT Id, Name, RecordTypeId FROM Account WHERE Id IN :accIds AND (RecordTypeId =: resellerRecordTypeId OR RecordTypeId =: fabricatorRecTypeId OR
                                (RecordTypeId =: tradeRecTypeId AND Account_Classification__c = 'National House Builders'))]);
        
        // Busca las Opp automáticas de las cuentas
        for (Opportunity opp : [SELECT Id, AccountId FROM Opportunity WHERE RecordTypeId =: oppRecordTypeId AND AccountId IN :mapAccounts.keySet()] ) {
            mapAutomaticOpps.put(opp.AccountId, opp);
        }
        
        for(Sales_Relationship__c newSalesRel : newItems){
            Boolean alreadyExists = false;
            if (mapAccounts.containsKey(newSalesRel.Account_Org__c)) {
                // The automatic Opp already exist
                if (mapAutomaticOpps.containsKey(newSalesRel.Account_Org__c)) {
                    alreadyExists = true;
                    break;
                }

                // Already added to the Automatic Opps to insert
                if (!alreadyExists && oppsToInsertAccountsId.contains(newSalesRel.Account_Org__c)) {
                    alreadyExists = true;
                    break;
                }

                // The Automatic Opp doesn't exist, so we create it
                if(!alreadyExists){
                    try{
                        Account acc = mapAccounts.get(newSalesRel.Account_Org__c);
                        oppsToInsert.add( SalesRelationshipUtils.createAutomaticOpportunity(acc) );
                        oppsToInsertAccountsId.add(acc.Id);
                    } catch(Exception ex){
                        System.debug('Error creating the opportunity: ' + ex.getMessage());
                    }
                }
            }
        }

        if( !oppsToInsert.isEmpty() ){
            Database.SaveResult[] oppListResults = Database.insert(oppsToInsert, false);
            
            for(Database.SaveResult sr : oppListResults){
                if(!sr.isSuccess()){
                    System.debug('Insert automatic opportunity error: ' + sr.getErrors()[0].getMessage() );
                }
            }
        }
    }

    /**
    * @description Creates Platform Events about the new event
    */
    private void platformEventNew(List<Sales_Relationship__c> salesRels) {
        List<PENewSalesRelationship__e> listPlatformEvents = new List<PENewSalesRelationship__e>();
        for (Sales_Relationship__c salesRel : salesRels) {
            listPlatformEvents.add( new PENewSalesRelationship__e( objectId__c = salesRel.Id ));
        }
        List<Database.SaveResult> results = EventBus.publish(listPlatformEvents);
       
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event "New Sales Relationship".');
            } else {
                for(Database.Error err : sr.getErrors()) {
                    Logger.error('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    Logger.saveLog();
                }
            }
        }
    } // platformEventNew


}