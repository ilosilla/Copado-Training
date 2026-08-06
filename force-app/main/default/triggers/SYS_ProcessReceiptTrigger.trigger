trigger SYS_ProcessReceiptTrigger on SYS_ProcessReceipt__c (before insert) {
    zflib_TriggerDomainClass.triggerHandler(SYS_ProcessReceiptsDomain.class);

}