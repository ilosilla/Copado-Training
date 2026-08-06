public class User_TestDataFactory {

    // Checkear si existen master relations.
    // Si no existen insertarlas.
    
    // Que todos los otros metodos llamen primero al metodo insert_MasterRelations.
    
    public static void insert_MasterRelations(){
        List<Master_relations__c> masterRels = DataFactoryMasterRelations.createMasterRelations();
        
        if( !masterRels.isEmpty() ){
            Insert masterRels;
        }
    }
    
    public static List<User> createUsers(Integer numberOfUsers, List<String> localeSidKeyList){
        insert_MasterRelations();
        
        List<User> userList = new List<User>();
        Profile p = [SELECT Id FROM Profile WHERE Name =: Label.System_Administrator];
        
        for(Integer i=0; i<localeSidKeyList.size(); i++){
            User userToAdd = new User(Alias = 'tAlias' + i, 
                                      Email ='PorcelanosatestUser' + i + '@testOrg.com',
                                      EmailEncodingKey ='ISO-8859-1', 
                                      LastName ='TestLastNameR' + i, 
                                      ProfileId = p.Id,
                                      UserName = 'porcelanosaTestUser' + i + '@testOrg' + i + '.com', 
                                      Sales_Office__c = '2541',
                                      Sales_Org__c = OrganizationCommons.ORG_NORTH_WEST + ';' + OrganizationCommons.ORG_YORKSHIRE,
                                      Default_Sales_Organization__c = OrganizationCommons.ORG_NORTH_WEST,
                                      Distribution_Channel__c = '60;70', 
                                    Distribution_channel_default__c = '70',
                                      Team_Manager__c = TRUE);
            
            userToAdd.LocaleSidKey = localeSidKeyList[i];
            
            if(localeSidKeyList[i] == 'fr_FR') {
                userToAdd.LanguageLocaleKey = 'fr';
                userToAdd.CountryCode = 'FR';
                userToAdd.Country = 'France';
            }
            else if(localeSidKeyList[i] == 'es_ES') {
                userToAdd.LanguageLocaleKey = 'es';
                userToAdd.CountryCode = 'ES';
                userToAdd.Country = 'Spain';
            }
            else {
                userToAdd.LanguageLocaleKey = 'en_US';
                userToAdd.CountryCode = 'GB';
                userToAdd.Country = 'United Kingdom';
            }

            userToAdd.TimeZoneSidKey= 'Europe/Paris';

            userToAdd.Does_this_position_have_a_sales_budget__c = Math.mod(i,2) == 0 ? 'Si' : 'No';
            
            userList.add(userToAdd);
            
        }

        return userList;
        
    }

    public static List<User> createUsersNoAdmin(Integer numberOfUsers, List<String> localeSidKeyList){
        insert_MasterRelations();
        
        List<User> userList = new List<User>();
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard Retail'];


        for(Integer i=0; i<localeSidKeyList.size(); i++){
            
            User userToAdd = new User(Alias = 'tAlias' + i, 
                                      Email ='testUser' + i + '@testOrgNoAdmin.com',
                                      EmailEncodingKey ='ISO-8859-1', 
                                      LastName ='TestLastName' + i, 
                                      ProfileId = p.Id,
                                      UserName = 'testUserNoAdmin' + i + '@testOrgNoAdmin' + i + '.com', 
                                      Sales_Office__c = '2541',
                                      Sales_Org__c = OrganizationCommons.ORG_NORTH_WEST + ';' + OrganizationCommons.ORG_YORKSHIRE,
                                      Default_Sales_Organization__c = OrganizationCommons.ORG_NORTH_WEST,
                                      Distribution_Channel__c = '60;70', 
                                     Distribution_channel_default__c = '70',
                                      Team_Manager__c = TRUE);
            
            userToAdd.LocaleSidKey = localeSidKeyList[i];
            
            if(localeSidKeyList[i] == 'fr_FR') {
                userToAdd.LanguageLocaleKey = 'fr';
                userToAdd.CountryCode = 'FR';
                userToAdd.Country = 'France';
            }
            else if(localeSidKeyList[i] == 'es_ES') {
                userToAdd.LanguageLocaleKey = 'es';
                userToAdd.CountryCode = 'ES';
                userToAdd.Country = 'Spain';
            }
            else {
                userToAdd.LanguageLocaleKey = 'en_US';
                userToAdd.CountryCode = 'GB';
                userToAdd.Country = 'United Kingdom';
            }

            userToAdd.TimeZoneSidKey= 'Europe/Paris';

            userToAdd.Does_this_position_have_a_sales_budget__c = Math.mod(i,2) == 0 ? 'Si' : 'No';
            
            userList.add(userToAdd);
            
        }

        return userList;
        
    }
    
    public static List<User> createUsers(Integer records, Map<String, Object> fieldsToAdd){
        insert_MasterRelations();
        
        List<User> userList = new List<User>();
        Profile p = [SELECT Id FROM Profile WHERE Name =: Label.System_Administrator];
        
        // Check if there are no user already created
        Integer alreadyCreated = [SELECT COUNT() FROM User WHERE UserName LIKE '%@testOrg.com'];
        Integer newIndex;
        for(Integer i=0; i<records; i++){
            
            newIndex = i + alreadyCreated;
            
            User userToAdd = new User(Alias = 'tAlias' + newIndex, 
                                      Email ='testUser' + newIndex + '@testOrg.com',
                                      EmailEncodingKey ='ISO-8859-1', 
                                      LastName ='TestLastName' + newIndex, 
                                      ProfileId = p.Id,
                                      UserName = 'testUserNamee' + newIndex + '@testOrg.com', 
                                      Sales_Office__c = '2541',
                                      Sales_Org__c = OrganizationCommons.ORG_NORTH_WEST + ';' + OrganizationCommons.ORG_YORKSHIRE,
                                      Default_Sales_Organization__c = OrganizationCommons.ORG_NORTH_WEST,
                                      Distribution_Channel__c = '60;70', 
                                      Distribution_channel_default__c = '70',
                                      Team_Manager__c = TRUE,
                                      TimeZoneSidKey= 'Europe/Paris');
            
            userToAdd.Does_this_position_have_a_sales_budget__c = Math.mod(newIndex,2) == 0 ? 'Si' : 'No';
            
            for(String fieldName: fieldsToAdd.keySet()){
                
                if(fieldName == 'LocaleSidKey'){
                    
                    userToAdd.put(fieldName, fieldsToAdd.get(fieldName));
                    
                    if(fieldsToAdd.get(fieldName) == 'fr_FR') {
                        userToAdd.put('LanguageLocaleKey', 'fr');
                        userToAdd.put('CountryCode', 'FR');
                        userToAdd.put('Country', 'France');
                    }
                    
                    else if(fieldsToAdd.get(fieldName) == 'es_ES') {
                        userToAdd.put('LanguageLocaleKey', 'es');
                        userToAdd.put('CountryCode', 'ES');
                        userToAdd.put('Country', 'Spain');
                    }
                    
                    else {
                        userToAdd.put('LanguageLocaleKey', 'en_US');
                        userToAdd.put('CountryCode', 'GB');
                        userToAdd.put('Country', 'United Kingdom');
                    }
                    
                }
                
                else {
                    userToAdd.put(fieldName, fieldsToAdd.get(fieldName));
                }
                
            }
            
            userList.add(userToAdd);
            
        }        
        
        return userList;
        
    }

}