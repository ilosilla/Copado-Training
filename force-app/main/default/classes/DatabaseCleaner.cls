@SuppressWarnings('PMD.AvoidDebugStatements')
/**
 * @author         Ramón Prades
 * @date           July 2025
 * @group          Tools / Maintenance
 * @description    
 * This class performs scheduled and sequential cleanup of custom objects
 * defined in the Custom Setting `PORSADatabaseCleanable__c`.
 * 
 * For each configured object:
 * - It deletes records whose CreatedDate is older than the configured number of days.
 * - Objects are processed one at a time in sequence using a single batch chain.
 * - Uses Database.Stateful to track progress across batches.
 * 
 * How it works:
 * - The constructor loads all valid cleanup configurations.
 * - The `start()` method builds a dynamic SOQL query for the current object.
 * - The `execute()` method deletes the matched records.
 * - The `finish()` method automatically triggers the next batch if more objects remain.
 * 
 * Usage:
 * - Can be scheduled periodically via System.schedule() or via Setup > Apex Classes > Schedule Apex.
 * - Also supports manual execution via anonymous Apex:
 * 
 *     // Run manually from Developer Console or Anonymous Apex:
 *     DatabaseCleaner cleaner = new DatabaseCleaner();
 *     Database.executeBatch(cleaner, 200);
 * 
 * Benefits:
 * - Centralized, stateful, and fault-tolerant cleanup across multiple SObjects.
 * - No need to manage multiple parallel batches.
 * - Resilient to invalid object names or missing configuration.
 * 
 * Requires:
 * - A List Custom Setting called `PORSADatabaseCleanable__c` with:
 *     - ObjectName__c (Text): API name of the custom object (e.g. 'SystemLog__c')
 *     - RetentionDays__c (Number): Number of days to retain records
 */
global class DatabaseCleaner implements Database.Batchable<SObject>, Database.Stateful, Schedulable {

    // Lista de configuración cargada al inicio
    private List<PORSADatabaseCleanable__c> configList = new List<PORSADatabaseCleanable__c>();
    private Integer currentIndex = 0;

    // Constructor por defecto: carga la configuración
    global DatabaseCleaner() {
        this.configList = [
            SELECT ObjectName__c, RetentionDays__c
            FROM PORSADatabaseCleanable__c
            WHERE ObjectName__c != null AND RetentionDays__c != null AND RetentionDays__c != 0
            ORDER BY ObjectName__c
        ];
    }

    // Schedulable: punto de entrada
    global void execute(SchedulableContext sc) {
        if (!configList.isEmpty()) {
            Database.executeBatch(this, 200);
        }
    }

    // Genera el QueryLocator para el objeto actual
    global Database.QueryLocator start(Database.BatchableContext bc) {
        if (currentIndex >= configList.size()) {
            return Database.getQueryLocator('SELECT Id FROM User WHERE Id = null'); // dummy
        }
        PORSADatabaseCleanable__c cfg = configList[currentIndex];
        String objName = cfg.ObjectName__c.trim();
        Integer days = Integer.valueOf(cfg.RetentionDays__c);
        Map<String, Schema.SObjectType> globalMap = Schema.getGlobalDescribe();
        Date cutoff = Date.today().addDays(-days);
        String query = 'SELECT Id FROM ' + objName + ' WHERE CreatedDate < :cutoff';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            delete scope;
        } catch (Exception e) {
            System.debug('❌ Error en delete: ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {
        currentIndex++;
        if (currentIndex < configList.size()) {
            System.debug('➡️ Siguiente objeto: ' + configList[currentIndex].ObjectName__c);
            Database.executeBatch(this, 200);
        } else {
            System.debug('✅ Limpieza completada para todos los objetos');
        }
    }
}