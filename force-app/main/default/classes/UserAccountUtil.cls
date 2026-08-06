/**
* @author Ramón Prades
* @date September 2020
*
* @group User 
* @group-content ../../ApexDocContent/User.htm
*
* @description Utility methods to relate accounts with users (custom object UserAccounts__c)
*/
public class UserAccountUtil {

    public static Id getUser(Id accountId, String role) {
        List<UserAccounts__c> tlist = [select User__c, Role__c from UserAccounts__c where Account__c = :accountId and Role__c = :role];
        if (tlist.size() > 0) {
            return tlist[0].User__c;
        } else {
            return null;
        }
            
    }
}