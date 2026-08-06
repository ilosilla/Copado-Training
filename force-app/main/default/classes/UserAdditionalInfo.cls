/**
* @author Ivan Losilla
* @date November 2024
*
* @group Users 
* @description Class to manage everything about User Additional
*/
public class UserAdditionalInfo {
    public static final String POPUPTIMEOPTION =     'POPUPLASTTIME';
    public static final String DVSMANAGEDACCOUNTS =  'DVSACCOUNTSMANAGED';

    @AuraEnabled
    public static Boolean setLastPopupTime(String userId) {
        try {
            UserAdditionalInfo__c found = getLastPopupTime(userId);

            if (found != null) {
                found.Value1__c = String.valueOf(Datetime.now());
                update found;
            } else {
                UserAdditionalInfo__c aux = new UserAdditionalInfo__c(
                    User__c = userId,
                    infoType__c = POPUPTIMEOPTION,
                    Value1__c = String.valueOf(Datetime.now())
                );
                insert aux;
            }

            return true;
        } catch (Exception ex) {
            return false;
        }
    }

    @AuraEnabled
    public static Boolean setDvsAccountsManaged(String userId, String accountId) {
        try {
            UserAdditionalInfo__c aux = new UserAdditionalInfo__c(
                User__c = userId,
                infoType__c = DVSMANAGEDACCOUNTS,
                Value1__c = accountId,
                Value2__c = String.valueOf(Date.today())
            );
    
            insert aux;
            return true;
        } catch (Exception ex) {
            return false;
        }
    }

    public static UserAdditionalInfo__c getLastPopupTime(String userId) {
        List<Account> result = new List<Account>();
        List<UserAdditionalInfo__c> additionalInfo = [SELECT Id, User__c, InfoType__c, Value1__c, Value2__c 
                                                        FROM UserAdditionalInfo__c
                                                        WHERE User__c =: userId AND InfoType__c =: POPUPTIMEOPTION];
        
        if (additionalInfo.size() > 0) {
            return additionalInfo[0];
        } else {
            return null;
        }
    }

    public static List<Account> getDvsAccountsManaged(String userId, Date dateParameter) {
        List<Account> result = new List<Account>();
        Set<Id> accIds = new Set<Id>();
        List<UserAdditionalInfo__c> additionalInfo = [SELECT Id, User__c, InfoType__c, Value1__c, Value2__c 
                                                        FROM UserAdditionalInfo__c
                                                        WHERE User__c =: userId AND InfoType__c =: DVSMANAGEDACCOUNTS AND Value2__c =: String.valueOf(dateParameter)];
        for (UserAdditionalInfo__c aux : additionalInfo) {
            accIds.add(aux.Value1__c);
        }

        if (accIds.size() > 0 ) {
            result = new AccountsSelector().selectById(accIds);
        }
        
        return result;
    }

    @AuraEnabled
    public static UAIAllInfoDTO getAllInfo(String userId) {
        UAIAllInfoDTO result = new UAIAllInfoDTO();
        result.dvsAccountsManaged = getDvsAccountsManaged(userId, Date.today());
        result.lastPopupTime = getLastPopupTime(userId);
        return result;
    }

    public class UAIAllInfoDTO {
        @AuraEnabled
        public List<Account> dvsAccountsManaged = new List<Account>();
        @AuraEnabled
        public UserAdditionalInfo__c lastPopupTime = null;
    }
}