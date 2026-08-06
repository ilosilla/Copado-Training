/**
 * @author       Ramón Prades
 * @group        System
 * @description  Despacha los SystemEvent__e a su handler concreto.
 *
 *  Resuelve la clase handler por nombre (evt.Handler__c), la instancia con
 *  Type.forName(...).newInstance() y llama a handle(evt). Aísla fallos por evento:
 *  un handler que peta (o desconocido) no impide procesar los demás.
 *
 *  Se invoca desde el trigger fino SystemEventTrigger (after insert), es decir,
 *  ya en el subscriber del Platform Event, en una transacción que hace commit
 *  (por eso la entrega sobrevive al rollback del publicador).
 *
 *  @see SystemEventAbstractHandler
 */
public without sharing class SystemEventDispatcher {

    public class SystemEventException extends Exception {}

    public static void dispatch(List<SystemEvent__e> events) {
        for (SystemEvent__e evt : events) {
            try {
                resolveHandler(evt.Handler__c).handle(evt);
            } catch (Exception ex) {
                // Fail-safe: un fallo de entrega (o un handler desconocido) no debe
                // tumbar el resto de eventos. No se alerta aquí: sería circular, ya
                // que las alertas de sistema viajan por este mismo bus.
                System.debug(LoggingLevel.ERROR, 'SystemEventDispatcher: fallo procesando '
                    + 'evento (Handler=' + evt.Handler__c + '): ' + ex.getMessage());
            }
        }
    }

    private static SystemEventAbstractHandler resolveHandler(String handlerName) {
        Type handlerType = String.isBlank(handlerName) ? null : Type.forName(handlerName);
        if (handlerType == null) {
            throw new SystemEventException('Handler no encontrado: ' + handlerName);
        }
        return (SystemEventAbstractHandler) handlerType.newInstance();
    }
}