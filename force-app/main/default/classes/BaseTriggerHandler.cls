/**
* @author Ramón Prades
* @date May 2020
*
* @group Triggers
*
* @description Base class with default implementation of the methods required by the framework. More information on
* http://chrisaldridge.com/triggers/lightweight-apex-trigger-framework/.
*/ 
public abstract class BaseTriggerHandler implements ITriggerHandler {
    	
    public virtual void beforeInsert(List<SObject> newItems) {} 
    public virtual void beforeUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {} 
    public virtual void beforeDelete(List<SObject> oldItems) {} 
    public virtual void afterInsert(List<SObject> newItems) {} 
    public virtual void afterUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {} 
    public virtual void afterDelete(List<SObject> oldItems) {} 
    public virtual void afterUndelete(List<SObject> newItems) {}      

    protected virtual String getFlagName() {
		String myName = String.valueOf(this).substring(0,String.valueOf(this).indexOf(':'));
        return myName.replace('TriggerHandler', '');
	} // getFlagName

    public Boolean isEnabled() { 
        try {
            return TriggerFlags.isEnabled(this.getFlagName());
        } catch (ObjectNotFoundException ex) {
            return true;    // Defaults to TRUE so all non declared flags are enabled
        }
    }
} // class