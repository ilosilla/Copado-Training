/**
* @author           Ramón Prades
* @date             Feb 2021
* @group            Triggers
* @description      New trigger handler for leads
*/
public class LeadNewTriggerHandler {


    public static String productSupportStatus = 'Product Support';
    /*


    /* *
     * Before insert
     * REFACTORED
     * /
    public override void beforeInsert(List<SObject> newItems) {     
        for (SObject ol :newItems)  {
            Lead aLead = (Lead) ol;
            LeadHelper helper = new LeadHelper(aLead);     
            if (LeadUtil.isUSWebRequest(aLead)) {  
                // This is for those leads with no country code
                if (String.IsEmpty(aLead.CountryCode__c)) {
                    aLead.CountryCode__c = 'US';
                }
                if (String.IsNotEMpty(aLead.LeadType__c) && aLead.LeadType__c != 'US Material Bank') {
                    helper.setAccountAndOwner();
                }                
            } else if (LeadUtil.isWebRequest(aLead)) {  
                helper.setWebRequestFields();
                helper.setAccountAndOwner();
            }
            aLead.existingAccount__c = (String.IsNotBlank(aLead.AccountId__c));
        }
    } // beforeInsert

    // beforeUpdate
    public override void beforeUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) { 
        for (Lead newLead : (List<Lead>) newItems) {            
            Lead oldLead = (Lead) oldItems.get(newLead.Id);
            if (newLead.RecordTypeId == RecordTypeLibrary.Lead_USWebRequest) {
                if (newLead.Status != oldLead.Status) {
                    if (newLead.Status == this.productSupportStatus) {
                        String managerId = this.getClaimsManager();
                        if (String.isNotEmpty(managerId) && managerId != oldLead.ownerId) {
                            newLead.ownerId = managerId;                    
                        }
                    }
                }
            }
        }
    } // afterUpdate

    // afterUpdate
    public override void afterUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) { 
        for (Lead newLead : (List<Lead>) newItems) {
            Lead oldLead = (Lead) oldItems.get(newLead.Id);
            if (newLead.RecordTypeId == RecordTypeLibrary.Lead_USWebRequest &&  newLead.Status != oldLead.Status && newLead.Status == this.productSupportStatus) {
                USLeadMailer mailer = new USLeadMailer(newLead.Id);
                mailer.emailLeadOwner();
            }
        }
    } // afterUpdate


    / ********************************************************* /
    / ******************** PRIVATE METHODS ******************** /
    / ********************************************************* /
    private String getClaimsManager() {
        String userId = null;
        String email = SystemSettings.USClaimsManager;
        if (String.isNotBlank(email)) {
            userId = UserUtils.getUserIdFromEmail(email);
        }
        return userId;
    }
    */
} // class LeadNewTriggerHandler