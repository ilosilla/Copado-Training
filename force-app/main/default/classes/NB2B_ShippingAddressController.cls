/**
 * @description       : 
 * @author            : EHG@nubika.com
 * @group             : 
 * @last modified on  : 02-03-2023
 * @last modified by  : EHG@nubika.com
**/
public without sharing class NB2B_ShippingAddressController {
    
    /**
    * @description devuelve info sobre deliveryGroup que se pasa al componente LWC ShippingAddress
    * @author EHG@nubika.com | 02-03-2023 
    * @param cartGroupId 
    * @return WrappData 
    **/
    @AuraEnabled
    public static WrappData getDataCartGroup(String cartGroupId){
        try {
            System.debug('cartGroupId:'+cartGroupId);
            WrappData wrap = new WrappData();
            List<CartDeliveryGroup> cdgList = [SELECT Id,NB2B_DeliveryDate__c,NB2B_OrderCode__c,ShippingInstructions,NB2B_Store_Pickup__c,NB2B_Porcelanosa_Address__c,NB2B_ContactPointAddress__c FROM CartDeliveryGroup WHERE Id =: cartGroupId LIMIT 1];
            if(cdgList != null && !cdgList.isEmpty()){
                wrap.deliveryDate           = cdgList[0].NB2B_DeliveryDate__c != null ? cdgList[0].NB2B_DeliveryDate__c : null;
                wrap.orderCode              = cdgList[0].NB2B_OrderCode__c != null ? cdgList[0].NB2B_OrderCode__c : null;
                wrap.shippingInstructions   = cdgList[0].ShippingInstructions != null ? cdgList[0].ShippingInstructions : null;
                wrap.pickup                 = cdgList[0].NB2B_Store_Pickup__c != null ? cdgList[0].NB2B_Store_Pickup__c : false;
                wrap.porceaddressId         = cdgList[0].NB2B_Porcelanosa_Address__c != null ? cdgList[0].NB2B_Porcelanosa_Address__c : null;
                wrap.contactpointaddress    = cdgList[0].NB2B_ContactPointAddress__c != null ? cdgList[0].NB2B_ContactPointAddress__c : null; 
            }
            System.debug('wrap devuelto:'+wrap);
            return wrap;
        } catch (Exception e) {throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String getUserCountry(String cartGroupId){
        try {
            return [SELECT CountryCode FROM User WHERE Id =: UserInfo.getUserId()].CountryCode;
        } catch (Exception e) {throw new AuraHandledException(e.getMessage());
        }
    }

    public class wrappData{
        @AuraEnabled
        public Date deliveryDate;
        @AuraEnabled
        public String orderCode;
        @AuraEnabled
        public String shippingInstructions;
        @AuraEnabled
        public Boolean pickup;
        @AuraEnabled
        public String porceaddressId;
        @AuraEnabled
        public String contactpointaddress;
    }
}