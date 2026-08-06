/**
    * Type: Apex batch class
    * Name: NBK_ImportMediaContentBatch
    * @author: Adrián Petit
    * Company: Nubika S.L.
    * Date: 04/08/2023
    * @description Helper class with API operations
    * @version 1.0
*/
public with sharing class NBK_B2BApiHelper {
    /**
   * @description gets invoked when the batch job executes and operates on one batch of records. Contains or calls the main execution logic for the batch job.
   * @param body contains the job ID
     * @return the response deserialized
   */
    public static Map<String,Object> contentVersionCallout(String body){
        Http http = new Http();
        HttpRequest csvRequest = new HttpRequest();
        csvRequest.setEndpoint('callout:Porcelanosa_B2B'+'/services/data/v54.0/sobjects/ContentVersion');
        csvRequest.setMethod('POST');
        csvRequest.setHeader('Accept', '*/*');
        csvRequest.setHeader('Content-Type', 'multipart/form-data; boundary=boundary_string');
        csvRequest.setBody(body);
        HTTPResponse csvResponse = http.send(csvRequest);
        System.debug('NBK_B2BApiHelper launchJobCallout - getStatusCode :' + csvResponse.getStatusCode());
        if(csvResponse.getStatusCode() > 300){
            throw new B2BAPIException(csvResponse.getStatus()+' '+csvResponse.getStatusCode());
        }
        return (Map<String, Object>) JSON.deserializeUntyped(csvResponse.getBody());
    }

    /**
   * @description gets invoked when the batch job executes and operates on one batch of records. Contains or calls the main execution logic for the batch job.
   * @param jobID contains the job ID
   */
    public static void launchJobCallout(String jobID){
        Http http = new Http();
        Porcelanosa_B2B_Portal__mdt importMediaMDT = Porcelanosa_B2B_Portal__mdt.getInstance('Default');
        HttpRequest jobRequest = new HttpRequest();
        jobRequest.setEndpoint('callout:Porcelanosa_B2B'+'/services/data/v54.0/commerce/management/webstores/'+importMediaMDT.WebStoreId__c+'/product-import');
        jobRequest.setMethod('POST');
        jobRequest.setHeader('Accept', '*/*');
        jobRequest.setHeader('Content-Type', 'application/json');
        jobRequest.setBody(JSON.serialize(new NBK_ProductImportDTO(importMediaMDT, jobID)));
        HTTPResponse jobResponse = http.send(jobRequest);
        Map<String,Object> mJobResponseByName = (Map<String, Object>) JSON.deserializeUntyped(jobResponse.getBody());
        if((String) mJobResponseByName.get('errorMessage') != null){
            System.debug('NBK_B2BApiHelper launchJobCallout - Exception ');
            throw new B2BAPIException((String) mJobResponseByName.get('errorMessage'));
        }
    }

    class B2BAPIException extends Exception {}
}