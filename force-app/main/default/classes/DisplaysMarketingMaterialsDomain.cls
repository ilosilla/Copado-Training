/**
* @author 		Ivan Losilla
* @date 		July 2022
* @group 		Displays
* @description 	Displays domain class
*/
public class DisplaysMarketingMaterialsDomain extends zflib_TriggerDomainClass {

    public DisplaysMarketingMaterialsDomain() {
        super();
    }

    public DisplaysMarketingMaterialsDomain(List<Displays_Marketing_Material__c> displays) {
        super(displays);
    }

    public override zflib_TriggerDomainClass cast() {
        return (DisplaysMarketingMaterialsDomain) this;
    } 

    public override Type getSObjectType() {
        return DisplaysMarketingMaterialsDomain.class;
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
    * @description Creates Platform Events about the new contact
    */
    private void platformEventNew() {
        List<PENewDisplay__e> listPlatformEvents = new List<PENewDisplay__e>();
        for (Displays_Marketing_Material__c ct : (List<Displays_Marketing_Material__c>) this.Records) {
            listPlatformEvents.add( new PENewDisplay__e( objectId__c = ct.Id ));
        }
        List<Database.SaveResult> results = EventBus.publish(listPlatformEvents);

        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event "New Display Marketing Material".');
            } else {
                for(Database.Error err : sr.getErrors()) {
                    Logger.error('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    Logger.saveLog();
                }
            }
        }
    } // platformEventNew
}