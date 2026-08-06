/**
    * Type: Apex class
    * Name: NBK_ControllerManager
    * @author: Nubika S.L.
    * Company: Nubika S.L.
    * Date: 20/06/2021
    * Description: Controller Manager
    * @version 1.0
*/
public with sharing class NBK_ControllerManager{
    //Unique instance
    private static NBK_ControllerManager managerInstance; 

    //private constructor
    private NBK_ControllerManager(){}

    //Singleton Object -> return an unique instance
    public static NBK_ControllerManager getManager(){
        managerInstance = (managerInstance != null)? managerInstance : new NBK_ControllerManager();
        return managerInstance;
    }

    // Return the appropriate class instance based on className
    public NBK_IController newClassInstance(String className){
        Type t = Type.forName(className);
        return (NBK_IController) t.newInstance();
    }
}