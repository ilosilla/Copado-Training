public class OrderTriggerHandler  extends BaseTriggerHandler {
    public override void beforeInsert(List<SObject> newItems) {
        /*for (Account acc : (List<Account>) newItems) {
            changesBefore(acc);
        }*/
        Id orderRTSamples = Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('NBK_rt_samples').getRecordTypeId();
        List<Order> orderList = (List<Order>)newItems;
        List<Order> orderToUpdateList = new List<Order>();
        Set<Id> accountSetId = new Set<Id>();
        Map<Id,Account> accountMap;

        for(Order thisOrder : orderList){
            if(thisOrder.NB2B_Delivery_Method__c != null && (thisOrder.NB2B_Delivery_Method__c == '1' || thisOrder.NB2B_Delivery_Method__c == '2')){
                System.debug('entra');
                thisOrder.NB2b_store_pickup__c = true;
            }
            if(thisOrder.RecordTypeId == orderRTSamples){
                accountSetId.add(thisOrder.AccountId);
                orderToUpdateList.add(thisOrder);
            }
        }

        if(!accountSetId.isEmpty()){
            accountMap = new Map<Id, Account>([SELECT Id, Name, CurrencyIsoCode FROM Account where id=:accountSetId]);
            if(!accountMap.keySet().isEmpty()){
                //VOLCAMOS EL VALOR DE CURRENCY EN EL ORDER
                for(Order thisOrder : orderToUpdateList){
                    if(accountMap.get(thisOrder.AccountId) != null){
                        thisOrder.CurrencyIsoCode = accountMap.get(thisOrder.AccountId).CurrencyIsoCode;
                        thisOrder.Currency__c = accountMap.get(thisOrder.AccountId).CurrencyIsoCode;
                    }
                }
            }
        }
    }
    /*public override void afterUpdate(List<SObject> newItems, Map<Id,SObject> oldItems) {
        /*for (Account acc : (List<Account>) newItems) {
            changesBefore(acc);
        }
        List<Order> orderList = (List<Order>)newItems;
        List<Sales_Relationship__c> salesList = new List<Sales_Relationship__c>();
        User salesRelUser = [SELECT Id, ProfileId, CountryCode, Default_Sales_Organization__c, Distribution_channel_default__c, Sales_Office__c
                            FROM User WHERE Id =: UserInfo.getUserId()];
        
        System.debug('orderList[0] : ' + orderList[0]);
        if(!Test.isRunningTest()){
          	     
	       	salesList = [select id from Sales_Relationship__c where Account_Org__c =:orderList[0].AccountId  and Sales_Office__c = :orderList[0].SalesOffice__c and Sales_Org__c =: orderList[0].SalesOrg__c];
        }
        System.debug('orderList[0] : ' + salesList);
        if(salesList.isEmpty() && orderList[0].SalesOffice__c != null && orderList[0].SalesOrg__c != null){
            Map<String, Schema.SObjectField> salesRelFieldMap = Schema.SObjectType.Sales_Relationship__c.fields.getMap();
            Sales_Relationship__c newSalesRel = new Sales_Relationship__c();                
            newSalesRel = new Sales_Relationship__c();
            
            for(String key: salesRelFieldMap.keySet()){
                Schema.DescribeFieldResult fieldValue = salesRelFieldMap.get(key).getDescribe();
                if(fieldValue.getDefaultValue() != null && fieldValue.isUpdateable() ){
                    newSalesRel.put(key, fieldValue.getDefaultValue() );
                }
            }
            
            newSalesRel.Sales_Org__c = orderList[0].SalesOrg__c;
            newSalesRel.Distribution_Channel__c = salesRelUser.Distribution_channel_default__c;
            newSalesRel.Sales_Office__c = orderList[0].SalesOffice__c;
            newSalesRel.Account_Org__c = orderList[0].AccountId;
            newSalesRel.Commercial__c = salesRelUser.Id;
            newSalesRel.Reason_of_creation__c = 'New Account Team Member';
            
            if(salesRelUser.CountryCode == 'GB'){
                newSalesRel.Currency__c = 'GBP';
            } else if(salesRelUser.CountryCode == 'FR'){
                newSalesRel.Currency__c = 'EUR';
            } else if(salesRelUser.CountryCode == 'US'){
                newSalesRel.Currency__c = 'USD';
            } else if(salesRelUser.CountryCode == 'CA'){
                newSalesRel.Currency__c = 'CAD';
            } else if(salesRelUser.CountryCode == 'CH'){
                newSalesRel.Currency__c = 'CHF';
            }
            if(!Test.isRunningTest()){
                insert newSalesRel;
            }
        }
        //return newSalesRel;
    }*/




    public override void beforeUpdate(List<SObject> newItems, Map<Id, SObject> oldItems) {
        /*for (Account acc : (List<Account>) newItems) {
            changesBefore(acc);
        }*/
        
        List<Order> orderList = (List<Order>)newItems;
        Map<Id, Order> oldMap =  (Map<Id, Order>) oldItems;

        for(Order thisOrder : orderList){
            if(oldMap.get(thisOrder.Id) != null && oldMap.get(thisOrder.Id).NB2B_DeliveryStatus__c == '12' ){
                if(thisOrder.NB2B_Delivery_Method__c != null && (thisOrder.NB2B_Delivery_Method__c == '1' || thisOrder.NB2B_Delivery_Method__c == '2')){
                    thisOrder.NB2b_store_pickup__c = true;
                }else{
                    thisOrder.NB2b_store_pickup__c = false;
                }
            }
        }
        //return newSalesRel;
    }
    
}