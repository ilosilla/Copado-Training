/*-----------------------------------------------------------------------------------------
     Apex Class:        NB2B_OrderSelector
     Created Date:      27/01/2022
     Author:            Cristobal Acero Lara
     Mail:              cristobal.acero@nubika.com
     Description:       Query collection of object Order
------------------------------------------------------------------------------------------*/

public with sharing class NB2B_OrderSelector {

    public static List<Order> getOrderById(Set<Id> orderIds){
        return [
            SELECT ID, Name, OrderNumber,SAP_Id__c, OpportunityId, AccountId
            FROM Order 
            WHERE Id IN : orderIds
        ];
    }

    public static List<Order> getOrderAndOrderItemById(Id orderId){
        return [
            SELECT Id, ContractId, AccountId, OriginalOrderId, Status, Description, StatusCode, SalesChannelId,DeliveryDate__c,NB2B_NetAmmount__c,
                OrderNumber, TotalAmount, CreatedDate, Amount__c, Company__c, Currency__c, LineNo__c, Ordered__c, Account.SAP_Id__c, NB2B_Delivery_Method__c,
                Product__c, SalesOffice__c, SalesOrg__c, TaxRate__c, Tax__c, Unit__c, Quantity__c, Sap_Id__c, GrandTotalAmount,TotalTaxAmount,NB2B_OrderCode__c,
                Origin__c, NB2b_store_pickup__c, ID_Salesforce__c, Observations__c, Client_Reference__c, OpportunityId, SalesChannel.ExternalChannelNumber,
                BillingStreet,BillingCity, BillingPostalCode,BillingCountry,NB2B_DeliveryCode__c,NBK_Sample__c,NBK_Contact_Point_Address__c,NBK_Contact_Point_Address__r.SAPId__c,
            	NBK_Warehouse_Address__c, NBK_Warehouse_Address__r.NBK_SAPId__c, Distribution_channel__c,
            	Account.Business_Email__c, Autopick__c,
                (select Id, Product2Id, OrderId, OriginalOrderItemId, AvailableQuantity, Quantity, CurrencyIsoCode, Product2.Umv__c,
                UnitPrice, ListPrice, TotalPrice, ServiceDate, Description, TotalLineAmount, RelatedOrderItemId, Product2.StockKeepingUnit,
                Type, TypeCode, CreatedDate, OrderItemNumber, LineNumber, GrossUnitPrice,NB2B_TaxAmount__c, TotalTaxAmount,NB2B_Shade__c   from OrderItems ) 
            FROM Order 
            WHERE Id  = :orderId
        ];
    }


    public static List<Pedidos_posicionesSet__x> getPedidosPosicionesById(List<String> orderReference){
        if(Test.isRunningTest()){
			return null;
        }else{
            return [
                SELECT Id, CurrencyIsoCode, ExternalId, DisplayUrl, Conversor__c, Cost__c, Dcurr__c, Dnet__c, Dtax__c, Dtotal__c, Erdat__c, 
                Erzet__c, Fecha_Entrega__c, Finishing__c, FormatSf__c, Gcurr__c, Gnet__c, Gtax__c, Gtotal__c, Hierarchy__c, Lcurr__c, Lnet__c, 
                Ltax__c, Ltotal__c, Make__c, Mat3__c, Mat5__c, Name__c, OpenF__c, Orderlin__c, Ordernum__c, Quantity__c, Series__c, Sku__c, 
                Sqmetres__c, Szone__c, Tariff__c, Unitcode__c, Zmetres__c, Zunits__c   
                FROM Pedidos_posicionesSet__x  
                WHERE Ordernum__c  IN :orderReference
            ];
        }
    }

    public static List<Order> getOrderAndOrderItemFromSap(List<String> sapIds){
        return [
            SELECT Id, ContractId, AccountId, OriginalOrderId, Status, Description, StatusCode, SalesChannelId,DeliveryDate__c,
                OrderNumber, TotalAmount, CreatedDate, Amount__c, Company__c, Currency__c, LineNo__c, Ordered__c, Account.SAP_Id__c, Autopick__c,
                Product__c, SalesOffice__c, SalesOrg__c, TaxRate__c, Tax__c, Unit__c, Quantity__c, Sap_Id__c, GrandTotalAmount,TotalTaxAmount,
                Origin__c, NB2b_store_pickup__c, ID_Salesforce__c, Observations__c, Client_Reference__c, OpportunityId, SalesChannel.ExternalChannelNumber,
                (select Id, Product2Id, OrderId, OriginalOrderItemId, AvailableQuantity, Quantity, CurrencyIsoCode, Product2.Umv__c,
                UnitPrice, ListPrice, TotalPrice, ServiceDate, Description, TotalLineAmount, RelatedOrderItemId, Product2.StockKeepingUnit,
                Type, TypeCode, CreatedDate, OrderItemNumber, LineNumber, GrossUnitPrice, TotalTaxAmount, Sap_id__c   from OrderItems ) 
            FROM Order 
            WHERE Sap_Id__c  IN :sapIds
        ];
    }

    public static List<Order> getOrderByOrderNum(List<String> orderNums){
        return [
            SELECT Id, Ordernum__c,AccountId, Status
            FROM Order 
            WHERE Ordernum__c IN : orderNums
        ];
    }


}