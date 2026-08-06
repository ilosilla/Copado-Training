/**
 * @description DTO used for returning the list of found companies
 * @author TrueLines
 */
global with sharing class CompanyInfosResult {

    @AuraEnabled
    global Boolean success {get; set;}
    
    @AuraEnabled
    global String message {get; set;}

    @AuraEnabled
    global String searchStatus {get; set;}

    @AuraEnabled
    global Map<String, String> currentAccount {get; set;}

    @AuraEnabled
    global List<Map<String, String>> singleSearchSocieties {get; set;}

    @AuraEnabled
    global Map<String, String> singleSearchSociety {get; set;}

    @AuraEnabled
    global Map<String, String> fieldLabels {get; set;}

    @AuraEnabled
    global Id accountId {get; set;}

    /**
     * @description Empty no-arg constructor
     */
    global CompanyInfosResult() {
        // Nothing to do. Initiate with null values
    }
    
    /**
     * @description Constructor
     * @param success Is the search sucessful
     * @param message Error message if not successful
     */
    global CompanyInfosResult(Boolean success, String message) {
        this.success = success;
        this.message = message;
    }
}