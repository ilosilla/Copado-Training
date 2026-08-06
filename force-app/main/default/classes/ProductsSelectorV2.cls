/**
 * @author         Ramón Prades
 * @date           December 2024
 * @layer          Selector
 * @description    Item GRoups selector (equivalento to SAP Grupo de Artículos)
*/
public class ProductsSelectorV2 extends zflib_SObjectSelector_v2 {    

    public override String getTypeName() {
        return 'Product2';
    }

    public List<Product2> selectBySKU(Set<String> skus){
        zflib_QueryFactory query = newQueryFactory();
        for (String rel : this.relationshipFields) {
            query.selectField(rel);
        }
        query.setCondition('StockKeepingUnit IN :skus');        
        return (List<Product2>) Database.query( query.toSOQL() );
     }

    protected override Set<String> getExcludedFields() {
        return new Set<String>{'taxpolicyid', 'isshippingchargenotapplicable', 'shippingweight', 'shippingweightunitofmeasure', 'stockcheckmethod', 'productpurpose'};
    }
     
}