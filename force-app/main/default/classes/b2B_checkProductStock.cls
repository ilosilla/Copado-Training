/**
 * @description       :
 * @author            : Nubika
 * @group             :
 * @last modified on  : 09-14-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class b2B_checkProductStock {

    @AuraEnabled
    public static Boolean checkOrder(Id orderId){
        system.debug('ORDERID ' + orderId);
        Boolean isDraft = false;
        try{
            if(orderId != null){
                Order order = [Select id,Status from Order where id=:orderId limit 1];
                if(order.status == 'Draft'){
                    isDraft = true;
                }

            }
        }catch(Exception e){
            System.debug('checkOrder Exception e: ' + e);
            return isDraft;

        }
        return isDraft;
    }


    @AuraEnabled
    public static List<String> getProductsByOrder(Id orderId){
        system.debug('ORDERID ' + orderId);
        if(orderId != null){
            List<OrderItem> orderProducts = [SELECT Product2.ProductCode FROM OrderItem WHERE OrderId =:orderId];
						System.debug('orderProducts:'+orderProducts);
            List<String> productCodes = new List<String>();
            for(OrderItem o : orderProducts){
                productCodes.add(String.valueOf(o.Product2.ProductCode));
            }
						System.debug('RETURN:'+productCodes);
            return productCodes;
        }
        return null;
    }

    @AuraEnabled
    public static List<NB2B_StockProductListCallOut.NB2B_StockProductListCallOutResponse> checkProductStockCallout(Id orderId, List<String> productCodeList){
        String userLocale = Userinfo.getLocale();
				System.debug('****** checkProductStockCallout INICIO *****');
        System.debug('productCodeList: '+productCodeList);
        System.debug('orderId: '+orderId);
        List<OrderItem> quantityValues = [SELECT Product2.Name, Product2.StockKeepingUnit, Quantity FROM OrderItem WHERE OrderId =: orderId];
        List <NB2B_StockProductListCallOut.NB2B_StockProductListCallOutResponse> response;
        if(orderId != null && !productCodeList.isEmpty()){
            String salesOrganization = [SELECT SalesOrg__c FROM Order WHERE Id =:orderId LIMIT 1].SalesOrg__c;
            NB2B_StockProductListCallOutManager callOut = new NB2B_StockProductListCallOutManager(productCodeList,salesOrganization);
            response = callOut.getCallout();
            System.debug('b2B_checkProductStock response: '+response);
        }
        if(response != null){
            System.debug('response : ' + JSON.serialize(response));
            System.debug('quantityValues : ' + JSON.serialize(quantityValues));
            if(!quantityValues.isEmpty() && !response.isEmpty() && response.get(0).error == null){
                for(OrderItem o : quantityValues){
                    for(NB2B_StockProductListCallOut.NB2B_StockProductListCallOutResponse resp : response){
                        if(resp.product.contains(o.Product2.StockKeepingUnit)){
                            System.debug('o.Quantity :'      + o.Quantity);
                            System.debug('resp.quantity :'   + resp.quantity);
                            resp.quantity = o.Quantity;
                            if(resp.availstk != null && resp.quantity <= resp.availstk){resp.available = true;
                            }
                            if(resp.nextProduction != null){resp.nextProduction = (Date.valueOf(resp.nextProduction)).format();
                            }
                        }
                    }
                }
            }
        }
				System.debug('response:'+response);
				System.debug('****** checkProductStockCallout FIN *****');
        return response;
    }

    @AuraEnabled
    public static String deleteOrderItemUncheked(Id orderId, List<String> productsToDelete){
        String result;
        system.debug('ORDERID ' + orderId);
        system.debug('productsToDelete ' + productsToDelete);
        Try{
        	if(orderId != null && !productsToDelete.isEmpty()){

                System.debug('###b2B_checkProductStock.deleteOrderItemUncheked() productsToDelete: '+productsToDelete);
                List<OrderItem> orderItemToDelete = [SELECT Id, Product2.ProductCode FROM OrderItem WHERE OrderId =:orderId AND Product2.ProductCode IN : productsToDelete];
                System.debug('###b2B_checkProductStock.deleteOrderItemUncheked() orderItemToDelete: '+orderItemToDelete);
                delete orderItemToDelete;
                result = 'OK';
            }
        }catch(Exception e){
            System.debug('###b2B_checkProductStock.deleteOrderItemUncheked() delete catch:'+e);
            result = 'KO,'+e;
        }

        return result;
    }

    @AuraEnabled
    public static String activateOrder(Id orderId){
        String result;
        system.debug('***** activateOrder ***** ORDERID ' + orderId);
				NB2B_OrderTransactionHandler.Response response;
        if(orderId != null){
            try{
                Order orderToActivate = new Order();
                //[SELECT Id,Status,StatusCode FROM Order WHERE Id =:orderId LIMIT 1];
                response = NB2B_OrderController.saveOrder(orderId);
                System.debug('response: ' + JSON.serialize(response));
                if(response != null && response.success){
                    orderToActivate.Sap_Id__c = String.isNotBlank(response.SamplesNumber)? response.SamplesNumber : orderToActivate.Sap_Id__c;
                    orderToActivate.Id = orderId;
                    orderToActivate.Status = 'Activated';
                    orderToActivate.StatusCode = 'Activated';
                    update orderToActivate;
                    result = 'OK';
                }else{
                    for (NB2B_OrderTransactionHandler.ResponseError e : response.Error){result = result + ' - ' + e.MESSAGE;}
                    // result = response.errorMessage;
                }

                System.debug('###b2B_checkProductStock.activateOrder() orderToActivate: '+orderToActivate);

            }catch(Exception e){
                System.debug('###b2B_checkProductStock.activateOrder() update catch:'+e);
								//Control de mensajes por pantalla. Si existe error de SAP mostrarlo. Si no mostramos error de Apex
								if(response != null && (response.errorMessage != null && response.errorMessage != '')){result = 'KO,'+response.errorMessage;
								}else{result = 'KO,'+'An unexpected error occurred while sendOrder. Please contact with your system administrator. Error: '+e.getMessage();
								}
								return result;
            }
        }
				if(response != null && response.success != null && response.success == false && (response.errorMessage != null && response.errorMessage != '')){result = 'KO,'+response.errorMessage;
					return result;
				}else{
					System.debug('result : ' + result);
        	return result;
				}
     
    }

    @AuraEnabled
    public static list<String> validateData(Id orderId){
        list<String> errors = new list<String>();
        Account acc;

        Order orderInfo = [SELECT DeliveryDate__c, SalesOrg__c, SalesOffice__c, NB2B_OrderCode__c,Account.NBK_Sample_Addresses__c, Account.Id,
                            NBK_Contact_Point_Address__c, NBK_Contact_Point_Address__r.SAPId__c, NBK_Contact_Point_Address__r.ParentId,
                            NB2B_Delivery_Method__c, Account.BillingCountryCode,NBK_Warehouse_Address__c, NBK_Warehouse_Address__r.Name,
                            NBK_Warehouse_Address__r.NBK_SAPId__c, NBK_Warehouse_Address__r.NBK_Sales_Org__c, NBK_Warehouse_Address__r.NBK_isWarehouse__c,
                             NBK_Warehouse_Address__r.NBK_Sales_Org__r.SalesOrg__c, NBK_Warehouse_Address__r.NBK_Address__c, NBK_Warehouse_Address__r.NBK_Address__CountryCode__s

                           FROM Order
                           WHERE Id =:orderId
                           LIMIT 1];

        if(orderInfo.DeliveryDate__c == null){errors.add('Delivery date is empty');
        }
        if(String.isBlank(orderInfo.SalesOrg__c)){errors.add('Sales Org is empty');
        }
        if(String.isBlank(orderInfo.SalesOffice__c)){errors.add('Sales Office is empty');
        }
        if(String.isBlank(orderInfo.NB2B_OrderCode__c)){errors.add('Order Code is empty');
        }
        if(orderInfo.NBK_Contact_Point_Address__c != null && String.isBlank(orderInfo.NBK_Contact_Point_Address__r.SAPId__c)){errors.add('The Sap ID field of the contact point address is empty');
        }
        if(orderInfo.NB2B_Delivery_Method__c == null){errors.add('Delivery Method is empty');
        }else if(orderInfo.NB2B_Delivery_Method__c == '3'){
            System.debug('Envío a cliente : ' + orderInfo.NBK_Contact_Point_Address__c);
            if(orderInfo.NBK_Contact_Point_Address__c != null){
                if(orderInfo.Account.Id != orderInfo.NBK_Contact_Point_Address__r.ParentId){errors.add('The order account and contact point address must be the same or the account has to be sample address.');
                }
            }/*else{
                errors.add('The order account and contact point address must be the same or the account has to be sample address.');
            }*/
        }else if(orderInfo.NB2B_Delivery_Method__c == '1' || orderInfo.NB2B_Delivery_Method__c == '2'){
            if(orderInfo.NBK_Warehouse_Address__c != null){
                //(acc = [Select id,NBK_Sample_Addresses__c,Country_formula__c  from Account where id =: orderInfo.NBK_Contact_Point_Address__r.ParentId Limit 1];
                System.debug('orderInfo.NBK_Warehouse_Address__r.NBK_Sales_Org__r.SalesOrg__c :' + orderInfo.NBK_Warehouse_Address__r.NBK_Sales_Org__r.SalesOrg__c);
                System.debug('orderInfo.SalesOrg__c :' + orderInfo.SalesOrg__c);
                System.debug('orderInfo.NBK_Warehouse_Address__r.NBK_SAPId__c :' + orderInfo.NBK_Warehouse_Address__r.NBK_SAPId__c);
                System.debug('orderInfo.NBK_Warehouse_Address__r.NBK_isWarehouse__c :' + orderInfo.NBK_Warehouse_Address__r.NBK_isWarehouse__c);
                if(orderInfo.NBK_Warehouse_Address__r.NBK_SAPId__c == null
                    ||
                    orderInfo.NBK_Warehouse_Address__r.NBK_isWarehouse__c ==false
                    ||
                    orderInfo.NBK_Warehouse_Address__r.NBK_Address__CountryCode__s != orderInfo.Account.BillingCountryCode){errors.add('The order account and pick up address must be in same Sales Organization.');
                    }
            }else{
                errors.add('The order account and pick up address must be wharehouse address and must be in Same Organization.');
            }
        }

        System.debug('errors: ' + errors);
        return errors;
    }
}