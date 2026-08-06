/**
 * Author           Ramón prades
 * Description      TriggerHandler interface
 * Date             May 2020
 * References       http://chrisaldridge.com/triggers/lightweight-apex-trigger-framework/
 * History          
*/
public interface ITriggerHandler 
{
    void beforeInsert(List<SObject> newItems);
    void beforeUpdate(List<SObject> newItems, Map<Id, SObject> oldItems); 
    void beforeDelete(List<SObject> oldItems); 
    void afterInsert(List<SObject> newItems); 
    void afterUpdate(List<SObject> newItems, Map<Id, SObject> oldItems); 
    void afterDelete(List<SObject> oldItems);
    void afterUndelete(List<SObject> newItems);
    Boolean isEnabled();
}