/**
* @author 		Ramón Prades
* @date 		May 2022
* @group 		ContactPointAddresses
* @description 	lead selector class
*/
public class ContactPointAddressesSelector extends zflib_SObjectSelector {
    
    public Schema.SObjectType getSObjectType(){
        return ContactPointAddress.sObjectType;
     }

     public List<ContactPointAddress> selectById(Set<Id> recordIds){
        return (List<ContactPointAddress>) selectSObjectsById(recordIds);
     }

     public List<ContactPointAddress> selectByAccount(Set<Id> accountIds){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('ParentId IN :accountIds and IsDeleted = false');
        query.addOrdering('Name', zflib_QueryFactory.SortOrder.ASCENDING);
        return (List<ContactPointAddress>) Database.query( query.toSOQL() );
     }

     public List<ContactPointAddress> selectBySAPId(Set<String> sapIds){
      zflib_QueryFactory query = newQueryFactory();
      query.setCondition('SAPId__c IN :sapIds and IsDeleted = false');
      query.addOrdering('Name', zflib_QueryFactory.SortOrder.ASCENDING);
      return (List<ContactPointAddress>) Database.query( query.toSOQL() );
   }


     /*public override String getOrderBy(){
        return 'Name DESC';
     }*/
           
     public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            ContactPointAddress.Id,
            ContactPointAddress.OwnerId,
            ContactPointAddress.IsDeleted,
            ContactPointAddress.Name,
            ContactPointAddress.RecordTypeId,
            ContactPointAddress.CreatedDate,
            ContactPointAddress.CreatedById,
            ContactPointAddress.LastModifiedDate,
            ContactPointAddress.LastModifiedById,
            ContactPointAddress.ParentId,
            ContactPointAddress.IsPrimary,
            ContactPointAddress.AddressType,
            ContactPointAddress.Street,
            ContactPointAddress.City,
            ContactPointAddress.State,
            ContactPointAddress.PostalCode,
            ContactPointAddress.Country,
            ContactPointAddress.StateCode,
            ContactPointAddress.CountryCode,
            ContactPointAddress.Latitude,
            ContactPointAddress.Longitude,
            ContactPointAddress.GeocodeAccuracy,
            ContactPointAddress.Address,
            ContactPointAddress.IsDefault,
            ContactPointAddress.SAPId__c,
            ContactPointAddress.Disabled__c,
            ContactPointAddress.EMail__c,
            ContactPointAddress.Mobile__c,
            ContactPointAddress.Phone__c       
        };     
    }
}