@isTest
public class Lead_TestDataFactory {
    public static List<Lead> createLeads(Integer records, Map<String, Object> fieldsToAdd){
        
        List<Lead> leadList = new List<Lead>();
        
        Integer alreadyCreated = [SELECT COUNT() FROM Lead WHERE Company LIKE '%testLead'];
        Integer newIndex;
        
        for(Integer i=0; i<records; i++){
            
            newIndex = i + alreadyCreated;
            
            Lead leadToAdd = new Lead(Company = newIndex+'testLead', Status = 'New', Opportunity_Name__c = 'OppName'+newIndex, 
                                      Operation_Type__c = 'Refurbishment', Close_Date__c = Date.today(),
                                      Opportunity_Classification__c = 'Commercial', Opportunity_Classification_II__c = 'Car dealership',
                                      Country__c = 'United Kingdom', City__c = 'Bristol', Address__c = 'Street Name '+newIndex, Postcode__c = 'BS1 3NZ', 
                                      Account_Classification__c = 'Architectural firm', Business_Email__c = 'mail'+newIndex+'@mail.com',
                                      CountryCode = 'GB', Street = 'Street Name '+newIndex, City = 'Bristol', PostalCode = 'BS1 3NZ',
                                      StateCode = 'AB', LastName = 'Contact Last Name ' + newIndex, FirstName = 'Contact First Name ' + newIndex, Salutation = 'Mr.');
            
            for(String fieldName: fieldsToAdd.keySet()){
                if(fieldName == 'Company'){
                    leadToAdd.put(fieldName, (String) fieldsToAdd.get(fieldName));
                }
            }
            
            leadList.add(leadToAdd);
            
        }        
        
        return leadList;
    }
}