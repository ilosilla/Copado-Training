/**
 * @author         Ramón Prades
 * @date           May 2024
 * @group          SAP
 * @description    Basic abstract implementation of a reposnse handler
 *
 * Test with SAPSalesOrderAPIHandlerTest
*/
@SuppressWarnings('PMD.EmptyStatementBlock')
public abstract class SAPAbstractAPIHandler implements ISAPAPIHandler {

    protected List<Object> serializedObjects;
    protected SAPRequestQueue__c sapRequest;

    public abstract String getServiceName();

    public abstract String processResponse(Id requesterId, Integer httpStatusCode, String response);

    /**
     * Updates the orioginal requester when the request has been skipped
     */
    public virtual void processSkipped(Id requesterId, String reason) {
        // Do nothing by default
    }
    
    /**
     * Returns the type of integration for this request.
     * Default is 'SAP', but can be overridden in subclasses (e.g., for CPI).
     */
    public virtual String getRequestType() {
        return SAPRequestDispatcher.REQUEST_TYPE_SAP;
    }

    public virtual Integer getTimeout() {
        return 0;
    }

    public virtual String getPayload() {
        // Permite override completo en la subclase si lo desea
        SAPAbstractAPISerializer serializer = this.getSerializer();        
        if (serializer != null) {
            Set<Id> ids = new Set<Id> { this.sapRequest.RequesterID__c };
            String json = serializer.serialize(ids);
            this.serializedObjects = serializer.getSerializedObjects();
            return json;
        } else {
            // Si no hay serializer, delega en un método simplificado que puede sobreescribirse
            return this.buildSimplePayload();
        }
    }

    /**
     * Método simplificado que puede sobreescribirse directamente en el Handler
     * si  se necesita un serializer completo.
     */
    public virtual SAPAbstractAPISerializer getSerializer() {
        return null;
    }

    /**
     * Método simplificado que puede sobreescribirse directamente en el Handler
     * si no se necesita un serializer completo.
     */
    public virtual String buildSimplePayload() {
        // Por defecto, lanza una excepción para forzar a implementar uno de los dos métodos
        // El ID del objeto a serializar está en this.sapRequest.RequesterID__c 
        throw new ContextException('Either getSerializer() or buildSimplePayload() must be implemented.');
    }

    @SuppressWarnings('PMD.EmptyStatementBlock, PMD.ExcessiveParameterList')
    public virtual void processError(Id requesterId, Integer httpStatusCode, String message, String details) {
        // do nothing by default
    }

    public virtual void setSAPRequestItem(SAPRequestQueue__c item) {
        this.sapRequest = item;
    }

    public virtual String getHttpMethod(String actionName) {
        String method = '';
        switch on (actionName.toUpperCase()) {
            when 'CREATE' {
                method = 'POST';
            }
            when 'UPDATE' {
                method = 'PUT';
            }
            when 'DELETE' {
                method = 'DELETE';
            }
            when 'READ' {
                method = 'GET';
            }
        }
        return method;
    }

    public virtual String parseErrors(Id requesterId, String response) {
        // Do Nothig so far
        return '';
    }

}