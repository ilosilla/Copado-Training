/**
* @author 		Ivan Losilla
* @date 		July 2022
* @group 		SalesRelationships
* @description 	sales relationship selector class
*/

public class SalesRelationshipsSelector extends zflib_SObjectSelector {

    public Schema.SObjectType getSObjectType(){
        return Sales_Relationship__c.sObjectType;
    }

    public List<Sales_Relationship__c> selectById(Set<Id> recordIds){
        return (List<Sales_Relationship__c>) selectSObjectsById(recordIds);
    }

    public List<Sales_Relationship__c> selectByAccountId(Set<Id> accountIds){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('Account_Org__c IN :accountIds');
        return (List<Sales_Relationship__c>) Database.query( query.toSOQL() );
    }
   
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {

            // Main info fields
            Sales_Relationship__c.Id,
            Sales_Relationship__c.CurrencyIsoCode,
            Sales_Relationship__c.Name,
            Sales_Relationship__c.Sales_Org__c,
            Sales_Relationship__c.Distribution_Channel__c,
            Sales_Relationship__c.Sales_Office__c,
            Sales_Relationship__c.B2BEnabled__c,
            Sales_Relationship__c.Bzirk__c,
            
            // Other info fields
            Sales_Relationship__c.Business_Unit__c,
            Sales_Relationship__c.Commission_Agent__c,
            Sales_Relationship__c.Currency__c,
            Sales_Relationship__c.Custom_Id__c,
            Sales_Relationship__c.Email__c,
            Sales_Relationship__c.Error_Message__c,
            Sales_Relationship__c.Is_Locked__c,
            Sales_Relationship__c.Locked__c,
            Sales_Relationship__c.Notes__c,
            Sales_Relationship__c.Phone__c,
            Sales_Relationship__c.Reason_of_creation__c,
            Sales_Relationship__c.Relationship__c,
            Sales_Relationship__c.Sap_Status__c,
            
            // Reference fields
            Sales_Relationship__c.Account_Org__c,
            Sales_Relationship__c.Commercial__c,
            
            // Admin fields
            Sales_Relationship__c.RecordTypeId,
            Sales_Relationship__c.CreatedById,
            Sales_Relationship__c.CreatedDate,
            Sales_Relationship__c.LastModifiedById,
            Sales_Relationship__c.LastModifiedDate,
            Sales_Relationship__c.LastViewedDate,

            // External keys
            Sales_Relationship__c.SAP_Id__c
        };
    }
}