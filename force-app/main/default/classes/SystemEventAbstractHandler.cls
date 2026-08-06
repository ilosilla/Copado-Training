/**
 * @author       Ramón Prades
 * @group        System
 * @description  Clase base de los handlers del bus de eventos de sistema (SystemEvent__e).
 *
 *  Un handler es cualquier clase que extienda esta abstracta e implemente handle(evt).
 *  El SystemEventDispatcher la instancia dinámicamente por nombre
 *  (Type.forName(evt.Handler__c).newInstance()); por eso hace falta un constructor
 *  público sin parámetros — que se hereda de aquí. Una clase concreta que ya tenga
 *  otros constructores (p. ej. SystemAlert) debe declarar el suyo vacío explícitamente.
 *
 *  @see SystemEventDispatcher
 */
public abstract class SystemEventAbstractHandler {

    public SystemEventAbstractHandler() {}

    /**
     * Entrega concreta del evento: enviar email, insertar registro, mandar a Teams…
     * Normalmente deserializa evt.Payload__c al objeto de dominio correspondiente y actúa.
     * Se ejecuta en el subscriber del Platform Event, en una transacción que hace commit.
     */
    public abstract void handle(SystemEvent__e evt);
}