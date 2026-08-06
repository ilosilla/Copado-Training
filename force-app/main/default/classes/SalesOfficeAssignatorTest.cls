@isTest
public class SalesOfficeAssignatorTest {
  @testSetup static void setup() {
    Insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
    List<PostCodeObjects__c> pcoList = new List<PostCodeObjects__c>();

    List<User> userList = User_TestDataFactory.createUsersNoAdmin(8, new List<String>{'fr_FR', 'es_ES', 'es_ES', 'en_US', 'fr_FR', 'fr_FR', 'en_US', 'en_US'});
    userList[0].Appointment__c = true;
    insert userList;

    pcoList.add(new PostCodeObjects__c(objectType__c = 'SALES_OFFICE', country__c = 'GB', postCode__c = 'LA22', objectId__c = userList[0].Sales_Office__c));
    pcoList.add(new PostCodeObjects__c(objectType__c = 'OWNER_USA', country__c = 'GB', state__c = 'UT', profile__c = 'SELLER', productLine__c = 'KRION', objectId__c = userList[7].id));

    insert pcoList;
  }

  @isTest
  public static void findOwner() {
    SalesOfficeAssignator aux = new SalesOfficeAssignator();
    aux.setCountry('GB');
    aux.setPostCode('LA22 9NZ');
    
    User result = aux.getOwner();
    System.assert(result != null, 'Debería haber encontrado uno');
    aux.setPostCode('LA45 9NZ');
    result = aux.getOwner();
    System.assert(result == null, 'No debería haber encontrado uno');
  }
}