public class TriggerFactory2{
 
    // Main function where you perform the 
    // dynamic creation of Handler and routing
 
    public static void createAndExecuteHandler(Type t){
        ITrigger2 handler = getHandler(t);
         
        if (Handler == null) 
           throw new TriggerException('No Trigger Handler: ' + 
                                           t.getName());
          
        // Execute routing to the function you want to use. 
        // implements the generated event
 
        execute(handler);
    }
  
    /*
     * Execution of routing
     */
    private static void execute(ITrigger2 handler){
 
        if (Trigger.isBefore){
 
            // Función de caché
            handler.bulkBefore();
            
            if (Trigger.isDelete){
                
                for (SObject so : Trigger.old){
                    handler.beforeDelete(so);
                }
            }
            
            else if (Trigger.isInsert){
                
                for (SObject so : Trigger.new){
                    handler.beforeInsert(so);
                }
                
            }
            
            else if (Trigger.isUpdate){
                
                for (SObject so : Trigger.old){
                    handler.beforeUpdate(so, Trigger.newMap.get(so.Id));                    
                }
                
            }
            
        }
         
        //Repeat the scheme towards the after functions*
 
        else{
             
            handler.bulkAfter();
  
            if (Trigger.isDelete){
                for (SObject so : Trigger.old){
                    handler.afterDelete(so);
                }
            }
 
            else if (Trigger.isInsert){
                for (SObject so : Trigger.new){
                    handler.afterInsert(so);
                }
            }
 
            else if (Trigger.isUpdate){
                for (SObject so : Trigger.old){
                    handler.afterUpdate(so, Trigger.newMap.get(so.Id));
                }
            }
        }
  
        // Post-processing and DML operations 
        handler.andFinally();
    }
  
    //Function for the creation of the handler
 
    private static ITrigger2 getHandler(Type t){
        Object o = t.newInstance();
  
        // Security check
        if (o instanceOf ITrigger2)return (ITrigger2)o;
        else return null;
    }
  
    /*
     * The code of the Exception, can be the one that we want
     */
    public class TriggerException extends Exception {}
}