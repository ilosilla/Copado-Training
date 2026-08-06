trigger PEVSAPInvoiceTrigger on SAP_SD_Invoices__e (after insert) {
    PEVSAPInvoicesTriggerHandler.afterInsert(Trigger.New);
}