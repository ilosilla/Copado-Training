/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 02-02-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class b2b_customLookupController {
    @AuraEnabled(cacheable=true)
    public static list<sObject> fetchLookupData(string countryCode , string sObjectApiName) {
        List < sObject > returnList = new List < sObject > ();
        //string sQuery = 'Select Id,Name From ' + sObjectApiName + ' Where Name Like : sWildCardText order by createdDate DESC LIMIT 5';
        string sQuery = 'SELECT Id,Name FROM ' + sObjectApiName + ' WHERE NBK_Address__CountryCode__s = \'' + countryCode + '\' AND NBK_isActive__c = true AND NBK_isWarehouse__c = true';
        for (sObject obj: database.query(sQuery)) {
            returnList.add(obj);
        }
        return returnList;
    }
}