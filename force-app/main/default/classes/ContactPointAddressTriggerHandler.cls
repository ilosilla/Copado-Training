/**
* @author 		Ramón Prades
* @date 		December 2021
* @group 		Triggers
* @description 	Trigger handler for Contact Point Address
*/
public class ContactPointAddressTriggerHandler extends BaseTriggerHandler {

    /**
     * @description     Checks if the address can be deleted
     * @param           oldItems    A Map with the ids and th objects being deleted
     */    
    public override void beforeDelete(List<SObject> oldItems) {
        this.checkCPAddresses(oldItems);
    } // beforeDelete    

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/
    private Boolean checkCPAddresses(List<SObject> items) {
        
        Boolean hasErrors = false;            
        List<id> disabled = new List<Id>();

        for (ContactPointAddress adr : (List<ContactPointAddress>) items) {
            if (adr.SAPId__c != null) {
                hasErrors = true;
                String msg = Label.addr_sap_delete;
                msg = msg.Replace('$1', adr.Name);
                // SAPAddressHelper.deleteSAPAddress(adr.Id);
                disabled.add(adr.Id);
                //adr.Disabled__c = true;
                adr.addError(msg);
            }
        }

        return hasErrors;
    }

}