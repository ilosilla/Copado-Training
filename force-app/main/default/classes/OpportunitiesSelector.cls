/**
* @author 		Ivan Losilla
* @date 		June 2022
* @group 		Opportunities
* @description 	opportunities selector class
*/
public class OpportunitiesSelector extends zflib_SObjectSelector  {
    public Schema.SObjectType getSObjectType(){
        return Opportunity.sObjectType;
    }

    public List<Opportunity> selectById(Set<Id> recordIds){
        return (List<Opportunity>) selectSObjectsById(recordIds);
    }

    public List<Opportunity> selectByIdWithOwner(Set<Id> recordIds){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('Id IN :recordIds');
        query.selectField('Owner.Execution_Context__c');
        return (List<Opportunity>) Database.query( query.toSOQL() );
    }

    public Opportunity selectById(Id recordId){
        List<Opportunity> opps = selectById(new Set<Id>{recordId});
        if (opps.size() == 1) {
            return opps[0];
        }
        return null;
    }
   
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {

            // Main info fields
            Opportunity.Id,
            Opportunity.Name,
            Opportunity.StageName,
            Opportunity.Amount,
            Opportunity.Amount_custom__c,
            Opportunity.CurrencyIsoCode,
            Opportunity.Currency__c,
            Opportunity.Description,
            Opportunity.Fiscal,
            Opportunity.FiscalQuarter,
            Opportunity.FiscalYear,
            Opportunity.Probability,
            
            //Classification fields
            Opportunity.Type,
            Opportunity.IsClosed,
            Opportunity.IsDeleted,
            Opportunity.IsWon,
            Opportunity.ecommerce__c,
            Opportunity.Operation_Type__c,
            Opportunity.Opportunity_Classification_II__c,
            Opportunity.Opportunity_Classification__c,

            // Other info fields
            Opportunity.LeadSource,
            Opportunity.NextStep,
            Opportunity.HasOpenActivity,
            Opportunity.HasOpportunityLineItem,
            Opportunity.HasOverdueTask,
            Opportunity.Activity_Level__c,
            Opportunity.Activity__c,
            Opportunity.Appointment_Date__c,
            Opportunity.Out_of_territory__c,
            Opportunity.Solicitud_Cita_En_Tienda__c,
            Opportunity.Sales_Org__c,
            Opportunity.Dist_Channel__c,
            Opportunity.SalesProgram__c,
            
            // Address fields
            Opportunity.State__c,
            Opportunity.Address__c,
            Opportunity.City__c,
            Opportunity.countryCode__c,
            Opportunity.Postcode__c,

            // Reference fields
            Opportunity.AccountId,
            Opportunity.Pricebook2Id,
            Opportunity.ContactId__c,

            // Admin fields
            Opportunity.RecordTypeId,
            Opportunity.OwnerId,
            Opportunity.CloseDate,
            Opportunity.CreatedById,
            Opportunity.CreatedDate,
            Opportunity.LastActivityDate,
            Opportunity.LastModifiedById,
            Opportunity.LastModifiedDate,
            Opportunity.Last_Activity_Date__c,
            Opportunity.LastEventDateTime__c,
            Opportunity.LastEmailDateTime__c,
            Opportunity.LastOrderDateTime__c,
            Opportunity.LastQuoteDateTime__c,

            // External keys
            Opportunity.SAP_Order__c,
            Opportunity.Related_Opportunity__c,

            // Counter Fields
            Opportunity.Number_of_Actors__c,
            Opportunity.Number_Of_Instalments__c,
            Opportunity.numberOfProducts__c,

            // Room Type Information Fields
            Opportunity.roomTypeBathroom__c,
            Opportunity.roomTypeBedroom__c,
            Opportunity.roomTypeFireplace__c,
            Opportunity.roomTypeFoyer__c,
            Opportunity.roomTypeFullHouse__c,
            Opportunity.roomTypeKitchen__c,
            Opportunity.roomTypeLaundryRoom__c,
            Opportunity.roomTypeLivingRoom__c,
            Opportunity.roomTypeOther__c,
            Opportunity.roomTypeOutdoorPatio__c,
            Opportunity.roomTypeSwimmingPool__c,
            Opportunity.roomTypeFilled__c
        };
    }
}