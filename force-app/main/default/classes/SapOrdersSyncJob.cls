global class SapOrdersSyncJob implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        Logger.setScenario('SAPSYNCORDERS_BEGIN');
        Logger.info('SAP Orders Sync iniciado');
        Logger.saveLog();
        // collect the batches of records or objects to be passed to execute
        String queryObj = new SAPOrdersSelector().selectSapSyncString();
        return Database.getQueryLocator(queryObj);
    }//end method
    
    global void execute(SchedulableContext sc) {
      	Database.executebatch(new SapOrdersSyncJob());
    }

    global void execute(Database.BatchableContext bc, List<Pedidos_cabeceraSet__x> scope) {
        try{
            ActivityDateService.updateFromSAPOrders(scope);
        }catch(Exception ex){
            System.debug('***ErrorExecute-->'+ex.getMessage());
            System.debug('***ErrorExecuteLine-->'+ex.getLineNumber());
        }
    }//end method

    global void finish(Database.BatchableContext bc){
        Logger.setScenario('SAPSYNCORDERS_END');
        Logger.info('SAP Orders Sync terminado');
        Logger.saveLog();
     }//end method
}