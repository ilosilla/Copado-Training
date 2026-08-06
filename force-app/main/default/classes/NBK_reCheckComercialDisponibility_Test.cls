@isTest
public class NBK_reCheckComercialDisponibility_Test {

    
    @testSetup
    static void setupData(){

        User admin = TestUtils.getAdminUser();
        system.runAs(admin){
            UserRole r = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
			insert r;
            DataFactoryUser.createUKAdmin();
            
            User currUser = [SELECT Id, Email FROM User WHERE Email = 'ukadmin@ukuser.cxm' LIMIT 1];
            currUser.IsActive = true;
            update currUser;
            
            List<Lead> l = DataFactoryLead.createUSWebRequest(1);
            l[0].OwnerId = currUser.Id;
            l[0].Email = currUser.Email;
            update l;
        }

    }
        
    static testMethod void testreCheckDisponibility(){
        User currUser = [SELECT Id, Sales_Office__c FROM User WHERE Email = 'ukadmin@ukuser.cxm' LIMIT 1];
        Datetime d = Datetime.now();
        List<BusinessHours> bhs = [SELECT id,TimeZoneSidKey FROM BusinessHours WHERE IsDefault = true];
        list<NBK_reCheckComercialDisponibility.comercialDisponibility> listTest = new list<NBK_reCheckComercialDisponibility.comercialDisponibility>();
        NBK_reCheckComercialDisponibility.comercialDisponibility cd = new NBK_reCheckComercialDisponibility.comercialDisponibility();
        cd.userId = currUser.Id;
        cd.dateSelected = d;
        cd.email = 'ukadmin@ukuser.cxm';
        cd.salesOffice = currUser.Sales_Office__c;
        cd.comercialEmail = 'ukcom@ukuser.cxm';
        cd.fechaHoraStr = '2023-09-29 11:00:00';
        cd.businessH = bhs[0];
        listTest.add(cd);
        
        Test.startTest();
        	list<NBK_reCheckComercialDisponibility.responseDisponibility> b = NBK_reCheckComercialDisponibility.recheckDisponibility(listTest);
       	Test.stopTest();
        
    }
    
        static testMethod void testreCheckDisponibility2(){
        User currUser = [SELECT Id, Sales_Office__c FROM User WHERE Email = 'ukadmin@ukuser.cxm' LIMIT 1];
        Datetime d = Datetime.now();
        List<BusinessHours> bhs = [SELECT id,TimeZoneSidKey FROM BusinessHours WHERE IsDefault = true];
        list<NBK_reCheckComercialDisponibility.comercialDisponibility> listTest = new list<NBK_reCheckComercialDisponibility.comercialDisponibility>();
        NBK_reCheckComercialDisponibility.comercialDisponibility cd = new NBK_reCheckComercialDisponibility.comercialDisponibility();
        cd.userId = currUser.Id;
        cd.dateSelected = d;
        cd.email = 'ukadmin2@ukuser.cxm';
        cd.salesOffice = currUser.Sales_Office__c;
        cd.fechaHoraStr = '2023-09-29 11:00:00';
        cd.businessH = bhs[0];
        listTest.add(cd);
        
        Test.startTest();
        	list<NBK_reCheckComercialDisponibility.responseDisponibility> b = NBK_reCheckComercialDisponibility.recheckDisponibility(listTest);
       	Test.stopTest();
        
    }
    
    static testMethod void testreCheckDisponibility3(){
        User currUser = [SELECT Id, Sales_Office__c FROM User WHERE Email = 'ukadmin@ukuser.cxm' LIMIT 1];
        Datetime d = Datetime.now();
        list<NBK_reCheckComercialDisponibility.comercialDisponibility> listTest = new list<NBK_reCheckComercialDisponibility.comercialDisponibility>();
        NBK_reCheckComercialDisponibility.comercialDisponibility cd = new NBK_reCheckComercialDisponibility.comercialDisponibility();
        cd.userId = currUser.Id;
        cd.dateSelected = d;
        cd.email = 'ukadmin2@ukuser.cxm';
        cd.salesOffice = currUser.Sales_Office__c;
        cd.fechaHoraStr = '2023-09-29 11:00:00';

        listTest.add(cd);
        
        Test.startTest();
        	list<NBK_reCheckComercialDisponibility.responseDisponibility> b = NBK_reCheckComercialDisponibility.recheckDisponibility(listTest);
       	Test.stopTest();
        
    }
}