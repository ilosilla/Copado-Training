/**
 * Batch controller for retreiving companies information and creating discrepencies records
 */
public with sharing class DvsBatchController implements Database.Batchable<sObject>, Database.AllowsCallouts {

    private DvsSetting__mdt dvsConfiguration;
    private String name;
    private String postalCode;
    private Integer limitation;
    private Datetime startDate;
    private Datetime endDate;
    private Boolean fuzzySearch = false;

    public DvsBatchController(DvsSetting__mdt configuration) {
        this.dvsConfiguration = configuration;
    }

    /**
     * Restricts batch execution for a given company name and city (for test purpose)
     */
    public void setParameters(String name, String postalCode) {
        this.name = name;
        this.postalCode = postalCode;
    }

    /**
     * Restricts batch execution to a given date range
     */
    public void setPeriod(Datetime startDate, Datetime endDate) {
        this.startDate = startDate;
        this.endDate = endDate;
    }

    /**
     * Limits the number of treated companies
     */
    public void setLimit(Integer limitation) {
        this.limitation = limitation;
    }

    /**
     * Allow fuzzySearch
     */
    public void setFuzzySearch(Boolean fuzzySearch) {
        this.fuzzySearch = fuzzySearch;
    }

    /**
     * Initialize the query for retrieving account depending on batch parameters and DVS settings
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {

        List<RecordType> rcTypes = [SELECT Id FROM RecordType WHERE (Name = 'Fabricator' OR Name = 'Third party Retailer / Reseller' OR Name = 'Trade and Specificators')];
        List<Id> rcTypesIds = new List<Id>{rcTypes[0].Id, rcTypes[1].Id, rcTypes[2].Id};
        
        String countryCode = dvsConfiguration.CountryCode__c;
        System.debug('DvsBatchController\'s start');
        System.debug('CountryCode: ' + countryCode);

        String query = 'SELECT ID, Name, BillingStreet, BillingPostalCode, BillingCity, BillingCountry, BillingCountryCode, VAT_Number__c, VAT_Number_2__c, DvsLongError__c, DvsHasError__c, (SELECT Id FROM Dvs_Discrepancies__r)'
        + ' FROM Account'
        + ' WHERE SynchronizedWithDvs__c = false'
        + ' AND BillingCountryCode = :countryCode'
        + ' AND RecordTypeId IN :rcTypesIds';

        if (name != null && postalCode != null) {
            query += ' AND Name = :name'
            + ' AND BillingPostalCode = :postalCode';
        }

        if (startDate != null && endDate != null) {
            query += ' AND Last_Activity_Date__c >= :startDate AND Last_Activity_Date__c <= :endDate';
        }

        if (limitation != null) {
            query += ' LIMIT ' + limitation;
        }
        System.debug(query);

        return Database.getQueryLocator(query);
    }

    /**
     * Update discrepencies on each batch chunk
     */
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Account> accounts = scope;
        String countryCode = dvsConfiguration.CountryCode__c;

        if (countryCode == 'FR') {
            DvsService.updateDiscrepancies(accounts, dvsConfiguration, fuzzySearch);
        } else {
            DvsHelper.searchDiscrepancies(accounts, fuzzySearch);
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Job has just finished.');
    }
}