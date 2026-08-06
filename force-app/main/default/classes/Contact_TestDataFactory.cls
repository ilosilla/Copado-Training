@isTest
public class Contact_TestDataFactory {
    
    public static List<Contact> createContacts(Integer numRecords, List<Map<String, Object>> fieldsToAdd){
        
        List<Contact> contactList = new List<Contact>();
        
        for(Integer i=0; i<numRecords; i++){
            
            Contact contact = new Contact(LastName = 'TestLastName' + i, FirstName = 'TestFirstName' + i);
            
            for(String fieldName: fieldsToAdd[i].keySet()){
                
                contact.put(fieldName, fieldsToAdd[i].get(fieldName));
                
            }
            
            contactList.add(contact);
            
        }
        
        return contactList;
        
    }
    
}