/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-27-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class NBK_USAEventCreation_Test {

    @testSetup
    static void setupData(){

        User admin = TestUtils.getAdminUser();
        system.runAs(admin){
            DataFactoryLead.createWebRequest(1);
            DataFactoryUser.createUKAdmin();
        }

    }
    
    static testMethod void testgenerateAppointmentEvent(){
        Id currUser = [SELECT Id FROM User WHERE Email = 'ukadmin@ukuser.cxm' LIMIT 1].Id;
        Id lead = [SELECT Id FROM Lead WHERE Email = 'testwr@testdomain.cxm' LIMIT 1].Id;
        Datetime d = Datetime.now();
        Datetime h = d.addHours(1);
        String etype = 'Showroom';
        String subject = 'Appointment';
        String description = 'Test';
        Id oId = currUser;
        Id whoId = lead;
		List<BusinessHours> bhs = [SELECT id,TimeZoneSidKey FROM BusinessHours WHERE IsDefault = true];

        list<NBK_USAEventCreation.Request> listTest = new list<NBK_USAEventCreation.Request>();
        NBK_USAEventCreation.Request event = new NBK_USAEventCreation.Request();

        event.startDate = d;
        event.endDate = h;
        event.eventType = etype;
        event.whoId = whoId;
        event.subject = subject;
        event.description = description;
        event.ownerId = oId;
        event.fechaHoraStr = '2023-09-29 11:00:00';
        event.businessH = bhs[0];
        
        listTest.add(event);
        Test.startTest();
        NBK_USAEventCreation.generateAppointmentEvent(listTest);
        Test.stopTest();
        
    }
    
}