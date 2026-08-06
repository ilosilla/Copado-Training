global with sharing class CompanyInfosInput {

    @AuraEnabled
    global String idNumber {get; set;}

    @AuraEnabled
    global String name {get; set;}
    
    @AuraEnabled
    global String city {get; set;}

    @AuraEnabled
    global String postalCode {get; set;}

    @AuraEnabled
    global String id {get; set;}


}