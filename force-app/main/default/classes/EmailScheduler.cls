global class EmailScheduler implements Schedulable {
    
    global void execute(SchedulableContext context) {
        
        List<Opportunity> oppList = getOppList();
        
        // Obtención del Email e Idioma (en base al País) de cada SalesOffice
        String salesOfficeLabel, salesOfficeApiName, languageStr;
        
        // Obtención de etiquetas (a partir de las picklists dependientes) que serán pasadas a la VFP
        Schema.DescribeFieldResult salesOfficeDescribe = Opportunity.SalesOfficeDate__c.getDescribe();
        
        List<SALES_OFFICE__c> salesOfficeRecord = new List<SALES_OFFICE__c>();
        
        // Map para almacenar info sobre SalesOffice <emailSalesOffice, <salesOfficeCode, language>>
        Map<String,Map<String,String>> salesOfficeMap = new Map<String,Map<String,String>>();
        
        Map<String, String> countryMap = new Map<String, String>{
            //'ES' => 'es_ES',
            //'US' => 'en_US',
            'GB' => 'en_GB',
            'FR' => 'fr_FR'/*,
            'PT' => 'pt_PT'*/
        };
                    
        for(Opportunity opp: oppList){
                
             salesOfficeApiName = opp.SalesOfficeDate__c;
               
             salesOfficeLabel = getPicklistLabel('SalesOfficeDate__c', opp.SalesOfficeDate__c);
                
             salesOfficeRecord = [SELECT Email__c, CountryCode__c 
                                  FROM SALES_OFFICE__c 
                                  WHERE Name =: salesOfficeLabel LIMIT 1];
                
              if(countryMap.containsKey(salesOfficeRecord[0].CountryCode__c)){languageStr = countryMap.get(salesOfficeRecord[0].CountryCode__c);}
              else{languageStr = 'en_GB';}
                
              salesOfficeMap.put(salesOfficeRecord[0].Email__c, new Map<String,String>{salesOfficeApiName => languageStr});
                
         }
        
        // Envío de correos electrónicos filtrados para cada representante de tienda
        String companyLabel, salesOrgLabel;
        
        for(String salesOfficeEmailKey: salesOfficeMap.keySet()){
            
            for(String salesOfficeApiNameKey : salesOfficeMap.get(salesOfficeEmailKey).keySet()){
                salesOfficeApiName = salesOfficeApiNameKey;
                languageStr = salesOfficeMap.get(salesOfficeEmailKey).get(salesOfficeApiNameKey);
                break;
            }
            
            // Obtención de etiquetas (a partir de las picklists dependientes) que serán pasadas a la VFP
            // Búsqueda de opp random para extraer nombres Api
            oppList = [SELECT CompanyDate__c, SalesOrgDate__c, SalesOfficeDate__c
                       FROM Opportunity
                       WHERE (SalesOfficeDate__c =: salesOfficeApiName) LIMIT 1];
            
			companyLabel = getPicklistLabel('CompanyDate__c', oppList[0].CompanyDate__c);
            salesOrgLabel = getPicklistLabel('SalesOrgDate__c', oppList[0].SalesOrgDate__c);            
            salesOfficeLabel = getPicklistLabel('SalesOfficeDate__c', oppList[0].SalesOfficeDate__c);
            
            sendEmail(salesOfficeEmailKey, companyLabel, salesOrgLabel, salesOfficeLabel, salesOfficeApiName, languageStr);
            
        }
        
    }
    
    global static List<Opportunity> getOppList(){
        
        // Lista de Opps que solicitaron cita en el día de ayer
        Date yesterdayDate = Date.Today().addDays(-1);
        
        return [SELECT CompanyDate__c, SalesOrgDate__c, SalesOfficeDate__c, Solicitud_Cita_En_Tienda__c
                FROM Opportunity
                WHERE (Solicitud_Cita_En_Tienda__c =: yesterdayDate) ORDER BY Name ASC];
        
    }
    
    global static String getPicklistLabel(String fieldApiName, String picklistValue){

        switch on fieldApiName {
            
            when 'CompanyDate__c' {
                
                Schema.DescribeFieldResult companyDescribe = Opportunity.CompanyDate__c.getDescribe();
                
                for (Schema.PicklistEntry ple : companyDescribe.getPicklistValues()){
                    if(ple.getValue() == picklistValue){
                        return ple.getLabel();
                    }                    
                }
                
            }
            
            when 'SalesOrgDate__c' {
                
                Schema.DescribeFieldResult salesOrgDescribe = Opportunity.SalesOrgDate__c.getDescribe();
                
                for (Schema.PicklistEntry ple : salesOrgDescribe.getPicklistValues()){
                    if(ple.getValue() == picklistValue){
                        return ple.getLabel();
                    }
                    
                }
                
            }
            
            when 'SalesOfficeDate__c' {
                
                Schema.DescribeFieldResult salesOfficeDescribe = Opportunity.SalesOfficeDate__c.getDescribe();
                
                for (Schema.PicklistEntry ple : salesOfficeDescribe.getPicklistValues()){
                    if(ple.getValue() == picklistValue){
                        return ple.getLabel();
                    }
                }
                
            }
            
        }
        
        return 'Error';
        
    }
    
    global static void sendEmail(String salesOfficeEmailKey, String companyLabel, String salesOrgLabel, String salesOfficeLabel, String salesOfficeApiName,
                                 String languageStr){
        
        List<String> EmailIds = salesOfficeEmailKey.split(',');
        PageReference ref = Page.GeneratePDF;
        
        ref.getParameters().put('companyLabel',companyLabel);
        ref.getParameters().put('salesOrgLabel',salesOrgLabel);
        ref.getParameters().put('salesOfficeLabel',salesOfficeLabel);
        
        ref.getParameters().put('salesOfficeCode',salesOfficeApiName);
        ref.getParameters().put('salesOfficeLanguage',languageStr);
                    
        Blob content = Test.isRunningTest() ? Blob.valueOf('UNIT.TEST') : ref.getContentAsPDF();
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                                     
        attach.setBody(content);
        
        // Template
        Map<String, String> attachNameTemplateMap = getAttachNameTemplate(new Map<String, String>{salesOfficeApiName => languageStr});
                                     
        String templateName;
                                     
        for(String attachNameKey: attachNameTemplateMap.keySet()){
               attach.setFileName(attachNameKey);
               templateName = attachNameTemplateMap.get(attachNameKey);
               break;
        }
                                     
        List<EmailTemplate> templateList = [SELECT Id, Name 
                         	                FROM EmailTemplate 
                                            WHERE developername =: templateName LIMIT 1];
        
        email.setToAddresses(EmailIds);
        
        // Si no existe la template, se asigna texto plano como cuerpo del email
        if(templateList.size() > 0){email.setTemplateId(templateList[0].Id);}
        else{email.setPlainTextBody('Plain Text Body');}
                                     
        email.setTargetObjectId(UserInfo.getUserId());
        email.setTreatTargetObjectAsRecipient(false);
        email.setFileAttachments(new Messaging.EmailFileAttachment[] {attach});
        
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
                                     
        /*String emailErrorReport;

		List<Messaging.SendEmailError> errors = new List<Messaging.SendEmailError>();
		for(Messaging.SendEmailResult currentResult : r ) {
			errors = currentResult.getErrors();
			if( null != errors ) {
				for( Messaging.SendEmailError currentError : errors ) {
				System.debug(currentError.getStatusCode() + ' ' + currentError.getMessage() + ' ') ; 
				}
			}
		}*/
        
    }
    
    global static Map<String, String> getAttachNameTemplate(Map<String, String> salesOfficeCodeMap){
        
        Map<String, String> attachNameTemplateMap = new Map<String, String>();       
        
        for(String salesOfficeCodeKey : salesOfficeCodeMap.keySet()){
            
            switch on salesOfficeCodeMap.get(salesOfficeCodeKey){                    
                //when 'es_ES'{attach.setFileName('Listado de Oportunidades.pdf');}
                when /*'En_US',*/ 'en_GB'{attachNameTemplateMap.put('Opportunity List.pdf', 'Porcelanosa_Email_Template_GB');}
                when 'fr_FR'{attachNameTemplateMap.put('Liste des Opportunités.pdf', 'Porcelanosa_Email_Template_FR');}
                when else{attachNameTemplateMap.put('Opportunity List.pdf', 'Porcelanosa_Email_Template_GB');}
            }
            
        }
        
        return attachNameTemplateMap;
        
    }
    
}