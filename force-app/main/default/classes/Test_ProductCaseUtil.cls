/**
* @cases cuando prepararon Service
*/
@isTest
public class Test_ProductCaseUtil 
{
	/*@TestSetup
  	static void test_CreateData()
  	{
  		List<Product2> productsToInsert = new List<Product2>
	    {
	    	new Product2 (
	    		Name = 'TestProduct1',
	    		IsActive = true
	    	),
	    	new Product2 (
	    		Name = 'TestProduct2',
	    		IsActive = true
	    	)
	    };

	    insert productsToInsert;

	    Pricebook2 standardPB = new Pricebook2(Name = 'PricebookTest', Description = 'PricebookTest', IsActive = true, State__c='California');
	    insert standardPB;

	    List<PricebookEntry> peToInsert = new List<PricebookEntry>();

	    for(Product2 p : productsToInsert)
	    {
	    	peToInsert.add(
	    		new PricebookEntry (
		    		Pricebook2Id = Test.getStandardPricebookId(),
		    		Product2Id = p.Id,
		    		UnitPrice = 100,
		    		UseStandardPrice = false,
		    		IsActive = true
	    		)
	    	);

	    	peToInsert.add(
		    	new PricebookEntry (
			    	Pricebook2Id = standardPB.Id,
			    	Product2Id = p.Id,
			    	UnitPrice = 100,
			    	UseStandardPrice = false,
			    	IsActive = true
			    )
		    );
	    }

	    insert peToInsert;

  		Case parentCase = new Case (
						        RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('USA Claim').getRecordTypeId(),
						        State__c = 'California'
						  );

  		insert parentCase;

  		List<Case> childCases = new List<Case>
  		{
  			new Case (
				RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('USA Claim').getRecordTypeId(),
				State__c = 'California',
				ParentId = parentCase.Id
			),
			new Case (
				RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('USA Claim').getRecordTypeId(),
				State__c = 'California',
				ParentId = parentCase.Id
			)
  		};

	    insert childCases;

  	}*/

	/**
   	* 
   	*
  	* @author adelgado
   	* @date 24/07/2018
   	*/
  	/*@isTest
  	static void test_obtainMaterialPrice()
  	{
  		List<Case> insertedCases = [SELECT Id FROM Case WHERE ParentId != null];
  		List<Product2> insertedProducts = [SELECT Id FROM Product2];

  		List<Product_Case__c> pcToInsert = new List<Product_Case__c>();

  		for(Case c : insertedCases)
  		{
  			for(Product2 p : insertedProducts)
  			{
	  			pcToInsert.add(
	  				new Product_Case__c (
				        Product__c = p.Id,
				        Case__c = c.Id
				 	)
	  			);
	  		}
  		}

  		insert pcToInsert;

  		List<Product_Case__c> pcInserted = [SELECT Material_Price__c, Final_Price__c FROM Product_Case__c];

  		for(Product_Case__c pc : pcInserted)
  		{
  			System.assertEquals(100, pc.Material_Price__c);
  		}

  	}*/


  	/**
   	* 
   	*
  	* @author adelgado
   	* @date 24/07/2018
   	*/
  	/*@isTest
  	static void test_updateFinalPrice()
  	{
  		List<Case> insertedCases = [SELECT Id FROM Case WHERE ParentId != null];
  		List<Product2> insertedProducts = [SELECT Id FROM Product2];

  		List<Product_Case__c> pcToInsert = new List<Product_Case__c>();

  		for(Case c : insertedCases)
  		{
  			for(Product2 p : insertedProducts)
  			{
	  			pcToInsert.add(
	  				new Product_Case__c (
				        Product__c = p.Id,
				        Case__c = c.Id,
				        Discount__c = 10
				 	)
	  			);
	  		}
  		}

  		insert pcToInsert;

  		List<Product_Case__c> pcInserted = [SELECT Final_Price__c, Material_Price__c FROM Product_Case__c];

  		for(Product_Case__c pc : pcInserted)
  		{
  			System.assertEquals(100, pc.Material_Price__c);
  			System.assertEquals(90, pc.Final_Price__c);
			pc.Material_Price__c = 70;
		}

		update pcInserted;

		pcInserted = [SELECT Final_Price__c, Material_Price__c FROM Product_Case__c];

  		for(Product_Case__c pc : pcInserted)
  		{
			  System.assertEquals(70, pc.Material_Price__c);
			  delete pc;
		}
		  
		
  	}*/

  	/**
   	* 
   	*
  	* @author adelgado
   	* @date 24/07/2018
   	*/
  	/*@isTest
  	static void test_updateParentCase()
  	{
  		List<Case> insertedCases = [SELECT Id FROM Case WHERE ParentId != null];
  		List<Product2> insertedProducts = [SELECT Id FROM Product2];

  		List<Product_Case__c> pcToInsert = new List<Product_Case__c>();

  		for(Case c : insertedCases)
  		{
  			for(Product2 p : insertedProducts)
  			{
	  			pcToInsert.add(
	  				new Product_Case__c (
				        Product__c = p.Id,
				        Case__c = c.Id
				 	)
	  			);
	  		}
  		}

  		insert pcToInsert;

  		List<Product_Case__c> pcInserted = [SELECT Parent_Case__c FROM Product_Case__c];
  		List<Case> parentCase = [SELECT Id FROM Case WHERE ParentId = null];

  		for(Product_Case__c pc : pcInserted)
  		{
  			System.assertEquals(parentCase[0].Id, pc.Parent_Case__c);
  		}

  	}*/

}