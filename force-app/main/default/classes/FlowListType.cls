/**
* @author 	Ramón Prades
* @date 	October 2020
*
* @group 	Installations
* @group-content ../../ApexDocContent/Installations.htm
*
* @description 	Encapsulates a list as a json so it can be passwd back and forth
* 				between a controller class, a flow and a lightning component.
*/

global class FlowListType {

	@AuraEnabled @InvocableVariable  	
    global Integer size;
    
    @AuraEnabled @InvocableVariable  	
    global String theJSON;
    
}