/**
* @author 		Ivan Losilla
* @date 		November 2025
* @group 		Scripts
* @description 	Crea los registros de Key Account y Opp Comments para que se rellenen en el weekly report, la última semana del mes
*/
global with sharing class ScriptCreateWeeklyComments implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        runJob();
    }
    
    @future
    public static void runJob() {
        Date hoy = Date.today();
        Date proximoJueves = hoy.addDays(7);

        // Si sumar 7 días pasa al siguiente mes, significa que este jueves es el último del mes
        if (proximoJueves.month() != hoy.month() || Test.isRunningTest()) {
            List<Account> keyAccounts = WeeklyManagementController.getKeyAccounts();
            List<Opportunity> keyOpps = WeeklyManagementController.getKeyOpportunities();
            List<AccountAdditionalInfo__c> accAdditionals = new List<AccountAdditionalInfo__c>();
            List<OpportunityAdditionalInfo__c> oppAdditionals = new List<OpportunityAdditionalInfo__c>();

            List<String> userIds = new List<String>();
            for (Account acc : keyAccounts) {
                userIds.add(acc.OwnerId);
            }

            for (Opportunity opp : keyOpps) {
                userIds.add(opp.OwnerId);
            }

            Map<String, List<String>> ccEmails = WeeklyManagementController.getEmailCCByUser(userIds);


            for (Account acc : keyAccounts) {
                AccountAdditionalInfo__c accAdditional = new AccountAdditionalInfo__c();
                accAdditional.Account__c = acc.Id;
                accAdditional.InfoType__c = 'WEEKLYCOMMENT';
                accAdditional.StartDateTime__c = System.today();
                accAdditional.Value4__c = acc.Owner.Email;
                accAdditional.Value3__c = String.join(ccEmails.get(acc.OwnerId), ';');
                accAdditionals.add(accAdditional);
            }

            for (Opportunity opp : keyOpps) {
                OpportunityAdditionalInfo__c oppAdditional = new OpportunityAdditionalInfo__c();
                oppAdditional.Opportunity__c = opp.Id;
                oppAdditional.InfoType__c = 'WEEKLYCOMMENT';
                oppAdditional.StartDateTime__c = System.today();
                oppAdditional.Value4__c = opp.Owner.Email;
                oppAdditional.Value3__c = String.join(ccEmails.get(opp.OwnerId), ';');
                oppAdditionals.add(oppAdditional);
            }

            insert accAdditionals;
            insert oppAdditionals;
        } else {
            System.debug('No es el último jueves del mes. No se ejecuta la lógica.');
        }
    }
}