/**
* @author 		Ivan Losilla
* @date 		August 2022
* @group 		InstallationRequests
* @description 	installation requests selector class
*/
public class InstallationRequestsSelector extends zflib_SObjectSelector  {
    public Schema.SObjectType getSObjectType(){
        return InstallationRequest__c.sObjectType;
    }

    public List<InstallationRequest__c> selectById(Set<Id> recordIds){
        return (List<InstallationRequest__c>) selectSObjectsById(recordIds);
    }

    public InstallationRequest__c selectById(Id recordId){
        List<InstallationRequest__c> listInstallations = (List<InstallationRequest__c>) selectSObjectsById(new Set<Id>{recordId});
        if (listInstallations.size() == 1) {
            return listInstallations[0];
        }
        return null;
    }
   
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            
            // Main info fields
            InstallationRequest__c.Id,
            InstallationRequest__c.Name,
            InstallationRequest__c.AccountId__c,
            InstallationRequest__c.InstallerAccount__c,
            InstallationRequest__c.Installer_Contact__c,
            InstallationRequest__c.Opportunity__c,
            InstallationRequest__c.CurrencyIsoCode,
            InstallationRequest__c.Description__c,
            
            // Other info fields
            InstallationRequest__c.bathrooms__c,
            InstallationRequest__c.kitchens__c,
            InstallationRequest__c.others__c,
            InstallationRequest__c.AcceptedDate__c,
            InstallationRequest__c.WorksElectrical__c,
            InstallationRequest__c.Installation_Cost__c,
            InstallationRequest__c.LastTransition__c,
            InstallationRequest__c.WorksOther__c,
            InstallationRequest__c.ReasonLost__c,
            InstallationRequest__c.ReasonRejected__c,
            InstallationRequest__c.Sales_Org__c,
            InstallationRequest__c.SAPPurchaseOrder__c,
            InstallationRequest__c.SAPQuote__c,
            InstallationRequest__c.SAPOrder__c,
            InstallationRequest__c.SurveyCompleted__c,
            InstallationRequest__c.SurveyDate__c,
            InstallationRequest__c.SurveyNotes__c,
            InstallationRequest__c.State__c,
            InstallationRequest__c.WorksWater__c,

            // Admin fields
            InstallationRequest__c.OwnerId,
            InstallationRequest__c.CreatedById,
            InstallationRequest__c.LastModifiedById,
            InstallationRequest__c.AcceptedBy__c
        };
    }
}