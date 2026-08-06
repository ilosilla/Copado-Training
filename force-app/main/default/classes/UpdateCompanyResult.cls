global with sharing class UpdateCompanyResult {

    @AuraEnabled
    global Boolean success {get; set;}
    
    @AuraEnabled
    global String message {get; set;}

    @AuraEnabled
    global String companyId {get; set;}

    @AuraEnabled
    global Map<String, String> company {get; set;}
}