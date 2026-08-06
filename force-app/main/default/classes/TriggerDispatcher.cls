/**
 * Author           Ramón prades
 * Description      Dispatcher for the trigger framework
 * Date             May 2020
 * References       http://chrisaldridge.com/triggers/lightweight-apex-trigger-framework/
 * History          
*/
public class TriggerDispatcher {
    
    /*
        Call this method from your trigger, passing in an instance of a trigger handler which implements ITriggerHandler.
        This method will fire the appropriate methods on the handler depending on the trigger context.
    */
    public static void run(ITriggerHandler handler) {
        if (!handler.isEnabled()) {
            return;
        }
               
        // Before trigger logic
        if (Trigger.IsBefore )
        {
            if (Trigger.IsInsert) {
                handler.beforeInsert(Trigger.new);
            }
 
            if (Trigger.IsUpdate) {
                handler.beforeUpdate(trigger.new, trigger.oldMap);
            }
 
            if (Trigger.IsDelete) {
                handler.beforeDelete(trigger.old);
            }
        }
         
        // After trigger logic
        if (Trigger.IsAfter)
        {
            if (Trigger.IsInsert) {
                handler.afterInsert(Trigger.new);
            }
 
            if (Trigger.IsUpdate) {
                handler.afterUpdate(trigger.new, trigger.oldMap);
            }
 
            if (trigger.IsDelete) {
                handler.afterDelete(trigger.old);
            }
 
            if (trigger.isUndelete) {
                handler.afterUndelete(trigger.new);
            }
        }

    }
}