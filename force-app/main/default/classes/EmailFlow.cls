global class EmailFlow {
    
    @InvocableMethod
    public static List<string> execute(List<String> emailList){
        List<string> result = new List<string>();
        //List<String> EmailIds = emailList.split(',');
        try{
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            Id templateId;
            
            // Asignamos la Email Template de acuerdo al idioma del usuario
            switch on UserInfo.getLanguage(){
                
                when 'en_US'{ // no se retorna en_GB
                    
                    templateId = [SELECT Id, Name 
                                  FROM EmailTemplate 
                                  WHERE developername = 'Porcelanosa_Email_Template_Cliente_GB'].id;
                    
                }
                
                when 'fr'{
                    
                    templateId = [SELECT Id, Name 
                                  FROM EmailTemplate 
                                  WHERE developername = 'Porcelanosa_Email_Template_Cliente_FR'].id;
                    
                }
                
                when else{
                    
                    templateId = [SELECT Id, Name 
                                  FROM EmailTemplate 
                                  WHERE developername = 'Porcelanosa_Email_Template_Cliente_GB'].id;
                    
                }
                
            } 
            
            //email.setSubject('Lista Oportunidades ' + Date.TODAY().format());
            
            email.setToAddresses(emailList);
            email.setTemplateId(templateId);
            email.setTargetObjectId(UserInfo.getUserId());
            email.setTreatTargetObjectAsRecipient(false);
            Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            
            result.add('Success');
        } catch(Exception ex){
            result.add( ex.getMessage() );
        }
        
        return result;
    }
    
}