/**
* @author 		Ramón Prades
* @date 		November 2021
* @group 		Utils
* @description 	Class to deal with SAP delivery addresses
*/
public without sharing class ContactPointAddressesService {

    /**
     * Reads the list of contact addresses of an account. 
     * The account is synced with SAP if necessary.
     */
    public static List<ContactPointAddress> getAccountAddresses(Id accountId) {
        List<ContactPointAddress> addresses = new List<ContactPointAddress>();
        try {
            addresses = syncFromSAP(accountId, false);
         } catch (ContextException cex) {
            ContactPointAddressesSelector selector = new ContactPointAddressesSelector();
            addresses = selector.selectByAccount(new Set<Id>{accountId});
         }
         return addresses;         
    } // getAccountAddresses

    /**
     * Reads a list of addresses from SAP and overwrites
     * the current list of addresses. 
     * - resync: When false only reads from SAP if the account has not been synced yet.
     *           When true reads again the addresses and updates chages.
     */
    public static List<ContactPointAddress> syncFromSAP(String accountId, Boolean resync) {

        Account account;
        
        try {
            account = new AccountsSelector().selectById(new Set<Id>{accountId})[0];
        } catch(Exception ex) {
            throw new ObjectNotFoundException('Account "' + accountId + '" not found!');
        }
        if (account.AddressesSynced__c && !resync) { 
            throw new ContextException('Account already synchronized!');
        }
        if (!ContactPointAddressesService.isAccountSyncable(account.recordTypeId, account.SAP_Id__c)) {
               throw new ContextException('Syncronization not enabled for this account!');
        }
        // Reads addresses from SAP
        List<ContactPointAddress> sapAddresses = SAPAddressHelper.readAccountAddresses(account.SAP_Id__c, true); // from SAP
        List<ContactPointAddress> syncedAddresses = syncFromSAP(accountId, sapAddresses);
        account.AddressesSynced__c = true;
        Database.update(account, false, AccessLevel.SYSTEM_MODE);        
        return syncedAddresses;
    } // syncFromSAP

    public static List<ContactPointAddress> syncFromSAP(String accountId, List<ContactPointAddress> sapAddresses) {
        List<ContactPointAddress> addresses = new List<ContactPointAddress>();        
        Map<String, ContactPointAddress> existingAddressesMap = new Map<String,ContactPointAddress>();
        if (sapAddresses.size() > 0) {
            existingAddressesMap = readAccountAddresses(accountId);            
            // Sync existing with SAP
            for (ContactPointAddress sapAddress : sapAddresses) {  
                sapAddress.ParentId = accountId;
                ContactPointAddress addr = existingAddressesMap.get(sapAddress.SAPId__c);
                if (addr != null) {
                    sapAddress.Id = addr.Id;
                    existingAddressesMap.remove(sapAddress.SAPId__c);
                }
                addresses.add(sapAddress);
            }
            if (addresses.size() > 0) {
                Database.upsert(addresses, false, AccessLevel.SYSTEM_MODE);
            }
            Set<Id> idsToDelete =  new Set<Id>();
            for (ContactPointAddress address : existingAddressesMap.values()) {
                idsToDelete.add(address.Id);
            }
            if (idsToDelete.size() > 0) {
                List<ContactPointAddress> addressesToDelete = [select Id from ContactPointAddress where id in :idsToDelete];
                if (addressesToDelete.size() > 0) {
                    delete addressesToDelete;
                }
            }
        }
        return addresses;
    } // syncFromSAP

    /**
     * Save Contact Point Address
     * Premise: Users can create CPA only AFTER the account has syned its addresses with SAP.
     */
    public static void save(ContactPointAddress address) {
        try {
            Account parentAccount = readParentAccountForSave(address);
            validateParentAccountForAddressSync(parentAccount);
            SAPAddressHelper.AddressDTO dto = SAPAddressHelper.sendAddressToSAP(address);
            if (address.SAPId__c == null) {
                address.SAPId__c = dto.sapId;
            }
            upsert address;
        } catch(ValidationException ex1) {
            throw ex1;
        } catch (DmlException dmlEx) {
            ValidationException vex = new ValidationException(dmlEx.getMessage());
            throw vex;
        }
    } // save

    /**
     * Saves and rolls back the database operation to test if the record is ok
     */
    public static void testSave(ContactPointAddress address) {
        Savepoint sp = Database.setSavepoint();
        try {
            upsert address;
        } catch (DmlException dmlEx) {
            ValidationException vex = new ValidationException(dmlEx.getMessage());
            throw vex;
        } finally {
            Database.rollback(sp);
        } 
    } // testSave

    /**
     * Returns true if the account can sync its addresses
     */
    public static Boolean isAccountSyncable(String recordTypeId, String SAPId) {
        // Extend CPA to all accounts and persona accounts
        return (String.IsNotBlank(SAPID)); // && recordTypeId == RecordTypeLibrary.Account_ResellerCustomer);
    }    

    /**
     * Returns a list of addresses edited to be used in a picklist.
     * The name is build as: City Postcode (Name)
     */
    public static List<PicklistItem> getPicklist(Id accountId) {
        List<ContactPointAddress> addresses = new ContactPointAddressesSelector().selectByAccount(new Set<Id>{accountId});
        List<PicklistItem> results = new List<PicklistItem>();
        for (ContactPointAddress cpa : addresses) {
            PicklistItem item = new PicklistItem();
            item.Id = cpa.Id;
            item.isDefault = cpa.IsDefault;
            item.key = cpa.SAPId__c;
            item.label = AddressCommons.buildAddressLabel(cpa.Name, cpa.address);
            item.address = cpa;
            results.add(item);
        }
        return results;
    } // getPicklist

    ///////////////////////////////////////////////////////////////////////
    // PRIVATE METHODS
    ///////////////////////////////////////////////////////////////////////

    /*
     * Builds a map of SAPId and Address
     */
    private static Map<String, ContactPointAddress> readAccountAddresses(String accountId) {
        Map<String, ContactPointAddress> addressesMap = new Map<String, ContactPointAddress>();
        ContactPointAddressesSelector selector = new ContactPointAddressesSelector();
        List<ContactPointAddress> addresses = selector.selectByAccount(new Set<Id>{accountId});
        for (ContactPointAddress addr : addresses) {            
            addressesMap.put(addr.SAPId__c, addr);
        }
        return addressesMap;
    } // readAccountAddresses

    private static Account readParentAccountForSave(ContactPointAddress address) {
        if (address == null || address.ParentId == null) {
            throw new ValidationException('A parent account is required to save the address.');
        }

        List<Account> accounts = [
            SELECT Id, SAP_Id__c, AddressesSynced__c
            FROM Account
            WHERE Id = :address.ParentId
            LIMIT 1
        ];
        if (accounts.isEmpty()) {
            throw new ValidationException('Parent account not found for address save.');
        }

        return accounts[0];
    }

    private static void validateParentAccountForAddressSync(Account account) {
        if (String.isBlank(account.SAP_Id__c)) {
            throw new ValidationException('The account must have a SAP Id before saving delivery addresses.');
        }
        if (!account.AddressesSynced__c) {
            throw new ValidationException('The account must synchronize its SAP delivery addresses before creating or editing addresses.');
        }
    }
    
    ///////////////////////////////////////////////////////////////////////
    // INNER CLASSES
    ///////////////////////////////////////////////////////////////////////
    public class PicklistItem {
        @AuraEnabled public String key;
        @AuraEnabled public String label;
        @AuraEnabled public Boolean isDefault;
        @AuraEnabled public Id Id;
        @AuraEnabled public ContactPointAddress address;
    }

} // class