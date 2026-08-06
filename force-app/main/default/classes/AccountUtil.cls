/**
 * @author 		Ramón Prades
 * @date 		June 2020
 * @group 		Utils
 * @description Account utility methods
 */

public class AccountUtil 
{
    /**
     * @description 	Checks if the account passed is an installer
     */    
    public static Boolean isInstaller(String accountId) {
        List<UserAccounts__c> users = [select User__c from UserAccounts__c where Account__c = :accountId and Role__c = 'INSTALLER' limit 1];
        return (users.size()>0);
    } // isInstaller

	/**
	 * Maps salutation from external values (Magento) to the person account picklist
	 */
	public static String mapSalutation(String salutation) {

		if (String.isNotBlank(salutation)) {

			switch on salutation.toUpperCase() {

				when 'MS.' {
					salutation = '0001';
				}
				when 'MR.' {
					salutation = '0002';
				}
				when 'DEAR' {
					salutation = '0002';
				}
				when 'MRS.' {
					salutation = 'Z001';
				}				
			}
		}
		
		return salutation;
	} // mapSalutation

	/**
	 * Returs the SAP Id of a customer
	 */
	public static String getSAPId(Id accountId) {
		String sapId = null;
		List<Account> acc = [select SAP_Id__c from Account where id = :accountId];
		if (acc.size() > 0) {
			sapId = acc[0].SAP_Id__c;
		}
		return sapId;
	}

	/**
	 * Returs the name of a customer
	 */
	public static String getName(Id accountId) {
		String name = null;
		List<Account> acc = [select Name from Account where id = :accountId];
		if (acc.size() > 0) {
			name = acc[0].Name;
		}
		return name;
	}

    public static String getFromSAPCode(String sapId) {
        String id18 = '';
        if (!String.isBlank(sapId)) {
            List<zsforce1Set__x> records = [select sfobj__c, sapky__c, id18__c from zsforce1Set__x where sfobj__c = 'C' and sapky__c = :sapId.leftPad(10, '0')];
            if (records.size() > 0) {
                id18 = records[0].Id18__c;
            }
        }
        return id18;
    } // sapId    

	public static List<Contact> getContacts(String accountId) {
		return [select Id, Name from Contact where AccountId = :accountId order by Name];
	}

	/**
	 * Given an account id, retrieves all contacts related to it
	 * 
	 * @author mario.navarro@seidor.com
	 * @date fecha 28/11/2023
	 * @param accountId id of the account to get its related contacts
	 * @return the list of contacts related to the account
	 */
	@AuraEnabled(cacheable=true)
	public static List<Contact> getRelatedContacts(String accountId) {
		return [SELECT Id, Name, IsPersonAccount FROM Contact WHERE AccountId = :accountId ORDER BY Name];
	}

	/**
	 * Gets all accounts
	 * 
	 * @author mario.navarro@seidor.com
	 * @date fecha 04/12/2023
	 * @return the list of Accounts found
	 */
	@AuraEnabled(cacheable=true)
	public static List<Id> getTeamMembersAccountsId() {
        List<Id> accountsAvailables = new List<Id>();
        List<AccountTeamMember> teamMemberAccounts = [SELECT Id, AccountId FROM AccountTeamMember WHERE UserId =: Userinfo.getUserId()];
        for (AccountTeamMember accteam: teamMemberAccounts) {
            if (!accountsAvailables.contains(accteam.AccountId)) accountsAvailables.add(accteam.AccountId);
        }
		return accountsAvailables;
	}

	
	/**
	 * @description Given a list of ids, returns all data of the accounts with those Ids
	 * @param accIds Set of Ids 
	 * @return 
	 *
	 * @example 
	 */
	public static List<Account> getData(Set<Id> accIds) {
        String objectName = 'Account';
        List<String> fields = new List<String>(Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().keySet());
        String queryString  = 'SELECT ' + String.join(fields, ',') + ' FROM ' + objectName + ' WHERE Id IN :accIds';

        return Database.query(queryString);
	}
}