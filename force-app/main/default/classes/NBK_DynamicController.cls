/**
 * @description       : 
 * @author            : alberto.martinez@nubika.com
 * @group             : 
 * @last modified on  : 10-18-2021
 * @last modified by  : alberto.martinez@nubika.com
**/
public virtual class NBK_DynamicController implements NBK_IController{
    
    public virtual NBK_ResponseWr init(Map<String, Object> params){
        return new NBK_ResponseWr(true,null,null);
    }

    public virtual NBK_ResponseWr execute(Map<String, Object> params){
        return new NBK_ResponseWr(true,null,null);
    }
}