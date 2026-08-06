/*-----------------------------------------------------------------------------------------
Author:         Ivan Losilla Perez
Company:        Porcelanosa
Description:    Clase test de ShipmentAddressHandler
Date:			05-06-2020
History
<Date>            <Author>              <Change Description>
-----------------------------------------------------------------------------------------*/
/**
* @service Hecho por NTS
*/
@isTest 
public class ShipmentAddressHandlerTest {}
// public class ShipmentAddressHandlerTest {
//     @testSetup static void setup() {
//     	// Los triggers usan la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
//         // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
//         // para activar el trigger.
//         insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();

//         List<Account> accountList =  new List<Account>{
//             Account_TestDataFactory.createFabricator(), Account_TestDataFactory.createRetailer(), 
//                 Account_TestDataFactory.createBusinessAccount(), Account_TestDataFactory.createCustomer()};
        
//         accountList[0].Name = 'Account WithOut Contacts';
//         accountList[1].Name = 'Account With Contacts';
//         accountList[2].Name = 'Dif Account With Contacts';
        
//         Account_TestDataFactory.insertAccounts(accountList);
        
//         Map<String, Object> fieldMap = new Map<String, Object>{'AccountId' => accountList[1].Id};
            
//             List<Contact> contactList = Contact_TestDataFactory.createContacts(9, new List<Map<String, Object>>{fieldMap, fieldMap, 
//                 fieldMap, fieldMap, fieldMap, fieldMap, fieldMap, fieldMap, fieldMap});
        
//         Insert contactList;
//     }
    
//     @isTest public static void test_ShippmentAddress(){
//         Shipment_Address__c shipAddress = new Shipment_Address__c(State__c='Spain', Name='test Name Shipment Address');
//         insert shipAddress;

//         List<Shipment_Address__c> shipmentsList = [SELECT Id from Shipment_Address__c];
//         System.assert(shipmentsList.size() > 0);

//         shipmentsList[0].State__c = 'Loredei';
//         update shipmentsList;

//         shipmentsList = [SELECT Id from Shipment_Address__c where State__c = 'Loredei'];
//         System.Assert(shipmentsList.size() > 0);
//         delete shipmentsList[0];
        
//         shipmentsList = [SELECT Id from Shipment_Address__c where State__c = 'Loredei'];
//         System.Assert(shipmentsList.size() == 0);
//     }

//     @isTest public static void test_shipmentUtil() {
//         Account accWithContacts = [SELECT Id, Number_Of_Contacts__c FROM Account WHERE Name = 'Account With Contacts'];
//         Contact contact = [SELECT Id FROM Contact WHERE AccountId =: accWithContacts.Id LIMIT 1];

//         Shipment_Address__c shipAddress = new Shipment_Address__c(State__c='Aveyron', Name='test Name Shipment Address',Country__c='France',Contact__c = contact.Id , isPrimary__c=true);
//         insert shipAddress;
//         System.assertEquals('dummy', 'dummy', 'apex pmd dummy');

//     }


// }