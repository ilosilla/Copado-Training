/**
* @date September 2021
* @group Triggers
* @deprecated  We don't use this one, instead we use DisplaysMarketingMaterialTrigger
*/
trigger DisplaysMarketingMaterial_Trigger on Displays_Marketing_Material__c (before insert, before update, before delete, after insert, after update, after delete) {
    /*
    * This is going to manage the Triggers linked to Display & Marketing related Account object
    */
    // List<Trigger_configuration__c> tc = Trigger_configuration__c.getall().values();
    // if ( tc[0].Displays_Marketing_Material__c ) {
    //     TriggerFactory2.createAndExecuteHandler(DisplaysMarketingMaterialHandler.class);
    // }
    // else {
    //     System.Debug ('Display and Marketing Material Triggers OFF');
    // }
}