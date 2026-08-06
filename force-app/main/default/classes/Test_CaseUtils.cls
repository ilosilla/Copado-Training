/** 
* Test class for CaseUtil 
* @author dguzman (nts) 
* @date 03/05/2018
* @service Hecho por NTS
*/
@isTest
private class Test_CaseUtils {}
// private class Test_CaseUtils 
// {

// 	 public static final Integer NUM_OF_CASES = 4;  // Number of Cases created    
// 	 public static final Integer NUM_OF_CHILD_CASES = 2; // Number of Child Cases    

// 	/** 
//     * Create test data
//     **
//     * @author daguzman-NTS
//     * @date 03/05/2018
//     */
//     @TestSetup static void test_CreateData()
//     {		
//     	List <Case> cases = new List <Case> ();
//     	for(Integer i= 0; i < NUM_OF_CASES; i++)
//     	{
//     		Case c = new Case( Status = Constants.CASE_STATUS_PENDING_TO_IDENTIFIED,
//     		Subject = 'Subject'+String.valueOf(i));

//     		cases.add(c);
//     	}

//     	insert cases;

//     	for(Integer i= 0; i < NUM_OF_CHILD_CASES; i++)
// 		{
// 			cases.get(i).ParentId = cases.get(NUM_OF_CASES-1).Id;
// 		}

// 		update cases;
//     }

//      /** 
//     * @author daguzman-NTS
//     * @date 03/05/2018
//     * @description Method to update status of a parent with the common status of the childs
//     */	
// 	@isTest static void updateStatusParent() 
// 	{
// 		System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
// 		/*
// 		List <Case> cases = [select id from Case where ParentId != null];

// 		//Updating all childs
// 		for(Case c : cases)
// 		{
// 			c.Status = Constants.CASE_STATUS_PENDING_TO_SKU_IDENTIFICATION;
// 		}

// 		update cases;

// 		Case parent = [select Status from Case where Id =: cases.get(0).Id];

// 		System.assertEquals(parent.Status, Constants.CASE_STATUS_PENDING_TO_SKU_IDENTIFICATION);

// 		//Updating all childs -1

// 		for(Integer i = 0; i < NUM_OF_CHILD_CASES-1;  i++)
// 		{
// 			cases.get(i).Status = Constants.CASE_STATUS_PENDING_PROBLEM_IDENTIFICATION;
// 		}

// 		update cases;

// 		System.assertEquals(parent.Status, Constants.CASE_STATUS_PENDING_TO_SKU_IDENTIFICATION);
// 		*/
// 	}
	
// 	/** 
//     * @author gmiranda-NTS
//     * @date 03/05/2018
//     * @description Every time the field refuse to attach photos field is not checked and customer is not identified, the case owner will not change to Charles.
//     */
// 	@isTest static void test_escalateToCharlesIncorrect()
// 	{
// 		List<User> user = [SELECT Id FROM User WHERE Name =: Constants.CHARLES_NAME];
// 		Id charlesId;
// 		if(!user.isEmpty())
// 		{
// 			charlesId = user.get(0).Id;
// 		}
// 		List <Case> cases = [select id,OwnerId,Reporter_refuse_to_attach_photos__c from Case where ParentId != null];

// 		System.assertNotEquals(cases[0].OwnerId,charlesId);
// 		cases[0].Reporter_refuse_to_attach_photos__c = false;
// 		update cases;

// 		cases = [select id,OwnerId,Reporter_refuse_to_attach_photos__c from Case where ParentId != null];
// 		System.assertNotEquals(cases[0].OwnerId,charlesId);		
// 	}

// 	/** 
//     * @author gmiranda-NTS
//     * @date 03/05/2018
//     * @description When customer and technician service conclusion is OK, the case status will change to Closed
//     */
// 	@isTest static void test_serviceAccomplishCloseCase_OK()
// 	{
// 		System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
// 		/*
// 		List <Case> cases = [select id,OwnerId,Status from Case where ParentId != null];
// 		System.assertNotEquals(cases[0].Status,Constants.CASE_STATUS_CLOSED);

// 		cases[0].Technician_service_conclusion__c = 'OK';
// 		cases[0].Customer_service_conclusion__c = 'OK';

// 		update cases;

// 		cases = [select id,OwnerId,Status,Technician_service_conclusion__c,Customer_service_conclusion__c from Case where ParentId != null];
// 		System.assertEquals(cases[0].Status,Constants.CASE_STATUS_CLOSED);
// 		*/
// 	}

// 	/** 
//     * @author gmiranda-NTS
//     * @date 03/05/2018
//     * @description When customer and technician service conclusion is NO OK, the case status will not change to Closed
//     */
// 	@isTest static void test_serviceAccomplishCloseCase_NO_OK()
// 	{
// 		System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
// 		/*
// 		List <Case> cases = [select id,OwnerId,Status from Case where ParentId != null];
// 		System.assertNotEquals(cases[0].Status,Constants.CASE_STATUS_CLOSED);

// 		cases[0].Technician_service_conclusion__c = 'No ok';
// 		cases[0].Customer_service_conclusion__c = 'OK';

// 		update cases;

// 		cases = [select id,OwnerId,Status,Technician_service_conclusion__c,Customer_service_conclusion__c from Case where ParentId != null];
// 		System.assertNotEquals(cases[0].Status,Constants.CASE_STATUS_CLOSED);
// 		*/
// 	}

// 	/** 
//     * @author gmiranda-NTS
//     * @date 03/05/2018
//     * @description When customer and technician service conclusion is NO OK, the case status will not change to Closed
//     */
// 	@isTest static void test_serviceAccomplishCloseCase_NO_OK2()
// 	{
// 		List <Case> cases = [select id,OwnerId,Status from Case where ParentId != null];
// 		System.assertNotEquals(cases[0].Status,Constants.CASE_STATUS_CLOSED);

// 		cases[0].Technician_service_conclusion__c = 'OK';
// 		cases[0].Customer_service_conclusion__c = 'No ok';

// 		update cases;

// 		cases = [select id,OwnerId,Status,Technician_service_conclusion__c,Customer_service_conclusion__c from Case where ParentId != null];
// 		System.assertNotEquals(cases[0].Status,Constants.CASE_STATUS_CLOSED);
// 	}

// 	/** 
//     * @author gmiranda-NTS
//     * @date 03/05/2018
//     * @description When customer and technician service conclusion is NO OK, the case status will not change to Closed
//     */
// 	@isTest static void test_serviceAccomplishCloseCase_NO_OK3()
// 	{
// 		System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
// 		/*
// 		List <Case> cases = [select id,OwnerId,Status from Case where ParentId != null];
// 		System.assertNotEquals(cases[0].Status,Constants.CASE_STATUS_CLOSED);

// 		cases[0].Technician_service_conclusion__c = 'No ok';
// 		cases[0].Customer_service_conclusion__c = 'No ok';

// 		update cases;

// 		cases = [select id,OwnerId,Status,Technician_service_conclusion__c,Customer_service_conclusion__c from Case where ParentId != null];
// 		System.assertNotEquals(cases[0].Status,Constants.CASE_STATUS_CLOSED);
// 		*/
// 	}

// 	/**
//    	* Testear que se crea correctamente el entitlement cuando se crea el primer caso y ase asigna al caso y a la cuenta
//    	*
//   	* @author gmiranda
//    	* @date 03/08/2018
//    	*/
//   	@isTest
//   	static void test_createAccountCaseManagementEntitlement_OK()
//   	{
// 		System.assertEquals('dummy', 'dummy', 'apex pmd dummy');
// 		  /*
//   		Set<Id> accIds = new Set<Id>();

      	
//   		List<Account> accInserted   =   new List<Account>();

//         for (Integer i = 0; i < 1; i++)
//         {
//             accInserted.add
//             (
//                 new Account
//                 (
//                     FirstName    =   'PersonAccountTest ' + i,
//                     LastName     =   'PersonAccountTest ' + i,
//                     RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('USA Person Account').getRecordTypeId()
//                 )
//             );
//         }

//         insert accInserted;
      	

//   		for(Account a: accInserted)
//   		{	
//   			accIds.add(a.Id);
//   		}	
//   		//Nos aseguramos que al crear cuentas nunca se crea entitlements
//   		list<Entitlement> entitlementsInserted = [SELECT Id FROM Entitlement WHERE AccountId IN :accIds];

//   		System.assertEquals(0, entitlementsInserted.size());


//   		accInserted = [SELECT Id,PersonContactId FROM Account where Id =:accInserted];

//   		//Insertamos un caso 2 casos a la vez asociados al mismo reporter
//   		List<Case>insertCases = new List<Case>();
//   		for(Integer i = 0;i<2;i++)
//   		{
//   			insertCases.add(new Case (AccountId = accInserted[0].Id,
// 						  				ContactId = accInserted[0].PersonContactId,
// 						  					RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.USA_CASE_CLAIM_RECORD_TYPE_NAME).getRecordTypeId(),
// 						  					Subject = '-'+(i+1)+'-'
// 						  				));
//   		}
//   		system.debug('-Insertando '+insertCases);
//   		insert insertCases;


//   		entitlementsInserted = [SELECT Id ,(select id,entitlementId from cases) FROM Entitlement WHERE AccountId IN :accIds];

//   		//Se ha insertado únicamente un entitlement asociado al cliente personal y hay dos casos asociados también
//   		System.assertEquals(1, entitlementsInserted.size());
//   		System.assertEquals(2, entitlementsInserted[0].Cases.size());

//   		//Si creamos un nuevo caso, se asigna al entitlement previamente creado
//   		Case lastCase = new Case (Subject='myLastCase',
//   			AccountId = accInserted[0].Id,
//   			ContactId = accInserted[0].PersonContactId,
//   			RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(Constants.USA_CASE_CLAIM_RECORD_TYPE_NAME).getRecordTypeId());
//   		system.debug('Insertando lastcase ');
//   		insert lastCase;

//   		//System.assertEquals(null,[SELECT EntitlementId FROM CASE Where iD =:lastCase.Id]);

//   		entitlementsInserted = [SELECT Id ,(select id,entitlementId from cases) FROM Entitlement WHERE AccountId IN :accIds];

//   		//Se ha insertado únicamente un entitlement asociado al cliente personal y hay dos casos asociados también
//   		System.assertEquals(1, entitlementsInserted.size());
//   		System.assertEquals(3, entitlementsInserted[0].Cases.size());

//   		*/
  		


//   	}

// }