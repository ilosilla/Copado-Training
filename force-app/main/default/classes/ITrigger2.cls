/*
 * For each of the Trigger events the interface 
 * implements a method. 
 * Also implements 2 additional methods for cache of
 * records, and a method of completion, where by 
 * e.g. concentrate DML operations, and thus avoid 
 * inefficiencies and exceeding limits in the Execution Context 
 *
 */
 
public interface ITrigger2
{
  
    // The characteristic of all these methods is that they are 
    // invoked for each record involved
 
    void beforeInsert(SObject so);  
    void beforeUpdate(SObject oldSo, SObject so);
    void beforeDelete(SObject so);
    void afterInsert(SObject so);
    void afterUpdate(SObject oldSo, SObject so);
    void afterDelete(SObject so);
    
   
    // The 2 Bulk methods are invoked to cache the 
    // registers in Map type variables, and thus to make efficient
    // your enquiry
 
    void bulkBefore();
    void bulkAfter();
    
    // This method will be invoked at the end of all the logic of the 
    // trigger. It can be used to perform DML operations, 
    // cleaning, audit/log, etc.
 
    void andFinally();
}