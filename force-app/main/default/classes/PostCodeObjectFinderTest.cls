/*
 * Author : Ivan Losilla
 * Description : Test Class for PostCodeObjectFinder
 * Date : 2020-06-23
 * History
 */
@isTest
public class PostCodeObjectFinderTest {
    
	@testSetup static void setup() {
        Insert TriggerConfiguration_TestDataFactory.createCustomSetting_ActivatedTriggers();
        List<PostCodeObjects__c> pcoList = new List<PostCodeObjects__c>();

        List<User> userList = User_TestDataFactory.createUsersNoAdmin(8, new List<String>{'fr_FR', 'es_ES', 'es_ES', 'en_US', 'fr_FR', 'fr_FR', 'en_US', 'en_US'});
        insert userList;

        pcoList.add(new PostCodeObjects__c(objectType__c = 'INSTALLER', country__c = 'ES', postCode__c = '12003', objectId__c = userList[2].id));
        pcoList.add(new PostCodeObjects__c(objectType__c = 'INSTALLER', country__c = 'ES', postCode__c = '46', objectId__c = userList[3].id));
        pcoList.add(new PostCodeObjects__c(objectType__c = 'INSTALLER', country__c = 'ES', postCode__c = '12003', objectId__c = userList[4].id));
        pcoList.add(new PostCodeObjects__c(objectType__c = 'INSTALLER', country__c = 'ES', postCode__c = '12', objectId__c = userList[7].id));
        
        pcoList.add(new PostCodeObjects__c(objectType__c = 'INSTALLER', country__c = 'FR', postCode__c = '28005', objectId__c = 'ID28005'));
        pcoList.add(new PostCodeObjects__c(objectType__c = 'INSTALLER', country__c = 'FR', postCode__c = '', objectId__c = 'COUNTRY'));
        pcoList.add(new PostCodeObjects__c(objectType__c = 'INSTALLER', country__c = 'FR', postCode__c = '28003', objectId__c = 'ID28003'));
        pcoList.add(new PostCodeObjects__c(objectType__c = 'INSTALLER', country__c = 'FR', postCode__c = '28', objectId__c = 'ID28'));

        pcoList.add(new PostCodeObjects__c(objectType__c = 'INSTALLER', country__c = 'GB', postCode__c = 'LA22', objectId__c = 'A'));
        pcoList.add(new PostCodeObjects__c(objectType__c = 'INSTALLER', country__c = 'GB', postCode__c = 'LA22 333', objectId__c = 'B'));
        
        pcoList.add(new PostCodeObjects__c(objectType__c = 'OWNER_USA', country__c = 'CA', state__c = '', postCode__c = 'A2B', objectId__c = 'GLOBAL-LEVEL'));
        pcoList.add(new PostCodeObjects__c(objectType__c = 'OWNER_USA', country__c = 'CA', state__c = '', postCode__c = 'A1A 6R4', objectId__c = 'POSTCODE-LEVEL'));
        pcoList.add(new PostCodeObjects__c(objectType__c = 'OWNER_USA', country__c = 'CA', state__c = '', postCode__c = 'A1A', objectId__c = 'GLOBAL-LEVEL'));

        pcoList.add(new PostCodeObjects__c(objectType__c = 'OWNER_USA', country__c = 'US', state__c = 'NJ', postCode__c = '', objectId__c = 'STATE-LEVEL'));
        pcoList.add(new PostCodeObjects__c(objectType__c = 'OWNER_USA', country__c = 'US', state__c = '', postCode__c = '', objectId__c = 'COUNTRY-LEVEL'));
        pcoList.add(new PostCodeObjects__c(objectType__c = 'OWNER_USA', country__c = 'US', state__c = '', postCode__c = '01100', postCodeTo__c = '01120', objectId__c = 'RANGE-LEVEL'));
        pcoList.add(new PostCodeObjects__c(objectType__c = 'OWNER_USA', country__c = 'US', state__c = '', postCode__c = '02200', objectId__c = 'POSTCODE-LEVEL'));


        insert pcoList;
    }
    
    @isTest static void findFirst_EUROPE() {
      PostCodeObjectFinder objFinder = new PostCodeObjectFinder('INSTALLER');
      objFinder.countryCode = 'GB';
      objFinder.postCode = 'LA23 XXX';
    	String result = objFinder.findFirst();
      System.assertEquals(null, result, 'No results should have been returned');
      
      objFinder.postCode = 'LA22 9NZ';
    	result = objFinder.findFirst();
      System.assertEquals('A', result, 'Id A should have been returned');

      objFinder.postCode = 'LA22 333';
    	result = objFinder.findFirst();
      System.assertEquals('B', result, 'Id B should have been returned');
      
      objFinder.countryCode = 'FR';
      objFinder.postCode = 'LXT 6553';
    	result = objFinder.findFirst();
      System.assertEquals('COUNTRY', result, 'Country default should have been found');
      
      objFinder.countryCode = 'FR';
      objFinder.postCode = '28003';
    	result = objFinder.findFirst();
      System.assertEquals('ID28003', result, 'One result should have been found');

      objFinder.countryCode = 'FR';
      objFinder.postCode = '28005';
    	result = objFinder.findFirst();
      System.assertEquals('ID28005', result, 'One result should have been found');

      objFinder.countryCode = 'FR';
      objFinder.postCode = '28017';
    	result = objFinder.findFirst();
      System.assertEquals('ID28', result, 'One result should have been found');
    }
      
    @isTest static void findFirst_USA() {
      
      PostCodeObjectFinder objFinder2 = new PostCodeObjectFinder('OWNER_USA');
      objFinder2.countryCode = 'US';
      objFinder2.postCode = '07777';
      objFinder2.state = 'NJ';
    	String result = objFinder2.findFirst();
		  System.assertEquals('STATE-LEVEL', result, '1 Result should have been returned');
      
      objFinder2.countryCode = 'US';
      objFinder2.postCode = '07777';
      objFinder2.state = 'CA';
    	result = objFinder2.findFirst();
		  System.assertEquals('COUNTRY-LEVEL', result, '1 Result should have been returned');

      objFinder2.countryCode = 'US';
      objFinder2.postCode = '01105';
      objFinder2.state = 'CA';
    	result = objFinder2.findFirst();
		  System.assertEquals('RANGE-LEVEL', result, '1 Result should have been returned fpor postcode ' + objFinder2.postCOde);

      objFinder2.countryCode = 'US';
      objFinder2.postCode = '02200';
      objFinder2.state = 'CA';
    	result = objFinder2.findFirst();
		  System.assertEquals('POSTCODE-LEVEL', result, '1 Result should have been returned');

      objFinder2.countryCode = 'US';
      objFinder2.postCode = '02200-2233';
      objFinder2.state = 'CA';
    	result = objFinder2.findFirst();
		  System.assertEquals('POSTCODE-LEVEL', result, '1 Result should have been returned');

      objFinder2.countryCode = 'US';
      objFinder2.postCode = '01111-2233';
      objFinder2.state = 'CA';
    	result = objFinder2.findFirst();
		  System.assertEquals('RANGE-LEVEL', result, '1 Result should have been returned');

    }

    @isTest static void findFirst_CA() {
      
        PostCodeObjectFinder objFinder1 = new PostCodeObjectFinder('OWNER_USA');
        objFinder1.countryCode = 'CA';
        objFinder1.postCode = 'A1A 6R4';
        String result = objFinder1.findFirst();
        System.debug(result);
        System.assertEquals('POSTCODE-LEVEL', result, '1 Result should have been returned');
        
        objFinder1.countryCode = 'CA';
        objFinder1.postCode = 'A2B 6Z4';
        result = objFinder1.findFirst();
        System.debug(result);
        System.assertEquals('GLOBAL-LEVEL', result, '1 Result should have been returned');

    }

    @isTest static void findAllRecords() {
      PostCodeObjectFinder objFinder2 = new PostCodeObjectFinder('OWNER_USA');
      objFinder2.countryCode = 'US';
      objFinder2.postCode = '01105';
      objFinder2.state = 'NJ';
    	List<PostCodeObjects__c> result = objFinder2.findAllRecords();
		  System.assertEquals(3, result.size(), '3 results expected');
    }
}