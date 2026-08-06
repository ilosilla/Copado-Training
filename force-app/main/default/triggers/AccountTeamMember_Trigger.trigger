/**
* @date September 2021
* @group Triggers
* @deprecated  We don't use this one, instead we use AccountTeamMemberTrigger
*/
trigger AccountTeamMember_Trigger on AccountTeamMember (before insert, before update, before delete, after insert, after update, after delete) {
    /*
    * This is going to manage the Triggers linked to the Account Team Members
    */
    // List<Trigger_configuration__c> tc = Trigger_configuration__c.getall().values();
    // if ( tc[0].Account_Team_Members__c ) {
    //     TriggerFactory2.createAndExecuteHandler(AccountTeamMemberHandler.class);
    // }
    // else {
    //     System.Debug ('AccountTeamMember Triggers OFF');
    // }
}