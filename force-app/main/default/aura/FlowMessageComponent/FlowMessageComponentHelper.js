({
	/**
     * Assigns a heading to the message
     */
    getHeader : function(type) {
    	var header = "";
        switch (type.toLowerCase()) {
    		case "warning": 
    			header = $A.get("$Label.c.app_warning");
    			break;
    		case "error": 
    			header = $A.get("$Label.c.app_error");
    			break;
        }
 		return header;
    } // getHeader 
})