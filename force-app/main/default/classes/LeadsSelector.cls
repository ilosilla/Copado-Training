/**
* @author 		Ramón Prades
* @date 		May 2022
* @group 		Leads
* @description 	lead selector class
*/
public class LeadsSelector extends zflib_SObjectSelector {
    
    public Schema.SObjectType getSObjectType(){
        return Lead.sObjectType;
     }

     public List<Lead> selectById(Set<Id> recordIds){
        return (List<Lead>) selectSObjectsById(recordIds);
     }

     /*public List<Lead> selectByName(Set<String> names){
        fflib_QueryFactory query = newQueryFactory();
        //query.setLimit( 100 );
        //query.selectFieldSet( Opportunity.fieldsets.MyFieldset );
        query.setCondition('Name IN :names');
        query.addOrdering('Name', fflib_QueryFactory.SortOrder.ASCENDING);
        return (List<Lead>) Database.query( query.toSOQL() );
     }*/

     /*public override String getOrderBy(){
        return 'Name DESC';
     }*/
   
        
     public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            // Main info fields
            Lead.Company,
            Lead.Title,
            Lead.Salutation,
            Lead.FirstName,
            Lead.LastName,
            Lead.Website,
            Lead.Description,
            Lead.Language__c,
            Lead.AppointmentType__c,
            Lead.Close_Date__c,
            Lead.CurrencyIsoCode,
            Lead.Name,
            Lead.OwnerId,
            Lead.OwnerReason__c,
            Lead.Profile__c,
            Lead.Status,
            Lead.IsConverted,
            Lead.NextAction__c,
            Lead.IsSupportOrWarranty__c,
            Lead.Showroom__c,
            Lead.Representative__c,
            Lead.CreatedDate,

            // Address fields
            Lead.Address__c,
            Lead.City__c,
            Lead.State__c,
            Lead.Postcode__c,
            Lead.CountryCode__c,
            Lead.Email,
            Lead.Phone,
            Lead.MobilePhone,
            Lead.Other_Phone__c,
            Lead.Fax,
            Lead.Address,

            //Classification fields
            Lead.Source__c,
            Lead.Lead_origin__c,
            Lead.LeadSource,
            Lead.LeadSubtype__c,
            Lead.LeadType__c,

            // Other info fields
            Lead.AnnualRevenue,
            Lead.IndividualId,
            Lead.Industry,
            Lead.NumberOfEmployees,
            Lead.PartnerAccountId,
            Lead.Rating,
            Lead.ReferredBy__c,
            Lead.OwnerLocked__c,

            // Opportunity fields
            Lead.Operation_Type__c,
            Lead.Opportunity_Classification__c,
            Lead.Opportunity_Classification_II__c,
            Lead.Opportunity_Name__c,
            Lead.Product_Categories__c,
            Lead.Quantity_of_the_opportunity__c,

            // Reference fields-
            Lead.Account_Classification__c,
            Lead.Account_Phone__c,
            Lead.AccountId__c,
            Lead.ContactId__c,
            Lead.ExistingAccount__c,
            Lead.Dealer__c,

            // Admin fields
            Lead.RecordTypeId,
            Lead.DateCreated__c,
            Lead.CreatedById,
            Lead.LastModifiedById,
            Lead.LastTransferDate,

            // Contact permissions
            Lead.DoNotCall,
            Lead.HasOptedOutOfEmail,
            Lead.HasOptedOutOfFax,

            // External keys
            Lead.External_ID__c,
            //Lead.google_campaign_id__c,
            //Lead.google_form_id__c,
            //Lead.google_lead_id__c

            // Room Type Information Fields
            Lead.roomTypeBathroom__c,
            Lead.roomTypeBedroom__c,
            Lead.roomTypeFireplace__c,
            Lead.roomTypeFoyer__c,
            Lead.roomTypeFullHouse__c,
            Lead.roomTypeKitchen__c,
            Lead.roomTypeLaundryRoom__c,
            Lead.roomTypeLivingRoom__c,
            Lead.roomTypeOther__c,
            Lead.roomTypeOutdoorPatio__c,
            Lead.roomTypeSwimmingPool__c,
            Lead.roomTypeFilled__c
        };
     }
} // class