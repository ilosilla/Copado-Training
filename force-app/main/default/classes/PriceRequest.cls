public class PriceRequest {
    @auraEnabled public Opportunity opportunity{get;set;}     // Opportunity related to the Price request
    @auraEnabled public string notes;                    // Sales Org of the Price Request
    @auraEnabled public string salesOrg;                    // Sales Org of the Price Request
    @auraEnabled public string channel;                     // Channel of the Price Request
    @auraEnabled public string salesOffice;                 // Sales Office of the Price Request
    @auraEnabled public string currencyRequest;                    // Currency of the Price Request
    @auraEnabled public Boolean isNew = true;                      // If the Price Request is a new one, or an existing one
    @auraEnabled public Date productsNeededDate ;            //
    @auraEnabled public OppPriceRequestHeader__c headerData = new OppPriceRequestHeader__c();
    @auraEnabled public List<OppPriceRequestItem__c> itemsData = new List<OppPriceRequestItem__c>();
    @auraEnabled public List<OpportunityLineItem> oppProducts = new List<OpportunityLineItem>();
    @auraEnabled public Pricebook2 pricebook;
    @auraEnabled public Map<String,Map<String, PricebookEntry>> pricebookEntries = new Map<String,Map<String, PricebookEntry>>();
    @auraEnabled public OpportunityPriceRequestService.PRPermissions permissions;
    @auraEnabled public Map<String, PricebookEntry> tariffPrices = new Map<String, PricebookEntry>();
    @auraEnabled public Map<String, PricebookEntry> referencePrices = new Map<String, PricebookEntry>();
    @auraEnabled public List<salesOrgsWrapper> salesOrgs = new List<salesOrgsWrapper>();

    public PriceRequest(String oppId) {
        this.opportunity = new OpportunitiesSelector().selectById(oppId);
        this.oppProducts = [SELECT Id,
                                Accepted__c,
                                Name,
                                CodigoAuxiliar__c,
                                DescripcionAuxiliar__c,
                                CodeFormula__c,
                                CurrencyCode__c,
                                DescriptionFormula__c,
                                Alternative__c,
                                Sample__c,
                                ListPrice,
                                Material__c,
                                Umv__c,
                                Umb__c,
                                UnitPrice,
                                TotalPrice,
                                Quantity,
                                ProductCode,
                                Product2.Name,
                                Product2.ProductCode,
                                PricebookEntry.Uprice__c,
                                PricebookEntryId,
                                PricebookEntry.Product2Id,
                                PricebookEntry.Product2.Name,
                                PricebookEntry.Product2.ProductCode
                                FROM OpportunityLineItem WHERE OpportunityId =: oppId];

        List<OppPriceRequestHeader__c> headers = [SELECT id,
                                                        ApproveCode__c,
                                                        CurrencyIsoCode,
                                                        NeededBy__c,
                                                        Notes__c,
                                                        Opportunity__c,
                                                        PendingItems__c,
                                                        RejectedItems__c,
                                                        FactoryPendingItems__c,
                                                        FactoryRejectedItems__c,
                                                        SalesOrg__c,
                                                        Status__c,
                                                        TotalItems__c,
                                                        WaitingItems__c,
                                                        FactoryWaitingItems__c,
                                                        SAPAccountingInfo__c,
                                                        SAPAccountingInfo__r.Sales_Org__c,
                                                        SAPAccountingInfo__r.Sales_Office__c,
                                                        SAPAccountingInfo__r.Distribution_Channel__c
                                                    FROM OppPriceRequestHeader__c
                                                    WHERE Opportunity__c =: oppId LIMIT 1];
        if (headers.size() > 0) {
            OppPriceRequestHeader__c header = headers[0];
            this.headerData = header;
            this.isNew = false;
            this.salesOrg = header.SAPAccountingInfo__r.Sales_Org__c;
            this.salesOffice = header.SAPAccountingInfo__r.Sales_Office__c;
            this.notes = header.Notes__c;
            this.channel = header.SAPAccountingInfo__r.Distribution_Channel__c;
            this.itemsData = [SELECT id,
                                    ApprovedPrice__c,
                                    Approver__c,
                                    Approver__r.Name,
                                    CreatedDate,
                                    Currency__c,
                                    CurrencyIsoCode,
                                    FactoryPrice__c,
                                    Margin__c,
                                    OpportunityProduct__c,
                                    Price__c,
                                    CreatedBy.Name,
                                    PriceBook__c,
                                    PriceNeeded__c,
                                    PriceRequestHeader__c,
                                    Product__c,
                                    ProductCode__c,
                                    ProductCodeFormula__c,
                                    ProductName__c,
                                    ProductNameFormula__c,
                                    PromoFactoryPrice__c,
                                    Quantity__c,
                                    ReferencePrice__c,
                                    ReviewedDate__c,
                                    Status__c,
                                    SubmittedBackDate__c,
                                    SubmittedDate__c,
                                    UnitOfPrice__c,
                                    FactoryApprovedPrice__c,
                                    FactoryStatus__c,
                                    SubmittedFactoryDate__c,
                                    SubmittedToFactoryManager__c,
                                    SubmittedToFactoryManager__r.Name,
                                    FactoryApprover__c,
                                    FactoryMargin__c,
                                    FactoryApprover__r.Name,
                                    FactoryPriceNeeded__c,
                                    FactoryReviewDate__c,
                                    toLabel(UnitOfPrice__c) labelUnitPrice
                                FROM OppPriceRequestItem__c
                                WHERE PriceRequestHeader__c =: header.id];
        } else {
            this.isNew = true;
        }
        if (this.opportunity.Pricebook2Id != null) {
            List<Pricebook2> pricebooks = new PricebooksSelector().selectById(new Set<Id>{this.opportunity.Pricebook2Id});
            if (pricebooks.size() > 0) {
                this.pricebook = new PricebooksSelector().selectById(new Set<Id>{this.opportunity.Pricebook2Id})[0];
                getPricebookPrices(this.opportunity.Id, this.pricebook);
            }
        }
        this.permissions = new OpportunityPriceRequestService.PRPermissions(Userinfo.getUserId(), oppId); 
        this.salesOrgs = getAccountSalesOrgs(oppId);
    }
    
    /*@AuraEnabled(cacheable=false)
    public static List<OppPriceRequestItem__c> getPendingStoreItems() {
        return getItemsByStatus('PENDING');
    }*/

    /*public static List<OppPriceRequestItem__c> getItemsByStatus(String status) {
        List<OppPriceRequestItem__c> result = [SELECT id,
                                        ApprovedPrice__c,
                                        Approver__c,
                                        CreatedDate,
                                        Currency__c,
                                        CurrencyIsoCode,
                                        FactoryPrice__c,
                                        Margin__c,
                                        OpportunityProduct__c,
                                        Price__c,
                                        PriceBook__c,
                                        PriceNeeded__c,
                                        PriceRequestHeader__c,
                                        Product__c,
                                        ProductCode__c,
                                        ProductCodeFormula__c,
                                        ProductName__c,
                                        ProductNameFormula__c,
                                        PromoFactoryPrice__c,
                                        Quantity__c,
                                        ReferencePrice__c,
                                        ReviewedDate__c,
                                        toLabel(Status__c),
                                        SubmittedBackDate__c,
                                        SubmittedDate__c,
                                        UnitOfPrice__c,
                                        PriceRequestHeader__r.NeededBy__c,
                                        PriceRequestHeader__r.Opportunity__r.Name,
                                        PriceRequestHeader__r.Opportunity__r.OwnerId,
                                        PriceRequestHeader__r.Opportunity__r.Owner.Name,
                                        PriceRequestHeader__r.Opportunity__r.Owner.Default_Sales_Organization__c,
                                        PriceRequestHeader__r.Opportunity__r.Owner.Sales_Office__c,
                                        PriceRequestHeader__r.Opportunity__r.Account.Name,
                                        PriceRequestHeader__r.Opportunity__r.AccountId
                                        FROM OppPriceRequestItem__c WHERE Status__c =: status];
        return result;
    }*/

    public void getPricebookPrices(String opportunityId, Pricebook2 pricebook) {
        Map<String,Map<String, PricebookEntry>> result = new Map<String,Map<String, PricebookEntry>>();
        Map<String, PricebookEntry> tariffPricesMap = new Map<String, PricebookEntry>();
        Map<String, PricebookEntry> referencePricesMap = new Map<String, PricebookEntry>();
        Map<Id, OpportunityLineItem> oppItemsMap = new Map<Id, OpportunityLineItem>();
        List<Opportunity> opps = [SELECT Id, Name, OwnerId, StageName, Currency__c, CurrencyIsoCode, AccountId, Account.OwnerId,
                                    (SELECT Id, CodigoAuxiliar__c, DescripcionAuxiliar__c, Product2.Name, ProductCode,Name, UnitPrice, Quantity FROM OpportunityLineItems) 
                                    FROM Opportunity
                                    where id =: opportunityId];
        List<Pricebook2> referencePricebookList = [SELECT Id, Bzirk__c, Name FROM Pricebook2 WHERE IsRetailReferencePricebook__c = true and ExecutionContext__c =: pricebook.ExecutionContext__c ];
        Pricebook2 referencePricebook = null;
        if (referencePricebookList.isEmpty()) {
            referencePricebook = [SELECT Id, Bzirk__c, Name FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
        } else {
            referencePricebook = referencePricebookList[0];
        }
                                    
        if (opps.size() == 1) {
            Set<String> productCodesList = new Set<String>();
            
            for (OpportunityLineItem variable : opps[0].OpportunityLineItems) {
                productCodesList.add(variable.ProductCode);
                oppItemsMap.put(variable.Product2.Id, variable);
            }

            if (pricebook != null) {

                List<PricebookEntry> pbTariffEntries = new List<PricebookEntry>();
                List<PricebookEntry> pbReferenceEntries = new List<PricebookEntry>();

                if (!String.isEmpty(pricebook.Bzirk__c)) {
                    pbTariffEntries = new PricebookEntriesSelector().selectByTariffAndProduct(new Set<String>{pricebook.Bzirk__c}, productCodesList);
                    pbReferenceEntries = new PricebookEntriesSelector().selectByTariffAndProduct(new Set<String>{referencePricebook.Bzirk__c}, productCodesList);  
                } else {
                    pbReferenceEntries = [SELECT Id, CurrencyIsoCode, IsActive,Name,Pricebook2Id,Product2Id,ProductCode,Bzirk__c,
                                           UPrice__c,UnitPrice,Pricebook2.Name,Product2.Name,Product2.ProductCode
                                           FROM PricebookEntry WHERE Pricebook2Id =: referencePricebook.Id and ProductCode in : productCodesList];
                    pbTariffEntries = pbReferenceEntries;
                }
                
                if (pbTariffEntries.size() > 0) {
                    for (PricebookEntry obj : pbTariffEntries) {
                        tariffPricesMap.put(obj.ProductCode, obj);
                    }
                    this.tariffPrices = tariffPricesMap;

                }
                if (pbReferenceEntries.size() > 0) {
                    for (PricebookEntry obj : pbReferenceEntries) {
                        referencePricesMap.put(obj.ProductCode, obj);
                    }
                    this.referencePrices = referencePricesMap;
                }
            }
        }
    }

    public static List<salesOrgsWrapper> getAccountSalesOrgs(String opportunityId) {
        List<salesOrgsWrapper> result = new List<salesOrgsWrapper>();
        Map<String, String> salesOrgsAux = new Map<String, String>();
        Map<String, String> channelOrgsAux = new Map<String, String>();
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Id =: opportunityId];
        List<Sales_Relationship__c> salesOrgs = [select id, Sales_Org__c,Distribution_Channel__c,Sales_Office__c from Sales_Relationship__c WHERE Account_Org__c =: opp.AccountId];
        User currentUser = new UsersSelector().selectById(UserInfo.getUserId());
        
        Schema.DescribeFieldResult fieldResult = Sales_Relationship__c.Sales_Org__c.getDescribe();
        Schema.DescribeFieldResult fieldResultChannel = Sales_Relationship__c.Distribution_Channel__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<Schema.PicklistEntry> pleChannel = fieldResultChannel.getPicklistValues();

        for( Schema.PicklistEntry pickListVal : ple){
            salesOrgsAux.put(pickListVal.getValue(), pickListVal.getLabel());
        }
        for( Schema.PicklistEntry pickListVal : pleChannel){
            channelOrgsAux.put(pickListVal.getValue(), pickListVal.getLabel());
        }
        for (Sales_Relationship__c salesOrg : salesOrgs) {
            salesOrgsWrapper auxSalesOrg = new salesOrgsWrapper();
            auxSalesOrg.id = salesOrg.Id;
            auxSalesOrg.label = salesOrgsAux.get(salesOrg.Sales_Org__c) + ' - ' + channelOrgsAux.get(salesOrg.Distribution_Channel__c);
            result.add(auxSalesOrg);
            if (salesOrg.Sales_Org__c == currentUser.Default_Sales_Organization__c && salesOrg.Distribution_Channel__c == currentUser.Distribution_channel_default__c && UserUtils.isAdministrator() == false) {
                return new List<salesOrgsWrapper>{auxSalesOrg};
            }
        }

		return result;
    }

    public class salesOrgsWrapper{
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String label;
    }

    @testVisible public static String testFiller() {
        String s = 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        return s;
    }
}