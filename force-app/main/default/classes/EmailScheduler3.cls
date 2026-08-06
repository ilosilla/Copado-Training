global class EmailScheduler3 implements Schedulable {
    
    global void execute(SchedulableContext context) {
        
        // Lista de Opps que solicitaron cita en el día de ayer
        Date yesterdayDate = Date.Today().addDays(-1);
        
        List<Opportunity> oppList = [SELECT Sales_Office_Date__c, Request_Store_Appointment__c
                                     FROM Opportunity
                                     WHERE (Request_Store_Appointment__c =: yesterdayDate) ORDER BY Name ASC];
        
        System.debug('oppList ' + oppList);
               
        /*Map<String, String> countryMap = new Map<String, String>{
            'ES' => 'es_ES',
            //'US' => 'en_US',
            'GB' => 'en_GB', //?
            'FR' => 'fr_FR'/*,
            'PT' => 'pt_PT'*/
        //};
        
        // salesOfficeManagers
        List<User> salesOfficeManagerList = [SELECT Name, CountryCode, LanguageLocaleKey, Sales_Office__c, Email
                                             FROM User
                                             WHERE Team_Manager__c = true];
        
        // Porcelanosa Email Templates
        Id templateIdFr = [SELECT Id, Name 
                           FROM EmailTemplate 
                           WHERE developername =: 'Porcelanosa_Email_Template_Cliente_FR'].Id;
        
        Id templateIdGb = [SELECT Id, Name 
                           FROM EmailTemplate 
                           WHERE developername =: 'Porcelanosa_Email_Template_Cliente_GB'].Id;
        
        // randomContact
        Id randomContact = [SELECT Id, Name 
                            FROM Contact LIMIT 1].Id;
                
        for(Opportunity opp: oppList){
            
            // salesOffice de Oportunidad
            String salesOfficeApiName = opp.Sales_Office_Date__c;
            
            // responsables de dicha salesOffice
            List<User> correspondingManagers = new List<User>();
            
            for(User userItem: salesOfficeManagerList){                
                if(userItem.Sales_Office__c == salesOfficeApiName){
                    correspondingManagers.add(userItem);
                }
            }
                        
            for(User correspondingItem: correspondingManagers){
                
                // se puede mejorar luego de despejar las dudas
                // 1) definir criterios para coutry language
                // 2) un comercial puede ser responsable de varias tiendas?
                List<String> EmailIds = new List<String>{correspondingItem.Email};
                PageReference ref = Page.GeneratePDF;
                ref.getParameters().put('salesOfficeCode', correspondingItem.Sales_Office__c);
                ref.getParameters().put('salesOfficeLanguage', 'en_US');
                
                // check if Test is running (pdfPage.getContentAsPDF() does not work directly for a test)
                Blob b = Test.IsRunningTest() ? Blob.valueOf('Unit Test') : ref.getContentAsPDF();
                
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                
                switch on correspondingItem.LanguageLocaleKey {                    
                    //when 'es_ES'{attach.setFileName('Listado de Oportunidades.pdf');}
                    when 'en_US', 'en_GB' {                        
                        attach.setFileName('Opportunity List.pdf');
                        email.setTemplateId(templateIdGb);                        
                    }
                    when 'fr_FR', 'fr' {                        
                        attach.setFileName('Liste des Opportunités.pdf');
                        email.setTemplateId(templateIdFr);                        
                    } 
                    when else {
                        attach.setFileName('Opportunity List.pdf');
                        email.setTemplateId(templateIdGb);
                    }
                }
                
                attach.setBody(b);
                
                //email.setSubject('Lista Oportunidades ' + Date.TODAY().format());
                email.setToAddresses(EmailIds);
                //email.setTemplateId(templateId);
                email.setTargetObjectId(randomContact);
                email.setTreatTargetObjectAsRecipient(false);
                email.setFileAttachments(new Messaging.EmailFileAttachment[] {attach});
                Messaging.SendEmailResult [] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
                
                for (Messaging.SendEmailResult res : results) {
                    if (res.isSuccess()) {
                    }
                    else {
                    }
                }
                
            }
            
        }
        
    }
    
}