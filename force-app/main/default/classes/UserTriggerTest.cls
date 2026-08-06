/*-----------------------------------------------------------------------------------------
Author:         Juan Manuel Martinez
Company:        Neoris
Date:			18-03-2019
Description:    Test para la clase UserHandler y el trigger UserTrigger.
History
<Date>            <Author>              <Change Description>
-----------------------------------------------------------------------------------------*/

@isTest
public class UserTriggerTest {

    @isTest static void test_beforeInsert() {
        insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();        

        List<User> userList = User_TestDataFactory.createUsers(7, new List<String>{'en_US', 'en_US', 'en_US','en_US','en_US', 'en_US','en_US'});
        System.debug('Usuario: ' + userList);
        
        // Test 1: Before Insert. Success
        // Usuario Valido.
        User testUser_1 = userList[0];
        Database.SaveResult result_test_1 = Database.insert(testUser_1, false);
		System.assert( result_test_1.isSuccess() );
        
        // Test 2: Before Insert Fail
        // Debe fallar la insercion porque Default_Sales_Organization__c no puede estar vacio.
        User testUser_2 = userList[1];
        testUser_2.Default_Sales_Organization__c = null;
        
        Database.SaveResult result_test_2 = Database.insert(testUser_2, false);
        if(! result_test_2.isSuccess()){
            System.debug('38: ' + result_test_2.getErrors()[0].getMessage());
        }
        
        System.assert( ! result_test_2.isSuccess() );
        System.assert( result_test_2.getErrors()[0].getMessage().contains(Label.User_SelectDefaultSalesOrg));
        
        // Debe fallar la insercion porque Distribution_channel_default__c no puede estar vacio.
        testUser_2.Default_Sales_Organization__c = OrganizationCommons.ORG_AZURCERAMIQUE;
        testUser_2.Distribution_channel_default__c = null;
        
        result_test_2 = Database.insert(testUser_2, false);
		System.assert( ! result_test_2.isSuccess() );
        
        // Debe fallar la insercion porque Country no puede estar vacio.
        testUser_2.Distribution_channel_default__c = '10';
        testUser_2.Country = null;
        result_test_2 = Database.insert(testUser_2, false);
		System.assert( ! result_test_2.isSuccess() );
        System.assert( result_test_2.getErrors()[0].getMessage().contains('Users must select a Country') );
        
        // Test 4: Before Insert Fail
        // Debe fallar la insercion porque Default Sales Org no esta en la lista de Sales Org
        User testUser_4 = userList[3];
        testUser_4.Default_Sales_Organization__c = OrganizationCommons.ORG_PIDF;
        
        Database.SaveResult result_test_4 = Database.insert(testUser_4, false);
		System.assert( ! result_test_4.isSuccess() );
        System.assert( result_test_4.getErrors()[0].getMessage().contains(Label.User_SalesOrgMismatch) );
        
        // Test 5: Before Insert Fail
        // Debe fallar la insercion porque Default Dist Channel no esta en la lista de Distribution Channels
        User testUser_5 = userList[4];
        testUser_5.Distribution_Channel__c = '10;15';
        testUser_5.Distribution_channel_default__c = '20';
        
        Database.SaveResult result_test_5 = Database.insert(testUser_5, false);
		System.assert( ! result_test_5.isSuccess() );
        System.assert( result_test_5.getErrors()[0].getMessage().contains(Label.User_DistChannelMismatch) );
        
        // Test 3: Before Insert Fail
        // Debe fallar porque la sales office no esta incluida en la dependencia con sales org y distribution channel
        User testUser_3 = userList[2];
        testUser_3.Sales_Office__c = '2524';
        
        Database.SaveResult result_test_3 = Database.insert(testUser_3, false);
		System.assert( ! result_test_3.isSuccess() );
        System.assert( result_test_3.getErrors()[0].getMessage().contains('The combination of default values') );
        
        // Test 6: Before Insert Fail
        // Debe fallar porque la sales office no esta incluida en la dependencia con sales org y distribution channel
        // Usuario con dos Sales Org
        User testUser_6 = userList[5];
        testUser_6.Distribution_channel__c = '10;15;20;30;50;60;65;70';
        
        Database.SaveResult result_test_6 = Database.insert(testUser_6, false);
		System.assert( ! result_test_6.isSuccess() );
        System.assert( result_test_6.getErrors()[0].getMessage().contains(Label.User_WrongDistChannel) );
        System.assert( result_test_6.getErrors()[0].getMessage().contains('20') );
        
        // Test 6: Before Insert Fail
        // Debe fallar porque la sales office no esta incluida en la dependencia con sales org y distribution channel
        // Usuario con una sales org
        User testUser_7 = userList[6];
        testUser_7.Distribution_channel__c = '10;15;20;30;40;50;60;65;70';
        testUser_7.Sales_Org__c = OrganizationCommons.ORG_AZURCERAMIQUE;
        testUser_7.Sales_office__c = '3387';
        
        Database.SaveResult result_test_7 = Database.insert(testUser_7, false);
		System.debug('result_test_7: ' + result_test_7.getErrors()[0].getMessage());
        System.assert( ! result_test_7.isSuccess() );
        System.assert( result_test_7.getErrors()[0].getMessage().contains('3387') );
        
    }
    
    @isTest static void test_beforeUpdate() {
        //insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();        

        User testUser; 
        Test.startTest();
        	testUser = User_TestDataFactory.createUsers(1, new List<String>{'en_US'})[0];
        	Insert testUser;
        Test.stopTest();
        System.debug('Usuario: ' + testUser);
        
        // Test 1: Before Update Success. Verifica que despues de actualizarse el usuario "SalesOrg_Text__c" sea igual a "Sales_Org__c"
        /*testUser.Sales_Org__c = '203;210';
        Database.SaveResult result_test_1 = Database.update(testUser, false);
        System.assert( result_test_1.isSuccess() );
        
        testUser = [SELECT SalesOrg_Text__c, Sales_Org__c, Distribution_Channel__c, DistributionChannel_Text__c 
                    FROM User WHERE Id =: testUser.Id];
        
        System.debug('Usuario: ' + testUser);
        System.assertEquals(testUser.SalesOrg_Text__c, testUser.Sales_Org__c );
        System.assertEquals(testUser.DistributionChannel_Text__c, testUser.Distribution_Channel__c );*/
        
		// Test 2: Before Update Fail
        // Debe fallar el update porque Default_Sales_Organization__c no puede estar vacio.
        // Luego debe fallar la insercion porque Distribution_channel_default__c no puede estar vacio.
        testUser.Default_Sales_Organization__c = null;
        Database.SaveResult result_test_2 = Database.update(testUser, false);
        
		System.assert( ! result_test_2.isSuccess() );
        System.debug('result_test_2 ACA: ' + result_test_2.getErrors());
        System.assert( result_test_2.getErrors()[0].getMessage().contains(Label.User_SelectDefaultSalesOrg));

        
    }
}