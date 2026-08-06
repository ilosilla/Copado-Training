@isTest
public class NBK_ScheduleSendReminder_Test {
    
    @testSetup
    static void testSetupData(){
        
       List<BusinessHours> bhs = [SELECT id,TimeZoneSidKey,MondayStartTime,MondayEndTime,TuesdayStartTime,
                                  TuesdayEndTime,WednesdayStartTime,WednesdayEndTime,ThursdayStartTime,ThursdayEndTime,
                                  FridayStartTime,FridayEndTime,SaturdayStartTime,SaturdayEndTime,SundayStartTime,SundayEndTime
                                  FROM BusinessHours WHERE IsDefault = true];
        
        List<Account> listAccount = DataFactoryAccount.createBusinessAccounts(1);
        
        List<User> listUser = DataFactoryUser.createUKUsers(1);
        
        system.debug('USERRR' + listUser[0]);
        
        List<SALES_OFFICE__c> salesoff = [SELECT Id, SalesOffice__c FROM SALES_OFFICE__c WHERE SalesOffice__c = '2552'];
        
        system.debug('````````' + salesoff);
        
        PorcelanosaAddress__c  ware = new PorcelanosaAddress__c ();
        ware.name = 'test';
        ware.NBK_SAPId__c = '2552';
        ware.NBK_Business_Hours__c = bhs[0].Id;
        ware.NBK_SalesOffice__c = salesoff[0].Id;
        insert ware;
        
        Profile profile = [Select Id From Profile Where Name='Standard Retail' LIMIT 1][0];
                    
        Contact ct = new Contact(AccountId = listAccount[0].Id, LastName = 'TestLastName', FirstName = 'TestFirstName');
        insert ct;
        
        lead lead1 = new Lead();
        lead1.Source__c = 'USW';
        lead1.FirstName = 'Test';
        lead1.LastName = 'Testing';
        lead1.Email = 'test@porcelanosa.com';
        lead1.Address__c = 'ramsay st';
        lead1.CountryCode__c = 'US';
        lead1.AppointmentType__c = 'SHOWROOM';
        insert lead1;
        
        Datetime startDateTime = Datetime.newInstance(Date.today().addDays(1),Time.newInstance(1, 0, 0, 0));
		Datetime endDateTime = startDateTime.addHours(2);
        
        Event ev = new Event(OwnerId = listUser[0].Id, StartDateTime = startDateTime, EndDateTime = endDateTime, WhoId = lead1.Id, Subject = 'Test Event', Description = 'Desc Test', Event_type__c = 'Showroom');
        insert ev;
    }
    
    @isTest 
 	public static void testExecute(){ 
  		Test.startTest(); 
  			String cronExp ='0 48 * * * ?'; 
  			System.schedule('testNotifications', cronExp, new NBK_ScheduleSendReminder()); 
  		Test.stopTest(); 
 } 

}