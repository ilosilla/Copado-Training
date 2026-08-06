/**
 * @description  : 
 * @author       : Nubika Team <example@nubika.com>
 * @version      : 1.0.0
 * @date         : 23-08-2023
 * @group        : 
 * @see          : 
**/
public class NB2B_SettingsManager {

    private static final Boolean isTest = Test.isRunningTest();
    public static final String errorEmailAddressFixed = System.Label.B2B_OrderErrorMailAddress;
    
    public static final NB2B_Settings__c settings {
        get{
            if(settings==null){
                return NB2B_Settings__c.getInstance();
            }
            return settings;
        }set;
    }

    public static final List<String> errorEmailAddresses {
        get{
            if(errorEmailAddresses == null){
                errorEmailAddresses = new List<String>();
                String emailFixed;
                List<String> addressesList = new List<String>();
                if(!isTest && settings.NB2B_CartToOrderFailEmailAddress__c != null){
                    addressesList = settings.NB2B_CartToOrderFailEmailAddress__c.split(',');
                    emailFixed = errorEmailAddressFixed;
                }else{
                    emailFixed = 'test@test.com'; 
                }
                errorEmailAddresses.addAll(addressesList);
                errorEmailAddresses.add(emailFixed);
            }
            return errorEmailAddresses;
        }set;
    }
}