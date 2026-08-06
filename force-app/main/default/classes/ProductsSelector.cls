/**
* @author 		Ivan Losilla
* @date 		July 2022
* @group 		Products
* @description 	Products selector class
*/
public class ProductsSelector extends zflib_SObjectSelector  {
    public Schema.SObjectType getSObjectType(){
        return Product2.sObjectType;
    }

    public List<Product2> selectById(Set<Id> recordIds){
        return (List<Product2>) selectSObjectsById(recordIds);
    }

    public List<Product2> selectByProductCode(Set<String> productCodes){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('productCode IN :productCodes');
        return (List<Product2>) Database.query( query.toSOQL() );
    }

    public List<Product2> selectBySKU(Set<String> skus){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('StockKeepingUnit IN :skus');
        return (List<Product2>) Database.query( query.toSOQL() );
    }

    public String selectAllString(){
        zflib_QueryFactory query = newQueryFactory();
        return query.toSOQL();
    }

    public List<Schema.SObjectField> getSObjectFieldList(){
        List<String> excludedFieldNames = new List<String>{'TaxPolicyId', 'IsShippingChargeNotApplicable', 'ShippingWeight', 'ShippingWeightUnitOfMeasure',
                        'StockCheckMethod', 'ProductPurpose'};
        SObjectType sobjectType = Schema.getGlobalDescribe().get('Product2');
        Map<String,Schema.SObjectField> mfields = sobjectType.getDescribe().fields.getMap();        
        List<Schema.SObjectField> fields = mfields.values();
        for (String fieldName : excludedFieldNames ) {
            Schema.SObjectField excludedField = mfields.get(fieldName);
            if (excludedField != null) {
                fields.remove(fields.indexOf(excludedField));
            }
        }
        return fields;
    }
      
}