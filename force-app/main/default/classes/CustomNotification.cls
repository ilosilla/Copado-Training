/*-----------------------------------------------------------------------------------------
Author:         Juan Manuel Martinez
Company:        Neoris
Date:			16-09-2019
Description:    Clase que simplifica el manejo del envio de custom notifications.
History
<Date>            <Author>              <Change Description>
-----------------------------------------------------------------------------------------*/

/**
 * Fun basic example of what an Apex Custom Notification API might look like! 
 *
    new CustomNotification()
        .type('BatchApexError')
        .title('Batch Error')
        .body('Some useful information')
        .sendToCurrentUser();
 */
public inherited sharing class CustomNotification {  

    private String notificationTypeId;
    private String notificationBody;
    private String notificationTitle;
    private List<Id> recipientIds;
    private Id targetId;
    private Id senderId; 

    public CustomNotification(String targetId) {
        // Destinatario, si es un test tiene que estar dirigido al usuario actual.
        this.targetId = Test.isRunningTest() ? UserInfo.getUserId() : targetId;
        
    }    
	
	// Obtiene el id de la custom notification type que se utiliza para la notificacion de campana.
	// Este id esta almacenado en un registro de custom metadata para hacerlo mas accesible sin teners que hardcodearlo.
	// El nombre es "SAP_Automations_Custom_Notification"
    public CustomNotification type(String notifName) {
        try{
            this.notificationTypeId = [SELECT Notification_Id__c FROM Custom_Notification_Id__mdt WHERE DeveloperName =: notifName].Notification_Id__c;
        } catch(Exception ex){
            System.debug('Error retrieving the notification type Id: ' + ex.getMessage());
        }
        return this;
    }
	
    public CustomNotification recipients(List<Id> recipientsIds){
        this.recipientIds = recipientsIds;
        return this;
    }
    
    public CustomNotification title(String title) {
        this.notificationTitle = title;
        return this;
    }

    public CustomNotification body(String body) {
        this.notificationBody = body;
        return this;
    }

    /*public CustomNotification sendToCurrentUser() {
        this.recipientIds = new List<ID> { UserInfo.getUserId() };
        return send();
    }*/

    // TODO: Add more methods to add multiple recipients for example
    // ...

    public Map<String, Object> send() {
        // Until there is an Apex API for Custom Notification 
        //   delegage to an Autolaunch Flow wrapper
        Map<String, Object> responseObject = new Map<String, Object>();
        
        if(notificationTypeId != null){
            responseObject = new FlowProcess()
                .named('Send_Custom_Notification_Flow')
                .with('customNotifTypeId', this.notificationTypeId)
                .with('body', this.notificationBody)
                .with('title', this.notificationTitle)
                .with('recipientIds', this.recipientIds)
                .with('targetId', this.targetId)
                .run();
        }
        
        return responseObject;       
    }
    
    
    public static void getNotificationId(String notifName){
        // Como el flow que se utiliza para disparar las notificaciones de campana requiere un custom notification id que no se puede obtener por query
        // Se debe almacenar el custom notification id en un registro de custom metadata.
        
        String endPoint = '/services/data/v46.0/tooling/query?q=Select+Id,CustomNotifTypeName+from+CustomNotificationType+Where+DeveloperName=\'' + notifName + '\'';
        
        Http h = new Http();
        HttpRequest hr = new HttpRequest();
        hr.setTimeout(60000);
        hr.setEndpoint('callout:SFToken' + endPoint);
        hr.setMethod('GET');
        HttpResponse r = h.send(hr);
        
        System.debug('response: ' + r.getBody());
        if(r.getStatusCode() == 200){
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(r.getBody());
            
            if((Integer) responseMap.get('size') == 1){
                // Si todo salio bien guardar el custom notification id
                String notifId = r.getBody().substringBetween('"Id":"', '"');
                
                Metadata.CustomMetadata newRecord =  new Metadata.CustomMetadata();
                newRecord.FullName = 'Custom_Notification_Id.' + notifName;
                newRecord.Label = notifName;
                
                Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
                customField.field = 'Notification_Id__c';
                customField.value = notifId;
                
                newRecord.values.add(customField);
                
                Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
                mdContainer.addMetadata(newRecord);
                
                // Setup deploy callback, MyDeployCallback implements
                // the Metadata.DeployCallback interface (code for
                // this class not shown in this example)
                CustomMetadataCallback callback = new CustomMetadataCallback();
                
                // Enqueue custom metadata deployment
                // jobId is the deployment ID
                String jobId = Test.isRunningTest() ? 'Fake job id' : Metadata.Operations.enqueueDeployment(mdContainer, callback);
                System.debug('jobId: ' + jobId);
            }
        }
        
        
    }
    // Funcion de callback para la operacion de deployment de custom metadata.
    private class CustomMetadataCallback implements Metadata.DeployCallback {
        public void handleResult(Metadata.DeployResult result,
                                 Metadata.DeployCallbackContext context) {
                                     if (result.status == Metadata.DeployStatus.Succeeded) {
                                         System.debug('success: '+ result);
                                     } else {
                                         // Deployment was not successful
                                         System.debug('fail: '+ result);
                                     }
                                 }
    }
    
}