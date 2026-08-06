/**
* @author 		Ivan Losilla
* @date 		July 2022
* @group 		EmailMessages
* @description 	emails selector class
*/
public class EmailMessagesSelector extends zflib_SObjectSelector  {
    public Schema.SObjectType getSObjectType(){
        return EmailMessage.sObjectType;
    }

    public List<EmailMessage> selectById(Set<Id> recordIds){
        return (List<EmailMessage>) selectSObjectsById(recordIds);
    }

    public EmailMessage selectById(Id recordId){
        List<EmailMessage> listEmails = (List<EmailMessage>) selectSObjectsById(new Set<Id>{recordId});
        if (listEmails.size() == 1) {
            return listEmails[0];
        }
        return null;
    }
   
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            
            // Main info fields
            EmailMessage.Id,
            EmailMessage.BccAddress,
            EmailMessage.CcAddress,
            EmailMessage.FromAddress,
            EmailMessage.FromName,
            EmailMessage.Subject,
            EmailMessage.RelatedToId,
            EmailMessage.ActivityId,

            //Classification fields
            EmailMessage.HasAttachment,
            EmailMessage.Status,

            // Admin fields
            EmailMessage.CreatedById,
            EmailMessage.CreatedDate
        };
    }
}