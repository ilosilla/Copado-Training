/**
 * @author          Ramón Prades
 * @date            November 2020
 * @description     Creates organization structures for testing
 * @group           Data Factories
 */
@SuppressWarnings('PMD.ExcessiveParameterList')
public without sharing class DataFactoryOrganization {

    public static void createData() {        
        if (!Test.isRunningTest()) {
            return;
        }

        List<Company__c> cs = [select Id from Company__c];
        if (cs.size() > 0) {
            return;
        }
        List<Company__c> companies = new  List<Company__c>();
        companies.add(createCompany(OrganizationCommons.SOC_EUROCERAMIQUE, 'EUROCERAMIQUE SARL','FR'));
        companies.add(createCompany(OrganizationCommons.SOC_PIDF, 'PORCELANOSA PARIS IDF','FR'));
        companies.add(createCompany(OrganizationCommons.SOC_SOUTH_EAST, 'PORCELANOSA SOUTHEAST','GB'));
        companies.add(createCompany(OrganizationCommons.SOC_NORTH_WEST, 'PORCELANOSA NORTHWEST','GB'));
        companies.add(createCompany('610', 'PORCELANOSA USA','US'));
    
        List<Sales_Org__c> orgs = new List<Sales_Org__c>();
        orgs.add(createOrg(OrganizationCommons.ORG_AZURCERAMIQUE, 'Azurceramique', 'FR', OrganizationCommons.SOC_EUROCERAMIQUE));
        orgs.add(createOrg(OrganizationCommons.ORG_LORCERAM, 'Lorceram', 'FR', OrganizationCommons.SOC_EUROCERAMIQUE));
        orgs.add(createOrg(OrganizationCommons.ORG_EUROCERAMIQUE, 'Euroceramique', 'FR', OrganizationCommons.SOC_EUROCERAMIQUE));
        orgs.add(createOrg(OrganizationCommons.ORG_PIDF, 'Porce. Paris IDF', 'FR', OrganizationCommons.SOC_PIDF));
        orgs.add(createOrg(OrganizationCommons.ORG_SOUTH_EAST, 'Porce. South East', 'GB', OrganizationCommons.SOC_SOUTH_EAST));
        orgs.add(createOrg(OrganizationCommons.ORG_NORTH_WEST, 'Porce. North West', 'GB', OrganizationCommons.SOC_NORTH_WEST));
        orgs.add(createOrg(OrganizationCommons.ORG_NEW_YORK, 'PORCELANOSA NEW YORK', 'US', '610'));


        List<Master_relations__c> relations = new List<Master_relations__c>();
        relations.add(createRelation(OrganizationCommons.ORG_AZURCERAMIQUE, 'Azurceramique', '60', 'Retail', '3015', 'Office Azur'));
        relations.add(createRelation(OrganizationCommons.ORG_PIDF, 'Paris', '60', 'Retail', '3035', 'Office paris'));
        relations.add(createRelation(OrganizationCommons.ORG_SOUTH_EAST, 'Londres', '60', 'Retail', '2552', 'Office 2552'));
        relations.add(createRelation(OrganizationCommons.ORG_SOUTH_EAST, 'Londres', '60', 'Retail', '2558', 'Office 2558'));
        relations.add(createRelation(OrganizationCommons.ORG_NORTH_WEST, 'Warrington', '60', 'Retail', '2541', 'Office 2541'));
        relations.add(createRelation(OrganizationCommons.ORG_AZURCERAMIQUE, 'Azurceramique', '70', 'Trade', '3015', 'Office Azur'));
        relations.add(createRelation(OrganizationCommons.ORG_PIDF, 'Paris', '70', 'Trade', '3035', 'Office paris'));
        relations.add(createRelation(OrganizationCommons.ORG_SOUTH_EAST, 'Londres', '70', 'Trade', '2552', 'Office 2552'));
        relations.add(createRelation(OrganizationCommons.ORG_SOUTH_EAST, 'Londres', '70', 'Retail', '2558', 'Office 2558'));
        relations.add(createRelation(OrganizationCommons.ORG_NORTH_WEST, 'Warrington', '70', 'Trade', '2541', 'Office 2541'));
        relations.add(createRelation(OrganizationCommons.ORG_NEW_YORK, 'Ramsey', '70', 'Trade', '6001', 'Office 6001'));
        relations.add(createRelation(OrganizationCommons.ORG_NEW_YORK, 'Manhattan', '70', 'Trade', '6002', 'Office 6002'));
        relations.add(createRelation(OrganizationCommons.ORG_NEW_YORK, 'Paramus', '70', 'Trade', '6003', 'Office 6003'));

        PostCodeObjects__c pc = new PostCodeObjects__c();
        pc.objectId__c = '2558';
        pc.postCode__c = 'W';
        pc.objectType__c = 'SALES_OFFICE';
        pc.country__c = 'GB';
        insert pc;

        insert companies;
        insert orgs;
        insert relations;

        List<Sales_Org__c> salesOrgs = [Select Id, SalesOrg__c from Sales_Org__c];
        Integer i = 1;
        List<Sales_Office__c> offices = new List<Sales_Office__c>();
        for (Sales_Org__c salesOrg : salesOrgs) {
            offices.add(createSalesOffice('303' + i, 'Office Paris ' + i, 'FR', salesOrg.SalesOrg__c, salesOrg.Id));
            offices.add(createSalesOffice('503' + i, 'Office London ' + i, 'GB', salesOrg.SalesOrg__c, salesOrg.Id));
            offices.add(createSalesOffice('255' + i, 'Office New York ' + i, 'US', salesOrg.SalesOrg__c, salesOrg.Id));
            i++;
        }

        insert offices;

    } // createData


    private static Company__c createCompany(String code, String name, String country) {
        return new Company__c(CompanyCode__c = code, Name = name, Country__c = country);
    } // createCompany

    private static Sales_Org__c createOrg(String code, String name, String country, String company) {
        String curr = 'EUR';
        Decimal tax = 0;
        if (country == 'US') {
            curr = 'USD';
        } else if (country == 'GB') {
            curr = 'GBP';
            tax = 20;
        }
        return new Sales_Org__c(SalesOrg__c = code, Name = name, CountryCode__c = country, Company__c = company, SAP_Id__c = code, CurrencyIsoCode = curr, TaxPercent__c = tax);
    } // createCompany

    
    private static Sales_Office__c createSalesOffice(String code, String name, String countryCode, String company, String salesOrgId) {
        return new Sales_Office__c(SalesOffice__c = code, Name = name, CountryCode__c = countryCode, Company__c = company, SalesOrg__c = salesOrgId);
    } // createSalesOffice
    

    private static Master_relations__c createRelation(String org, String name, String channel, String channelName, String office, String officeName) {
        return new Master_relations__c(
            SalesOrg_name__c =name , SalesOrg_code__c = org, 
            DistributionChannel_name__c = channelName, DistributionChannel_code__c = channel, 
            SalesOffice_code__c = office, SalesOffice_name__c = officeName,
             Sector__c = '10');
    }

} // class