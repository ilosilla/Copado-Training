trigger PEVSAPAccountLockTrigger on SAP_Account_Lock__e (after insert) {
    PEVSAPAccountLockTriggerHandler.afterInsert(Trigger.New);
}