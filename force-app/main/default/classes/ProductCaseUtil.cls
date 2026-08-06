/** 
* Help method for CaseUtil 
* @author gmiranda (nts)  
* @date 09/05/2018 DESACTIVADO
* @service Hecho por NTS
*/
/**
* @cases cuando prepararon Service
*/
public class ProductCaseUtil 
{
	
    /** 
	* @author dguzman (nts) 
	* @date 18/05/2018
	* @description Every time a productcase is created the material price is extracted from the product list 
	*/
	/*public static void obtainMaterialPrice(list<Product_Case__c> newList)
	{
		Set <Id> products	=	new Set <Id>();
		Set<Id> scopeCases	=	new Set<Id>();

// 		for(Product_Case__c productCase: newList)
// 		{
// 			products.add(productcase.Product__c);
// 			scopeCases.add(productCase.Case__c);
// 		}

// 		Map<Id,Case> cases	=	new Map<Id,Case>([SELECT Id,State__c FROM Case WHERE Id IN: scopeCases]);
// 		Set<String> states	=	new Set<String>();
// 		for( Case caso: cases.values())
// 		{
// 			states.add(caso.State__c);
// 		}

// 		//Se obtiene de la pricebookentry la entrada para ese producto en la lista de precios del pais y se actualiza el material price
// 		List <PriceBookEntry> entries = [
// 											SELECT 	Id, Product2Id, UnitPrice, Pricebook2.State__c 
// 											FROM 	PriceBookEntry 
// 											WHERE 	Product2Id IN :products 
// 													AND
// 													Pricebook2.State__c in :states
// 										] ;

// 		for ( Product_Case__c productCase: newList )
// 		{
// 			for ( PriceBookEntry pbe : entries )
// 			{
// 				if( productcase.Product__c == pbe.Product2Id 
// 					&& cases.get(productcase.Case__c).State__c == pbe.Pricebook2.State__c )
// 				{
// 					productcase.Material_Price__c = pbe.UnitPrice;
// 				}
// 			}	

// 			if ( productCase.Material_Price__c == null ) productCase.Material_Price__c = 0;
// 		}
// 		*/

	// }*/

	/** 
	* @author gmiranda (nts) 
	* @date 09/05/2018
	* @description Every time a productcase is created or every time material price or discount is changed, the final price is recalculated
	*/
	/*public static void updateFinalPrice(list<Product_Case__c> newList, map<Id,Product_Case__c> oldMap)
	{
		List<Product_Case__c> scopeProductCases	=	new List<Product_Case__c>();
		for(Product_Case__c productCase: newList)
		{
			if(oldMap == null)
			{//Se trata de una creación
				if(productCase.Material_Price__c != null)		scopeProductCases.add(productCase);
			}
			else if( productCase.Material_Price__c	!=	oldMap.get(productCase.Id).Material_Price__c 
					||	productCase.Discount__c		!=	oldMap.get(productCase.Id).Discount__c)
			{				
					scopeProductCases.add(productCase);
			}
		}

		for(Product_Case__c scopeProductCase:scopeProductCases)
		{
			if (scopeProductCase.Material_Price__c == null )	scopeProductCase.Final_Price__c = null;
			else if (scopeProductCase.Discount__c == null)		scopeProductCase.Final_Price__c = scopeProductCase.Material_Price__c;				
			else												scopeProductCase.Final_Price__c = scopeProductCase.Material_Price__c - ((scopeProductCase.Material_Price__c * scopeProductCase.Discount__c) / 100);
		}
	}*/

	/** 
	* @author dguzman (nts) 
	* @date 29/05/2018
	* @description Cuando se crea un nuevo product case se asocia al caso padre del caso que contiene dicho product case
	*/
	/*public static void updateParentCase(list<Product_Case__c> newList)
	{
		Set <String> idPCs			=	new Set <String>();

// 		for(Product_Case__c pc : newList )
// 		{
// 			idPCs.add(pc.Case__c);
// 		}

// 		Map <Id,Case> childcases	=	new Map <Id, Case>(
// 			[
// 				SELECT	Id, ParentId 
// 				FROM	Case
// 				WHERE	ParentId != null AND Id IN :idPCs
// 			]
// 		);

		for(Product_Case__c pc : newList )
		{
			if(childcases.containsKey(pc.Case__c))
			{
				pc.Parent_Case__c = childcases.get(pc.Case__c).ParentId;
			}
		}
	}*/
}