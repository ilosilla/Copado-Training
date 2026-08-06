/**
* @author Ivan Losilla
* @date July 2025
* @group Scripts
* @description Script que crea los eventos de tipo Weekly report que han de rellenar los comerciales. Se lanza cada jueves, para que el evento sea del viernes
* @test ScriptCreateWeeklyReportEventTest
*/
public class ScriptCreateWeeklyReportEvent implements Schedulable, Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {

    public Iterable<SObject> start(Database.BatchableContext BC) {
        String query = 'select id, name,languagelocaleKey,TimeZoneSidKey, email from user where Default_Sales_Organization__c in (\'502\',\'602\',\'604\',\'603\',\'605\',\'608\',\'650\',\'606\',\'225\',\'615\',\'226\',\'227\',\'228\',\'229\',\'230\',\'231\',\'232\',\'511\',\'514\',\'515\',\'516\',\'517\',\'518\',\'850\') and isactive = true AND Profile.name IN (\'Managers\', \'Standard Trade\')'+(Test.isRunningTest()?' LIMIT 200':'');
        return Database.getQueryLocator(query);
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new ScriptCreateWeeklyReportEvent());
    }

    // Método que se invoca para procesar los registros de manera asincrónica
    public void execute(Database.BatchableContext BC, List<User> scope) {
        // Obtener el usuario que ejecuta el método
        User currentUser = [SELECT Id, TimeZoneSidKey FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        Map<String, Integer> timezoneOffsets = new Map<String, Integer>{
            'Europe/Paris'        => -120,  // UTC+2 (CET + DST)
            'Europe/London'       => -60,   // UTC+1 (BST - British Summer Time)
            'GMT'                 => 0,     // UTC+0
            'America/New_York'    => 240,  // UTC-4 (EDT)
            'America/Los_Angeles' => 420,  // UTC-7 (PDT)
            'America/Chicago'     => 300,  // UTC-5 (CDT)
            'Europe/Lisbon'       => -60,  // UTC+1 (WEST - Western European Summer Time)
            'America/Detroit'     => 240,  // UTC-4 (EDT)
            'America/Montreal'    => 240,  // UTC-4 (EDT)
            'America/Denver'      => 360,  // UTC-6 (MDT)
            'America/Tijuana'     => 420,  // UTC-7 (PDT)
            'Australia/Brisbane'  => -600,   // UTC+10 (AEST, no DST)
            'Australia/Melbourne' => -660,   // UTC+11 (AEDT - con DST)
            'Australia/Sydney'    => -660    // UTC+11 (AEDT - con DST)
        };
        
        List<Event> eventsToInsert = new List<Event>();
        
        Date localDate = Date.today().addDays(1);
        Time localStartTime = Time.newInstance(5, 0, 0, 0);
        Time localEndTime = Time.newInstance(6, 0, 0, 0);
        
        for (User u : scope) {
            Integer offset = timezoneOffsets.get(u.TimeZoneSidKey);
            if (offset == null) {
                System.debug('Sin offset definido para ' + u.TimeZoneSidKey);
                continue;
            }
        
            DateTime localStart = DateTime.newInstance(localDate, localStartTime);
            DateTime localEnd = DateTime.newInstance(localDate, localEndTime);
        
            // Restar 120 por el horario de España de mi usuario
            DateTime utcStart = localStart.addMinutes(-offset-120);
            DateTime utcEnd = localEnd.addMinutes(-offset-120);
        
            String subject = (u.LanguageLocaleKey == 'fr') ? 'Rapport Hebdomadaire' : 'Weekly Report';
        
                Event e = new Event(
                    OwnerId = u.Id,
                    Subject = subject,
                    IsAllDayEvent = true,
                    EventType__c = 'Weekly report',
                    StartDateTime = utcStart,
                    EndDateTime = utcEnd
                );
        
            eventsToInsert.add(e);
            System.debug(e);
        }

        if (!eventsToInsert.isEmpty()) {
            insert eventsToInsert;
        }
    }

    // Método para manejar las actualizaciones post-ejecución (si es necesario)
    public void finish(Database.BatchableContext BC) {
        // Este método se puede usar para hacer seguimiento, enviar notificaciones, etc.
        System.debug('Batch de calculo de Docs de SAP finalizado.');
    }
}