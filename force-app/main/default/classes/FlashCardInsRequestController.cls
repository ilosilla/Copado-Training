/**
* @author 	Ramón Prades
* @date 	August 2020
*
* @group 	Installations
* @group-content ../../ApexDocContent/Installations.htm
*
* @description Controller for the Installation Request Flash Card component
*/
public class FlashCardInsRequestController {
     
    @AuraEnabled 
    public static List<sObject> getRequest(Id opportunityId) {
        if (!InstallationUtil.hasInstallations()) {
            throw new NotEnabledException('Installations not enabled');
        }
        List<sObject> result = new List<sObject>();
        String fields = 'Id, State__c, Name, Description__c, Installation_Cost__c, Currency__c, SurveyDate__c, Opportunity__c, InstallerAccount__c';
        String sql = 'select ' + fields + ' from InstallationRequest__c where Opportunity__c = :opportunityId';
        List<InstallationRequest__c> requests = Database.query(sql);
        if (requests.size() > 0) {
            result.add(requests[0]);            
            Account installer = [select Id, Name from Account where Id = :requests[0].InstallerAccount__c][0];
            result.add(installer);
        }                   
        return result;        
    } // getRequest    
    
} // class