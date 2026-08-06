@isTest
public class NBK_CreateSamplesOrderControllerTest {
    
    @TestSetup
    static public void setupData(){
        List<String> timezone = new List<String>();
        timezone.add('en_US');
        List<User> usrlist = User_TestDataFactory.createUsers(1, timezone);
        insert usrlist;
        
        Account acc = Account_TestDataFactory.createBusinessAccount();
        insert acc;

        Sales_RelationShip__c sr = new Sales_RelationShip__c();

        sr.Sales_Org__c = '502';
        sr.Distribution_Channel__c = usrlist[0].Distribution_channel_default__c;
        sr.Sales_Office__c ='2552';
        sr.Account_Org__c = acc.id; 
        sr.Commercial__c = usrlist[0].Id;
        sr.Reason_of_creation__c = 'New Account Team Member';
        insert sr;
        
        ContactPointAddress cpa = new ContactPointAddress();
        cpa.Name = 'UK';
        cpa.IsDefault = true;
        cpa.ParentId = acc.Id;
        //Address add = new Address();
        cpa.City = 'HASLEMERE';
        cpa.country = 'United Kingdom';
        cpa.countryCode = 'GB';
        cpa.postalCode = 'GU27 1HE';
        cpa.state = 'Surrey';
        cpa.stateCode = 'SY';
        cpa.street = 'WALNUT HOUSE, FARNHAM LANE';
        
        insert cpa;
        
        Pricebook2 pb = new Pricebook2();
        pb.Name = 'SAMPLES-US';
        pb.isActive = true;
        pb.SapSync__c = true;
        
        insert pb;
        
        PorcelanosaAddress__c warehouse = new PorcelanosaAddress__c();
        warehouse.NBK_SAPId__c = '5065403';
        warehouse.Name = 'TEST';
        warehouse.NBK_Address__City__s = 'Braehead';
        warehouse.NBK_Address__CountryCode__s = 'GB';
        warehouse.NBK_Address__PostalCode__s = 'PA4 8XY';
        warehouse.NBK_Address__StateCode__s = 'RE';
        warehouse.NBK_Address__Street__s = 'NBK_Address__Street__s';
        warehouse.NBK_Address_Type__c = 'Warehouse';
        insert warehouse;

        Sales_Org__c sorg= new Sales_Org__c(
            SalesOrg__c = '502', Name = 'SOUTH EAST', CountryCode__c = 'GB', Company__c = '502', SAP_Id__c = '502',
            SamplesCutoff__c = Time.newInstance(9, 30, 0, 0), SamplesMinDays__c = 1, SamplesWeekendDays__c = '', TImeZone__c = 'Europe/London'
        );
        insert sorg;
        
    }
    
    /*
    @isTest public static void getDefaultContactPoint() {
        Id accId = [SELECT Id FROM Account WHERE Name = 'TestAcctBusinessAccount1'].Id;
        NBK_CreateSamplesOrderController.getDefaultContactPoint(accId);
    }
    */
    
    /*
    @isTest public static void getWarehouse() {
        Id accId = [SELECT Id FROM Account WHERE Name = 'TestAcctBusinessAccount1'].Id;
        NBK_CreateSamplesOrderController.getWareHousePicklist(accId);
    }
    */
    
    @isTest public static void getSalesRelationShip(){
        Id accId = [SELECT Id FROM Account WHERE Name = 'TestAcctBusinessAccount1'].Id;
        NBK_CreateSamplesOrderController.getSalesRelationShip(accId);
    }

    @isTest public static void getPermissionSet() {
         User userId = [SELECT Id FROM User WHERE LastName = 'TestLastNameR0' LIMIT 1];
         System.runAs(userId) {
            NBK_CreateSamplesOrderController.getPermissionSet();
         }
    }
    
    @isTest public static void getSamplePricebook() {
		NBK_CreateSamplesOrderController.getSamplePricebook('US');
    }

    @isTest private static void getDeliveryDateOptions() {
        NBK_CreateSamplesOrderController.DeliveryOptionsDTO dto = NBK_CreateSamplesOrderController.getDeliveryDateOptions('502');
        Assert.isTrue(true);
    }

}