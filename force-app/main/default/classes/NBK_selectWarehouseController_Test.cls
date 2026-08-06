@isTest
public class NBK_selectWarehouseController_Test {
    
	@testSetup static void setup() {
		List<Account> listAccount = DataFactoryAccount.createBusinessAccounts(1);
    
		PorcelanosaAddress__c  ware = new PorcelanosaAddress__c ();
		ware.name = 'test';
		ware.NBK_SAPId__c = '2552';
        ware.NBK_Address__City__s = 'Miami';
        ware.NBK_Address__Street__s = '8700 N.W. 13th Terrace';
        ware.NBK_Address__PostalCode__s = '33172';
        ware.NBK_Address__StateCode__s = 'FL';
        ware.NBK_Address__CountryCode__s = 'US';
		insert ware;
    	
		List<User> listUser = DataFactoryUser.createUKUsers(1);
    
		Contact ct = new Contact(AccountId = listAccount[0].Id, LastName = 'TestLastName', FirstName = 'TestFirstName');
		insert ct;
    
		Event ev = new Event(WhatId = listAccount[0].Id, StartDateTime = System.now(), EndDateTime = System.now().addDays(8), WhoId = ct.Id, Subject = 'Test Event', Description = 'Desc Test');
		insert ev;
    }
    
    @isTest
    public static void getStatePicklistTest(){
        Test.startTest();
            list<NBK_selectWarehouseController.picklistStates> resultado = NBK_selectWarehouseController.getStatePicklist();
        Test.stopTest();
        Assert.areEqual(resultado != null, true);
    }
    
    @isTest
    public static void initializeMapTest(){
        Test.startTest();
            list<NBK_selectWarehouseController.mapMarkers> resultado = NBK_selectWarehouseController.initializeMap();
        Test.stopTest();
        Assert.areEqual(resultado != null, true);
    }
    
        @isTest
    public static void getWarehousesByStateTest(){
        Test.startTest();
            list<PorcelanosaAddress__c> resultado = NBK_selectWarehouseController.getWarehousesByState('CA','TO');
        	resultado = NBK_selectWarehouseController.getWarehousesByState('US','US');
        Test.stopTest();
        Assert.areEqual(resultado != null, true);
    }


}