/**
 * Author           Ramón prades
 * Description      Custom setting 'TriggerFlags' to enable/disable trigger execution
 * Date             May 2020
 * History          
*/
public with sharing class TriggerFlags {

    @testvisible
    private static TriggerFlags__c tFlags;
    
    /**
     * Class constructor
     */
    static {
        if (Test.isRunningTest()) {
			enableForTesting();
        }
		readTriggerFlags();
    }

    public static Boolean isEnabled(String flag) {
        switch on flag.toLowerCase() {
            when 'account'                   { return tFlags.Account__c; }
            when 'contact'                   { return tFlags.Contact__c; }
            when 'event'                     { return tFlags.Event__c; }
            when 'lead'                      { return tFlags.Lead__c; }
            when 'opportunity'               { return tFlags.Opportunity__c; }
            when 'opportunitycontactrole'    { return tFlags.Opportunity_Contact_Role__c; }
            when 'opportunity_split'         { return tFlags.Opportunity_Split__c; }
            when 'opportunityteammember'     { return tFlags.Opportunity_Team_Member__c; }
            when 'order'                     { return tFlags.Order__c; }
            when 'salesrelationship'         { return tFlags.Sales_Relationship__c; }
            when 'task'                      { return tFlags.Task__c; }
            when 'user'                      { return tFlags.User__c; }
            when 'installationrequest'		 { return tFlags.InstallationRequest__c; }
            when 'oppcustomproject'		     { return tFlags.OppCustomProject__c; }
            when 'contactpointaddress'		 { return tFlags.ContactPointAddress__c; }
            when 'moodboard'		         { return tFlags.Moodboard__c; }
            when 'opportunitylineitem'		 { return tFlags.Opportunity_Line_Item__c; }
            when 'emailmessage'              { return tFlags.Email_Message__c; }
            when else                        { throw new ObjectNotFoundException(); }
        } // switch
            
    } // isEnabled

    private static void readTriggerFlags() {        
        tFlags = TriggerFlags__c.getInstance();
        
        if (tFlags == null) {
            writeDefaultValues();
        } 
    } // readTriggerFlags   
    
    @testvisible
    private static void enableForTesting() {
        tFlags = TriggerFlags__c.getValues(UserInfo.getOrganizationId());
        if (Test.isRunningTest() && tFlags == null) {
			writeDefaultValues();
        }
    } // enableForTesting
    
    private static void writeDefaultValues() {
		tFlags = new TriggerFlags__c();                
        tFlags.Account__c = true;
        tFlags.Contact__c = true;
        tFlags.ContactPointAddress__c = true;
        tFlags.Event__c = true;
        tFlags.InstallationRequest__c = true;
        tFlags.InstallationOrder__c = true;
        tFlags.Lead__c = true;
        tFlags.Opportunity__c = true;
        tFlags.Opportunity_Contact_Role__c = true;
        tFlags.Opportunity_Split__c = true;
        tFlags.Opportunity_Team_Member__c = true;
        tFlags.Opportunity_Line_Item__c = true;
        tFlags.Order__c = true;
        tFlags.Sales_Relationship__c = true;
        tFlags.Task__c = true;
        tFlags.User__c = true;
        tFlags.Moodboard__c = true;
		Database.insert(tFlags);
    }
} // Class