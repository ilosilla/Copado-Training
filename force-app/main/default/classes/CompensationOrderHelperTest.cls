@isTest(isParallel=false) public class CompensationOrderHelperTest {

        @testSetup public static void testSetup()  {
            DataFactoryOrganization.createData();
            DataFactoryProduct.ignoreStandardPriceBook = true;
            DataFactoryProduct.skipPriceBooks = true;
            DataFactoryProduct.createProducts();        
            DataFactoryCase.autoInsert = false;
            Case[] cases = DataFactoryCase.createClaims(1);
            cases[0].Compensation__c = 300;
            SAPCasesService.createSAPInvoiceCase(cases);             
        }

        @isTest private static void testCreate() {
            Product2 product = [select Id from Product2 limit 1];
            Case c = [select Id from Case limit 1];
            Test.startTest();
            c.SalesOrg__c = '502';
            c.DistributionChannel__c = '60';
            c.CurrencyIsoCode = 'GBP';
            update c;
            CompensationOrderHelper helper = new CompensationOrderHelper(c.Id);
            helper.setCompensationProductId(product.Id);
            Id orderId = helper.create();
            Test.stopTest();
            Assert.isNotNull(orderId);    
        }
    
    }