/**
* @author 		Ramón Prades
* @date 		October 2021
* @group 		Leads
* @description 	Lead edit component controller.
*/

public class LeadEditController {

    /**
     * Gets the list of contacts of an account
     */
    @AuraEnabled 
    public static List<Contact> getContacts(String accountId) {
        List<Contact> contacts = new List<Contact>();
        if (accountId != null) {
            Account account = [select Id, Name, IsPersonAccount from Account where Id = :accountId limit 1];   
            if (!account.IspersonAccount) {
                contacts = AccountUtil.getContacts(accountId);
            }
        }        
        return contacts;
    } // getContacts

    /**************************************************************************
     * INNER CLASSES
     **************************************************************************/
}