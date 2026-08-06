/**
* @author Ivan Losilla
* @date June 2019
* @group SalesRelationships
* @description General methods for Sales Relationship object
*/
public class SalesRelationshipUtils {
    public static Sales_Relationship__c createDefaultSalesRelations(Account acc, String reason) {
        User usr = new UsersSelector().selectById(acc.OwnerId);
        return createDefaultSalesRelations(acc,usr,reason);
    }

    public static Sales_Relationship__c createDefaultSalesRelations(Account acc, User salesRelUser, String reason) {
        Map<String, Schema.SObjectField> salesRelFieldMap = Schema.SObjectType.Sales_Relationship__c.fields.getMap();
        Sales_Relationship__c newSalesRel = new Sales_Relationship__c();                
        newSalesRel = new Sales_Relationship__c();

        for(String key: salesRelFieldMap.keySet()){
            Schema.DescribeFieldResult fieldValue = salesRelFieldMap.get(key).getDescribe();
            if(fieldValue.getDefaultValue() != null && fieldValue.isUpdateable() ){
                newSalesRel.put(key, fieldValue.getDefaultValue() );
            }
        }
        
        newSalesRel.Sales_Org__c = salesRelUser.Default_Sales_Organization__c;
        newSalesRel.Distribution_Channel__c = salesRelUser.Distribution_channel_default__c;
        newSalesRel.Sales_Office__c = salesRelUser.Sales_Office__c;
        newSalesRel.Account_Org__c = acc.Id;
        newSalesRel.Commercial__c = salesRelUser.Id;
        newSalesRel.Reason_of_creation__c = reason;
        
        if(salesRelUser.CountryCode == 'GB'){
            newSalesRel.Currency__c = 'GBP';
        } else if(salesRelUser.CountryCode == 'FR'){
            newSalesRel.Currency__c = 'EUR';
        } else if(salesRelUser.CountryCode == 'US'){
            newSalesRel.Currency__c = 'USD';
        } else if(salesRelUser.CountryCode == 'CA'){
            newSalesRel.Currency__c = 'CAD';
        } else if(salesRelUser.CountryCode == 'CH'){
            newSalesRel.Currency__c = 'CHF';
        } else if(salesRelUser.CountryCode == 'SE'){
            newSalesRel.Currency__c = 'SEK';
        } else if(salesRelUser.CountryCode == 'IL'){
            newSalesRel.Currency__c = 'ILS';
        } else if(salesRelUser.CountryCode == 'CL'){
            newSalesRel.Currency__c = 'CLP';
        } else if(salesRelUser.CountryCode == 'AU'){
            newSalesRel.Currency__c = 'AUD';
        } else if(salesRelUser.CountryCode == 'DK'){
            newSalesRel.Currency__c = 'DKK';
        }else if(salesRelUser.CountryCode == 'RD'){
            newSalesRel.Currency__c = 'DOP';
        }
        return newSalesRel;
    }

    public static Opportunity createAutomaticOpportunity(Account acc){
        
        Id oppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Automatic_Opportunity').getRecordTypeId();
        String oppName = 'AUT-OPTY-' + Date.today().year() + '-' + acc.Name;
        
        Opportunity newOpp = new Opportunity(Name = oppName, AccountId=acc.Id, StageName = 'Abierta',
                                             CloseDate = Date.today().addYears(1), RecordTypeId=oppRecordTypeId);
        System.debug('newOpp: ' + newOpp);
        
        return newOpp;
    }

    public static String getSalesRelName(Sales_Relationship__c salesRel, String countryCode){
        String codes = '[' + salesRel.Sales_Org__c + '-' + salesRel.Distribution_Channel__c + '] ';
        List<Schema.PicklistEntry> salesOrgPicklist = Sales_Relationship__c.Sales_Org__c.getDescribe().getPicklistValues();
        String salesOrgLabel = '';
        
        for(Schema.PicklistEntry pkl : salesOrgPicklist){
            if(pkl.getValue() == salesRel.Sales_Org__c){
                salesOrgLabel = pkl.getLabel();
                break;
            }
        }
        
        codes += salesOrgLabel;
        
        return codes;
    }
}