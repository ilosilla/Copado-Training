/**
* @author 			Ramón Prades
* @date 			October-2020
* @group 			ECommerce
* @group-content 	../../ApexDocContent/ecommerce.htm
* @description 	    ECommerce utility methos
*/
public with sharing class ECommerceUtils {

    public static final String readyStatus = 'Being Prepared';
    public static final String deliveryStatus = 'On Delivery';

    public static Id findOpportunity(String sapOrder) {
        Id id = null;
        List<Opportunity> matches = [select Id, SAP_Order__c from Opportunity where SAP_Order__c = :sapOrder];
        if (matches.size() > 0) {
            id = matches[0].Id;
        }
        return id;
    } // findOpportunity
}