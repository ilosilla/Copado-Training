/**
 * @author       Ramón Prades
 * @group        System
 * @description  Subscriber del bus de eventos de sistema. Trigger fino: delega en
 *               SystemEventDispatcher, que resuelve y ejecuta el handler de cada evento.
 *               Corre en su propia transacción (que hace commit), por eso la entrega
 *               sobrevive al rollback del publicador.
 */
trigger SystemEventTrigger on SystemEvent__e (after insert) {
    SystemEventDispatcher.dispatch(Trigger.new);
}