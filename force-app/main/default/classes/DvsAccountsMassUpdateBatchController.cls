public with sharing class DvsAccountsMassUpdateBatchController implements Database.Batchable<sObject>{

    public Database.QueryLocator start(Database.BatchableContext bc) {

        
        System.debug('DvsAccountsMassUpdateBatchController\'s start');

        String query = 'SELECT DvsName__c, DvsLastName__c, DvsFirstName__c, DvsStreet__c, DvsPostalCode__c, DvsCity__c, DvsId__c, DvsId2__c, SalesforceName__c, SalesforceStreet__c, SalesforcePostalCode__c, SalesforceCity__c, SalesforceId__c, SalesforceId2__c, SalesforceCountryCode__c, Account__c '
        + ' FROM DvsDiscrepancy__c'
        + ' WHERE DvsId__c != null'
        + ' AND DvsName__c != null';

        System.debug(query);

        return Database.getQueryLocator(query);
    }

    /**
     * Update discrepencies on each batch chunk
     */
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        
        List<DvsDiscrepancy__c> discrepancies = scope;
        System.debug(discrepancies.size());
        // From the discrepancies found, create a list with all the accounts ids.
        // And a map to store the account id and the corresponding discrepancy.
        Map<Id, DvsDiscrepancy__c> discrepanciesMap = new Map<Id, DvsDiscrepancy__c>();
        List<Id> accountIds = new List<Id>();
        for (DvsDiscrepancy__c discrepancy : discrepancies) {
            accountIds.add(discrepancy.Account__c);
            discrepanciesMap.put(discrepancy.Account__c, discrepancy);
        }

        // Retrieve all the accounts to update and already existing backups
        List<Account> accounts = getAccounts(accountIds);
        List<DvsAccountInfo__c> dvsAccountInfoList = getDvsAccountInfoList(accountIds);
        Map<Id, DvsAccountInfo__c> dvsAccountInfoMap = new Map<Id, DvsAccountInfo__c>();

        for (DvsAccountInfo__c dvsAccountInfo : dvsAccountInfoList) {
            dvsAccountInfoMap.put(dvsAccountInfo.Account__c, dvsAccountInfo);
        }

        // Create back up custom object for each account before modifying it
        for (Account account : accounts) {

            DvsAccountInfo__c dvsAccountInfo = dvsAccountInfoMap.get(account.Id);
            
            if (dvsAccountInfo == null) {
                dvsAccountInfo = new DvsAccountInfo__c();
                dvsAccountInfoList.add(dvsAccountInfo);

            }

            dvsAccountInfo.Account__c = account.Id;
            dvsAccountInfo.PreviousName__c = account.Name;
            dvsAccountInfo.PreviousStreet__c = account.BillingStreet;
            dvsAccountInfo.PreviousPostalCode__c = account.BillingPostalCode;
            dvsAccountInfo.PreviousCity__c = account.BillingCity;
            dvsAccountInfo.PreviousId1__c = account.VAT_Number__c;
            dvsAccountInfo.PreviousId2__c = account.VAT_Number_2__c;
            dvsAccountInfo.ProcessedTime__c = Datetime.now();


            DvsDiscrepancy__c discrepancy = discrepanciesMap.get(account.Id);
            account.Name = discrepancy.DVSName__c;
            account.BillingStreet = discrepancy.DVSStreet__c;
            account.BillingPostalCode = discrepancy.DVSPostalCode__c;
            account.BillingCity = discrepancy.DVSCity__c;
            account.VAT_Number__c = discrepancy.DVSId__c;
            account.VAT_Number_2__c = discrepancy.DVSId2__c;
            account.SynchronizedWithDvs__c = true;
        }

        Database.UpsertResult[] srList = Database.upsert(dvsAccountInfoList, false);
        for (Database.UpsertResult sr : srList) {
            if (!sr.isSuccess()) {
                System.debug(sr.getErrors());
            }
        }

        Database.SaveResult[] upList = Database.update(accounts, false);
        for (Database.SaveResult up : upList) {
            if (!up.isSuccess()) {
                System.debug(up.getErrors());
            }
        }

        Database.DeleteResult[] delList = Database.delete(discrepancies, false);
        for (Database.DeleteResult del : delList) {
            if (!del.isSuccess()) {
                System.debug(del.getErrors());
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Job has just finished.');
    }

    private static List<DvsAccountInfo__c> getDvsAccountInfoList(List<Id> accountsIds) {
        
         return [SELECT Id, 
                        Account__c 
                FROM DvsAccountInfo__c 
                WHERE Account__c 
                IN :accountsIds
                ];
    }

    private static List<Account> getAccounts(List<Id> accountIds) {

        return [SELECT Id, 
                        Name, 
                        BillingStreet,
                        BillingPostalCode,
                        BillingCountryCode,
                        BillingCity,
                        VAT_Number__c, 
                        VAT_Number_2__c
                FROM Account 
                WHERE Id IN :accountIds
                ];
    }
}