/**
* @author         Ramón Prades
* @date           May 2023
* @group          Product List Items
* @description    Selector class. 
*                 Aprovechamos esta clase y su test como test de zflib_SObejctSelectoir_v2
*/
public class ProductListItemsSelector extends zflib_SObjectSelector_v2 {

    public override String getTypeName() {
        return 'ProductListItem__c';
    }

    public List<ProductListItem__c> selectByCase(Set<Id> caseIds){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('Case__c IN :caseIds');
        return (List<ProductListItem__c>) Database.query( query.toSOQL() );
    }

} // class