/**
* @author Ivan Losilla
* @date February 2025
* @group Scripts
* @description Script para calcular las compras según las facturas de SAP. Siempre pasarlo con un scope de 1
* @test ScriptGetSapPurchasesTest
*/
public class ScriptGetSapPurchases implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    private Set<string> accountIds = new Set<String>();

    //public ScriptSirenPartnerBatch() {}

    public ScriptGetSapPurchases(String accountId) {
        this.accountIds = new Set<String>{accountId};
    }

    public ScriptGetSapPurchases(Set<String> accountIds) {
        this.accountIds = accountIds;
    }

    // Método que se invoca para recuperar los registros a procesar
    public Iterable<SObject> start(Database.BatchableContext BC) {
        String query = 'select id, sap_id__c, VAT_Number_2__c from account where Id in : accountIds';
        return Database.getQueryLocator(query);
    }

    // Método que se invoca para procesar los registros de manera asincrónica
    public void execute(Database.BatchableContext BC, List<Account> scope) {
        if (scope.size() == 1) {
            AccountAdditionalDataService.setSAPDocumentsData(scope[0].Id);
        }
    }

    // Método para manejar las actualizaciones post-ejecución (si es necesario)
    public void finish(Database.BatchableContext BC) {
        // Este método se puede usar para hacer seguimiento, enviar notificaciones, etc.
        System.debug('Batch de calculo de Docs de SAP finalizado.');
    }
}