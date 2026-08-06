/*-----------------------------------------------------------------------------------------
     Apex Class:        NB2B_OrderController
     Created Date:      7/02/2022
     Author:            Cristobal Acero Lara
     Mail:              cristobal.acero@nubika.com
     Description:       Order crontoller class
------------------------------------------------------------------------------------------*/
public with sharing class NB2B_OrderController {
    @AuraEnabled
    public static NB2B_OrderTransactionHandler.Response saveOrder(Id recordId){
        NB2B_OrderTransactionHandler.Response result = new NB2B_OrderTransactionHandler.Response();
        Logger.info('[SAP] - Save Order Invocation - [Started]')
            .setRecordId(recordId)
            .addTag(NB2B_GlobalConstants.LOGGER_B2B_SAP_INTEGRATION_TAG);
        try{
            List<Order> listOrder = NB2B_OrderSelector.getOrderAndOrderItemById(recordId);
            if(listOrder.isEmpty()){ throw new OrderControllerException('Not found Order with Id "' + recordId + '"'); }

            Order ordToWrapper = listOrder.get(0);
            if(ordToWrapper.OrderItems == null || ordToWrapper.OrderItems.isEmpty()){ throw new OrderControllerException(System.Label.NB2B_CartOrderEmptyError); }

            NB2B_OrderWrapper orderWrapper = new NB2B_OrderWrapper(ordToWrapper, !ordToWrapper.OrderItems.isEmpty()? ordToWrapper.OrderItems : new List<OrderItem>());
            String jsonTransaction = JSON.serialize(orderWrapper)
                .replace(Nb2b_GlobalConstants.CURRENCY_ORDER_NAME, Nb2b_GlobalConstants.CURRENCY_NAME)
                .replace(Nb2b_GlobalConstants.CURRENCY_VALUE_EUR, Nb2b_GlobalConstants.CURRENCY_VALUE_GBP);

            result = NB2B_OrderTransactionHandler.runTransaction(jsonTransaction);
            if(!result.success){ throw new OrderControllerException(filterErrorMessage(result.errorMessage, false));}
        }catch(Exception e){
            result.errorMessage = e.getMessage();
            Logger.error('[SAP] - Save Order Invocation - [Error]: ' + result.errorMessage + '\n' + e.getStackTraceString())
                .setRecordId(recordId)
                .addTags(new List<String>{NB2B_GlobalConstants.LOGGER_B2B_SAP_INTEGRATION_TAG,NB2B_GlobalConstants.LOGGER_B2B_SAP_INTEGRATION_ERROR_TAG});
        }

        Logger.info('[SAP] - Save Order Invocation - [Finished]')
            .setRecordId(recordId)
            .addTag(NB2B_GlobalConstants.LOGGER_B2B_SAP_INTEGRATION_TAG);
        Logger.saveLog();

        return result;
    }

    @AuraEnabled
    public static NB2B_OrderTransactionHandler.Response saveOrder(Order order, List<OrderItem> listOrdItems, Map<Id,Product2> productMap, String sapAccountId){
        NB2B_OrderTransactionHandler.Response result = new NB2B_OrderTransactionHandler.Response();
        Logger.info('[SAP] - Save Order Invocation - [Started]').addTag(NB2B_GlobalConstants.LOGGER_B2B_SAP_INTEGRATION_TAG);
        Logger.saveLog();
        try{
            NB2B_OrderWrapper orderWrapper  = new NB2B_OrderWrapper(order, listOrdItems, sapAccountId, productMap);
            String jsonTransaction = JSON.serialize(orderWrapper)
                .replace(Nb2b_GlobalConstants.CURRENCY_ORDER_NAME, Nb2b_GlobalConstants.CURRENCY_NAME)
                .replace(Nb2b_GlobalConstants.CURRENCY_VALUE_EUR, Nb2b_GlobalConstants.CURRENCY_VALUE_GBP);

            result = NB2B_OrderTransactionHandler.runTransaction(jsonTransaction);
            if(!result.success){ throw new OrderControllerException(filterErrorMessage(result.errorMessage,false)); }
        }catch(Exception e){
            result.errorMessage = e.getMessage();
            Logger.error('[SAP] - Save Order Invocation - [Error]: ' + result.errorMessage + '\n' + e.getStackTraceString()).addTags(new List<String>{NB2B_GlobalConstants.LOGGER_B2B_SAP_INTEGRATION_TAG,NB2B_GlobalConstants.LOGGER_B2B_SAP_INTEGRATION_ERROR_TAG});
        }

        Logger.info('[SAP] - Save Order Invocation - [Finished]').addTag(NB2B_GlobalConstants.LOGGER_B2B_SAP_INTEGRATION_TAG);
        Logger.saveLog();

        return result;
    }

    // Limpia mensajes de errores
    public static string filterErrorMessage(String errorMessage, Boolean regularUpdate){

        String result = errorMessage;

        if(String.isNotBlank(result)){
            Integer stringLength = errorMessage.length();
            if(regularUpdate){
                Integer pos = errorMessage.indexOf(Nb2b_GlobalConstants.FIELD_INTEGRITY_EXCEPTION);
                result = pos != -1 ? errorMessage.mid(pos, stringLength) : result;
                pos = errorMessage.indexOf(Nb2b_GlobalConstants.FIELD_CUSTOM_VALIDATION_EXCEPTION);
                result = pos != -1 ? errorMessage.mid(pos, stringLength) : result;
            } else {
                result = errorMessage.remove(Nb2b_GlobalConstants.FIELD_CUSTOM_VALIDATION_EXCEPTION);
                result = result.remove(Nb2b_GlobalConstants.ACCOUNT_FIELD_AFFECTED);
            }
        }
        return result;
    }

    public class OrderControllerException extends Exception{}
}