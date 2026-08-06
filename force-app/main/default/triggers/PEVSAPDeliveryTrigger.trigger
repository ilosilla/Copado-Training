trigger PEVSAPDeliveryTrigger on SAP_SD_Delivery__e (after insert) {
    PEVSAPDeliveryTriggerHandler.afterInsert(Trigger.New);
}