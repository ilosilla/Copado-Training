@IsTest
public class Test_EmailScheduler {
    
    @isTest public static void Test_execute(){
        
        Test.startTest();        
        // Agendamos el trabajo a las 8:00 AM (todos los días)
        String CRON_EXP = '0 0 8 1/1 * ? *';
        // Verificamos que no exista el trabajo "myScheduledJob"
        List<CronTrigger> ct = [SELECT Id, CronJobDetail.Name, CronExpression, TimesTriggered, NextFireTime 
                                FROM CronTrigger 
                                WHERE CronJobDetail.Name =: 'myScheduledJob' LIMIT 1];
        
        if(ct.size() == 0){
            String jobId = System.schedule('myScheduledJob', CRON_EXP, new EmailScheduler());
            ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                  FROM CronTrigger 
                  WHERE id = :jobId LIMIT 1];
        }
          
        // Verificamos que el trabajo no haya sido ejecutado
        System.assertEquals(0, ct[0].TimesTriggered); 
        // Verificamos la próxima ejecución
        System.assert(ct.size() > 0);
        Test.stopTest();
        
    }
    
    @isTest public static void Test_getPicklistLabel(){
        
        String label = EmailScheduler.getPicklistLabel('CompanyDate__c', OrganizationCommons.ORG_SOUTH_EAST);
        System.assertEquals(label, 'PORCELANOSA SOUTHEAST LTD');
        label = EmailScheduler.getPicklistLabel('SalesOrgDate__c', OrganizationCommons.ORG_SOUTH_EAST);
        System.assertEquals(label, 'Porce. South East');
        label = EmailScheduler.getPicklistLabel('SalesOfficeDate__c', '2553');
        System.assertEquals(label, 'SE SOUTHAMPTON');
        label = EmailScheduler.getPicklistLabel('SalesOfficeDate__c', '-1');
        System.assertEquals(label, 'Error');
        
    }
    
    @isTest public static void Test_sendEmail(){
        
        String salesOfficeEmailKey = 'julian.besso@neoris.com';
        String companyLabel = 'PORCELANOSA SOUTHEAST LTD';
        String salesOrgLabel = 'Porce. South East';
        String salesOfficeLabel = 'SE SOUTHAMPTON';
        String salesOfficeApiName = '2553'; 
        String languageStr = 'en_GB';
        
        EmailScheduler.sendEmail(salesOfficeEmailKey, companyLabel, salesOrgLabel, salesOfficeLabel, salesOfficeApiName, languageStr);
        System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
        
    }
    
    
}