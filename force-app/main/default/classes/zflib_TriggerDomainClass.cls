@SuppressWarnings('PMD.EmptyStatementBlock, PMD.ExcessiveParameterList, PMD.IfStmtsMustUseBraces, PMD.IfElseStmtsMustUseBraces, PMD.UnusedLocalVariable, PMD.EmptyIfStmt') 
/**
* @author 		Ramón Prades
* @date 		June 2022
* @group 		Framework
* @description 	Base class for domain classes (based on the Apex Commons library).
* -------------------------------------------------------------------------------------------------------------
* This is the base class all domain classes must extend. It must contain all business logic for the object and
* includes the trigger logic. If you do not plan to use tyhe domain class as a trigger handler please
* use the more basic "zflib_DomainClass".
*
* 0. Naming Conventions
*
* Domain classes extending this class should be named after the object in plural plus the suffix "Domain". For
* example "LeadsDomain" or "OpportunitiesDomain".
*
* 1. Constructors
* 
* The class has two constructors. One with no arguments to be used for dynamic casting (see zflib_DomainConstructor) 
* and another one with the list of records used by the class. Both have to be implemented because Apex does not inherit constructors:
*
*    public LeadsDomain() {
*        super();
*    }
*    public LeadsDomain(List<Lead> leads) {
*        super(leads);
*    }
* 
* 2. IDomainCastable
*
* All classes extending this must implement a method "cast". It is used to dynamically create instenaces when 
* creating the object from a trigger.
*
* Example (from LeadsDomain.cls):
*
*   public override zflib_TriggerDomainClass cast() { 
*     return (LeadsDomain) this;
*   } 
*
* 3. getSObjectType
*
* Another method that has to be implemented in the child classes to return the object type:
*
*    public override Type getSObjectType() {
*        return LeadsDomain.class;
*    }
* 
* 4. Records, ExistingRecords and Errors
*
* These are class variables that hold the list od records being treated ni the class and, if the event is an update, the
* Map with the old verison of the records. Errors array has the list of erors found during the validation of records.
*
* 5. Default values and Validation
* 
* A common task in domain classes is the assignation of default values to empty fields and the validation of records. Logic can be implemente by overriding
* the following methods (both should operate on this.records collection ):
*
* public void onApplyDefaults()
* public void onValidate()
*
* 6. Trigger handler
* 
* This class can be used as a trigger handler:
*
*   trigger LeadTrigger on Lead (before insert, before update, before delete, after insert, after update, after delete) {
*      zflib_TriggerDomainClass.triggerHandler(LeadsDomain.class);
*   } //trigger
*
* 7. Trigger enabling
*
* Trigger function can be disabled from TriggerFlags. By default the flag name is built by removing "sDomain" from the class
* (see Naming Conventions). If the flag name can't be derived from this rule, th echild class can override the
* method "getTriggerFlagName" to declare the correct flag name:
*
*   protected override String getTriggerFlagName() {
*      return 'Lead';
*   }
*
* 8. Trigger logic
*
* The following methods can be overriden to implement the requried business loginc:	
*
* - onBeforeInsert
* - onBeforeUpdate
* - onBeforeDelete
* - onAfterInsert
* - onAfterUpdate
* - onAfterDelete
* - onAfterUndelete
*
* Please remember that onBeforeInsert and onBeforeUpdate and called only if no errors have ben detedted in onValidate:
*
*    public virtual void handleBeforeInsert() { 
*    	onApplyDefaults(); 
*		onValidate();
*		if (!this.hasErrors()) {
*    		onBeforeInsert();
*		}
*    }
*
*    public virtual void handleBeforeUpdate(Map<Id,SObject> existingRecords) {
*    	onValidate(existingRecords);
*		if (!this.hasErrors()) {
*    		onBeforeUpdate(existingRecords);
*		}
*    }
*
* 9. Trigger Errors
*
* As Apex does not provide a method to access the errors added to records it is important to use the method 
* addRecordError Method instead of directly adding the error. Otherwise the error variables won't be updated and 
* won't be accurate.
* -------------------------------------------------------------------------------------------------------------
*/

public abstract class zflib_TriggerDomainClass extends zflib_DomainClass implements zflib_IDomainCastable {

	public abstract zflib_TriggerDomainClass cast();
	protected Boolean isInsert = false;
	protected Boolean isUpdate = false;
	protected Boolean assignDefaultsOnUpdate = false;

    /*
	 * Class properties
	 */
	public static String triggerFlagName;
	protected Map<Id, SObject> ExistingRecords {				// Old records as used in the trigger section of this class
		get { return Trigger.oldMap; }
		protected set;
	}
    
	/**
	 * Empty constructor
	 */
	public zflib_TriggerDomainClass() {
		super();
	}
	
	/**
     * Constructor
     **/
	public zflib_TriggerDomainClass(List<SObject> records) {
		super(records);
	} // Constructor

	/**
	 * Sets assignDefaultsOnUpdate
	 */
	public void setAssignDefaultsOnUpdate(Boolean value) {
		this.assignDefaultsOnUpdate = value;
	}

	/**
     * Implement this method to inform the base class of the SObject (custom or standard) to be queried
	 * 
	 * For example: return Account.sObjectType;
     **/
    public abstract Type getSObjectType();	

	/**
	 * Override this to perform processing during the before insert phase, this is called by the handleBeforeInsert method
	 **/
    public virtual void onBeforeInsert() { }
    
	/**
	 * Override this to perform processing during the before update phase, this is called by the handleBeforeUpdate method
	 **/
    public virtual void onBeforeUpdate(Map<Id,SObject> existingRecords) { }
    
	/**
	 * Override this to perform processing during the before delete phase, this is called by the handleBeforeDelete method
	 **/
    public virtual void onBeforeDelete() { }
    
	/**
	 * Override this to perform processing during the after insert phase, this is called by the handleAfterInsert method
	 **/
    public virtual void onAfterInsert() { }
    
	/**
	 * Override this to perform processing during the after update phase, this is called by the handleAfterUpdate method
	 **/    
    public virtual void onAfterUpdate(Map<Id,SObject> existingRecords) { }
    
	/**
	 * Override this to perform processing during the after delete phase, this is called by the handleAfterDelete method
	 **/    
    public virtual void onAfterDelete() { }	
	
	/**
	 * Override this to perform processing during the after undelete phase, this is called by the handleAfterDelete method
	 **/    
    public virtual void onAfterUndelete() { }	
	
	/**
	 * Base handler for the Apex Trigger event Before Insert, calls the onApplyDefaults method, followed by onBeforeInsert
	 **/
    public virtual void handleBeforeInsert() { 
		this.isInsert = true;
		this.isUpdate = !this.isInsert;
    	onApplyDefaults(); 
		onValidate();
		if (!this.hasErrors()) {
    		onBeforeInsert();
		}
    }
    
    /**
     * Base handler for the Apex Trigger event Before Update, calls the onBeforeUpdate method
     **/
    public virtual void handleBeforeUpdate(Map<Id,SObject> existingRecords) {
		this.isInsert = false;
		this.isUpdate = !this.isInsert;
		this.ExistingRecords = existingRecords;
		if (this.assignDefaultsOnUpdate) {
			onApplyDefaults(); 
		}
		onValidate();
		if (!this.hasErrors()) {
    		onBeforeUpdate(existingRecords);
		}
    }
    
    /**
     * Base handler for the Apex Trigger event Before Delete, calls the onBeforeDelete method
     **/
    public virtual void handleBeforeDelete() {
    	onBeforeDelete();
    }
    
    /**
     * Base handler for the Apex Trigger event After Insert, checks object security and calls the onValidate and onAfterInsert methods
     **/
    public virtual void handleAfterInsert() {
    	onAfterInsert(); 
    }
    
    /**
     * Base handler for the Apex Trigger event After Update, checks object security and calls the onValidate, onValidate(Map<Id,SObject>) and onAfterUpdate methods
     **/
    public virtual void handleAfterUpdate(Map<Id,SObject> existingRecords) {    
		this.ExistingRecords = existingRecords;	
    	onAfterUpdate(existingRecords); 
    }
    
    /**
     * Base handler for the Apex Trigger event After Delete, checks object security and calls the onAfterDelete method
     **/
    public virtual void handleAfterDelete() {
    	onAfterDelete();
    }	

    /**
     * Base handler for the Apex Trigger event After Undelete, checks object security and calls the onAfterUndelete method
     **/
    public virtual void handleAfterUndelete() {    	   
    	onAfterUndelete();
    }	

	/**
	 * Detects whether any values in context records have changed for given fields as strings
	 * Returns list of SObject records that have changes in the specified fields
	 **/
	/*
	public List<SObject> getChangedRecords(Set<String> fieldNames)	{
		List<SObject> changedRecords = new List<SObject>();
		for (SObject newRecord : Records) {
			Id recordId = (Id) newRecord.get('Id');
			if (this.ExistingRecords == null || !this.ExistingRecords.containsKey(recordId)) {
				continue;
			}

			SObject oldRecord = this.ExistingRecords.get(recordId);
			for (String fieldName : fieldNames) {
				if (oldRecord.get(fieldName) != newRecord.get(fieldName)) {
					changedRecords.add(newRecord);
					break;  // prevents the records from being added multiple times
				}
			}
		}
		return changedRecords;
	}
	*/

	/**
	 * Detects whether any values in context records have changed for given fields as tokens
	 * Returns list of SObject records that have changes in the specified fields
	 **/
	/*
	public List<SObject> getChangedRecords(Set<Schema.SObjectField> fieldTokens) {
		List<SObject> changedRecords = new List<SObject>();
		for (SObject newRecord : Records) {
			Id recordId = (Id) newRecord.get('Id');
			if (this.ExistingRecords == null || !this.ExistingRecords.containsKey(recordId)) {
				continue;
			}
			SObject oldRecord = this.ExistingRecords.get(recordId);
			for (Schema.SObjectField fieldToken : fieldTokens) {
				if (oldRecord.get(fieldToken) != newRecord.get(fieldToken))	{
					changedRecords.add(newRecord);
					break;  // prevents the records from being added multiple times
				}
			}
		}
		return changedRecords;
	}
	*/
   
	/**
	 * Method constructs the given Domain class with the current Trigger context 
	 * before calling the applicable override methods such as beforeInsert, beforeUpdate etc.
	 **/
	public static void triggerHandler(Type domainClass)
	{		
		// Process the runtime Apex Trigger context 
		triggerHandler(domainClass, 
			Trigger.isBefore, 
			Trigger.isAfter, 
			Trigger.isInsert, 
			Trigger.isUpdate, 
			Trigger.isDelete, 
			Trigger.isUnDelete,
			Trigger.new, 
			Trigger.oldMap);
	}
	
	/**
	 * Calls the applicable override methods such as beforeInsert, beforeUpdate etc. based on a Trigger context
	 **/
	private static void triggerHandler(Type domainClass, Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, List<SObject> newRecords, Map<Id, SObject> oldRecordsMap)	{	

		zflib_TriggerDomainClass domainObject = null;

		if (isDelete) {
		}

		if(domainObject == null) {		
			// Construct the domain class constructor class
			String domainClassName = domainClass.getName();
			zflib_TriggerDomainClass obj =  null;			
	        if (isInsert) 
				domainObject = zflib_DomainConstructor.construct(domainclass, newRecords);
	        else if (isUpdate) 
				domainObject = zflib_DomainConstructor.construct(domainclass, newRecords);
	        else if (isDelete) 			
				domainObject = zflib_DomainConstructor.construct(domainclass, oldRecordsMap.values());
	        else if (isUndelete) 
				domainObject = zflib_DomainConstructor.construct(domainclass, newRecords);
		}

		// has this event been disabled?
		if(!domainObject.isTriggerEnabled()) {
			return;
		}

		// Invoke the applicable handler
		if(isBefore) {
	        if(isInsert) domainObject.handleBeforeInsert();
	        else if(isUpdate) domainObject.handleBeforeUpdate(oldRecordsMap);
	        else if(isDelete) domainObject.handleBeforeDelete();
	    } else {
	        if(isInsert) domainObject.handleAfterInsert();
	        else if(isUpdate) domainObject.handleAfterUpdate(oldRecordsMap);
	        else if(isDelete) domainObject.handleAfterDelete();
	        else if(isUndelete) domainObject.handleAfterUndelete();
	    }				
	}

	/**
	 * Checks if the trigger is disabled in TriggerFlags
	 */
	public Boolean isTriggerEnabled() { 
        try {
			String flagName = this.getTriggerFlagName();
            return TriggerFlags.isEnabled(flagName);
        } catch (ObjectNotFoundException ex) {
            return true;    // Defaults to TRUE so all non declared flags are enabled
        }
    } // isTriggerEnabled

	/**
	 * Assumes the name of the class is "ObjectsDomain" so removes the plural and the suffix
	 * and returns the object name in singular.
	 * Domain classes whose name does not follow this rule must override this method
	 */
	@testVisible protected virtual String getTriggerFlagName() {
		String myName = String.valueOf(this.getSObjectType());
		triggerFlagName = myName.replace('sDomain', '');
		return triggerFlagName;
	} // getFlagName


	
} // class