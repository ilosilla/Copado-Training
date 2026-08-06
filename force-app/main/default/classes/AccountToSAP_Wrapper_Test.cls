@isTest
public class AccountToSAP_Wrapper_Test {
	@testSetup static void setup(){
        // El trigger usa la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
        
    }
    
    @isTest
    public static void test_AccountToSAP_Wrapper_Constructor(){
        // Solo hay que testear el contructor. Entonces se verifica que los datos que se le pasa al constructor
        // sean accesibles despues de crear el objeto y sean los mismos datos que los que se ingresaron.
        Account acc = new Account(Name = 'AccToSapWrap');
        Sales_Relationship__c salesRel = new Sales_Relationship__c(Name = 'SalesRelName');
        
        AccountToSAP_Wrapper accToSAPWrapp = new AccountToSAP_Wrapper(acc, new List<Sales_Relationship__c> {salesRel});
        
        System.assertEquals(acc.Name, accToSAPWrapp.customer.Name);
        System.assertEquals(salesRel.Name, accToSAPWrapp.companies[0].Name);
        
    }
}