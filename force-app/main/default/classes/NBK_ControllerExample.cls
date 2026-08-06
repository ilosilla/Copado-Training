/**
    * Type: Apex class
    * Name: NBK_ControllerExample
    * @author: Nubika S.L.
    * Company: Nubika S.L.
    * Date: 20/06/2021
    * Description: Example Aura/LWC Dynamic controller
    * @version 1.0
*/

public with sharing class NBK_ControllerExample extends NBK_DynamicController{
    
    public override NBK_ResponseWr execute(Map<String, Object> params){
        try{
            String actionName = String.valueOf(params.get(NBK_ControllerExecuterConstants.PARAM_ACTION));
            switch on actionName{
                when 'action1'  { return action1(String.valueOf(params.get('paramString'))); }
                when 'action2'  { return action2((Id) params.get('paramId')); }
                when else       { throw new ControllerExampleException('Invalid action'); }
            }
        }catch(Exception e){ return new NBK_ResponseWr(false,e,null); }
    }

    private static NBK_ResponseWr action1(String paramString){
        try{
            //Process request
            return new NBK_ResponseWr(true,null,null);
        }catch(Exception e){ return new NBK_ResponseWr(false,e,null); }
    }

    private static NBK_ResponseWr action2(Id paramId){
        try{
            //Process request
            return new NBK_ResponseWr(true,null,null);
        }catch(Exception e){ return new NBK_ResponseWr(false,e,null); }
    }


    private class ControllerExampleException extends Exception {}
}