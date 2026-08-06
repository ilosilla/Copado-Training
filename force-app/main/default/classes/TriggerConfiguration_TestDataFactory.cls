/*-----------------------------------------------------------------------------------------
Author:         Juan Manuel Martinez
Company:        Neoris
Description:    Crea custom settings para ser usadas en test de clases que implementen TriggerFactory.
                Es necesario insertarla porque los test no pueden ver instancias de esta setting que ya estan insertadas
Date:           26-03-2019
History
<Date>            <Author>              <Change Description>
26-04-2019								Agregado el metodo createSalesOrg
-----------------------------------------------------------------------------------------*/

@isTest
public class TriggerConfiguration_TestDataFactory {
    
    public static Trigger_configuration__c createCustomSetting_ActivatedTriggers() {
        Trigger_configuration__c testCustomSetting = new Trigger_configuration__c();
        
        testCustomSetting.Name = 'Activated Test Setting';
        testCustomSetting.Event__c = true;
        testCustomSetting.Task__c = true;
        testCustomSetting.Sales_Relationship__c = true;
        testCustomSetting.User__c = true;
        testCustomSetting.Opportunity_Split__c = false;
        testCustomSetting.Opportunity_Team_Member__c = false;
        testCustomSetting.Account__c = true;
        testCustomSetting.Opportunity__c = true;
        testCustomSetting.Order__c = true;
        testCustomSetting.Lead__c = true;
        testCustomSetting.Contact__c = true;
        
        return testCustomSetting;
    }
    
    public static Trigger_configuration__c createCustomSetting_DeactivatedTriggers() {
        Trigger_configuration__c testCustomSetting = new Trigger_configuration__c();
        
        testCustomSetting.Name = 'Deactivated Test Setting';
        testCustomSetting.Event__c = false;
        testCustomSetting.Task__c = false;
        testCustomSetting.Sales_Relationship__c = false;
        testCustomSetting.User__c = false;
        testCustomSetting.Opportunity_Split__c = false;
        testCustomSetting.Opportunity_Team_Member__c = false;
        testCustomSetting.Account__c = false;
        testCustomSetting.Opportunity__c = false;
        testCustomSetting.Order__c = false;
        testCustomSetting.Lead__c = false;
        testCustomSetting.Contact__c = false;
        
        return testCustomSetting;
    }
    
}