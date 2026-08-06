/**
* @author         Ramón Prades
* @date           May 2023
* @group          Product List Items
* @description    Enhances zflib_SObjectSelector to facilitate creating selectors.
* 
* INFO
* ----
* This class uses some generic methods to avoid having to implement them in the child class. Actually, the only method
* to implement i the child class is "getTypeName".
*
* For example:
*
*    public class ProductListItemsSelector extends zflib_SObjectSelector_v2 {
*       public override String getTypeName() {
*           return 'ProductListItem__c';
*       }
*    } // class
*
* Additionally, this class introduces a new method "selectSingle":
*
*    ProductListItemsSelector selector = new ProductListItemsSelector();
*    ProductListItem__c result = (ProductListItem__c) selector.selectSingle(item.Id);
*
* For coverage, use ProductListItemsSelectorTest.
*/
public abstract class zflib_SObjectSelector_v2  extends zflib_SObjectSelector {

    public abstract String getTypeName();
    public List<String> relationshipFields = new List<String>();

    public void addRelationshipField(String fieldName) {
        this.relationshipFields.add(fieldName);
    }

    /*
     * Fields should be in lower case
     */
    protected virtual Set<String> getExcludedFields() {
        return new Set<String>();
    }

    public SObject selectSingle(Id recordId) {
        Set<Id> recordIds = new Set<Id>{recordId};        
        List<SObject> results= selectSObjectsById(recordIds);
        if (results.size() == 1) {
            return results[0];
        } else {
            return null;
        }
    }

    public List<SObject> selectById(Set<Id> recordIds) {
        return selectSObjectsById(recordIds);
    }

    public List<SObject> selectAll(){
        zflib_QueryFactory query = newQueryFactory();        
        return Database.query( query.toSOQL() );
    }
 
    public Schema.SObjectType getSObjectType() {
        return Schema.getGlobalDescribe().get(this.getTypeName());
    }

    public virtual List<Schema.SObjectField> getSObjectFieldList() {
        Set<String> excluded = this.getExcludedFields();
        SObjectType oType = Schema.getGlobalDescribe().get(this.getTypeName());
        Map<String,Schema.SObjectField> mfields = oType.getDescribe().fields.getMap();
        if (excluded.size() == 0) {
            return mfields.values();
        }        
        List<Schema.SObjectField> fields = new List<Schema.SObjectField>();
        for (String fieldName : mfields.keySet()) {
            if (!excluded.contains(fieldName)) {
                fields.add(mfields.get(fieldName));
            }
        }
        return fields;
    }

    public override List<SObject> selectSObjectsById(Set<Id> idSet)  {

        return Database.query(buildQuerySObjectById2());
    }

    protected String buildQuerySObjectById2() {   
        zflib_QueryFactory queryFactory = newQueryFactory();
        queryFactory.setCondition('id in :idSet');
        for (String rel : this.relationshipFields) {
            queryFactory.selectField(rel);
        }
        return QueryFactory.toSOQL();
    }
} // class


/*
public class ProductListItemsSelector extends zflib_SObjectSelector{

    public Schema.SObjectType getSObjectType() {
        return ProductListItem__c.sObjectType;
    }

    public List<ProductListItem__c> selectById(Set<Id> recordIds) {
       return (List<ProductListItem__c>) selectSObjectsById(recordIds);
    }

    public List<Schema.SObjectField> getSObjectFieldList(){
        / *
        SObjectType caseType = Schema.getGlobalDescribe().get('ProductListItem__c');
        Map<String,Schema.SObjectField> mfields = caseType.getDescribe().fields.getMap();
        List<Schema.SObjectField> fields = mfields.values();
        * /
        return new List<Schema.SObjectField> {

            // Main info fields
            ProductListItem__c.Id,
            ProductListItem__c.OwnerId
        };
        //return fields;
     }

} // class
*/