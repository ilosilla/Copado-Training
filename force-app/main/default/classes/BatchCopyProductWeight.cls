/**
* @author       Codex
* @date         March 2026
* @group        Products
* @description  Compatibility wrapper for the weight-copy operation in BatchProductServiceTools.
*
* @execution    Database.executeBatch(new BatchCopyProductWeight(), 200);
*/
global class BatchCopyProductWeight implements Database.Batchable<SObject>, Database.Stateful {
    private BatchProductServiceTools delegate = BatchProductServiceTools.forWeightCopy();

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return this.delegate.start(bc);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        this.delegate.execute(bc, scope);
    }

    global void finish(Database.BatchableContext bc) {
        this.delegate.finish(bc);
    }
}