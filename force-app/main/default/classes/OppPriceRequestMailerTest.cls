@isTest
public class OppPriceRequestMailerTest {
    @TestSetup
    static void makeData(){
        TestUtils.enableTriggers();
        DataFactoryOrganization.createData();
        List<Product2> listProducts = DataFactoryProduct.createProducts();
        List<Opportunity> opps = DataFactoryOpportunity.createRetailOpportunities(2, 1);

        OppPriceRequestHeader__c priceRequestHeader = new OppPriceRequestHeader__c(Neededby__c = Date.newInstance(2021, 8, 17), currencyIsoCode = 'USD', Opportunity__c = opps[0].Id);
        insert priceRequestHeader;
        OppPriceRequestItem__c item = new OppPriceRequestItem__c(ProductCode__c='111111',ProductName__c='Test product',Product__c = listProducts[0].Id, Price__c = 34.45, currencyIsoCode = 'GBP', priceRequestHeader__c = priceRequestHeader.Id);
        insert item;
    }

    @isTest
    static void sendToApprovalMail() {
        OppPriceRequestHeader__c header = [select Id, NeededBy__c from OppPriceRequestHeader__c limit 1];
        OppPriceRequestItem__c item = [select Id, status__c from OppPriceRequestItem__c];
        item.Status__c = 'PENDING';
        update item;
        
        OppPriceRequestMailer aux =  new OppPriceRequestMailer();
        aux.sendToApprovalMail(header.Id, new Set<Id>{item.Id});
        aux.sendToFactoryApprovalMail(header.Id, new Set<Id>{item.Id});
        
        Integer invocations = Limits.getEmailInvocations();
        System.assert(invocations > 0, 'Mail not sent. Mails sent: ' + invocations);
    }
    
    @isTest
    static void sendReviewedMail() {
        OppPriceRequestHeader__c header = [select Id, NeededBy__c from OppPriceRequestHeader__c limit 1];
        OppPriceRequestItem__c item = [select Id, status__c from OppPriceRequestItem__c];
        item.Status__c = 'APPROVED';
        update item;

        OppPriceRequestMailer aux =  new OppPriceRequestMailer();
        aux.sendReviewedMail(header.Id, new Set<Id>{item.Id});
        aux.sendFactoryReviewedMail(header.Id, new Set<Id>{item.Id});

        Integer invocations = Limits.getEmailInvocations();
        System.assert(invocations > 0, 'Mail not sent. Mails sent: ' + invocations);
    }
}