/**
* @author 		Ivan Losilla
* @date 		July 2022
* @group 		AccountTeamMembers
* @description 	Account Team Members domain class
*/
public class AccountTeamMembersDomain extends zflib_TriggerDomainClass {

    public AccountTeamMembersDomain() {
        super();
    }

    public AccountTeamMembersDomain(List<AccountTeamMember> accountTeamMembers) {
        super(accountTeamMembers);
    }

    public override zflib_TriggerDomainClass cast() {
        return (AccountTeamMembersDomain) this;
    } 

    public override Type getSObjectType() {
        return AccountTeamMembersDomain.class;
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
        List<PENewAccTeamMember__e> listPlatformEvents = new List<PENewAccTeamMember__e>();
        for (AccountTeamMember ct : (List<AccountTeamMember>) this.Records) {
            listPlatformEvents.add( new PENewAccTeamMember__e( objectId__c = ct.Id ));
        }
        List<Database.SaveResult> results = EventBus.publish(listPlatformEvents);

        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                for(Database.Error err : sr.getErrors()) {
                    Logger.error('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    Logger.saveLog();
                }
            }
        }
    } // platformEventNew
}