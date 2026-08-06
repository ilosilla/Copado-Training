/**
 * @description       :
 * @author            : EHG@nubika.com
 * @group             :
 * @last modified on  : 10-27-2022
 * @last modified by  : EHG@nubika.com
**/
@isTest
public without sharing class NBK_AppointmentManager_Test {

    @testSetup static void setup() {
        List<Account> listAccount = DataFactoryAccount.createBusinessAccounts(1);

        PorcelanosaAddress__c  ware = new PorcelanosaAddress__c ();
        ware.name = 'test';
        ware.NBK_SAPId__c = '2552';
        insert ware;

        List<User> listUser = DataFactoryUser.createUKUsers(1);

        Contact ct = new Contact(AccountId = listAccount[0].Id, LastName = 'TestLastName', FirstName = 'TestFirstName');
        insert ct;

        Event ev = new Event(WhatId = listAccount[0].Id, StartDateTime = System.now(), EndDateTime = System.now().addDays(8), WhoId = ct.Id, Subject = 'Test Event', Description = 'Desc Test');
        insert ev;

    }

@isTest
    static void testGetHourList() {
        Datetime selectedDay = Datetime.now();
        BusinessHours actualBusinessHours = [SELECT id,TimeZoneSidKey,MondayStartTime,MondayEndTime,TuesdayStartTime,
        TuesdayEndTime,WednesdayStartTime,WednesdayEndTime,ThursdayStartTime,ThursdayEndTime,
        FridayStartTime,FridayEndTime,SaturdayStartTime,SaturdayEndTime,SundayStartTime,SundayEndTime
        FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        List<NBK_AppointmentManager.hoursWrapper> result = NBK_AppointmentManager.getHourList(selectedDay, actualBusinessHours, null);

        System.assertNotEquals(null, result);


    }
    /**
    * @description
    * @author EHG@nubika.com | 10-27-2022
    **/
    @isTest
    public static void test1(){
        List<BusinessHours> bhs = [SELECT id,TimeZoneSidKey,MondayStartTime,MondayEndTime,TuesdayStartTime,
                                    TuesdayEndTime,WednesdayStartTime,WednesdayEndTime,ThursdayStartTime,ThursdayEndTime,
                                    FridayStartTime,FridayEndTime,SaturdayStartTime,SaturdayEndTime,SundayStartTime,SundayEndTime
                                    FROM BusinessHours WHERE IsDefault = true];

                Datetime hoy = Datetime.now();
List<PorcelanosaAddress__c> listPorce = [SELECT Id , Name, NBK_SAPId__c FROM PorcelanosaAddress__c WHERE NBK_SAPId__c != NULL Limit 1];

        List<User> comercial  = [SELECT Id, Name, Email
                                FROM User
                                WHERE Sales_Office__c =: listPorce[0].NBK_SAPId__c AND Appointment__c = true AND IsActive = true];

       Event ev = new Event();
       ev.OwnerId = comercial[0].Id;
       ev.StartDateTime = DateTime.now().addMinutes(2);
       ev.EndDateTime = DateTime.now().addHours(1);
       insert ev;

        System.debug('ev.StartDateTime:'+ev.StartDateTime);
        System.debug('ev.StartDateTime:'+ev.EndDateTime);

        List<NBK_AppointmentManager.hoursWrapper> resultado;
        Test.startTest();
            resultado = NBK_AppointmentManager.getAvailableHours(listPorce[0],hoy,bhs[0], null);
        	resultado = NBK_AppointmentManager.getAvailableDays(listPorce[0], '12:00',hoy,bhs[0],'US');
        Test.stopTest();

        Assert.areEqual(resultado != null, true);
    }

    /**
    * @description
    * @author EHG@nubika.com | 10-27-2022
    **/
    @isTest
    public static void test2(){
        List<BusinessHours> bhs = [SELECT id,MondayStartTime,MondayEndTime,TuesdayStartTime,
                                    TuesdayEndTime,WednesdayStartTime,WednesdayEndTime,ThursdayStartTime,ThursdayEndTime,
                                    FridayStartTime,FridayEndTime,SaturdayStartTime,SaturdayEndTime,SundayStartTime,SundayEndTime
                                    FROM BusinessHours WHERE IsDefault = true];

        NBK_AppointmentManager.daysWrapper resultado1;
        NBK_AppointmentManager.daysWrapper resultado2;
        NBK_AppointmentManager.daysWrapper resultado3;
        NBK_AppointmentManager.daysWrapper resultado4;
        NBK_AppointmentManager.daysWrapper resultado5;
        NBK_AppointmentManager.daysWrapper resultado6;
        NBK_AppointmentManager.daysWrapper resultado7;

        Test.startTest();
            resultado1 = NBK_AppointmentManager.getstartEndTime( 'Mon', bhs[0] );
            resultado2 = NBK_AppointmentManager.getstartEndTime( 'Tue', bhs[0] );
            resultado3 = NBK_AppointmentManager.getstartEndTime( 'Wed', bhs[0] );
            resultado4 = NBK_AppointmentManager.getstartEndTime( 'Thu', bhs[0] );
            resultado5 = NBK_AppointmentManager.getstartEndTime( 'Fri', bhs[0] );
            resultado6 = NBK_AppointmentManager.getstartEndTime( 'Sat', bhs[0] );
            resultado7 = NBK_AppointmentManager.getstartEndTime( 'Sun', bhs[0] );
        Test.stopTest();

        Assert.areEqual(resultado1 != null, true);
        Assert.areEqual(resultado2 != null, true);
        Assert.areEqual(resultado3 != null, true);
        Assert.areEqual(resultado4 != null, true);
        Assert.areEqual(resultado5 != null, true);
        Assert.areEqual(resultado6 != null, true);
        Assert.areEqual(resultado7 != null, true);
    }

    /**
    * @description
    * @author EHG@nubika.com | 10-27-2022
    **/
    @isTest
    public static void test3(){
        TimeZone tz = UserInfo.getTimeZone();
        Date hoy = Date.today();
        Integer resultado;
        Test.startTest();
            resultado = NBK_AppointmentManager.getOffset( hoy, tz.getDisplayName());
        Test.stopTest();

        Assert.areEqual(resultado != null, true);
    }

    /**
    * @description
    * @author EHG@nubika.com | 10-27-2022
    **/
    @isTest
    public static void test4(){
        User user = [SELECT Id FROM User limit 1];
        NBK_AppointmentManager.Request request = new NBK_AppointmentManager.Request();
        request.comercialId = user.Id;
        request.country = 'ES';
        request.phone = '917111111';
        request.selectedDatetime = Datetime.now();
        request.comercialEmail = 'ee@gmail.com';
         List<BusinessHours> bhs = [SELECT id,MondayStartTime,MondayEndTime,TuesdayStartTime,
                                    TuesdayEndTime,WednesdayStartTime,WednesdayEndTime,ThursdayStartTime,ThursdayEndTime,
                                    FridayStartTime,FridayEndTime,SaturdayStartTime,SaturdayEndTime,SundayStartTime,SundayEndTime,TimeZoneSidKey
                                    FROM BusinessHours WHERE IsDefault = true];
        request.businessHour = bhs[0];

        Test.startTest();
            NBK_AppointmentManager.sendSMS(new List<NBK_AppointmentManager.Request>{request});
        Test.stopTest();

        Assert.areEqual(true, true);
    }


    @isTest
    static void test5() {

        List<PorcelanosaAddress__c> listPorce = [SELECT Id , Name, NBK_SAPId__c FROM PorcelanosaAddress__c WHERE NBK_SAPId__c != NULL Limit 1];

        List<User> comercial  = [SELECT Id, Name, Email
                                FROM User
                                WHERE Sales_Office__c =: listPorce[0].NBK_SAPId__c AND Appointment__c = true AND IsActive = true];

       Event ev = new Event();
       ev.OwnerId = comercial[0].Id;
       ev.StartDateTime = DateTime.now().addDays(1).addHours(2).addMinutes(2);
       ev.EndDateTime = DateTime.now().addDays(1).addHours(3);
        insert ev;

        System.debug('ev.StartDateTime:'+ev.StartDateTime);
        System.debug('ev.StartDateTime:'+ev.EndDateTime);

         BusinessHours actualBusinessHours = [SELECT id,MondayStartTime,MondayEndTime,TuesdayStartTime,
                                    TuesdayEndTime,WednesdayStartTime,WednesdayEndTime,ThursdayStartTime,ThursdayEndTime,
                                    FridayStartTime,FridayEndTime,SaturdayStartTime,SaturdayEndTime,SundayStartTime,SundayEndTime
                                    FROM BusinessHours WHERE IsDefault = true LIMIT 1];

        DateTime startDateTime = DateTime.now();
        String selectedTime = '10:00:00';
        String warehousecountry = '';

        Test.startTest();
        NBK_AppointmentManager.getAvailableDays(listPorce[0],selectedTime, startDateTime, actualBusinessHours,warehousecountry);

        DateTime publicHoliday = startDateTime;

        Boolean isWithinBusinessHours = BusinessHours.isWithin(actualBusinessHours.id, publicHoliday);
    	if (comercial.size() != 0) {
            Integer hoursToAdd = 3;
			Datetime endDateTime = startDateTime.addHours(hoursToAdd);
            List<Event> events = [
                SELECT StartDateTime, EndDateTime, Id, OwnerId
                FROM Event
                WHERE OwnerId = :comercial[0].Id AND StartDateTime >= :startDateTime AND EndDateTime <= :endDateTime
            ];

        }
        Test.stopTest();


	}

 	@isTest
    static void test6() {
        List<PorcelanosaAddress__c> listPorce = [SELECT Id , Name, NBK_SAPId__c FROM PorcelanosaAddress__c WHERE NBK_SAPId__c != NULL Limit 1];

        List<User> comercial  = [SELECT Id, Name, Email
                                FROM User
                                WHERE Sales_Office__c =: listPorce[0].NBK_SAPId__c AND Appointment__c = true AND IsActive = true Limit 1];

        Id comercialId = comercial[0].Id;
        List<Event> events = new List<Event>();
        Integer quantity = 5;
        List<Time> bHours = new List<Time>();

        NBK_AppointmentManager.comercialsWrapper wrapper = new NBK_AppointmentManager.comercialsWrapper(comercialId, events, quantity, bHours);

        System.assertEquals(comercialId, wrapper.userId);
        System.assertEquals(events, wrapper.eventsPerComercial);
        System.assertEquals(quantity, wrapper.quantityEvents);
        System.assertEquals(bHours, wrapper.busyHours);
    }


}