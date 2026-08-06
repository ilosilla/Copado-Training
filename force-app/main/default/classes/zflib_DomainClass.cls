/**
* @author 		Ramón Prades
* @date 		June 2022
* @group 		Framwork
* @description 	Base class for domain classes (based on the Apex Commons library).
* -------------------------------------------------------------------------------------------------------------
* This is the base class all domain classes must extend. It must contain all business logic for the object but
* does not include the trigger logic. If you do want to use the domain class as a trigger handler please
* use "zflib_TriggerDomainClass".
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
* 2. Records and Errors
*
* Records is the class variables that hold the list od records being treated in the class.
* Errors array has the list of erors found during the validation.
*
* 5. Default values and Validation
* 
* A common task in domain classes is the assignation of default values to empty fields and the validation of records. Logic can be implemente by overriding
* the following methods (both should operate on this.records collection ):
*
* public void onApplyDefaults()
* public void onValidate()
*/

public abstract class zflib_DomainClass {

    public List<SObject> Records {get; set;}					// List of records managed in tis domain class
	public List<zflib_Error> Errors = new List<zflib_Error>();	// List of errors
	protected Map<Id, SObject> ExistingRecords;					// Map of existing records managed in tis domain class


    /**
     * Constructor
     **/
	public zflib_DomainClass() {
	} // Constructor

	/**
     * Constructor
     **/
	public zflib_DomainClass(List<SObject> records) {
		this.Records = records;
	} // Constructor

    /**
	 * Override this to apply defaults to the records, this is called by the handleBeforeInsert method
	 **/
	public virtual void onApplyDefaults() { }
	
	/**
	 * Override this to apply general validation to be performed during insert or update, called by the handleAfterInsert and handleAfterUpdate methods
	 **/
	public virtual void onValidate() {	}
		
	public Boolean hasErrors() {
		return (this.Errors.size() > 0);
	}

	public void addRecordError(SObject record, String message) {
		this.addRecordError(record, message, '');
	}

	public void addRecordError(SObject record, String message, String fieldName) {
		zflib_Error errorObject = new zflib_Error(record, message, fieldName);
		this.addRecordError(record, errorObject);
	}

	public void addRecordError(SObject record, Exception ex) {
		this.addRecordError(record, ex, '');
	}

	public void addRecordError(SObject record, Exception ex, String fieldName) {
		zflib_Error errorObject = new zflib_Error(record, ex, fieldName);
		this.addRecordError(record, errorObject);
	}

	protected void addRecordError(SObject record, zflib_Error errorObject) {
		this.errors.add(errorObject);
		if (String.isNotBlank(errorObject.fieldName)) {
			record.addError(errorObject.fieldName, errorObject.message);
		} else {
			record.addError(errorObject.message);	
		}
	} // addRecordError
}