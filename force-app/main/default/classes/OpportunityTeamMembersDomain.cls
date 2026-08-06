/**
* @author 		Ivan Losilla
* @date 		July 2022
* @group 		OpportunityTeamMembers
* @description 	Opportunity Team Members domain class
*/
public class OpportunityTeamMembersDomain extends zflib_TriggerDomainClass {

    public OpportunityTeamMembersDomain() {
        super();
    }

    public OpportunityTeamMembersDomain(List<OpportunityTeamMember> contacts) {
        super(contacts);
    }

    public override zflib_TriggerDomainClass cast() {
        return (OpportunityTeamMembersDomain) this;
    } 

    public override Type getSObjectType() {
        return OpportunityTeamMembersDomain.class;
    }

    /*********************************************************/
    /******************** TRIGGER METHODS ********************/
    /*********************************************************/

    public override void onAfterInsert() {
        platformEventNew();
    } //onAfterInsert

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/

    /**
    * @description Creates Platform Events about the new account team member
    */
    private void platformEventNew() {
        List<PENewOppTeamMember__e> listPlatformEvents = new List<PENewOppTeamMember__e>();
        for (OpportunityTeamMember ct : (List<OpportunityTeamMember>) this.Records) {
            listPlatformEvents.add( new PENewOppTeamMember__e( objectId__c = ct.Id ));
        }
        List<Database.SaveResult> results = EventBus.publish(listPlatformEvents);

        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event "New Opportunity Team Member".');
            } else {
                for(Database.Error err : sr.getErrors()) {
                    Logger.error('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    Logger.saveLog();
                }
            }
        }
    } // platformEventNew
}