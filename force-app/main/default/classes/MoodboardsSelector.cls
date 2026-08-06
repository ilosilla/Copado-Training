/**
* @author 		Ivan Losilla
* @date 		August 2022
* @group 		Moodboards
* @description 	moodboards selector class
*/
public class MoodboardsSelector extends zflib_SObjectSelector  {
    public Schema.SObjectType getSObjectType(){
        return Moodboard__c.sObjectType;
    }

    public List<Moodboard__c> selectById(Set<Id> recordIds){
        return (List<Moodboard__c>) selectSObjectsById(recordIds);
    }

    public Moodboard__c selectById(Id recordId){
        List<Moodboard__c> listMoodboards = (List<Moodboard__c>) selectSObjectsById(new Set<Id>{recordId});
        if (listMoodboards.size() == 1) {
            return listMoodboards[0];
        }
        return null;
    }
   
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            
            // Main info fields
            Moodboard__c.Id,
            Moodboard__c.CurrencyIsoCode,
            Moodboard__c.Name,

            // Other info fields
            Moodboard__c.IsDefault__c,
            Moodboard__c.Opportunity__c,
            Moodboard__c.Url__c,

            // Admin fields
            Moodboard__c.CreatedById
        };
    }
}