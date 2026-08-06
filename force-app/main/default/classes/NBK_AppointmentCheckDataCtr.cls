public with sharing class NBK_AppointmentCheckDataCtr {
    
    @AuraEnabled
    public static void registerError(String body){
        system.debug('registerError ' + body);

        Logger.error('Appointment out of BS: ' + body);
        Logger.saveLog();
    }
}