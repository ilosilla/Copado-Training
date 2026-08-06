public with sharing class DvsScheduler implements Schedulable {
    
    /**
     * Retrieve all active DVS settings
     */
    private List<DvsSetting__mdt> getDVSSettings() {
        return [SELECT Id, 
                        DvsId__c, 
                        DvsSecret__c, 
                        DvsURL__c, 
                        DvsTokenUrl__c,
                        BatchSize__c, 
                        DvsWaitingTime__c,
                        IsActif__c,
                        CountryCode__c 
                FROM DvsSetting__mdt
                WHERE IsActif__c = true
        ];
    }

    public void execute(SchedulableContext sc) {
        List<DvsSetting__mdt> dvsSettings = getDVSSettings();
        for (DvsSetting__mdt dvsSetting : dvsSettings) {
            DvsBatchController batch = new DvsBatchController(dvsSetting);
            Database.executeBatch(batch, (Integer) dvsSetting.BatchSize__c);
        }
    }
}