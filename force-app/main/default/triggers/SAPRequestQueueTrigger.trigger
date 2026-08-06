/**
 * @author: Ramópn Prades
 * @date: July 2024
 */
trigger SAPRequestQueueTrigger on SAPRequestQueue__c (before insert, after insert, before update, after update) {
    zflib_TriggerDomainClass.triggerHandler(SAPRequestQueueDomain.class);
}