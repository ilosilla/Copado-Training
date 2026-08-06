/**
* @author 		Ramón Prades
* @date 		June 2022
* @group 		Leads
* @description 	Leads domain class
*/
public class LeadsDomain extends zflib_TriggerDomainClass {

    public static final String MATERIAL_BANK_SUBTYPE = 'Material Bank';
    public static final String APPOINTMENT_TYPE = 'Book an Appointment';

    // Class variables
    String productSupportStatus = 'Product Support';

    public LeadsDomain() {
        super();
    }

    public LeadsDomain(List<Lead> leads) {
        super(leads);
    }

    public override zflib_TriggerDomainClass cast() {
        return (LeadsDomain) this;
    } 

    public override Type getSObjectType() {
        return LeadsDomain.class;
    }

    public override void onApplyDefaults() {
        for (Lead l : (List<Lead>) this.Records) {
            this.applyRecordDefaults(l);
        }
    } // onApplyDefaults

    /*********************************************************/
    /******************** TRIGGER METHODS ********************/
    /*********************************************************/
    public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {        
        for (Lead newLead : (List<Lead>) this.Records) {            
                Lead oldLead = (Lead) existingRecords.get(newLead.Id);                
                if (newLead.Status != oldLead.Status) {
                    // US Status change rules
                    if (newLead.RecordTypeId == RecordTypeLibrary.Lead_USWebRequest) {
                        if (newLead.Status == this.productSupportStatus) {
                            String managerId = this.getUSClaimsManager();
                            if (String.isNotEmpty(managerId) && managerId != oldLead.ownerId) {
                                newLead.ownerId = managerId;                    
                            }
                        }
                    // Global rules                    
                    if (newLead.Status == 'Converted' && !newLead.isConverted ) {
                        String message = 'Manual converssion not allowed. Please use the converssion process.';
                        this.addRecordError(newLead, message, 'Status');
                    }
                }
            }
        }
    } // onBeforeUpdate

    public override void onAfterUpdate(Map<Id, SObject> existingRecords) {        
        for (Lead newLead : (List<Lead>) this.Records) {
            Lead oldLead = (Lead) existingRecords.get(newLead.Id);
            if (newLead.RecordTypeId == RecordTypeLibrary.Lead_USWebRequest &&  newLead.Status != oldLead.Status && newLead.Status == this.productSupportStatus) {
                USLeadMailer mailer = new USLeadMailer(newLead.Id);
                // Send an email because when the stage changes, the owner changes
                mailer.emailLeadOwner();
            }
        }
    } // onAfterUpdate

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/

    private void applyRecordDefaults(Lead l) {
        if (String.IsBlank(l.Opportunity_Name__c)) {
            l.Opportunity_Name__c = l.FirstName + ' ' + l.LastName;
            l.Opportunity_Name__c = l.Opportunity_Name__c.trim();
        }
        // Material bank leads do not
        if (!l.OwnerLocked__c && !this.isMaterialBank(l) ) {
            if (this.isUSWebRequest(l)) {
                this.setUSWebRequestDefaults(l);
            } else if (this.isWebRequest(l)) {
                this.setWebRequestDefaults(l);
            }
        }
        l.existingAccount__c = (String.IsNotBlank(l.AccountId__c));
    } // applyRecordDefaults

    private void setUSWebRequestDefaults(Lead l) {        
        // This is for those leads with no country code
        if (String.IsEmpty(l.CountryCode__c)) {
            l.CountryCode__c = 'US';
        }
        l.Source__c = 'USW';
        if (l.LeadType__c != 'US Material Bank') {
            LeadHelper helper = new LeadHelper(l);
            helper.setAccountAndOwner();
        }
    } // setUSWebRequestDefaults

    private Boolean isMaterialBank(Lead l) {
        return (l.LeadType__c?.containsIgnoreCase('MATERIAL BANK') ?? false);
    }

    private void setWebRequestDefaults(Lead l) {        
        LeadHelper helper = new LeadHelper(l);
        helper.setWebRequestFields();
        helper.setAccountAndOwner();
    }               

    private Boolean isUSWebRequest(lead l) {
        return (l.Source__c == 'USW' || l.RecordTypeId == RecordTypeLibrary.Lead_USWebRequest);
    }

    private Boolean isWebRequest(lead l) {
        return (l.Source__c == 'WEB' || l.RecordTypeId == RecordTypeLibrary.Lead_WebRequest);
    }

    private String getUSClaimsManager() {
        String userId = null;
        String email = SystemSettings.USClaimsManager;
        if (String.isNotBlank(email)) {
            userId = UserUtils.getUserIdFromEmail(email);
        }
        return userId;
    }
}