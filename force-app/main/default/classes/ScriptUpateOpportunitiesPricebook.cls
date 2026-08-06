/**
* @author 		?????
* @date 		October 2022
* @group 		Oportunities
* @description 	Enter a description
*/
global class ScriptUpateOpportunitiesPricebook {
    // implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
        public static String dummy() {
            return 'Hi';
        }

    /*global Database.QueryLocator start(Database.BatchableContext bc) {
        // collect the batches of records or objects to be passed to execute
        String queryObj = 'SELECT Id, OwnerId,Pricebook2Id, AccountId, Owner.Execution_Context__c FROM Opportunity';
        return Database.getQueryLocator(queryObj);
    }//end method
    
    global void execute(SchedulableContext sc) {
      	Database.executebatch(new SAPTariffSyncJob());
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        try{
            for (Opportunity opp : scope) {
                AbstractPricebookAssignator pricebookAssign = PricebookAssignator.getInstance(opp.Owner.Execution_Context__c);
                pricebookAssign.setUser(opp.OwnerId);
                pricebookAssign.setAccount(opp.AccountId);
                Pricebook2 pbAssigned = pricebookAssign.getPricebook();

                if (pbAssigned != null && opp.Pricebook2Id != pbAssigned.Id) {
                    opp.Pricebook2Id = pbAssigned.Id;
                    oppsToUpdate.add(opp);
                }
            }

            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.runAsCurrentUser = true;
            dml.DuplicateRuleHeader.AllowSave = true;
            List<Database.SaveResult> srList = Database.update(oppsToUpdate, false);

            for (Integer x=0; x<oppsToUpdate.size(); x++) {
                if (!srList[x].isSuccess()){
                    String error = '';
                    for(Database.Error err : srList[x].getErrors()) {
                        error += err.getStatusCode() + ': ' + err.getMessage() + '\n';
                    }
                    System.debug('Los siguientes Errores ocurrieron en el batch: ' + error);
                } 
            }//end for
        }catch(Exception ex){
            System.debug('***ErrorExecute-->'+ex.getMessage());
            System.debug('***ErrorExecuteLine-->'+ex.getLineNumber());
        }
    }//end method

    global void finish(Database.BatchableContext bc){

     }//end method
     */
}