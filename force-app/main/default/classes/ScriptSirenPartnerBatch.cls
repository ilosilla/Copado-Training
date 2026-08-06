/**
* @author Ivan Losilla
* @date January 2025
* @group Scripts
* @description Script to create all Partner Relationship by Siren. Use it always with a batch not greater than 10. If startDate and endDate is given, it filters through DvsAcceptedDate
* @test ScriptSirenPartnerBatchTest
*/
public class ScriptSirenPartnerBatch implements Schedulable, Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    private Set<string> sirenToSet = new Set<String>();
    private Date startDateFilter = null;
    private Date endDateFilter = null;
    private String siren = null;
    private INTEGER limitAccountsPerVat = 20;

    public ScriptSirenPartnerBatch() {}

    public ScriptSirenPartnerBatch(String siren) {
        this.siren = siren;
    }

    public ScriptSirenPartnerBatch(Date startDate, Date endDate) {
        this.startDateFilter = startDate;
        this.endDateFilter = endDate;
    }

    public void setLimit(Integer limitPerVat) {
        this.limitAccountsPerVat = limitPerVat;
    }

    // Método que se invoca para recuperar los registros a procesar
    public Iterable<SObject> start(Database.BatchableContext BC) {
        Logger.setScenario('PARTNERS_BY_VAT_START');
        Logger.info('Creación de Partners por Vats iniciado');
        Logger.saveLog();
        // Consultamos todas las cuentas que tengan un valor en SIREN
        String query = 'select id, VAT_Number__c,F_domain__c, VAT_Number_2__c,Business_Email__c from account where recordtype.name <> \'Private Customer\'';
        if (this.siren != null) {
            query += ' AND VAT_Number_2__c = :siren';
        } else if (this.startDateFilter != null && this.endDateFilter != null) {
            query += ' and lastmodifieddate >= :startDateFilter AND lastmodifieddate <= :endDateFilter';
        } else {
            query += ' and lastmodifieddate = LAST_N_DAYS:1';
        }
        return Database.getQueryLocator(query);
    }

    public void execute(SchedulableContext sc) {
        System.debug('START SYNC PARTNERS');
        Database.executeBatch(new ScriptSirenPartnerBatch(),1);
    }

    // Método que se invoca para procesar los registros de manera asincrónica
    public void execute(Database.BatchableContext BC, List<Account> scope) {
        Logger.setScenario('PARTNERS_BY_VAT_BATCH');
        SavePoint sp = Database.setSavepoint();

        try {
            // Agrupar por vat_number__c y email
            Map<String, Set<String>> vatMap = new Map<String, Set<String>>();
            Map<String, Set<String>> vat2Map = new Map<String, Set<String>>();

            //GET VAT AND VAT2 ACCOUNTS MAP
            for (Account acc : scope) {
                if (acc.vat_number__c != null) {
                    String key = acc.vat_number__c.trim();
                    if (!vatMap.containsKey(key)) {
                        vatMap.put(key, new Set<String>());
                    }
                    vatMap.get(key).add(acc.Id);
                }

                if (acc.vat_number_2__c != null) {
                    String key = acc.vat_number_2__c.trim();
                    if (!vat2Map.containsKey(key)) {
                        vat2Map.put(key, new Set<String>());
                    }
                    vat2Map.get(key).add(acc.Id);
                }
            }

            // SEARCH ACCOUNTS HAVING THE LISTED DOMAINS
            for (Account aux : [SELECT Id, vat_number__c, vat_number_2__c FROM Account WHERE vat_number__c IN : vatMap.keySet() OR vat_number_2__c IN : vat2Map.keySet()]) {
                if (aux.vat_number__c != null) {
                    String key = aux.vat_number__c.trim();
                    vatMap.get(key).add(aux.Id);
                }

                if (aux.vat_number_2__c != null) {
                    String key = aux.vat_number_2__c.trim();
                    vat2Map.get(key).add(aux.Id);
                }
            }

            

            Set<String> accountIds = new Set<String>();
            for (String keyMap : vatMap.keySet()) {
                accountIds.addAll(vatMap.get(keyMap));
            }
            for (String keyMap : vat2Map.keySet()) {
                accountIds.addAll(vat2Map.get(keyMap));
            }

            Set<String> existingRelations = getExistingPartnersByVats(accountIds);
            List<Partner> partnersToInsert = createPartnerRelationShips( vatMap, existingRelations );
            partnersToInsert.addAll(createPartnerRelationShips( vat2Map, existingRelations ));
    
            Logger.info('Vats: ' + vatMap.keySet().toString());
            Logger.info('Vat 2s: ' + vat2Map.keySet().toString());
            Logger.info('Partner relations to create on batch: ' + partnersToInsert.size());
            Logger.saveLog();

            if (!partnersToInsert.isEmpty()) {
                insert partnersToInsert;
                Logger.info('Success');
                Logger.saveLog();
            }
        } catch (Exception e) {
            Database.rollback(sp);
            System.debug('ERROR');
            System.debug(e);
        }
    }

    // Método para manejar las actualizaciones post-ejecución (si es necesario)
    public void finish(Database.BatchableContext BC) {
        // Este método se puede usar para hacer seguimiento, enviar notificaciones, etc.
        System.debug('Batch de creación de Partners finalizado.');
    }

    private static List<Partner> createPartnerRelationShips( Map<String, Set<String>> vatToAccounts, Set<String> existingRelations ){
        List<Partner> newPartners = new List<Partner>();
        
        for (String vat : vatToAccounts.keySet()) {
            Set<String> accountIds = vatToAccounts.get(vat);
        
            if (accountIds.size() < 2) {
                continue; // no se pueden hacer relaciones con un solo account
            }

            List<String> accountIdList = new List<String>(accountIds);

            for (Integer i = 0; i < accountIdList.size(); i++) {
                for (Integer j = i + 1; j < accountIdList.size(); j++) {
                    String fromId = accountIdList[i];
                    String toId = accountIdList[j];
                    String relationKey = fromId + '-' + toId;
                    String relationKeyInverse = toId + '-' + fromId;

                    if (!existingRelations.contains(relationKey) && !existingRelations.contains(relationKeyInverse)) {
                        Partner p = new Partner();
                        p.AccountFromId = fromId;
                        p.AccountToId = toId;
                        p.role = null;
                        newPartners.add(p);
                        existingRelations.add(relationKey);
                    }
                }
            }
        }

        return newPartners;
    }

    private static Set<String> getExistingPartnersByVats(Set<String> accountsSet) {
        // GET EXISTING RELATIONS BY DOMAINS
        List<Partner> existingPartners = [
            SELECT AccountFromId, AccountToId
            FROM Partner
            WHERE AccountFromId IN : accountsSet
        ];

        Set<String> result = new Set<String>();
        // Paso 1: Guardar relaciones ya existentes en formato ordenado
        for (Partner p : existingPartners) {
            if (p.AccountFromId != null && p.AccountToId != null) {
                Id fromId = p.AccountFromId;
                Id toId = p.AccountToId;
                result.add(fromId + '-' + toId);
                result.add(toId + '-' + fromId);
            }
        }

        return result;
    }
}