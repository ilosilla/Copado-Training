/**
    * Type: Apex class
    * Name: NBK_ControllerExecuter
    * @author: Nubika S.L.
    * Company: Nubika S.L.
    * Date: 20/06/2021
    * Description: Controller Executer
    * @version 1.0
*/

public with sharing class NBK_ControllerExecuter {

    @AuraEnabled(cacheable=true)
    public static String getControllerData(String dataJSON) {
        try{
            Map<String, Object> objectData = (Map<String, Object>) JSON.deserializeUntyped(dataJSON);
            if(objectData == null) throw new ControllerExecuterException('Data should not be empty');
            String controllerName = String.valueOf(objectData.get(NBK_ControllerExecuterConstants.PARAM_CONTROLLER));
            if(String.isBlank(controllerName)) throw new ControllerExecuterException('You should specify the \'controller\' param');
            return JSON.serialize(NBK_ControllerFactory.bulkprocessInit(controllerName, objectData));
        }catch(Exception e){
            System.debug('### NBK_ControllerExecuter - getControllerData() - [EXCEPTION]: ' + e.getMessage() + ' on line: ' + e.getLineNumber());
            return JSON.serialize(new NBK_ResponseWr(false, e, null));
        }
        
    }

    @AuraEnabled
    public static String executeAction(String dataJSON) {
        try{
            Map<String, Object> objectData = (Map<String, Object>) JSON.deserializeUntyped(dataJSON);
            if(objectData == null) throw new ControllerExecuterException('Data should not be empty');
            String controllerName = String.valueOf(objectData.get(NBK_ControllerExecuterConstants.PARAM_CONTROLLER));
            if(String.isBlank(controllerName)) throw new ControllerExecuterException('You should specify the \'controller\' param');
            return JSON.serialize(NBK_ControllerFactory.bulkprocessExecute(controllerName, objectData));
        }catch(Exception e){
            System.debug('### NBK_ControllerExecuter - executeAction() - [EXCEPTION]: ' + e.getMessage() + ' on line: ' + e.getLineNumber());
            return JSON.serialize(new NBK_ResponseWr(false, e, null));
        }
    }

    private class ControllerExecuterException extends Exception {}
}