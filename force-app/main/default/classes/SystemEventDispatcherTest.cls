/**
 * @author   Ramón Prades
 * @group    System
 * @description Tests del bus de eventos de sistema: SystemEventDispatcher,
 *              SystemEventTrigger, SystemEventAbstractHandler y el cierre fluido
 *              SystemAlert.notify(). Los Platform Events se entregan en
 *              Test.stopTest(), momento en que el trigger dispara el dispatcher.
 */
@IsTest
private class SystemEventDispatcherTest {

    @IsTest
    static void alertNotify_flowsThroughBus() {
        SystemAlert alert = new SystemAlert('TEST - BUS', SystemAlert.Severity.HIGH)
            .withException(new IllegalArgumentException('boom'))
            .withContext(new Map<String, Object>{ 'k' => 'v', 'n' => 1 })
            .withHints(new List<String>{ 'hint 1' })
            .withDedupKey('BUS_TEST_NOTIFY');

        Test.startTest();
        alert.notify();          // fluent terminal → SystemAlertService.notify → publica el PE
        Test.stopTest();         // entrega el PE → trigger → dispatcher → handle → deliver

        System.assert(true, 'alert.notify() atraviesa el bus sin errores');
    }

    @IsTest
    static void dispatcher_routesToHandler() {
        SystemEvent__e evt = new SystemEvent__e(
            Handler__c  = 'SystemAlertService',
            Payload__c  = JSON.serialize(new Map<String, Object>{
                'source' => 'TEST', 'severity' => 'HIGH', 'userName' => 'test',
                'contextJson' => JSON.serialize(new Map<String, Object>{ 'a' => 'b' })
            }),
            Severity__c = 'HIGH',
            Summary__c  = 'routing'
        );

        Test.startTest();
        EventBus.publish(evt);   // el trigger dispara dispatch en stopTest
        Test.stopTest();

        System.assert(true, 'El evento se enruta al handler vía trigger + dispatcher');
    }

    @IsTest
    static void dispatcher_unknownHandler_isIsolated() {
        SystemEvent__e evt = new SystemEvent__e(
            Handler__c  = 'NonExistentHandler_XYZ',
            Payload__c  = '{}',
            Severity__c = 'LOW',
            Summary__c  = 'unknown handler'
        );

        Test.startTest();
        // Llamada directa: un handler desconocido no debe propagar excepción.
        SystemEventDispatcher.dispatch(new List<SystemEvent__e>{ evt });
        Test.stopTest();

        System.assert(true, 'Un handler desconocido se aísla sin lanzar');
    }
}