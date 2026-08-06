/**
* @author 		Ramón Prades
* @date 		December 2021
* @group 		Accounts
* @description 	Account's CONTACT POINT ADDRESS Controller class 
*/
public class ContactAddressController {
    /**
     * Syncs the SAP address in Salesforce
     */
    @AuraEnabled 
    public static DataDTO syncSAPAddresses(String accountId) {  
        DataDTO result = new DataDTO();    
        try {
            Account account = [select Id, SAP_Id__c, AddressesSynced__c, RecordTypeId from Account where Id = :accountId limit 1];
            result.syncable = ContactPointAddressesService.isAccountSyncable(account.RecordTypeId, account.SAP_Id__c);
            if (result.syncable) {
                result.addresses = ContactPointAddressesService.syncFromSAP(accountId, false);
                result.synced = true;    
            }
        } catch(ContextException ex1) {            
            result.alreadySynced = true; 
        } catch(Exception ex3) {
            result.error = true;
            result.errorMessage = ex3.getMessage();
            throw ex3;
        }
        return result;       
    } // syncSAPAddresses

    /**
     * tests the update of an address to see if tehre are errors
     */
    @AuraEnabled public static Boolean testAddressUpsert(ContactPointAddress address) {
        try {
            ContactPointAddressesService.testSave(address);
        } catch (ValidationException vex) {
            AuraHandledException auraEx = new AuraHandledException(vex.getMessage());
            throw auraEx;
        }
        return true;
    } // testUpsertObject

    /**
     * Saves a salesforce address and sends it to SAP
     */
    @AuraEnabled public static ContactPointAddress saveAddress(ContactPointAddress address) {        
        //try {
            ContactPointAddressesService.save(address);
            return address;
        /*} catch (Exception ex) {
            AuraHandledException auraEx = new AuraHandledException(ex.getMessage());
            throw auraEx;
        }*/
    } // saveAddress

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/

    public class DataDTO {
        @AUraEnabled public Boolean error = false;
        @AUraEnabled public Boolean syncable = false;
        @AUraEnabled public Boolean alreadySynced = false;
        @AUraEnabled public Boolean accountNotInSAP = false;
        @AuraEnabled public Boolean synced = false;
        @AuraEnabled public List<ContactPointAddress> addresses = new List<ContactPointAddress>();
        @AUraEnabled public String errorMessage;
    } // inner class

} // class