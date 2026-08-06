@isTest public class CountryOwnerAssignatorTest {

	@testSetup static void setup() {
        DataFactoryUser.autoInsert = false;
        List<User> users = DataFactoryUser.createUKUsers(2);
        users[0].LastName = 'USER-0';
        users[1].LastName = 'USER-1';
        insert users;

        List<PostCodeObjects__c> pcoList = new List<PostCodeObjects__c>();
        pcoList.add(new PostCodeObjects__c(objectType__c = 'MBK-EUR', country__c = 'IT', objectId__c = users[0].id));
        pcoList.add(new PostCodeObjects__c(objectType__c = 'MBK-EUR', country__c = '**', objectId__c = users[1].id));
        insert pcoList;
    }
    
    @isTest static void test001() {
        String errorMessage = '';
        CountryOwnerAssignator assignator = new CountryOwnerAssignator();
        assignator.setCountry('IT');
        try {
            assignator.getOwner();
            Assert.fail('An exception should have been raised');
        } catch (Exception ex) {
            errorMessage = ex.getMessage();
        }
        Assert.isTrue(String.IsNotBlank(errorMessage), 'An error message is expected');
    }

    @isTest static void test002() {
        CountryOwnerAssignator assignator = new CountryOwnerAssignator();
        assignator.setVariant('MBK-EUR');
        assignator.setCountry('IT');
        User u0 = assignator.getOwner();
        Assert.areEqual('USER-0', u0.LastName, 'Wrong user');

        assignator.setCountry('GE');
        User u1 = assignator.getOwner();
        Assert.areEqual('USER-1', u1.LastName, 'Wrong user');
    }

}