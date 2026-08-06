/****
 * @author   Ramon Prades
 * @date     2025-08-21
 * @group    SAP Integrations
 * @description Exposes an invocable method to trigger SAPRequestDispatcher.processQueue()
 */
public class SAPRequestDispatcherInvoker {
    @InvocableMethod(label='Iniciar procesamiento de la cola SAP' description='Lanza SAPRequestDispatcher.processQueue()')
    public static void invoke(List<String> dummy) {
        SAPRequestDispatcher.processQueue();
    }
}