/**
 * Author           Ramón prades
 * Description      Utility methods for tests
 * Date             May 2020
 * History              
 */
public class TestUtils {
    
    private static User adminUser;
    private static User regularUser;
    private static User genericUser;
    private static Integer idcounter = 1;
    
    public static void enableTriggers() {
		Insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
    } // enableTriggers
    
    public static User getAdminUser() {        
        if (adminUser == null) {        
            String admins = SystemSettings.adminProfiles;
            if ( admins <> null ) {
                List<String> lista = admins.split(';');
                for (String profile : lista ) {
                    try {
                        adminUser = [select Id, Name, ProfileId from User where profileId = :profile and isActive = true limit 1][0];                                
                        break;
                    } catch (ListException lex) {}
                } // for
            }
        }
        return adminUser;        
    } // getAdminUser
    
    public static User getRegularUser() {
        if (regularUser == null) {        
            String admins = SystemSettings.adminProfiles;
            if ( admins <> null ) {
                List<User> users = [select Id, Name, ProfileId from User where isActive = true order by Name];                                
                for (User user : users ) {
                    if (!admins.contains(user.ProfileId )) {
                        regularUser = user;
                        break;
                    } // if
                } // for
            } // if
        } // if
        return regularUser;                
    } // getRegularUser

    public static User getGenericUser() {        
        if (genericUser == null) {        
            String generics = SystemSettings.genericUsers;
            if ( generics <> null ) {
                List<String> lista = generics.split(';');
                for (String generic : lista ) {
                    try {
                        genericUser = [select Id, Name from User where Id = :generic and isActive = true limit 1][0];                                
                        break;
                    } catch (ListException lex) {}
                } // for
            }
        }
        return genericUser;        
    } // getGenericUser
    
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr;        
    }

    public static String getFakeId(Schema.SObjectType otype) {
        String result = String.valueOf(idcounter++);
        return otype.getDescribe().getKeyPrefix() + '0'.repeat(12-result.length()) + result;        
    } // getFakeId

    public static String getPicklistOption(Schema.sObjectField field) {
        String option = null;
        List<Schema.PicklistEntry> result = ReflectionUtils.getPicklistValues(field);
        if (result.size() > 0) {
            option = result[0].getValue();
        }
        return option;
    } // getPicklistOption
    
}