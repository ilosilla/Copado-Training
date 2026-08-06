@isTest
public class OpportunityToSAP_Wrapper_Test {
	
    @testSetup static void setup(){
        // El trigger usa la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
        
    }
    
    @isTest
    public static void test_OpportunityToSAP_Wrapper_Controller(){
        // Solo hay que testear el contructor. Entonces se verificar que los datos que se le pasa al constructor
        // sean accesibles despues de crear el objeto y sean los mismos datos que los que se ingresaron.
        
        Opportunity opp = new Opportunity(Name = 'OppToSapWrapper');
        OpportunityContactRole oppActor = new OpportunityContactRole(Role = 'Architect');
        
        OpportunityToSAP_Wrapper oppToSapWrap = new OpportunityToSAP_Wrapper(opp, new List<OpportunityContactRole>{oppActor});
        
        System.assertEquals(opp.Name, oppToSapWrap.opportunity.Name);
        System.assertEquals(oppActor.Role, oppToSapWrap.opportunityActorsList[0].Role);
        
    }
}