public class ContactsHelper {
    @AuraEnabled
    public static Contact getContact(String id){
        try {
            return new ContactsSelector().selectById(id);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}