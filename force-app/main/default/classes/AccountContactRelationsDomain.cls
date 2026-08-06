/**
* @author 		Ivan Losilla
* @date 		July 2023
* @group 		AccountContactRelation
* @description 	AccountContactRelations domain class
*/
public class AccountContactRelationsDomain extends zflib_TriggerDomainClass {

    public AccountContactRelationsDomain() {
        super();
    }

    public AccountContactRelationsDomain(List<AccountContactRelation> contactRelations) {
        super(contactRelations);
    }

    public override zflib_TriggerDomainClass cast() {
        return (AccountContactRelationsDomain) this;
    } 

    public override Type getSObjectType() {
        return AccountContactRelationsDomain.class;
    }

    /*********************************************************/
    /******************** TRIGGER METHODS ********************/
    /*********************************************************/

    public override void onAfterInsert() {
        Set<Id> idsUpdateLastActivity = new Set<Id>();
        for (AccountContactRelation acr : (List<AccountContactRelation>) this.Records) {
            idsUpdateLastActivity.add(acr.Id);
        }
        updateActivityDate(idsUpdateLastActivity);
    } //onAfterInsert

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/

    /**
    * @description Creates Platform Events about the new contact
    */
    @future
    private static void updateActivityDate(Set<Id> listRelations) {
       ActivityDateService.updateFromAccountContactRelations(listRelations);
    } // platformEventNew
}