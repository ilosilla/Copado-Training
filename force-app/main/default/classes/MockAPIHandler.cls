/**
 * @author         Ramón Prades
 * @date           July 2025
 * @group          SAP
 * @description    
 * 
 * MockAPIHandler
 * ==============
 * 
 * Clase de utilidad utilizada exclusivamente en contextos de prueba (`@isTest`) para simular un `SAPAbstractAPIHandler`
 * sin realizar llamadas reales ni depender de datos reales.
 * 
 * ✅ Uso previsto únicamente en clases de test.
 * ❌ No debe usarse en ejecución real.
 * 
 * ----------------------------------------------------------------------------------------------------------------------
 * * El test para conseguir la cobertura mínima es SAPRequestDispatcherTest
 * ----------------------------------------------------------------------------------------------------------------------
 */
public with sharing class MockAPIHandler extends SAPAbstractAPIHandler {
    
    public override String getServiceName() {
        return SAPProxy.HELLO_SERVICE;
    }

    public override String getRequestType() {
        return SAPRequestDispatcher.REQUEST_TYPE_SAP;
    }

    public override String buildSimplePayload() {
        return '{"mock": true}';
    }

    public override String processResponse(Id requesterId, Integer httpStatusCode, String response) {
        return response;
    }
    
    public override String parseErrors(Id requestedId, String response) {
        return response;
    }

}