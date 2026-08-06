/**
* @author 		Ivan Losilla
* @date 		June 2022
* @group 		Users
* @description 	users selector class
*/
public class UsersSelector extends zflib_SObjectSelector  {
    public Schema.SObjectType getSObjectType(){
        return User.sObjectType;
    }

    public List<User> selectById(Set<Id> recordIds){
        return (List<User>) selectSObjectsById(recordIds);
    }

    public User selectById(Id recordId){
        List<User> listUsers = (List<User>) selectSObjectsById(new Set<Id>{recordId});
        if (listUsers.size() == 1) {
            return listUsers[0];
        }
        return null;
    }

    public List<User> selectByRepCode(Set<String> repCodes) {
        return Database.query(newQueryFactory().setCondition('kunnr__c in :repCodes').toSOQL());
    } // selectByRepCode
   
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            
            // Main info fields
            User.Id,
            User.Username,
            User.FirstName,
            User.LastName,
            User.Name,
            User.LanguageLocaleKey,
            User.TimeZoneSidKey,
            User.Phone,
            User.MobilePhone,
            User.Email,
            
            //Classification fields
            User.UserRoleId,
            User.UserType,
            User.ProfileId,
            User.Commercial_Type__c,
            User.Es_Comisionista__c,
            User.Does_this_position_have_a_sales_budget__c,
            
            // Other info fields
            User.Default_Sales_Organization__c,
            User.Distribution_channel_default__c,
            User.Distribution_channel__c,
            User.Sales_Office__c,
            User.Sales_Org__c,
            User.Appointment__c,
            User.kunnr__c,
            User.Countries__c,
            User.SAP_Pass__c,
            User.SAP_User__c,
            
            // Address fields
            User.CountryCode,

            // Admin fields
            User.CreatedById,
            User.CreatedDate,
            User.IsActive,
            User.Execution_Context__c,
            User.LastLoginDate
        };
    }
}