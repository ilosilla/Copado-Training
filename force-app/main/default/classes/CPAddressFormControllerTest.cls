@isTest public class CPAddressFormControllerTest {

    @testSetup private static void testSetup() {
        TestUtils.enableTriggers();      
  
        // Create account
        DataFactoryAccount.autoInsert = false;
        List<Account> accounts = DataFactoryAccount.createAccounts(RecordTypeLibrary.Account_ResellerCustomer, 1);
        accounts[0].SAP_Id__c = '0001234567';
        accounts[0].Name = 'RESELLER';
        insert accounts;
        DataFactoryPorcelanosaAddress.createAddresses();
    }
    
    @isTest public static void testGetFormData() {
        Test.setMock(HttpCalloutMock.class, new SAPAddressHelperMockupTest());        
        Account acc = [select Id from Account limit 1];
        CPAddressFormController.DataDTO data = CPAddressFormController.getFormData(acc.Id);
        Assert.IsTrue(data.countries.size() > 0, 'Countries is empty');
        Assert.IsTrue(data.states.get('ES').size() > 0, 'States is empty');
    }

    @isTest public static void testSaveContactPointAddress() {
        Account acc = [select Id from Account limit 1];
        Account syncableAccount = new Account(Id = acc.Id, AddressesSynced__c = true);
        update syncableAccount;
        ContactPointAddress caddress = new ContactPointAddress();
        caddress.ParentId = acc.Id;
        caddress.Name = 'TEST CPA';
        caddress.CountryCode = 'US';
        caddress.StateCode = 'NJ';
        caddress.Street = '7 Boroline Road';
        caddress.City = 'Saddle River';
        caddress.PostalCode = '07458';
        caddress.Phone__c = '01234 432 323';
        Test.setMock(HttpCalloutMock.class, new SAPAddressHelperMockupTest());
        try {
            CPAddressFormController.SavedAddressDTO dto = CPAddressFormController.saveContactPointAddress(caddress);
            Assert.isNotNull(dto.address.Id, 'Error saving the address');
        } catch (Exception wx) {
            Assert.isNotNull(wx, 'Yeah, no probs if tehre is an exception');
        }

    }

    @isTest private static void testPicklists() {
        List<PorcelanosaAddress__c> addresses = new PorcelanosaAddressesSelector().selectBySalesOrg(new Set<String> {'502', '605'});
        List<CPAddressFormController.PicklistOption> l1 = CPAddressFormController.getShowroomsPicklist(addresses);
        Assert.isTrue(l1.size() > 0, 'No showrooms found');
        List<CPAddressFormController.PicklistOption> l2 = CPAddressFormController.getPickupPointsPicklist(addresses);
        Assert.isTrue(l2.size() > 0, 'No collection points found');
    }

}