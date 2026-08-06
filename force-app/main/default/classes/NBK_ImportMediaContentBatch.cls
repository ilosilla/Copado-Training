/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-26-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/

/**
    * Type: Apex batch class
    * Name: NBK_ImportMediaContentBatch
    * @author: Adrián Petit
    * Company: Nubika S.L.
    * Date: 04/08/2023
    * @description Batch to import Media Content from URL
    * @version 1.0
*/
global with sharing class NBK_ImportMediaContentBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {

    /**
   * @description empty constructor to start the batch
   */ 
    global NBK_ImportMediaContentBatch() {}

    /**
   * @description gets invoked when the batch job starts
   * @param context contains the job ID
   * @return the record set as a QueryLocator object that will be batched for execution
   */ 
  global Database.QueryLocator start(Database.BatchableContext context) {
       /** return Database.getQueryLocator([SELECT Id, , URL_Photo_1__c, URL_Photo_2__c,URL_Photo_3__c,URL_Photo_4__c,URL_Photo_5__c,URL_Photo_6__c,
                                                ProductClass, Name, ProductCode 
                                        FROM Product2 WHERE URL_Photo_1__c <> NULL 
                                                        OR URL_Photo_2__c <> NULL
                                                        OR URL_Photo_3__c <> NULL
                                                        OR URL_Photo_4__c <> NULL
                                                        OR URL_Photo_5__c <> NULL
                                                        OR URL_Photo_6__c <> NULL]);
        */ 
        return Database.getQueryLocator([SELECT Id, URL_Photo_1__c, ProductClass, Name, ProductCode FROM Product2 WHERE URL_Photo_1__c <> NULL]);
    }

    /**
   * @description gets invoked when the batch job executes and operates on one batch of records. Contains or calls the main execution logic for the batch job.
   * @param context contains the job ID
   * @param scope contains the batch of records to process.
   */ 
    global void execute(Database.BatchableContext context, List<Product2> scope) {
        try{
            String csvBody = System.label.JSON_Header + '\n\n' + System.label.CSV_Headers+ '\n';
            String csvProductLine;

            for(Product2 product : scope){
               /** 
                csvProductLine = product.ProductClass == 'Variation' ? product.Name+','+product.ProductCode+','+product.GB_B2B_Foto_frontal_SKU__c+',Image,PDP Image,'+product.GB_B2B_Foto_frontal_SKU__c+',Image,PLP Image\n' :
                                                                    product.Name+','+product.ProductCode+','+product.GB_B2B_Foto_Frontal__c+',Image,PDP Image,'+product.GB_B2B_Foto_Frontal__c+',Image,PLP Image\n';
                */
                csvProductLine = '"'+product.Name+'",'+product.ProductCode+','+product.URL_Photo_1__c+',Image,'+product.ProductCode+','+product.URL_Photo_1__c+',Image,'+product.ProductCode+'\n';

                csvBody += '\n'+csvProductLine;
            }
            csvBody += System.label.JSON_End;
            System.debug('NBK_ImportMediaContentBatch csvBody:' + csvBody);
            Map<String,Object> mCSVResponseByName = new Map<String,Object>();
            mCSVResponseByName = NBK_B2BApiHelper.contentVersionCallout(csvBody);
            System.debug('NBK_ImportMediaContentBatch mCSVResponseByName:' + mCSVResponseByName);
            NBK_B2BApiHelper.launchJobCallout((String)mCSVResponseByName.get('id'));

        }catch(Exception e){
            //Nbk_ErrorsManager.addError(e, NBK_CaseHandlerTrigger.class.getName(), Nbk_ErrorsManager.Causante.INTEGRACION, true);
            //Nbk_ErrorsManager.flush();
            System.debug('NBK_ImportMediaContentBatch Exception:' + e);
        }
    }

    /**
   * @description gets invoked when the batch job finishes. Place any clean up code in this method.
   * @param context contains the job ID
   */ 
  global void finish(Database.BatchableContext context) {
        Porcelanosa_B2B_Portal__mdt importMediaMDT = Porcelanosa_B2B_Portal__mdt.getInstance('Default');
        NBK_RefreshIndex.refreshIndex(importMediaMDT.WebStoreId__c);
    }

    class ImportMediaContentBatchException extends Exception {}
}