/**
* @author 			Ramón Prades
* @date 			November-2020
* @group 			Data Factories
* @description 	    User Data Factories. Should replace User_TestDataFactory
*/
public class DataFactoryUser {

    public static Boolean autoInsert = true;

    /**
     * Creates a UK administrator
     */
    public static User createUKAdmin() {
        DataFactoryOrganization.createData();
        String email = 'ukadmin@ukuser.cxm';        
        User user = new User(Alias = 'tstuka', 
            Email = email,
            EmailEncodingKey ='ISO-8859-1', 
            LastName ='Johnson', 
            CountryCode = 'GB',
            Country = 'United Kingdom',
            ProfileId = getAdminProfile(), 
            UserName = email,
            Sales_Office__c = '2552',
            Sales_Org__c = OrganizationCommons.ORG_SOUTH_EAST + ';' + OrganizationCommons.ORG_NORTH_WEST,
            Default_Sales_Organization__c =OrganizationCommons.ORG_SOUTH_EAST,
            Distribution_Channel__c = '60;70', 
            Distribution_channel_default__c = '70',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_GB',
            LanguageLocaleKey = 'en_US',
            Team_Manager__c = TRUE);
        if (autoInsert) {
            insert user;
        }
        return user;
    } // createUKAdmin

    /**
     * Creates a UK user
     */    
    public static User createUKUser() { 
        return createUKUsers(1)[0];
    } // createUKUser

    /**
     * Creates a UK user
     */    
    public static List<User> createUKUsers(Integer numUsers) { 
        
        DataFactoryOrganization.createData();
        List<User> users = new List<User>();
        Profile profile = [Select Id From Profile Where Name='Standard Retail' LIMIT 1][0];

        Map<String, String> currentOrgsMap = PicklistCommons.getValuesSwaped(User.Sales_Org__c);
        
        for (Integer i = 0; i<numUsers; i++) {
            String email = 'ukuser@ukuser' + i + '.cxm';        
            User user = new User(Alias = 'USER' + i, 
                Email = email,
                EmailEncodingKey ='ISO-8859-1', 
                LastName ='Johnson ' + i, 
                CountryCode = 'GB',
                countries__c = 'GB',
                Country = 'United Kingdom',
                ProfileId = profile.Id, 
                UserName = email,
                Sales_Office__c = '2552',
                Sales_Org__c = OrganizationCommons.ORG_SOUTH_EAST + ';' + OrganizationCommons.ORG_NORTH_WEST,
                Default_Sales_Organization__c =OrganizationCommons.ORG_SOUTH_EAST,
                Distribution_Channel__c = '60;70', 
                Distribution_channel_default__c = '70',
                TimeZoneSidKey = 'GMT',
                LocaleSidKey = 'en_GB',
                LanguageLocaleKey = 'en_US',
                Appointment__c = true,
                Team_Manager__c = TRUE);
            users.add(user);
        }
        if (autoInsert) {
            insert users;
        }
        return users;
    } // createUKUser
  
  

    private static Id getNonAdminProfile() {
        Id profile = null;
        String admins = SystemSettings.adminProfiles;
        if ( admins <> null ) {
            List<String> lista = admins.split(';');
            for (String profileId : lista ) {
                try {
                    Profile p = [select Id from Profile where id != :profileId limit 1][0];                                
                    profile = p.Id;
                    break;
                } catch (ListException lex) {}
            } // for
        }
        return profile;
    } // getAdminProfile

    private static Id getAdminProfile() {
        Id profile = null;
        String admins = SystemSettings.adminProfiles;
        if ( admins <> null ) {
            List<String> lista = admins.split(';');
            for (String profileId : lista ) {
                try {
                    Profile p = [select Id from Profile where id = :profileId limit 1][0];                                
                    profile = p.Id;
                    break;
                } catch (ListException lex) {}
            } // for
        }
        return profile;
    } // getAdminProfile

}