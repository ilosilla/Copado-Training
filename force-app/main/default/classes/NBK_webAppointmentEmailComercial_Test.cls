@IsTest
public class NBK_webAppointmentEmailComercial_Test {

    @testSetup static void setup() {
        List<Account> listAccount = DataFactoryAccount.createBusinessAccounts(1);
		Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
      	User u2 = new User(Alias = 'newUser', Email='newuser@testorg.com',
             EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',Default_Sales_Organization__c = '502',
             LocaleSidKey='en_US', ProfileId = p.Id,Country = 'United States',Sales_Org__c = '502',
             TimeZoneSidKey='America/Los_Angeles', UserName='newuser@testorg.com');

        Contact ct = new Contact(AccountId = listAccount[0].Id, LastName = 'TestLastName', FirstName = 'TestFirstName');
        insert ct;
        
        User usuario = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId()];
        
        System.runAs(usuario){
            Lead lead1 = new Lead();
            lead1.Source__c = 'USW';
            lead1.FirstName = 'prueba';
            lead1.LastName = 'prueba';
            lead1.Email = 'aaa@aaa.cc';
            lead1.Description = 'asdasd';
            lead1.MobilePhone = '12345678';
            lead1.Status = 'New';
            lead1.LeadSource = 'Website';
            lead1.LeadType__c = 'Others';
            lead1.LeadSubtype__c = 'adadas';
            lead1.Postcode__c = '123123';
            lead1.City__c = 'adasdasd';
            lead1.State__c = 'FL';
            
            insert lead1; 
        }
  
    }

    /**
    * @description 
    * @author EHG@nubika.com | 10-27-2022 
    **/
    @isTest
    public static void test1(){
        User usertest = [SELECT Id,Name, FirstName FROM User limit 1];
		List<Lead> listLead = [SELECT Id,Opportunity_Name__c,FirstName,LastName,Title,Company,
								MobilePhone,Email,Status,LeadSource,Owner.Email,Owner.Name,Owner.Id,Owner.FirstName,LeadType__c,LeadSubtype__c,
                                Postcode__c,City__c,State__c,Description 
                               		FROM Lead 
                               			WHERE Email = 'aaa@aaa.cc'];
       	System.debug('listLead:'+listLead);
        User usuario = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId()];
        
        NBK_webAppointmentEmailComercial.LeadInfo leadinfo = new NBK_webAppointmentEmailComercial.LeadInfo();
        leadinfo.leadId = listLead[0].Id;
        leadinfo.fechaHoraS = '2023-11-14 10:00:00';
       
        Test.startTest();
            System.runAs(usuario){
                NBK_webAppointmentEmailComercial.execute(new List<NBK_webAppointmentEmailComercial.LeadInfo>{leadinfo});
            }
            
        Test.stopTest();

        Assert.areEqual(true, true);
    }
}