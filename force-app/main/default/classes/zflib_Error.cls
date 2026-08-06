/**
* @author 		Ramón Prades
* @date 		June 2022
* @group 		Framework
* @description 	Domain class object error
*/
public class zflib_Error {
    
    public String domain;
    public String message;
    public String exceptionType;
    public String recordId;
    public string fieldName;

    /**
     * Constructor (derives the main class from the object)
     **/
    public zflib_Error(SObject obj, String message) { 
        this(obj, message, '');
    }

    /**
     * Constructor (derives the main class from the object)
     **/
    public zflib_Error(SObject obj, String message, String fieldName) { 
        this.domain = String.valueOf(obj).split(':')[0];
        this.recordId = obj.Id;
        this.message = message;
        this.fieldName = fieldName;
    }

    /**
     * Constructor (Fills from an object and an exception)
     **/
    public zflib_Error(SObject obj, Exception ex) { 
        this(obj, ex, '');
    }

    /**
     * Constructor (Fills from an object and an exception)
     **/
    public zflib_Error(SObject obj, Exception ex, String fieldName) { 
        this(obj, ex.getMessage(), fieldName);
        this.exceptionType = ex.getTypeName();
    }


 } // class