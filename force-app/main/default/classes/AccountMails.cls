/**
* @author Ivan Losilla Perez
* @date November 2020
*
* @group Mail
* @group-content ../../ApexDocContent/AccountMails.htm
*
* @description Methods wich sends emails to users
*/
public class AccountMails {
    /******************************************** ACCOUNT APPROVAL POSTCODE **********************************************/
    /**
    * @description check if an Account is not a valid creation looking at the Account Post Code 
    * and the Owner default Sales Org, and sends an email.
    * @param listAccounts List of all the accounts
    *
    */

    public static void alertNotValidCreation(List<Account> listAccounts) {
        try {
            Set<Id> ownersIds = new Set<Id>();
            for (Account acc : listAccounts) {
                ownersIds.add(acc.OwnerId);
            }
            Map<Id,User> listOwners = UserUtils.getMapUserData(ownersIds);

            List<Account> notValidAccountList = filterValidAccountsByPC(listAccounts, listOwners);
            
            if (notValidAccountList.size() > 0) {
                Map<String, List<String>> accountSettingsMails = AccountSettings.getCreateValidationMailsTo();
                List<Mail> mailsToSend = new List<Mail>();
                
                for (Account acc : notValidAccountList) {
                    String countryCode = acc.IsPersonAccount == true ? acc.PersonMailingCountryCode : acc.BillingCountryCode;
                    if (accountSettingsMails.containsKey(countryCode)) {
                        Mail auxMail = new Mail();
                        auxMail.setHtml(alertNotValidCreationHtml(acc, listOwners.get(acc.OwnerId)));
                        auxMail.setGeneric(); // It will come from a generic email address
                        auxMail.setTo(accountSettingsMails.get(countryCode));
                        auxMail.setSubject('NOT VALID ACCOUNT CREATED');
                        mailsToSend.add(auxMail);
                    } 
                }
                MailUtils.sendBatch(mailsToSend);
            }
        } catch (Exception e) {
            SystemUtils.debugWarning('MAIL ALERT VALID CREATION', 'Mail not sent', e);
        }
    }

    private static String alertNotValidCreationHtml(Account acc, User owner) {
        String mailBody = '';
        String longTextBody = Label.account_created_not_valid;
        longTextBody = longTextBody.replace('#LINK', '<a href="' + URL.getOrgDomainUrl().toExternalForm() + '/' + acc.Id + '">LINK</a>');
        longTextBody = longTextBody.replace('#POSTCODE', acc.IsPersonAccount == true ? acc.PersonMailingPostalCode : acc.BillingPostalCode);
        longTextBody = longTextBody.replace('#SALESORG', owner.Default_Sales_Organization__c);
        mailBody+= longTextBody;
        
        return MailStyles.internalStyle() + mailBody;
    }

    private static List<Account> filterValidAccountsByPC(List<Account> listAccounts, Map<Id,User> mapOwners) {
        List<Account> result = new List<Account>();
        for (Account acc : listAccounts) {
            User aux = mapOwners.get(acc.OwnerId);
            if (aux != null && !UserUtils.isAdministrator(aux)) {
                String postCode = acc.IsPersonAccount == true ? acc.PersonMailingPostalCode : acc.BillingPostalCode;
                String countryCode = acc.IsPersonAccount == true ? acc.PersonMailingCountryCode : acc.BillingCountryCode;
                List<String> salesOrg =AddressUtil.salesOrgPostCode(countryCode, postCode);
                if (salesOrg.size() > 0 && ListUtils.anyOn(aux.Sales_Org__c.split(';'), salesOrg) == false) {
                    result.add(acc);
                }
            }
        }

        return result;
    }
}