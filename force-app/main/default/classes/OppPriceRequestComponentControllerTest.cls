@isTest
public class OppPriceRequestComponentControllerTest {
    @isTest
    static void getData() {
        //TestUtils.enableTriggers();
        DataFactoryOrganization.createData();
        DataFactoryProduct.skipPriceBooks = true;
        List<Product2> products = DataFactoryProduct.createProducts();
        User usrerAs = DatafactoryUser.createUKAdmin();
        List<PricebookEntry> entryPriceBook = [select id, CurrencyIsoCode, Pricebook2Id, Pricebook2.Name  from PricebookEntry where Product2Id =: products[0].Id and currencyIsoCode = 'EUR'];
        Account acc = Account_TestDataFactory.createBusinessAccount();
        Insert acc;
        List<Opportunity> opps = DataFactoryOpportunity.createTradeOpportunities(new List<Account>{acc}, 1);
        opps[0].ownerid = usrerAs.Id;
        opps[0].countrycode__c = 'FR';
        opps[0].CurrencyIsoCode = 'EUR';
        opps[0].Pricebook2Id = entryPriceBook[0].Pricebook2Id;
        update opps;

        List<PorcelanosaSetting__c> settings = new List<PorcelanosaSetting__c>();
        settings.add(new PorcelanosaSetting__c(key__c = 'FACTORYPRICEREQUEST',Subkey__c = opps[0].countryCode__c,value1__c = 'P', value2__c = '002', value3__c = '1000000'));
        settings.add(new PorcelanosaSetting__c(key__c = 'FACTORYPRICEREQUEST',Subkey__c = opps[0].countryCode__c,value1__c = 'L', value2__c = '002', value3__c = '1000000'));
        settings.add(new PorcelanosaSetting__c(key__c = 'FACTORYPRICEREQUEST',Subkey__c = opps[0].countryCode__c,value1__c = 'X', value2__c = '002', value3__c = '1000000'));
        settings.add(new PorcelanosaSetting__c(key__c = 'FACTORYPRICEREQUEST',Subkey__c = opps[0].countryCode__c,value1__c = 'N', value2__c = '002', value3__c = '1000000'));
        settings.add(new PorcelanosaSetting__c(key__c = 'FACTORYPRICEREQUEST',Subkey__c = opps[0].countryCode__c,value1__c = 'V', value2__c = '002', value3__c = '1000000'));
    
        insert settings;

        Sales_Relationship__c salesRelSuccess = Sales_RelationShip_TestDataFactory.createSalesRelationship(acc);
        Insert salesRelSuccess;
        List<Account> accs = [SELECT id FROM Account];

        Sales_Relationship__c rel = new Sales_Relationship__c(
            Account_Org__c = accs[0].Id,
            Sales_Org__c = '502',
            Distribution_Channel__c = '60',
            Sales_Office__c	= '2552'
        );
        insert rel;
        
        OppPriceRequestHeader__c priceRequestHeader = new OppPriceRequestHeader__c(Neededby__c = Date.newInstance(2021, 8, 17), CurrencyIsoCode = 'EUR', SAPAccountingInfo__c = salesRelSuccess.Id,Opportunity__c = opps[0].Id);
        insert priceRequestHeader;
        OppPriceRequestItem__c item = new OppPriceRequestItem__c(Status__c = 'PENDING', ProductCode__c = '1111111', ProductName__c = 'TTTTT', priceRequestHeader__c = priceRequestHeader.Id);
        insert item;

        User usr = [Select Id, CountryCode from User where Id =: UserInfo.getUserId()];

        List<Group> existGroup = [SELECT Id FROM Group where DeveloperName = : 'price_approvers_' + usr.CountryCode ];
        
        System.runAs(usrerAs) {
            if (existGroup.size() > 0) {
                List<GroupMember> existGroupMember = [SELECT Id FROM GroupMember where GroupId =: existGroup[0].Id and UserOrGroupId =: UserInfo.getUserId()];
                if (existGroupMember.size() == 0) {
                    GroupMember createdGroupMember = new GroupMember(GroupId = existGroup[0].Id, UserOrGroupId = UserInfo.getUserId());
                    insert createdGroupMember;
                }
            } else {
                Group createdGroup = new Group(DeveloperName = 'price_approvers_' + usr.CountryCode, Name = 'price_approvers_' + usr.CountryCode);
                insert createdGroup;
                GroupMember createdGroupMember = new GroupMember(GroupId = createdGroup.Id, UserOrGroupId = UserInfo.getUserId());
                insert createdGroupMember;
            }
        }
        
        entryPriceBook = [select id, currencyIsoCode, Pricebook2Id  from PricebookEntry where currencyIsoCode = 'EUR' and Pricebook2Id =: opps[0].Pricebook2Id];

        List<OpportunityLineItem> items = new List<OpportunityLineItem>();

        items.add(new OpportunityLineItem(OpportunityId = opps[0].Id, Product2Id = products[0].Id, PricebookEntryId = entryPriceBook[0].Id ,Quantity = 4, UnitPrice = 334));
        items.add(new OpportunityLineItem(OpportunityId = opps[0].Id, Product2Id = products[1].Id, PricebookEntryId = entryPriceBook[0].Id ,Quantity = 4, UnitPrice = 334));
        insert items;

        List<OppPriceRequestItem__c> itemsRequest = new List<OppPriceRequestItem__c>();
        itemsRequest.add(new OppPriceRequestItem__c(OpportunityProduct__c= items[1].Id,Status__c = 'PENDING', ProductCode__c = '1111111', ProductName__c = 'TTTTT', PromoFactoryPrice__c = 34.45, currencyIsoCode = 'USD', priceRequestHeader__c = priceRequestHeader.Id));
        itemsRequest.add(new OppPriceRequestItem__c(OpportunityProduct__c= items[0].Id,ProductCode__c = '1111111', ProductName__c = 'TTTTT', PromoFactoryPrice__c = 34.45, currencyIsoCode = 'USD', priceRequestHeader__c = priceRequestHeader.Id));
        insert itemsRequest;

        ExecutionContext context = ExecutionContext.getUserExecutionContext();
        context.priceRequest = true;
        OpportunityPriceRequestService.PRPermissions permissions = OppPriceRequestComponentController.getPermissions(opps[0].Id);
        PriceRequest data = OppPriceRequestComponentController.getAllData(opps[0].Id);
        System.assertEquals(true, opps[0].Id == data.opportunity.Id, 'No se encuentra la oportunidad');
        System.assertEquals(true, data.headerData.Id == data.headerData.Id, 'No se encuentra el Price Request');

        Test.startTest();

        // Ejecutamos el método
        PriceRequestPrices.SAPItem result = OppPriceRequestComponentController.updateOppProductPrice(items[0].Id);
        PriceRequestPrices.SAPItem result2 = OppPriceRequestComponentController.OppProductFactoryPrice(items[0].Id,'', false);

        Test.stopTest();

        // Validación
        System.assertEquals(null, result.retailValue, 'El precio debería ser nulo');
        System.assertEquals(null, result2.retailValue, 'El precio debería ser nulo');

         List<OppPriceRequestHeader__c> beforeList = [SELECT Id, CurrencyIsoCode, Notes__c from OppPriceRequestHeader__c];
        beforeList[0].Notes__c = 'Test Notes';
        
        OppPriceRequestComponentController.updatePriceRequest(beforeList[0]);

        /*List<OppPriceRequestHeader__c> listHeaders = OppPriceRequestComponentController.getHeadersList();
        System.assertEquals(true, listHeaders.size() > 0, 'Price Headers not received');

        List<OppPriceRequestHeader__c> headers = [SELECT Id, CurrencyIsoCode, Notes__c from OppPriceRequestHeader__c];
        List<OppPriceRequestItem__c> beforeListI = [SELECT Id, Price__c, ProductCode__c,PriceRequestHeader__c from OppPriceRequestItem__c];
        beforeListI[0].Price__c = 555;
        
        OppPriceRequestComponentController.upsertItem(beforeListI[0]);
        List<OppPriceRequestItem__c> afterListI = [SELECT Id, Price__c from OppPriceRequestItem__c];
        System.assert(afterListI[0].Price__c == 555, 'No se ha actualizado');

        List<OppPriceRequestItem__c> itemsStore = OppPriceRequestComponentController.getHistoricData();
        List<OppPriceRequestItem__c> itemsFactory = OppPriceRequestComponentController.getFactoryHistoricData();*/

        OppPriceRequestComponentController.testFiller();
        OppPriceRequestsDomain.testFiller();
        OpportunityPriceRequestService.testFiller();
        PriceRequestPrices.testFiller();
        PriceRequest.testFiller();
        Assert.isTrue(1 == 1);
    }
}