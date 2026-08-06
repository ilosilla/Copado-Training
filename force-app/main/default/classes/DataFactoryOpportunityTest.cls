@isTest
public class DataFactoryOpportunityTest {
	
    private static final Integer NUM_ACCOUNTS = 2;
	private static final Integer NUM_OPPORTUNITIES = 3;    

	/**
	 * Setup data
	 */
    @testSetup static void setup() {
        
        // Los triggers usan la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        Insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
    }
    
    @isTest static void createRetailOpportunities() {
        List<Opportunity> opps = DataFactoryOpportunity.createRetailOpportunities(NUM_ACCOUNTS, NUM_OPPORTUNITIES);        
        System.assertEquals(opps.size(), NUM_ACCOUNTS * NUM_OPPORTUNITIES, 'The number of opportunities do not match the number requested');
    } // createRetailOpportunities
    
    @isTest static void createTradeOpportunities() {
        List<Opportunity> opps = DataFactoryOpportunity.createTradeOpportunities(NUM_ACCOUNTS, NUM_OPPORTUNITIES);        
        System.assertEquals(opps.size(), NUM_ACCOUNTS * NUM_OPPORTUNITIES, 'The number of opportunities do not match the number requested');
    } // createRetailOpportunities

}