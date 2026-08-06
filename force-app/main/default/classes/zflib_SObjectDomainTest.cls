/**
 * WARNING:
 * This class is the adaptation to Porcelanosa of the Apex Commons Framework.
 * The framework has been adapted to pass the tests because of our required fields and
 * validation rules.
 * Only the classes we need have been adapted and are those prefixed with "zflib".
 * Ivan, June 2022
 * 
 * Copyright (c), FinancialForce.com, inc
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, 
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice, 
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice, 
 *      this list of conditions and the following disclaimer in the documentation 
 *      and/or other materials provided with the distribution.
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors 
 *      may be used to endorse or promote products derived from this software without 
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

@IsTest
private with sharing class zflib_SObjectDomainTest 
{	
	@IsTest
	private static void testValidationWithoutDML()
	{
		zflib_SObjectDomain.TestSObjectDomain opps = new zflib_SObjectDomain.TestSObjectDomain(new Opportunity[] { new Opportunity ( Name = 'Test', Type = 'Existing Account' ) } );
		opps.onValidate();
		System.assertEquals(1, zflib_SObjectDomain.Errors.getAll().size());		
		System.assertEquals('You must provide an Account for Opportunities for existing Customers.', zflib_SObjectDomain.Errors.getAll()[0].message);
		System.assertEquals(Opportunity.AccountId, ((zflib_SObjectDomain.FieldError)zflib_SObjectDomain.Errors.getAll()[0]).field); 		

		opps = new zflib_SObjectDomain.TestSObjectDomain(new SObject[] { new Opportunity ( Name = 'Test', Type = 'Existing Account' ) }, Opportunity.SObjectType );
		System.assertEquals(1, zflib_SObjectDomain.Errors.getAll().size());		
		System.assertEquals('You must provide an Account for Opportunities for existing Customers.', zflib_SObjectDomain.Errors.getAll()[0].message);
		System.assertEquals(Opportunity.AccountId, ((zflib_SObjectDomain.FieldError)zflib_SObjectDomain.Errors.getAll()[0]).field);		
	}
	
	@IsTest
	private static void testInsertValidationFailedWithoutDML()
	{
		Opportunity opp = new Opportunity ( Name = 'Test', Type = 'Existing Account' );
		System.assertEquals(false, zflib_SObjectDomain.Test.Database.hasRecords());
		zflib_SObjectDomain.Test.Database.onInsert(new Opportunity[] { opp } );		
		System.assertEquals(true, zflib_SObjectDomain.Test.Database.hasRecords());
		zflib_SObjectDomain.triggerHandler(zflib_SObjectDomain.TestSObjectDomainConstructor.class);		
		System.assertEquals(1, zflib_SObjectDomain.Errors.getAll().size());		
		System.assertEquals('You must provide an Account for Opportunities for existing Customers.', zflib_SObjectDomain.Errors.getAll()[0].message);
		System.assertEquals(Opportunity.AccountId, ((zflib_SObjectDomain.FieldError)zflib_SObjectDomain.Errors.getAll()[0]).field); 		
	}

	@IsTest
	private static void testUpdateValidationFailedWithoutDML()
	{
		Opportunity oldOpp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ');
		oldOpp.Name = 'Test';
		oldOpp.Type = 'Existing Account'; 
		Opportunity newOpp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ'); 
		newOpp.Name = 'Test';
		newOpp.Type = 'New Account'; 
		System.assertEquals(false, zflib_SObjectDomain.Test.Database.hasRecords());		
		zflib_SObjectDomain.Test.Database.onUpdate(new Opportunity[] { newOpp }, new Map<Id, SObject> { newOpp.Id => oldOpp } );
		System.assertEquals(true, zflib_SObjectDomain.Test.Database.hasRecords());				
		zflib_SObjectDomain.triggerHandler(zflib_SObjectDomain.TestSObjectDomainConstructor.class);		
		System.assertEquals(1, zflib_SObjectDomain.Errors.getAll().size());		
		System.assertEquals('You cannot change the Opportunity type once it has been created.', zflib_SObjectDomain.Errors.getAll()[0].message);
		System.assertEquals(Opportunity.Type, ((zflib_SObjectDomain.FieldError)zflib_SObjectDomain.Errors.getAll()[0]).field); 		
	}
	
	@IsTest
	private static void testOnBeforeDeleteWithoutDML()
	{
		Opportunity opp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ'); 
		opp.Name = 'Test';
		opp.Type = 'Existing Account';
		System.assertEquals(false, zflib_SObjectDomain.Test.Database.hasRecords());		
		zflib_SObjectDomain.Test.Database.onDelete(new Map<ID, Opportunity> { opp.Id => opp } );		
		System.assertEquals(true, zflib_SObjectDomain.Test.Database.hasRecords());				
		zflib_SObjectDomain.triggerHandler(zflib_SObjectDomain.TestSObjectDomainConstructor.class);		
		System.assertEquals(1, zflib_SObjectDomain.Errors.getAll().size());		
		System.assertEquals('You cannot delete this Opportunity.', zflib_SObjectDomain.Errors.getAll()[0].message);
	}
	
	@IsTest
	private static void testOnAfterUndeleteWithoutDML()
	{
		Opportunity opp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ'); 
		opp.Name = 'Test';
		opp.Type = 'Existing Account';
		System.assertEquals(false, zflib_SObjectDomain.Test.Database.hasRecords());		
		zflib_SObjectDomain.Test.Database.onUndelete(new list<Opportunity> { opp } );		
		System.assertEquals(true, zflib_SObjectDomain.Test.Database.hasRecords());				
		zflib_SObjectDomain.triggerHandler(zflib_SObjectDomain.TestSObjectDomainConstructor.class);		
	}
	
	@IsTest
	private static void testObjectSecurity()
	{
		// Create a user which will not have access to the test object type
		User testUser = createChatterExternalUser();
		if(testUser==null)
			return; // Abort the test if unable to create a user with low enough acess
		System.runAs(testUser)
		{					
			// Test Create object security
			Opportunity opp = new Opportunity ( Name = 'Test', Type = 'Existing Account' );
			zflib_SObjectDomain.Test.Database.onInsert(new Opportunity[] { opp } );
			try {
				zflib_SObjectDomain.triggerHandler(zflib_SObjectDomain.TestSObjectDomainConstructor.class);
				System.assert(false, 'Expected access denied exception');						
			} catch (Exception e) {
				System.assertEquals('Permission to create an Opportunity denied.', e.getMessage());
			}		
			
			// Test Update object security
			Opportunity existingOpp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ');
			existingOpp.Name = 'Test';
			existingOpp.Type = 'Existing Account'; 			
			zflib_SObjectDomain.Test.Database.onUpdate(new List<Opportunity> { opp }, new Map<Id, Opportunity> { opp.Id => opp } );
			try {
				zflib_SObjectDomain.triggerHandler(zflib_SObjectDomain.TestSObjectDomainConstructor.class);
				System.assert(false, 'Expected access denied exception');						
			} catch (Exception e) {
				System.assertEquals('Permission to update an Opportunity denied.', e.getMessage());
			}		
			
			// Test Delete object security
			zflib_SObjectDomain.Test.Database.onDelete(new Map<Id, Opportunity> { opp.Id => opp });
			try {
				zflib_SObjectDomain.triggerHandler(zflib_SObjectDomain.TestSObjectDomainConstructor.class);
				System.assert(false, 'Expected access denied exception');						
			} catch (Exception e) {
				System.assertEquals('Permission to delete an Opportunity denied.', e.getMessage());
			}		
		}			
	}
	
	@IsTest
	private static void testErrorLogging()
	{	
		// Test static helpers for raise none domain object instance errors
		Opportunity opp = new Opportunity ( Name = 'Test', Type = 'Existing Account' );		
		zflib_SObjectDomain.Errors.error('Error', opp);
		zflib_SObjectDomain.Errors.error('Error', opp, Opportunity.Type);
		System.assertEquals(2, zflib_SObjectDomain.Errors.getAll().size());		
		System.assertEquals('Error', zflib_SObjectDomain.Errors.getAll()[0].message);
		System.assertEquals('Error', zflib_SObjectDomain.Errors.getAll()[1].message);
		System.assertEquals(Opportunity.Type, ((zflib_SObjectDomain.FieldError)zflib_SObjectDomain.Errors.getAll()[1]).field);
		zflib_SObjectDomain.Errors.clearAll();		
		System.assertEquals(0, zflib_SObjectDomain.Errors.getAll().size());		
	}
	
	@IsTest
	private static void testTriggerState()
	{
		Opportunity opp = new Opportunity ( Name = 'Test', Type = 'Existing Account' );
		zflib_SObjectDomain.Test.Database.onInsert(new Opportunity[] { opp } );		
		zflib_SObjectDomain.triggerHandler(zflib_SObjectDomain.TestSObjectStatefulDomainConstructor.class);		
		System.assertEquals(1, zflib_SObjectDomain.Errors.getAll().size());		
		System.assertEquals('Error on Record Test', zflib_SObjectDomain.Errors.getAll()[0].message);
	}	

	@IsTest
	private static void testRecursiveTriggerState()
	{
		Opportunity opp = new Opportunity ( Name = 'Test Recursive 1', Type = 'Existing Account' );
		zflib_SObjectDomain.Test.Database.onInsert(new Opportunity[] { opp } );		
		zflib_SObjectDomain.triggerHandler(zflib_SObjectDomain.TestSObjectStatefulDomainConstructor.class);		
		System.assertEquals(2, zflib_SObjectDomain.Errors.getAll().size());		
		System.assertEquals('Error on Record Test Recursive 2', zflib_SObjectDomain.Errors.getAll()[0].message);
		System.assertEquals('Error on Record Test Recursive 1', zflib_SObjectDomain.Errors.getAll()[1].message);
	}	

	@IsTest
	private static void testOnValidateBehaviorDefault()
	{
		Opportunity oldOpp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ');
		oldOpp.Name = 'Test Default Behaviour';
		oldOpp.Type = 'Existing Account'; 
		Opportunity newOpp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ'); 
		newOpp.Name = 'Test Default Behaviour';
		newOpp.Type = 'New Account'; 		
		zflib_SObjectDomain.Test.Database.onUpdate(new Opportunity[] { newOpp }, new Map<Id, SObject> { newOpp.Id => oldOpp } );		
		zflib_SObjectDomain.triggerHandler(zflib_SObjectDomain.TestSObjectOnValidateBehaviourConstructor.class);		
	}	

	@IsTest
	private static void testOnValidateBehaviorOld()
	{
		Opportunity oldOpp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ');
		oldOpp.Name = 'Test Enable Old Behaviour';
		oldOpp.Type = 'Existing Account'; 
		Opportunity newOpp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ'); 
		newOpp.Name = 'Test Enable Old Behaviour';
		newOpp.Type = 'New Account'; 		
		zflib_SObjectDomain.Test.Database.onUpdate(new Opportunity[] { newOpp }, new Map<Id, SObject> { newOpp.Id => oldOpp } );
		try {		
			zflib_SObjectDomain.triggerHandler(zflib_SObjectDomain.TestSObjectOnValidateBehaviourConstructor.class);
			System.assert(false, 'Expected exception');
		} catch (Exception e) {
			System.assertEquals('onValidate called', e.getMessage());
		}
	}

	@IsTest
	private static void testGetChangedFieldsAsStrings()
	{
		Account acct1 = new Account ( Id = '001E0000006mkRP', Name = 'Test1', AccountNumber = '12345', Site = 'Here'),
		        acct2 = new Account ( Id = '001E0000006mkRQ', Name = 'Test2', AccountNumber = '54321', Site = 'There');
		System.assertEquals(false, zflib_SObjectDomain.Test.Database.hasRecords());
		zflib_SObjectDomain.Test.Database.onInsert(new Account[] { acct1, acct2 } );
		System.assertEquals(true, zflib_SObjectDomain.Test.Database.hasRecords());
		zflib_SObjectDomain.triggerHandler(zflib_SObjectDomain.TestSObjectChangedRecordsConstructor.class);
		Account acct1changed = acct1.clone(),
		        acct2changed = acct2.clone();
		acct1changed.Name = 'Test1changed';
		zflib_SObjectDomain.Test.Database.onUpdate(
			new Account[]{ acct1, acct2},
			new Map<Id, Account>{
				acct1changed.Id => acct1,
				acct2changed.Id => acct2
			}
		);
	}


	@IsTest
	private static void itShouldReturnTheChangedRecordsBySObjectFields()
	{
		// GIVEN a domain with old and changed records

		Id idLuke = zflib_IDGenerator.generate(Account.SObjectType);
		Id idHan = zflib_IDGenerator.generate(Account.SObjectType);
		Id idLeia = zflib_IDGenerator.generate(Account.SObjectType);
		List<Account> oldRecords = new List<Account>
		{
				new Account(Id = idLuke, Name = 'Luke', Description = 'Jedi'),
				new Account(Id = idHan, Name = 'Han', Description = 'Pilot'),
				new Account(Id = idLeia, Name = 'Leia')
		};

		List<Account> newRecords = oldRecords.deepClone(true, true, true);
		newRecords.get(0).Name = 'Luke SkyWalker';
		newRecords.get(0).Description = 'Jedi Master';
		newRecords.get(1).Name = 'Han Solo';
		Accounts accounts = new Accounts(newRecords);
		accounts.ExistingRecords = new Map<Id, SObject>(oldRecords);

		// WHEN we create a domain with ExistingRecords and request the changed records
		List<SObject> result = accounts.getChangedRecords(
				new Set<Schema.SObjectField>
				{
						Account.Name,
						Account.Description
				}
		);

		// THEN it should only return the changed records
		Map<Id, SObject> resultMap = new Map<Id, SObject>(result);
		System.assertEquals(2, result.size());
		System.assert(resultMap.containsKey(idLuke));
		System.assert(resultMap.containsKey(idHan));
	}

	@IsTest
	private static void itShouldReturnTheChangedRecordsByStringFields()
	{
		// GIVEN a domain with old and changed records

		Id idLuke = zflib_IDGenerator.generate(Account.SObjectType);
		Id idHan = zflib_IDGenerator.generate(Account.SObjectType);
		Id idLeia = zflib_IDGenerator.generate(Account.SObjectType);
		List<Account> oldRecords = new List<Account>
		{
				new Account(Id = idLuke, Name = 'Luke', Description = 'Jedi'),
				new Account(Id = idHan, Name = 'Han', Description = 'Pilot'),
				new Account(Id = idLeia, Name = 'Leia')
		};

		List<Account> newRecords = oldRecords.deepClone(true, true, true);
		newRecords.get(0).Name = 'Luke SkyWalker';
		newRecords.get(0).Description = 'Jedi Master';
		newRecords.get(1).Name = 'Han Solo';
		Accounts accounts = new Accounts(newRecords);
		zflib_SObjectDomain.Test.Database.onUpdate(newRecords, new Map<Id, SObject>(oldRecords));

		// WHEN we create a domain with ExistingRecords and request the changed records
		List<SObject> result = accounts.getChangedRecords(
				new Set<String>
				{
						'Name',
						'Description'
				}
		);

		// THEN it should only return the changed records
		Map<Id, SObject> resultMap = new Map<Id, SObject>(result);
		System.assertEquals(2, result.size());
		System.assert(resultMap.containsKey(idLuke));
		System.assert(resultMap.containsKey(idHan));
	}


	/**
	 * Create test user
	 **/
	private static User createChatterExternalUser()
	{
		// Can only proceed with test if we have a suitable profile - Chatter External license has no access to Opportunity
		List<Profile> testProfiles = [Select Id From Profile where UserLicense.Name='Chatter External' limit 1];
		if(testProfiles.size()!=1)
			return null; 		

		// Can only proceed with test if we can successfully insert a test user 
		String testUsername = System.now().format('yyyyMMddhhmmss') + '@testorg.com';
		User testUser = new User(Alias = 'test1', Email='testuser1@testorg.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = testProfiles[0].Id, TimeZoneSidKey='America/Los_Angeles', UserName=testUsername);
		try {
			insert testUser;
		} catch (Exception e) {
			return null;
		}		
		return testUser;
	}

	/**
	 *	The following tests that the ability to enable/disable all trigger events works as required
	 **/
	@IsTest
	private static void testDisableTriggerEventsBehaviour()
	{
		boolean bError = false;

		String  sErrorMessage = '';

		Opportunity oldOpp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ');
		oldOpp.Name = 'Test';
		oldOpp.Type = 'Existing'; 
		Opportunity newOpp = (Opportunity) Opportunity.sObjectType.newSObject('006E0000006mkRQ'); 
		newOpp.Name = 'Test';
		newOpp.Type = 'New'; 



		// these will be called multiple times making sure the correct error message comes back out
		// so... there are alot of tests to do here sadly and remember everything is reversed and you need to run backwards!
		// 1 - all disabled 
		try
		{
			zflib_SObjectDomain.getTriggerEvent(zflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class).disableAll();
			zflib_SObjectDomain.Test.Database.onInsert(new Opportunity[] { newOpp } );
			zflib_SObjectDomain.triggerHandler(zflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class);
		}
		catch (Exception e)
		{
			bError = true;
		}

		System.AssertEquals(false, bError, 'Error - Trigger events have been fired when they are disabled');

		////////////////////////////
		// Insert!
		try
		{
			// now lets go after insert and then before
			zflib_SObjectDomain.getTriggerEvent(zflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class).enableAfterInsert();
			zflib_SObjectDomain.Test.Database.onInsert(new Opportunity[] { newOpp } );
			zflib_SObjectDomain.triggerHandler(zflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class);
		}
		catch (Exception e)
		{
			sErrorMessage = e.getMessage();
			System.Debug('Exception Fired :' + e.getMEssage());
		}

		System.AssertEquals('onAfterInsert called', sErrorMessage, 'Error - After Insert Event is enabled but did not run');

		try
		{
			// now lets go after insert and then before
			zflib_SObjectDomain.getTriggerEvent(zflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class).enableBeforeInsert();
			zflib_SObjectDomain.Test.Database.onInsert(new Opportunity[] { newOpp } );
			zflib_SObjectDomain.triggerHandler(zflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class);
		}
		catch (Exception e)
		{
			sErrorMessage = e.getMessage();
		}

		System.AssertEquals('onBeforeInsert called', sErrorMessage, 'Error - Before Insert Event is enabled but did not run');

		////////////////////////////
		// Update!
		try
		{
			// now lets go after insert and then before
			zflib_SObjectDomain.getTriggerEvent(zflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class).enableAfterUpdate();
			zflib_SObjectDomain.Test.Database.onUpdate(new Opportunity[] { newOpp }, new Map<Id, SObject> { newOpp.Id => oldOpp } );
			zflib_SObjectDomain.triggerHandler(zflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class);
		}
		catch (Exception e)
		{
			sErrorMessage = e.getMessage();
		}

		System.AssertEquals('onAfterUpdate called', sErrorMessage, 'Error - After Update Event is enabled but did not run');

		try
		{
			// now lets go after insert and then before
			zflib_SObjectDomain.getTriggerEvent(zflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class).enableBeforeUpdate();
			zflib_SObjectDomain.Test.Database.onUpdate(new Opportunity[] { newOpp }, new Map<Id, SObject> { newOpp.Id => oldOpp } );
			zflib_SObjectDomain.triggerHandler(zflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class);
		}
		catch (Exception e)
		{
			sErrorMessage = e.getMessage();	
		}

		System.AssertEquals('onBeforeUpdate called', sErrorMessage, 'Error - Before Update Event is enabled but did not run');

		////////////////////////////
		// Delete!
		try
		{
			// now lets go after insert and then before
			zflib_SObjectDomain.getTriggerEvent(zflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class).enableAfterDelete();
			zflib_SObjectDomain.Test.Database.onDelete(new Map<Id, Opportunity> { newOpp.Id => newOpp } );
			zflib_SObjectDomain.triggerHandler(zflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class);
		}
		catch (Exception e)
		{
			sErrorMessage = e.getMessage();
		}

		System.AssertEquals('onAfterDelete called', sErrorMessage, 'Error - After Delete Event is enabled but did not run');

		try
		{
			// now lets go after insert and then before
			zflib_SObjectDomain.getTriggerEvent(zflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class).enableBeforeDelete();
			zflib_SObjectDomain.Test.Database.onDelete(new Map<Id, Opportunity> { newOpp.Id => newOpp } );
			zflib_SObjectDomain.triggerHandler(zflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class);
		}
		catch (Exception e)
		{
			sErrorMessage = e.getMessage();	
		}

		System.AssertEquals('onBeforeDelete called', sErrorMessage, 'Error - Before Delete Event is enabled but did not run');

		////////////////////////////
		// Undelete!
		try
		{
			// now lets go after insert and then before
			zflib_SObjectDomain.getTriggerEvent(zflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class).enableAfterUndelete();
			zflib_SObjectDomain.Test.Database.onUndelete(new Opportunity[] { newOpp });
			zflib_SObjectDomain.triggerHandler(zflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class);
		}
		catch (Exception e)
		{
			sErrorMessage = e.getMessage();
		}

		System.AssertEquals('onAfterUndelete called', sErrorMessage, 'Error - After Undelete Event is enabled but did not run');

		/*

		zflib_SObjectDomain.Test.Database.onInsert(new Opportunity[] { opp } );



		zflib_SObjectDomain.Test.Database.onUpdate(new Opportunity[] { newOpp }, new Map<Id, SObject> { newOpp.Id => oldOpp } );

		zflib_SObjectDomain.Test.Database.onDelete(new Map<ID, Opportunity> { opp.Id => opp } );		

		zflib_SObjectDomain.Test.Database.onUndelete(new list<Opportunity> { opp } );		


		try {		
			zflib_SObjectDomain.triggerHandler(zflib_SObjectDomain.TestSObjectOnValidateBehaviourConstructor.class);
			System.assert(false, 'Expected exception');
		} catch (Exception e) {
			System.assertEquals('onValidate called', e.getMessage());
		}
		*/
	}



	private class Accounts extends zflib_SObjectDomain
	{
		public Accounts(List<SObject> records)
		{
			super(records);
		}
	}
}