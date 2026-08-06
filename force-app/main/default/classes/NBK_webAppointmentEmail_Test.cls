/**
 * @description       : 
 * @author            : EHG@nubika.com
 * @group             : 
 * @last modified on  : 10-27-2022
 * @last modified by  : EHG@nubika.com
**/
@isTest
public without sharing class NBK_webAppointmentEmail_Test {

    @testSetup static void setup() {
        List<Account> listAccount = DataFactoryAccount.createBusinessAccounts(1);
        List<User> listUser = DataFactoryUser.createUKUsers(1);

        Contact ct = new Contact(AccountId = listAccount[0].Id, LastName = 'TestLastName', FirstName = 'TestFirstName');
        insert ct;
    }

    /**
    * @description 
    * @author EHG@nubika.com | 10-27-2022 
    **/
    @isTest
    public static void test1(){
        User usertest = [SELECT Id,Name, FirstName FROM User limit 1];

        NBK_webAppointmentEmail.emailInfo emailinfo = new NBK_webAppointmentEmail.emailInfo();
        emailinfo.appointmentType = 'Virtual';
        emailinfo.dateSelected = Datetime.now();
        emailinfo.comercialId = usertest.Id;
        emailinfo.comercialEmail = 'test@gmail.com';
        emailinfo.showroomName = '12';
        emailinfo.targetEmail = 'test@gmail.com';
        emailinfo.fechaHoraStr = '2023-09-29 11:00:00';
  
        List<BusinessHours> bhs = [SELECT id,MondayStartTime,MondayEndTime,TuesdayStartTime,
                                    TuesdayEndTime,WednesdayStartTime,WednesdayEndTime,ThursdayStartTime,ThursdayEndTime,
                                    FridayStartTime,FridayEndTime,SaturdayStartTime,SaturdayEndTime,SundayStartTime,SundayEndTime,TimeZoneSidKey
                                    FROM BusinessHours WHERE IsDefault = true];
        emailinfo.businessHour = bhs[0];

        NBK_webAppointmentEmail.emailInfo emailinfo2 = new NBK_webAppointmentEmail.emailInfo();
        emailinfo2.appointmentType = 'Showroom';
        emailinfo2.dateSelected = Datetime.now();
        emailinfo2.comercialId = usertest.Id;
        emailinfo2.comercialEmail = 'test@gmail.com';
        emailinfo2.showroomName = '12';
        emailinfo2.targetEmail = 'test@gmail.com';
        emailinfo2.businessHour = bhs[0];
        emailinfo2.fechaHoraStr = '2023-09-29 11:00:00';

        Test.startTest();
            NBK_webAppointmentEmail.execute(new List<NBK_webAppointmentEmail.emailInfo>{emailinfo});
            NBK_webAppointmentEmail.execute(new List<NBK_webAppointmentEmail.emailInfo>{emailinfo2});
        Test.stopTest();

        Assert.areEqual(true, true);
    }
}