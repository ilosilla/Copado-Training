@isTest
public class USAAssignatorTest 
{
    @testSetup static void setup() {
        TestUtils.EnableTriggers();
        DataFactoryUser.autoInsert = false;
        List<User> users = DataFactoryUser.createUKUsers(5);
        users[0].LastName = 'NJ-KC';
        users[1].LastName = 'NJ-K@';
        users[2].LastName = 'NJ-@C';
        users[3].LastName = 'US-@C';
        users[4].LastName = 'UNLISTED';
        insert users;
        
        List<PostCodeObjects__c> pcoList = new List<PostCodeObjects__c>();
        pcoList.add(buildObject('NJ', 'KRION', 'CONSUMER', users[0].Id));
        pcoList.add(buildObject('NJ', 'KRION', '', users[1].Id));
        pcoList.add(buildObject('NJ', '', 'CONSUMER', users[2].Id));
        pcoList.add(buildObject('', '', 'CONSUMER', users[3].Id));

        PostCodeObjects__c unlistedRow = buildObject('', '', '', users[4].Id);
        unlistedRow.country__c = '**';
        pcoList.add(unlistedRow);
        insert pcoList;
  	}

    @isTest
    public static void findOwner_01() {      
        // Full match
        USAAssignator aux = new USAAssignator();
        aux.setCountry('US');
        aux.setState('NJ');
        aux.setPostCode('07250');
        aux.setProfile('CONSUMER');
        aux.setProductLine('KRION FACADE');
        User user = aux.getOwner();
        System.assertEquals('NJ-KC', user.LastName, 'Should have been assigned the KRION CONSUMER MANAGER IN NJ');    
    }

    @isTest public static void findOwner_02() {      
        // Full match
        USAAssignator aux = new USAAssignator();
        aux.setCountry('US');
        aux.setState('NJ');
        aux.setPostCode('07250');
        aux.setProfile('ARCHITECT');
        aux.setProductLine('KRION FACADE');
        User user = aux.getOwner();
        System.assertEquals('NJ-K@', user.LastName, 'Should have been assigned the KRION MANAGER IN NJ');    
    }

    @isTest public static void findOwner_03() {      
        // Full match
        USAAssignator aux = new USAAssignator();
        aux.setCountry('US');
        aux.setState('NJ');
        aux.setPostCode('07250');
        aux.setProfile('CONSUMER');
        aux.setProductLine('KITCHENS');
        User user = aux.getOwner();
        System.assertEquals('NJ-@C', user.LastName, 'Should have been assigned the CONSUMER MANAGER IN NJ');    
    }

    @isTest public static void findOwner_04() {      
        // Full match
        USAAssignator aux = new USAAssignator();
        aux.setCountry('US');
        aux.setState('FL');
        aux.setPostCode('07250');
        aux.setProfile('CONSUMER');
        aux.setProductLine('KITCHENS');
        User user = aux.getOwner();
        System.assertEquals('US-@C', user.LastName, 'Should have been assigned the CONSUMER MANAGER IN US');    
    }

    @isTest public static void findOwner_05() {      
        // Full match
        USAAssignator aux = new USAAssignator();
        aux.setCountry('US');
        aux.setState('FL');
        aux.setPostCode('07300');
        aux.setProfile('FIXER');
        aux.setProductLine('KITCHENS');
        User user = aux.getOwner();
        System.assertEquals(null, user, 'User should be null');    
    }

    @isTest public static void findOwner_06() {      
        // Unlisted country
        USAAssignator aux = new USAAssignator();
        aux.setCountry('IT');
        aux.setState('');
        aux.setPostCode('07300');
        aux.setProfile('FIXER');
        aux.setProductLine('KITCHENS');
        User user = aux.getOwner();
        System.assertNotEquals(null, user, 'A user should have been assigned as owner');    
        System.assertEquals('UNLISTED', user.lastName, 'User should be the unlisted');    
    }


    /******************************************************/
    /***************** PRIVATE METHODS ********************/
    /******************************************************/

    private static PostCodeObjects__c buildObject(String state, String product, String profile, String objectId) {
        return new PostCodeObjects__c(
        objectType__c = 'OWNER_USA', 
        country__c = 'US', 
        state__c = state, 
        postCode__c = '', 
        productline__c = product, 
        profile__c = profile, 
        objectId__c = objectId);
    } // buildObject
} // class