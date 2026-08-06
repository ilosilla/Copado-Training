/**
* @author 		Ramón Prades
* @date 		April 2021
* @group 		DataFactories   
* @description 	Creates contacts for testing purposes
*/
public  class DataFactoryContact {

    public static Boolean autoInsert = true;    

    public static Contact[] createContacts(Id accountId, Integer count) {
        Contact[] contacts = new List<Contact>();
		String random = TestUtils.generateRandomString(6);
        if(Test.isRunningTest()){
            for (Integer i = 0; i<count; i++) {
				Contact c = new Contact(LastName = 'Smith ' + random + ' #' +  i, FirstName = 'John', AccountId = accountId,
								Email='contact' + random + i + '@test.c0m');
                contacts.add(c);
            }
            if (autoInsert) {
         		insert contacts;
            }
        } 
        return contacts;                        
    }

} // DataFactoryContact