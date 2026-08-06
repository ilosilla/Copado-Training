public class OppController3 {
    
    public String salesOfficeCode { get; set; }
    public String salesOfficeLanguage { get; set; }
    
    public List<Opportunity> getOppList(){
        
        Date yesterdayDate = Date.Today().addDays(-1);
        
        List<Opportunity> oppList =  [SELECT Name, Account.Name, Account.Address__c, Account.PersonMobilePhone, Account.PersonEmail, Account.Professional__c, 
                                      Contractor_Consulting__c, Company_Date__c, Sales_Org_Date__c, Sales_Office_Date__c, Appointment_Date__c, 
                                      Request_Store_Appointment__c, Project_Zone__c, Materials__c, Start_Project_Date__c , End_Project_Date__c , ReasonProject__c  
                                      FROM Opportunity
                                      WHERE (Request_Store_Appointment__c =: yesterdayDate AND Sales_Office_Date__c =: salesOfficeCode) ORDER BY Name ASC];
        
        System.debug('salesOfficeCode ' + salesOfficeCode);
        System.debug(oppList);
        
        return oppList;
        
    }
    
    public OppController3(){
        
        salesOfficeCode = ApexPages.CurrentPage().getParameters().get('salesOfficeCode');
        System.debug('salesOfficeCode ' + salesOfficeCode);
        salesOfficeLanguage = ApexPages.CurrentPage().getParameters().get('salesOfficeLanguage');
        System.debug('salesOfficeLanguage ' + salesOfficeLanguage);
        
    }
    
}