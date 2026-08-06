/**
    * Type: Apex class
    * Name: NBK_ControllerFactory
    * @author: Nubika S.L.
    * Company: Nubika S.L.
    * Date: 20/06/2021
    * Description: Controller Factory
    * @version 1.0
*/
public class NBK_ControllerFactory {

    //Bulk Process class will invoke modvalue for each class using manager object
    public static NBK_ResponseWr bulkprocessInit(String methodName, Map<String, Object> params){
        return NBK_ControllerManager.getManager().newClassInstance(methodName).init(params);
    }

    //Bulk Process class will invoke modvalue for each class using manager object
    public static NBK_ResponseWr bulkprocessExecute(String methodName, Map<String, Object> params){
        return NBK_ControllerManager.getManager().newClassInstance(methodName).execute(params);
    }

}