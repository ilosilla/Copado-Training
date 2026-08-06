public class OppController {
    
    public String companyLabel { get; set; }
    public String salesOrgLabel { get; set; }
    public String salesOfficeLabel { get; set; }
    public String salesOfficeCode { get; set; }
    public String salesOfficeLanguage { get; set; }
    
    public List<Opportunity> getOppList(){
        
        Date yesterdayDate = Date.Today().addDays(-1);
        
        List<Opportunity> oppList =  [SELECT Name, Account.Name, Account.Address__c, Account.PersonMobilePhone, Account.PersonEmail, Account.Profesional__c, 
                                      ContractorConsulting__c, CompanyDate__c, SalesOrgDate__c, SalesOfficeDate__c, Solicitud_Cita_En_Tienda__c, FechaHoraCita__c, 
                                      Description, ProjectZone__c, Matherials__c, IniProjectDate__c, EndProjectDate__c, ReasonProject__c, ProjectType__c, 
                                      Order__r.Product__c, Interest__c
                                      FROM Opportunity 
                					  WHERE (Solicitud_Cita_En_Tienda__c =: yesterdayDate AND SalesOfficeDate__c =: salesOfficeCode) ORDER BY Name ASC];
        
        return oppList;        
        
    }
    
    public OppController(){
        
        companyLabel = ApexPages.CurrentPage().getParameters().get('companyLabel');
        salesOrgLabel = ApexPages.CurrentPage().getParameters().get('salesOrgLabel');
        salesOfficeLabel = ApexPages.CurrentPage().getParameters().get('salesOfficeLabel');      
        salesOfficeCode = ApexPages.CurrentPage().getParameters().get('salesOfficeCode');
        salesOfficeLanguage = ApexPages.CurrentPage().getParameters().get('salesOfficeLanguage');
        
    }

}