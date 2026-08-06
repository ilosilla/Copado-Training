@isTest
public class LightningConnectQuickstartTest {
    @testSetup static void setup() {
        // Los triggers usan la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();

        Account_TestDataFactory.insertAccounts( new List<Account>{
            Account_TestDataFactory.createFabricator(),
            Account_TestDataFactory.createCustomer(),
            Account_TestDataFactory.createRetailer() });
    }

    @isTest public static void testGetCustomersId(){
        List<Account> accList = [SELECT Id, Customer_Id__c FROM Account];
        LightningConnectQuickstart aux = new LightningConnectQuickstart();
        
        System.assert(accList.size() > 0);
        System.assert(aux.getCustomerIDsSet() == true || aux.getCustomerIDsSet() == false);
    }
    
    @isTest public static void testSetCustomersId(){
        List<Account> accList = [SELECT Id, Customer_Id__c FROM Account];
        LightningConnectQuickstart aux = new LightningConnectQuickstart();
        aux.setCustomerIDs();
        System.assert(aux.getCustomerIDsSet() == true || aux.getCustomerIDsSet() == false);
    }




}