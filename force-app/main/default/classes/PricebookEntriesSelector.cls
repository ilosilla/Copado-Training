/**
* @author 		Ivan Losilla
* @date 		July 2022
* @group 		PricebookEntries
* @description 	pricebookentries selector class
*/
public class PricebookEntriesSelector extends zflib_SObjectSelector  {
    public Schema.SObjectType getSObjectType(){
        return PricebookEntry.sObjectType;
    }

    public List<PricebookEntry> selectById(Set<Id> recordIds){
        return (List<PricebookEntry>) selectSObjectsById(recordIds);
    }

    public List<PricebookEntry> selectByPricebook(Id pricebookId, String currencyCode, Set<Id> productIds){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('Pricebook2Id = :pricebookId and CurrencyIsoCode = :currencyCode and Product2Id in :productIds');
        return Database.query(query.toSOQL());

    }

    public List<PricebookEntry> selectByTariffAndProduct(Set<String> tariffs, Set<String> productCodes){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('Bzirk__c IN :tariffs and ProductCode IN :productCodes and Bzirk__c <> null');
        query.selectField('Pricebook2.Name');
        query.selectField('Product2.Name');
        query.selectField('Product2.ProductCode');
        return (List<PricebookEntry>) Database.query( query.toSOQL() );
    }
   
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            
            PricebookEntry.Id,
            PricebookEntry.CurrencyIsoCode,
            PricebookEntry.IsActive,
            PricebookEntry.Name,
            PricebookEntry.Pricebook2Id,
            PricebookEntry.Product2Id,
            PricebookEntry.ProductCode,
            
            // Custom fields
            PricebookEntry.Bzirk__c,
            PricebookEntry.UPrice__c,
            PricebookEntry.UnitPrice,
            PricebookEntry.SAPPrice__c,
            PricebookEntry.SAPPriceUnit__c,
            PricebookEntry.UMVPrice__c,
            PricebookEntry.UMVPriceUnit__c,

            //Admin fields
            PricebookEntry.CreatedById,
            PricebookEntry.CreatedDate,
            PricebookEntry.LastModifiedDate,
            PricebookEntry.LastModifiedById

        };
    }
}