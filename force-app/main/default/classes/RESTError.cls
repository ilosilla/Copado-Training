/**
* @author 		Ramón Prades
* @date 		December 2021
* @group 		Exceptions
* @description 	Object to return an error JSON when a rest request fails
*/
public class RESTError {    
    public String errorCode;
    public String message;
    public String target;
    public String details;

    public RESTError() {}

    public RESTError(Exception ex) {
        this.errorCode = ex.getTypeName();
        this.message = ex.getMessage();
        this.details = ex.getStackTraceString();
    }
}