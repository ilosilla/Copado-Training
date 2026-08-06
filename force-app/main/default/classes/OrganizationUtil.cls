/**
* @author 			Ramón Prades
* @date 			October 2020
* @group 			Tools
* @description 	    Utility methods to help finding out the organization of the company
*/
public with sharing class OrganizationUtil { 

    /**
     * Calculates the cut-off time to deliver samples
     */
    public static Datetime getSamplesCutoff(Sales_Org__c org) {
        DateTime cutoff = DateTimeCommons.buildDateTime(org.SamplesCutOff__c, org.TimeZone__c);
        if (Datetime.now() > cutoff) {
            cutoff = cutoff.addDays(1);
            cutoff = DateTimeCommons.advanceWeekend(cutoff);
        }
        return cutoff;
    }
    
    /**
     * Checks if the sales org is in France
     */
    public static Boolean isFrench(String salesOrg) {
        return ( (salesOrg != null) && (salesOrg.substring(0, 1) == '2'));
    }

    /**
     * @description Returns the company code linked to a sales org.
     */
    public static String getSalesOrgCompany(String salesOrg) {
        String company = '';
        List<Sales_org__c> orgs = [select Company__c from Sales_org__c where SalesOrg__c = :salesOrg];
        if (orgs.size() > 0) {
            company = orgs[0].Company__c;
        }
        return company;        
    } 

    /**
     * Name of the sales org
     */
    public static String getSalesOrgName(String salesOrg) {
        String name = '';
        List<Sales_org__c> orgs = [select Name from Sales_org__c where SalesOrg__c = :salesOrg];
        if (orgs.size() > 0) {
            name = orgs[0].Name;
        }
        return name;
    }

    /**
    * @description Returns data of all Sales Offices
    * @return Map<OfficeCode, SALES_OFFICE__c>
    */
    public static Map<String, SALES_OFFICE__c> getSalesOffices() {
        Map<String, SALES_OFFICE__c> aux = new Map<String, SALES_OFFICE__c>();
        List<SALES_OFFICE__c> listSalesOffices = new List<SALES_OFFICE__c>();

        listSalesOffices = [SELECT Id,Name,SalesOffice__c,Address__c,City__c,Company__c,CountryCode__c,Email__c,Postcode__c,Phone__c,Region__c,RegionName__c,SalesOrg__c,WaitingList__c FROM SALES_OFFICE__c];
        for (SALES_OFFICE__c elem : listSalesOffices) {
            aux.put(elem.SalesOffice__c, elem);
        }
        
        return aux;
    }

    /**
     * Name of the sales office
     */
    public static String getSalesOfficeName(String salesOffice) {
        String name = '';
        if (!String.isBlank(salesOffice)) {
            List<Master_relations__c> offices = [select SalesOffice_name__c  from Master_relations__c where SalesOffice_code__c = :salesOffice];
            if (offices.size() > 0) {
                name = offices[0].SalesOffice_name__c ;
            }

        }
        return name;        
    }

    /**
    * @description Returns data of all Sales Orgs
    * @return Map<OrgCode, Sales_Org__c>
    */
    public static Map<String, Sales_Org__c> getSalesOrgs() {
        Map<String, Sales_Org__c> aux = new Map<String, Sales_Org__c>();
        List<Sales_Org__c> listSalesOrgs = new List<Sales_Org__c>();

        listSalesOrgs = [SELECT Id, Name,SalesOrg__c,Company__c,CountryCode__c FROM Sales_Org__c];
        for (Sales_Org__c elem : listSalesOrgs) {
            aux.put(elem.SalesOrg__c, elem);
        }
        
        return aux;
    }

    /**
     * Name of the channel
     */
    public static String getChannelName(String channel) {
        switch on channel {
            when '10' { return 'Distribution';}
            when '20' { return 'Subsidiaries';}
            when '30' { return 'Group';}
            when '40' { return 'Intercompany';}
            when '50' { return 'Others';}
            when '60' { return 'Retail';}
            when '65' { return 'E-Commerce';}
            when '70' { return 'Trade';}
            when else { return 'Unknown';}
        }
    }

    public static Map<String, Sales_Org__c> getSalesOrgsMap(){
        Map<String, Sales_Org__c> returnMap = new Map<String, Sales_Org__c>();
        
        List<Sales_Org__c> salesOrgList = [SELECT Name, SalesOrg__c, Company__c, CountryCode__c FROM Sales_Org__c];
        
        for(Sales_Org__c salesOrg : salesOrgList){
            returnMap.put(salesOrg.SalesOrg__c, salesOrg);
        }
        
        return returnMap;
    }

}