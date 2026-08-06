/**
* @author 		Ivan Losilla
* @date 		July 2022
* @group 		Displays
* @description 	displays selector class
*/
public class DisplaysSelector extends zflib_SObjectSelector  {
    public Schema.SObjectType getSObjectType(){
        return Displays_Marketing_Material__c.sObjectType;
    }

    public List<Displays_Marketing_Material__c> selectById(Set<Id> recordIds){
        return (List<Displays_Marketing_Material__c>) selectSObjectsById(recordIds);
    }

    public Displays_Marketing_Material__c selectById(Id recordId){
        List<Displays_Marketing_Material__c> listDisplays = (List<Displays_Marketing_Material__c>) selectSObjectsById(new Set<Id>{recordId});
        if (listDisplays.size() == 1) {
            return listDisplays[0];
        }
        return null;
    }
   
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            
            // Main info fields
            Displays_Marketing_Material__c.Id,
            Displays_Marketing_Material__c.CurrencyIsoCode,
            Displays_Marketing_Material__c.Name,
            Displays_Marketing_Material__c.Account__c,
            Displays_Marketing_Material__c.Number__c,
            
            //Classification fields
            Displays_Marketing_Material__c.Status__c,
            Displays_Marketing_Material__c.Type__c ,

            // Admin fields
            Displays_Marketing_Material__c.CreatedById,
            Displays_Marketing_Material__c.CreatedDate,
            Displays_Marketing_Material__c.LastModifiedById
        };
    }
}