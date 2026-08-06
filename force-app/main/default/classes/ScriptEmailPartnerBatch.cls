/**
* @author Ivan Losilla
* @date January 2025
* @group Scripts
* @description Script to create all Partner Relationship by Siren. Use it always with a batch not greater than 10. If startDate and endDate is given, it filters through DvsAcceptedDate
* @test ScriptEmailPartnerBatchTest
*/
public class ScriptEmailPartnerBatch implements Schedulable, Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    private Set<string> sirenToSet = new Set<String>();
    private INTEGER limitAccountsPerDomain = 10;
    private Date startDateFilter = null;
    private Date endDateFilter = null;
    private Set<String> invalidDomains = getGenericDomains();
    private Set<String> domainsChecked = new Set<String>();

    public ScriptEmailPartnerBatch() {}

    public ScriptEmailPartnerBatch(Date startDate, Date endDate) {
        this.startDateFilter = startDate;
        this.endDateFilter = endDate;
    }

    public void setLimit(Integer limitPerDomain) {
        this.limitAccountsPerDomain = limitPerDomain;
    }

    // Método que se invoca para recuperar los registros a procesar
    public Iterable<SObject> start(Database.BatchableContext BC) {
        Logger.setScenario('PARTNERS_BY_EMAIL_START');
        Logger.info('Creación de Partners por Email iniciado');
        Logger.saveLog();
        // Consultamos todas las cuentas que tengan un valor en SIREN
        String query = 'select id, VAT_Number__c,F_domain__c, VAT_Number_2__c,Business_Email__c from account where recordtype.name <> \'Private Customer\'';
        if (this.startDateFilter != null && this.endDateFilter != null) {
            query += ' and lastmodifieddate >= :startDateFilter AND lastmodifieddate <= :endDateFilter';
        } else {
            query += ' and lastmodifieddate = LAST_N_DAYS:1';
        }
        return Database.getQueryLocator(query);
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new ScriptEmailPartnerBatch(),1);
    }

    // Método que se invoca para procesar los registros de manera asincrónica
    public void execute(Database.BatchableContext BC, List<Account> scope) {
        Logger.setScenario('PARTNERS_BY_EMAIL_BATCH');
        SavePoint sp = Database.setSavepoint();

        try {
            Map<String, Set<String>> domainAccountsMap = new Map<String, Set<String>>();
            Set<String> baseAccountIds = new Set<String>();

            for (Account acc : scope) {
                if (acc.F_domain__c != null) {
                    String domain = acc.f_domain__c.trim().toLowerCase();
                    if (isValidDomain(domain, this.invalidDomains) == true && !this.domainsChecked.contains(domain)) {
                        domainAccountsMap.put(domain, new Set<String>{ acc.Id });
                        baseAccountIds.add(acc.Id);
                    }
                }
            }

            for (Contact c : [SELECT AccountId, Email, f_domain__c FROM Contact WHERE AccountId IN :baseAccountIds AND f_domain__c != null]) {
                if (isValidDomain(c.f_domain__c, this.invalidDomains) == true) {
                    String domain = c.f_domain__c.trim().toLowerCase();
                    if (isValidDomain(domain, this.invalidDomains) == true && !this.domainsChecked.contains(domain)) {
                        if (!domainAccountsMap.containsKey(domain)) {
                            domainAccountsMap.put(domain, new Set<String>{ c.AccountId });
                        }
                        domainAccountsMap.get(domain).add(c.AccountId);
                    }
                }
            }

            // SEARCH CONTACTS HAVING THE LISTED DOMAINS
            for (Contact c : [SELECT Id,AccountId, Email, f_domain__c FROM Contact WHERE f_domain__c IN : domainAccountsMap.keySet() AND f_domain__c != NULL]) {
                if (c.AccountId != null) {
                    String domain = c.f_domain__c.trim().toLowerCase();
                    if (isValidDomain(domain, this.invalidDomains) == true && !this.domainsChecked.contains(domain)) {
                        if (!domainAccountsMap.containsKey(domain)) {
                            domainAccountsMap.put(domain, new Set<String>{ c.AccountId });
                        }
                        domainAccountsMap.get(domain).add(c.AccountId);
                    }
                }
            }

            // SEARCH ACCOUNTS HAVING THE LISTED DOMAINS
            for (Account aux : [SELECT Id, f_domain__c FROM Account WHERE f_domain__c IN : domainAccountsMap.keySet() AND F_domain__c != NULL]) {
                String domain = aux.f_domain__c.trim().toLowerCase();
                if (isValidDomain(domain, this.invalidDomains) == true && !this.domainsChecked.contains(domain)) {
                    if (!domainAccountsMap.containsKey(domain)) {
                        domainAccountsMap.put(domain, new Set<String>{ aux.Id });
                    }
                    domainAccountsMap.get(domain).add(aux.Id);
                }
            }

            Map<String, Set<String>> filteredDomainAccountsMap = new Map<String, Set<String>>();
            Set<String> accountIds = new Set<String>();
            filteredDomainAccountsMap = filterDomains(domainAccountsMap);

            for (String domain : filteredDomainAccountsMap.keySet()) {
                accountIds.addAll(filteredDomainAccountsMap.get(domain));
            }

            if (domainAccountsMap.size() > 0) {
                Set<String> existingRelations = getExistingPartnersByDomains(accountIds);
                List<Partner> partnersToInsert = createPartnerRelationShips( filteredDomainAccountsMap, existingRelations);
    
                Logger.info('Domains: ' + domainAccountsMap.keySet().toString());
                Logger.info('Partner relations to create on batch: ' + partnersToInsert.size());
                Logger.saveLog();
    
                if (!partnersToInsert.isEmpty()) {
                    insert partnersToInsert;
                    this.domainsChecked.addAll(domainAccountsMap.keySet());
                    Logger.info('Success');
                    Logger.saveLog();
                }
            }
        } catch (Exception e) {
            Database.rollback(sp);
            Logger.error('Error returned: ' + e.getMessage());
            Logger.saveLog();
        }
    }

    // Método para manejar las actualizaciones post-ejecución (si es necesario)
    public void finish(Database.BatchableContext BC) {
        Logger.setScenario('PARTNERS_BY_EMAIL_END');
        Logger.info('Creación de Partners por Email terminado');
        Logger.saveLog();
    }

    private Map<String, Set<String>> filterDomains( Map<String, Set<String>> domainsMap) {
        Map<String, Set<String>> result = new Map<String, Set<String>>();

        for (String domain : domainsMap.keySet()) {
            if (isValidDomain(domain, this.invalidDomains) == true && domainsMap.get(domain).size() <= this.limitAccountsPerDomain) {
                result.put(domain, domainsMap.get(domain));
            } else {
                Logger.setScenario('PARTNERS_BY_EMAIL_BATCH');
                Logger.info('Dominio superior al límite de Accounts o dominio no válido. LIMITE: ' + this.limitAccountsPerDomain + ' DOMAIN: ' + domain);
            }
        }

        return result;

    }

    private Set<String> getGenericDomains() {
        Set<String> invalidDomains = new Set<String>();

        for (PorcelanosaSetting__c setting : [
            SELECT value1__c
            FROM PorcelanosaSetting__c
            WHERE key__c = 'EMAIL' AND subkey__c = 'GENERICDOMAINS'
        ]) {
            if (setting.value1__c != null) {
                List<String> parts = setting.value1__c.split(';');
                for (String d : parts) {
                    invalidDomains.add(d.trim().toLowerCase());
                }
            }
        }
        return invalidDomains;
    }

    private static Set<String> getExistingPartnersByDomains(Set<String> accountIds) {
        // GET EXISTING RELATIONS BY DOMAINS
        List<Partner> existingPartners = [
            SELECT AccountFromId, AccountToId
            FROM Partner
            WHERE AccountFromId IN : accountIds
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

    private static List<Partner> createPartnerRelationShips( Map<String, Set<String>> domainToAccountIds, Set<String> existingRelations){
        List<Partner> newPartners = new List<Partner>();
        
        for (String domain : domainToAccountIds.keySet()) {
            Set<String> accountIds = domainToAccountIds.get(domain);
        
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

    private static Boolean isValidDomain(String domainParam, Set<String> blacklist) {
        Boolean result = true;
        String domain = domainParam.toLowerCase().trim();
        for (String invalid : blacklist) {
            if (domain.contains(invalid.toLowerCase().trim())) {
                result = false;
            }
        }

        return result;
    }
}