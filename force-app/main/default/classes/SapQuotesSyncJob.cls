global class SapQuotesSyncJob implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        Logger.setScenario('SAPSYNCQUOTES_BEGIN');
        Logger.info('SAP Quotes Sync iniciado');
        Logger.saveLog();
        // collect the batches of records or objects to be passed to execute
        String queryObj = new SAPQuotesSelector().selectSapSyncString();
        return Database.getQueryLocator(queryObj);
    }//end method
    
    global void execute(SchedulableContext sc) {
      	Database.executebatch(new SapQuotesSyncJob());
    }

    global void execute(Database.BatchableContext bc, List<Ofertas_cabeceraSet__x> scope) {
        try{
            ActivityDateService.updateFromSAPQuotes(scope);
        }catch(Exception ex){
            System.debug('***ErrorExecute-->'+ex.getMessage());
            System.debug('***ErrorExecuteLine-->'+ex.getLineNumber());
        }
    }//end method

    global void finish(Database.BatchableContext bc){
        Logger.setScenario('SAPSYNCQUOTES_END');
        Logger.info('SAP Quotes Sync terminado');
        Logger.saveLog();
     }//end method
}