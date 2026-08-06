@isTest public class RESTContactPointAddressTest {

    @TestSetup static void makeData(){
        TestUtils.enableTriggers();        
        // Create account
        DataFactoryAccount.autoInsert = false;
        List<Account> accounts = DataFactoryAccount.createAccounts(1);
        accounts[0].SAP_Id__c = '0001234567';
        insert accounts;
        ContactPointAddress address = getContactAddress(accounts[0]);
        insert address;
    }

    @isTest static void testGET1() {
        Account acc = [select Id from Account limit 1];
        ContactPointAddress adr = [select Id, SAPId__c from ContactPointAddress where parentId = :acc.Id limit 1];
        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        request.addHeader('httpMethod', 'GET');
        request.requestUri = '/services/apexrest/contactpointaddress/' + adr.Id;       
        RestContext.request = request; 
        RestContext.response= response;
        Test.startTest();
        RESTContactPointAddress.get();
        System.assertEquals(200, response.statusCode);
        Test.stopTest();
    }

    @isTest static void testGET2() {
        Account acc = [select Id from Account limit 1];
        ContactPointAddress adr = [select Id, SAPId__c from ContactPointAddress where parentId = :acc.Id limit 1];
        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        request.addHeader('httpMethod', 'GET');
        request.requestUri = '/services/apexrest/contactpointaddress/sapId/' + adr.SAPId__c;       
        RestContext.request = request; 
        RestContext.response= response;
        Test.startTest();
        RESTContactPointAddress.get();
        System.assertEquals(200, response.statusCode);
        Test.stopTest();
    }

    @isTest static void testGET3() {
        Account acc = [select Id from Account limit 1];
        ContactPointAddress adr = [select Id, SAPId__c from ContactPointAddress where parentId = :acc.Id limit 1];
        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        request.addHeader('httpMethod', 'GET');
        request.requestUri = '/services/apexrest/contactpointaddress/sapId/0006786786';       
        RestContext.request = request; 
        RestContext.response= response;
        Test.startTest();
        RESTContactPointAddress.get();
        System.assertEquals(404, response.statusCode);
        Test.stopTest();
    }

    @isTest static void testPATCH1() {
        Account acc = [select Id from Account limit 1];
        ContactPointAddress adr = [select Id, SAPId__c, parentId, COuntryCode, StateCode from ContactPointAddress where parentId = :acc.Id limit 1];
        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();

        String toDelete = adr.Id;
        adr.Id = null;
        List<ContactPointAddress> addresses = new List<ContactPointAddress>();
        addresses.add(adr);

        List<String> deletedId = new List<String>();
        deletedId.add(toDelete);

        request.addHeader('httpMethod', 'PATCH');
        request.requestUri = '/services/apexrest/contactpointaddress/' + adr.parentId;       
        RestContext.request = request; 
        RestContext.response= response;
        Test.startTest();
        RESTContactPointAddress.patch(addresses, deletedId);
        System.assertEquals(200, response.statusCode);
        Test.stopTest();
    }


    @isTest static void testPOST1() {
        Account acc = [select Id from Account limit 1];
        ContactPointAddress adr = [select Id, Name, SAPId__c, parentId, COuntryCode, StateCode from ContactPointAddress where parentId = :acc.Id limit 1];
        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        String oldName = adr.Name;

        List<ContactPointAddress> addresses = new List<ContactPointAddress>();
        adr.Name = 'New Name';
        addresses.add(adr);
        request.addHeader('httpMethod', 'POST');
        request.requestUri = '/services/apexrest/contactpointaddress';       
        RestContext.request = request; 
        RestContext.response= response;
        Test.startTest();
        RESTContactPointAddress.post(addresses);
        Test.stopTest();
        System.assertEquals(200, response.statusCode);
        ContactPointAddress adr2 = [select Id, Name, SAPId__c, parentId, COuntryCode, StateCode from ContactPointAddress where parentId = :acc.Id limit 1];
        System.assertNotEquals(oldName, adr2.Name, 'Name should have changed');
    }

    @isTest static void testPOST2() {
        Account acc = [select Id from Account limit 1];
        ContactPointAddress adr = [select Id, Name, SAPId__c, parentId, COuntryCode, StateCode from ContactPointAddress where parentId = :acc.Id limit 1];
        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        String oldName = adr.Name;
        adr.Id = null;
        adr.parentId = null;
        List<ContactPointAddress> addresses = new List<ContactPointAddress>();
        addresses.add(adr);

        request.addHeader('httpMethod', 'POST');
        request.requestUri = '/services/apexrest/contactpointaddress';       
        RestContext.request = request; 
        RestContext.response= response;
        Test.startTest();
        RESTContactPointAddress.post(addresses);
        System.assertEquals(400, response.statusCode);
        Test.stopTest();
    }

    
    private static ContactPointAddress getContactAddress(Account acc) {
        ContactPointAddress address = new ContactPointAddress();
        address.addressType = 'Billing';
        address.Name = 'Test adddress';
        address.SAPId__c = '0001111111';
        address.ParentId = acc.Id;
        address.City = 'Ilkley';
        address.CountryCode = 'GB';
        address.PostalCode = 'LS9 9EE';
        address.stateCode = 'YN';
        address.Street = '9 The Grove';
        address.EMail__c = 'aaa@ccc.cxm';
        address.Phone__c = '111 222 333';  
        address.Mobile__c = '666 777 888';
        return address;
    }


}