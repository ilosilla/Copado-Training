/**
 * @description       : 
 * @author            : EHG@nubika.com
 * @group             : 
 * @last modified on  : 11-18-2022
 * @last modified by  : EHG@nubika.com
**/
@isTest
public without sharing class NB2B_ProductSelectorTest {
    
    /**
    * @description 
    * @author EHG@nubika.com | 11-18-2022 
    **/
    @testSetup static void setup(){
        Product2 prod = new Product2(
        	Name = 'test',
            productCode = '1235',
            StockKeepingUnit = '12345',
            UmbKg__c = 123,
            ExternalId = '12345'
        );
        insert prod;
    }
    
    /**
    * @description 
    * @author EHG@nubika.com | 11-18-2022 
    **/
    @isTest
    public static void test1(){
        //NB2B_ProductSelector.selectProductDtByExternalId();
        List<String> prodStrList = new List<String>();
        prodStrList.add('12345');
		List<Product2> prodList = Nb2b_ProductsSelector.selectProductByExternalId(prodStrList);
        Assert.areEqual(prodList[0].ExternalId , '12345');
    }
    /**
    * @description 
    * @author EHG@nubika.com | 11-18-2022 
    **/
    @isTest
    public static void test2(){
        //NB2B_ProductSelector.selectProductDtByExternalId();
        List<String> prodStrList = new List<String>();
        prodStrList.add('12345');
		List<Product2> prodList = Nb2b_ProductsSelector.selectProductBySKU(prodStrList);
        Assert.areEqual(prodList[0].ExternalId , '12345');
    }
    /**
    * @description 
    * @author EHG@nubika.com | 11-18-2022 
    **/
    @isTest
    public static void test3(){
        //NB2B_ProductSelector.selectProductDtByExternalId();
        Set<String> prodStrList = new Set<String>();
        prodStrList.add([Select id from Product2 limit 1].Id);
		List<Product2> prodList = Nb2b_ProductsSelector.selectProductById(prodStrList);
        Assert.areEqual(prodList[0].ExternalId , '12345');
    }
    
    @isTest
    public static void test4(){
        //NB2B_ProductSelector.selectProductDtByExternalId();
        List<String> prodStrList = new List<String>();
        prodStrList.add('12345');
		List<Product2DataTranslation> prodList = Nb2b_ProductsSelector.selectProductDtBySku(prodStrList);
        List<N2B2_LanguageTraduction__mdt> listmdt = Nb2b_ProductsSelector.getTranslationMetadata();
    }

}