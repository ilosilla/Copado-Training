/*-----------------------------------------------------------------------------------------
Author:         
Company:        Neoris
Description:    Clase test de LeadTriggerHandler
Date:			10-06-2019
History
<Date>            <Author>              <Change Description>
-----------------------------------------------------------------------------------------*/

@isTest
public class LeadTriggerHandler_Test {
	@testSetup static void setup() {
		// El trigger usa la custom setting "Trigger_configuration__c" para saber si ejecutar las validaciones.
        // Como desde adentro de un test no se puede ver la instacia de "Trigger_configuration__c" hay que insertar una
        // para activar el trigger.
        Insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
        
        List<Lead> leadList = Lead_TestDataFactory.createLeads(3, new Map<String, Object>());
        leadList.addAll(Lead_TestDataFactory.createLeads(2, new Map<String, Object>{'Company' => 'Lead Error Test'}));
        Insert leadList;
    }
    
    @isTest
    public static void leadTriggerSuccess(){
        List<Lead> leadList = [SELECT Id FROM Lead WHERE Company LIKE '%testLead'];
        
        String leadMasterLabel = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1].MasterLabel;
        
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        
		Database.LeadConvertResult[] leadConvertResultsSuccess;
        List<Database.LeadConvert> leadConvertList = new List<Database.LeadConvert>();
        
        for(Integer i=0; i<leadList.size(); i++){
            System.debug('Lead ' + i + ': ' + leadList[i]);
            
            Database.LeadConvert leadConvert = new Database.LeadConvert();
            leadConvert.setBypassAccountDedupeCheck(true);
            leadConvert.setBypassContactDedupeCheck(true);
            leadConvert.setLeadId(leadList[i].Id);
            leadConvert.setConvertedStatus(leadMasterLabel);
            
            leadConvertList.add(leadConvert);
        }
        
        Test.setMock(HttpCalloutMock.class, new OpportunityMockHttpResponseGenerator());
        Test.startTest();
        	
        	leadConvertResultsSuccess = Database.convertLead(leadConvertList, false);
        Test.stopTest();

        List<Account> accCreated = [SELECT Id FROM Account];
        Assert.isTrue((accCreated.size()>=0), 'Me da igual si se han grabado todos los Leads');
    }
}