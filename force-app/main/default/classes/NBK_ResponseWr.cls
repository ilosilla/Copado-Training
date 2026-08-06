/**
    * Type: Apex Class
    * Name: NBK_ResponseWr
    * @author: Nubika S.L.
    * Company: Nubika S.L.
    * Date: 20/06/2021
    * Description: Wrapper class for manage Response from Aura and LWC controller's calls
    * @version 1.0
*/

public with sharing class NBK_ResponseWr {
    private Boolean success = true;
    private String errorMsg = null;
    private String errorStackTrace = null;
    private Integer errorLineNumber = null;
    private String dataJSON = null;
    private Boolean defaultAdd = false;
    private Decimal daysToDelay = null;
    private String validationMsg = null;

    public NBK_ResponseWr(){}
    
    public NBK_ResponseWr(Boolean success, Exception error, String dataJSON, Boolean defaultAdd, Decimal daysToDelay){
        this.success = success;
        if(error!=null){
            this.errorMsg = error.getMessage();
            this.errorStackTrace = error.getStackTraceString();
            this.errorLineNumber = error.getLineNumber();
        }
        this.dataJSON = dataJSON;
        this.defaultAdd = defaultAdd;
        this.daysToDelay = daysToDelay;
    }

    public NBK_ResponseWr(Boolean success, Exception error, String dataJSON){
        this.success = success;
        if(error!=null){
            this.errorMsg = error.getMessage();
            this.errorStackTrace = error.getStackTraceString();
            this.errorLineNumber = error.getLineNumber();
        }
        this.dataJSON = dataJSON;
    }

    public NBK_ResponseWr(String errorMsg){
        this.success = false;
        this.errorMsg = errorMsg;
    }

    public Boolean getSuccess(){
        return this.success;
    }

    public String getErrorMsg(){
        return this.errorMsg;
    }

    public String getDataJSON(){
        return this.dataJSON;
    }

    public void setValidationMsg (String validationMsg){
        this.validationMsg = validationMsg;
    }
}