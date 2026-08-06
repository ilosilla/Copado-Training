/**
* @author Ivan Losilla
* @date February 2025
* @group Scripts
* @description Script para calcular las datos financieros según la API de Pappers. Usar siempre con un scope de 1
* @test ScriptGetPappersDataTest
*/
public class ScriptGetPappersData implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    private Set<string> sirens = new Set<String>();

    //public ScriptSirenPartnerBatch() {}

    public ScriptGetPappersData(String siren) {
        this.sirens = new Set<String>{siren};
    }

    public ScriptGetPappersData(Set<String> sirens) {
        this.sirens = sirens;
    }

    // Método que se invoca para recuperar los registros a procesar
    public Iterable<SObject> start(Database.BatchableContext BC) {
        String query = 'select id, sap_id__c, VAT_Number_2__c from account where VAT_Number_2__c in : sirens';
        return Database.getQueryLocator(query);
    }

    // Método que se invoca para procesar los registros de manera asincrónica
    public void execute(Database.BatchableContext BC, List<Account> scope) {
        Set<String> sirenList = new Set<String>();
        for (Account acc : scope) {
            sirenList.add(acc.VAT_Number_2__c);
            AccountAdditionalDataService.setSAPDocumentsData(acc.Id);
        }

        AccountAdditionalDataService.getPappersData(sirenList);
        AccountAdditionalDataService.setPappersData(sirenList);
    }

    // Método para manejar las actualizaciones post-ejecución (si es necesario)
    public void finish(Database.BatchableContext BC) {
        // Este método se puede usar para hacer seguimiento, enviar notificaciones, etc.
        System.debug('Batch de calculo de Docs de SAP finalizado.');
    }
}