/**
* @author 		Ivan Losilla
* @date 		August 2022
* @group 		Moodboards
* @description 	Moodboards domain class
*/
public class MoodboardsDomain extends zflib_TriggerDomainClass {

    public MoodboardsDomain() {
        super();
    }

    public MoodboardsDomain(List<Moodboard__c> moodboards) {
        super(moodboards);
    }

    public override zflib_TriggerDomainClass cast() {
        return (MoodboardsDomain) this;
    } 

    public override Type getSObjectType() {
        return MoodboardsDomain.class;
    }

    /*********************************************************/
    /******************** TRIGGER METHODS ********************/
    /*********************************************************/

    public override void onAfterInsert() {
        updateUrlField();
        platformEventNew();
    } //onBeforeInsert

    /*********************************************************/
    /********************* PUBLIC METHODS ********************/
    /*********************************************************/

    /**
    * @description Creates Moodboards given a list of opportunities 
    */
    public void createDefaultMoodboards(List<Opportunity> oppsList) {
        List<Moodboard__c> listMoodboards = new List<Moodboard__c>();
        try {
            for (Opportunity opp : oppsList) {
                listMoodboards.add(new Moodboard__c(Opportunity__c = opp.Id, Name = 'Auto Moodboard', isDefault__c = true));
            }
    
            if (listMoodboards.size() > 0) {
                List<Database.SaveResult> resultsMoodboards       = Database.insert(listMoodboards, false);
    
                for (Database.SaveResult sr : resultsMoodboards) {
                    if (!sr.isSuccess()) {
                        System.debug('Failed insert Default Moodboard');
                        System.debug(sr);
                    }
                }
            }
        } catch (ContextException ex) {
            System.debug('Auto Moodboards not created');
        }
    }

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/

    /**
    * @description Calculates the Url of the Moodboard after the creation 
    */
    private void updateUrlField() {
        Set<Id> moodboardIds = new Set<Id>();

        for (Moodboard__c moodboard : (List<Moodboard__c>) this.Records) {
            moodboardIds.add(moodboard.Id);
        }

        List<Moodboard__c> moodboardsList = [SELECT Id, Url__c, Opportunity__r.Owner.LanguageLocaleKey FROM Moodboard__c where Id IN : moodboardIds];

        for (Moodboard__c moodboard : moodboardsList) {
            moodboard.Url__c = 'https://moodboard.porcelanosagrupo.com/#/templates/' + moodboard.Opportunity__r.Owner.LanguageLocaleKey + '/SFORCE_' + moodboard.Id;
        }

        if (moodboardsList.size() > 0) {
            List<Database.SaveResult> resultsAccounts       = Database.update(moodboardsList, false);

            for (Database.SaveResult sr : resultsAccounts) {
                if (!sr.isSuccess()) {
                    System.debug('Failed set URL Moodboard');
                    System.debug(sr);
                }
            }
        }
    }

    /**
    * @description Creates Platform Events about the new event
    */
    private void platformEventNew() {
        List<PENewMoodboard__e> listPlatformEvents = new List<PENewMoodboard__e>();
        for (Moodboard__c moodboard : (List<Moodboard__c>) this.Records) {
            listPlatformEvents.add( new PENewMoodboard__e( objectId__c = moodboard.Id ));
        }
        List<Database.SaveResult> results = EventBus.publish(listPlatformEvents);

        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                System.debug('Successfully published event "New Moodboard".');
            } else {
                for(Database.Error err : sr.getErrors()) {
                    Logger.error('Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    Logger.saveLog();
                }
            }
        }
    } // platformEventNew
}