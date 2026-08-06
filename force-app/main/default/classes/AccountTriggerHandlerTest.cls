@isTest
public class AccountTriggerHandlerTest {
    @TestSetup
    static void setup(){
        TestUtils.enableTriggers();
        Account_TestDataFactory.insertAccounts( new List<Account>{
            Account_TestDataFactory.createFabricator(), //accountForNameChange,
            Account_TestDataFactory.createCustomer(), Account_TestDataFactory.createRetailer() });
        
        //Insert Sales_RelationShip_TestDataFactory.createSalesRelationship(accountForNameChange);
        
        Id managerUserId = [SELECT Id FROM Profile WHERE Name = 'Managers'].Id;
        Map<String, Object> fieldMap = new Map<String, Object>{'LocaleSidKey' => 'en_GB'};
        
		List<User> userListToInsert = User_TestDataFactory.createUsers(4, fieldMap);
        userListToInsert[0].ProfileId = managerUserId;
        userListToInsert[1].ProfileId = managerUserId;
        
        Insert userListToInsert;
        
        System.runAs(userListToInsert[0]){
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            
            Account accForAfterUpdate = Account_TestDataFactory.createFabricator();
            accForAfterUpdate.Name = 'AccForAfterUpdateTest';
            
            Account_TestDataFactory.insertAccounts(new List<Account>{accForAfterUpdate});
        }
    }
    @isTest
    public static void beforeDelete(){
        Account acc = [Select Id, sap_id__c from Account][0];
        acc.sap_id__c = '000888888';
        update acc;
        
        List<Account> listAcc = [Select Id, sap_id__c from Account where sap_id__c = '000888888'];
        System.assert(listAcc.size() == 1, 'There is an Accoutn with Sap_id');

        acc = [Select Id, sap_id__c from Account where sap_id__c = '000888888'][0];
        Account accAux = [Select Id, sap_id__c from Account where sap_id__c = ''][0];
        Database.DeleteResult[] drList = Database.delete(new List<Account>{acc,accAux}, false);
		
        System.assert(!drList[0].isSuccess(),'It shouldn\'t has been created');
        System.assert(drList[0].getErrors()[0].getMessage().contains(Label.Account_Cant_delete), 'The error is not the "Cannott delete" one');
        System.assert(drList[1].isSuccess(), 'It should has been created');
    }

    @isTest
    public static void afterInsert(){
        PorcelanosaSetting__c aux = new PorcelanosaSetting__c(Key__c = 'REQUIRED_VAT', Subkey__c = 'ALL', Value1__c = 'FR' );
        insert aux;

        User adminUser = [SELECT Id FROM User WHERE UserName LIKE '%@testOrg.com' AND Profile.Name =: Label.System_Administrator LIMIT 1];
        User managerUser = [SELECT Id FROM User WHERE UserName LIKE '%@testOrg.com' AND Profile.Name =: 'Managers' LIMIT 1];
        
        List<Account> accListToInsert = new List<Account>();
        accListToInsert.add(Account_TestDataFactory.createFabricator());
        accListToInsert.add(Account_TestDataFactory.createCustomer());
        accListToInsert.add(Account_TestDataFactory.createRetailer());
        accListToInsert.add(Account_TestDataFactory.createBusinessAccount());
        //accListToInsert[3].Account_Classification__c = '';
        Database.SaveResult[] svR;
        
        System.runAs(adminUser){
            svR = Account_TestDataFactory.insertAccounts(accListToInsert);
        }
        
        System.assert(svR[0].isSuccess(), 'It should has been created');
        System.assert(svR[1].isSuccess(), 'It should has been created');
        System.assert(svR[2].isSuccess(), 'It should has been created');
        System.assert(svR[3].isSuccess(), 'It should has been created');
        
        List<Sales_Relationship__c> saleRelAuto = [SELECT Id FROM Sales_Relationship__c WHERE Account_Org__c =: svR[0].getId() OR
                                             Account_Org__c =: svR[1].getId() OR Account_Org__c =: svR[2].getId() 
                                             OR Account_Org__c =: svR[3].getId()];
        System.assert(saleRelAuto.isEmpty(), 'There is a Sales Rleationship');
        
        Id oppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Automatic_Opportunity').getRecordTypeId();
        List<Opportunity> oppAuto = [SELECT Id FROM Opportunity WHERE RecordTypeId =: oppRecordTypeId AND (AccountId =: svR[0].getId() OR
                                             AccountId =: svR[1].getId() OR AccountId =: svR[2].getId() 
                                             OR AccountId =: svR[3].getId())];
        
        System.assert(oppAuto.isEmpty(), 'There is an Opportunity');
        
        List<Account> accListToInsertAuto = new List<Account>();
        accListToInsertAuto.add(Account_TestDataFactory.createFabricator());
        accListToInsertAuto.add(Account_TestDataFactory.createCustomer());
        accListToInsertAuto.add(Account_TestDataFactory.createRetailer());
        accListToInsertAuto.add(Account_TestDataFactory.createBusinessAccount());
        
        Database.SaveResult[] svRAuto;
        
        System.runAs(managerUser){
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
            Test.startTest();
            svRAuto = Account_TestDataFactory.insertAccounts(accListToInsertAuto);
            Test.stopTest();
        }
        
        System.assert(svRAuto[0].isSuccess(), 'It should has been created');
        System.assert(svRAuto[1].isSuccess(), 'It should has been created');
        System.assert(svRAuto[2].isSuccess(), 'It should has been created');
        System.assert(svRAuto[3].isSuccess(), 'It should has been created');
        
        List<Sales_Relationship__c> saleRelAuto2 = [SELECT Id FROM Sales_Relationship__c WHERE Account_Org__c =: svRAuto[0].getId() OR
                                             Account_Org__c =: svRAuto[1].getId() OR Account_Org__c =: svRAuto[2].getId() 
                                             OR Account_Org__c =: svRAuto[3].getId()];
        System.assert(saleRelAuto2.size() == 1, 'Not the correct size');
        
        List<Opportunity> oppAuto2 = [SELECT Id FROM Opportunity WHERE RecordTypeId =: oppRecordTypeId AND (AccountId =: svRAuto[0].getId() OR
                                             AccountId =: svRAuto[1].getId() OR AccountId =: svRAuto[2].getId() 
                                             OR AccountId =: svRAuto[3].getId())];
                                             System.debug('AAAAAAAAAA');
                                             System.debug(oppAuto2.size());
        System.assert(oppAuto2.size() == 0, 'Not the correct size');
    }

    @isTest
    public static void vatGB(){
        PorcelanosaSetting__c aux = new PorcelanosaSetting__c(Key__c = 'REQUIRED_VAT', Subkey__c = 'ALL', Value1__c = 'GB' );
        insert aux;

        User adminUser = [SELECT Id FROM User WHERE UserName LIKE '%@testOrg.com' AND Profile.Name =: Label.System_Administrator LIMIT 1];
        User managerUser = [SELECT Id FROM User WHERE UserName LIKE '%@testOrg.com' AND Profile.Name =: 'Managers' LIMIT 1];
        
        List<Account> accounts = DataFactoryAccount.createAccounts(2);
        accounts[0].vat_number__c = '854674490';

        update accounts[0];

        Assert.areEqual(1, [SELECT Id FROM Account WHERE vat_number__c = '854674490'].size(), 'No se ha actualizado con el vat');
    }

    @isTest
    public static void SetRegisterUniqueId(){
        List<Account> accounts = DataFactoryAccount.createAccounts(2);
        accounts[0].business_email__c = 'test@test.com';
        accounts[1].business_email__c = 'test@testdos.com';

        update accounts;

        List<Account> accs = [SELECT id,business_email__c, registeruniqueid__c FROM Account WHERE id = :accounts[0].id OR id = :accounts[1].id];

        if (accs[0].business_email__c == 'test@test.com') {
            Assert.areEqual('TEST.COM:AB03EH', accs[0].registeruniqueid__c, 'No se ha actualizado el uniquieid');
            Assert.areEqual('TESTDOS.COM:AB13EH', accs[1].registeruniqueid__c, 'No se ha actualizado el uniquieid');
        } else {
            Assert.areEqual('TEST.COM:AB03EH', accs[1].registeruniqueid__c, 'No se ha actualizado el uniquieid');
            Assert.areEqual('TESTDOS.COM:AB13EH', accs[0].registeruniqueid__c, 'No se ha actualizado el uniquieid');


        }
    }
}