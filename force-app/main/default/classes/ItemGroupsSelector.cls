/**
 * @author         Ramón Prades
 * @date           December 2024
 * @layer          Selector
 * @description    Item GRoups selector (equivalento to SAP Grupo de Artículos)
*/
public class ItemGroupsSelector extends zflib_SObjectSelector_v2 {    
    public override String getTypeName() {
        return 'ItemGroup__c';
    }
}