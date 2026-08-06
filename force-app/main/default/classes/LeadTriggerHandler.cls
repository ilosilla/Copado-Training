/**
* @author           Ramón Prades
* @date             Feb 2021
* @group            Triggers
* @description      New trigger handler for leads.
* @deprecated       replaced by LeadNewTriggerHandler
*/
public class LeadTriggerHandler  extends BaseTriggerHandler{

    public override void beforeInsert(List<SObject> newItems) {     
        /*
        for (SObject ol :newItems)  {
            Lead aLead = (Lead) ol;
            if (LeadUtil.isWebRequest(aLead)) {  
                leadHelper helper = new LeadHelper(aLead);     
                helper.setWebRequestFields();
                helper.setAccountAndOwner();
            }
        }
        */
    }

}