/**
    * Type: Apex Interface
    * Name: NBK_IController
    * author: Nubika S.L.
    * Company: Nubika S.L.
    * Date: 20/06/2021
    * Description: Controller Interface
    * @version 1.0
*/

public interface NBK_IController{
    NBK_ResponseWr execute(Map<String, Object> params);
    NBK_ResponseWr init(Map<String, Object> params);
}