@isTest class RESTUSLeadsTest {

    @testSetup static void testSetup() {
        TestUtils.enableTriggers();
        DataFactoryOrganization.createData();
    }

    @isTest static void test0 () {
        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        request.addHeader('httpMethod', 'GET');
        request.requestUri = '/services/apexrest/web-leads/us';       
        RestContext.request = request; 
        RestContext.response= response;
        Test.startTest();
        Boolean ok = false;
        RESTUSLeads.get();
        ok = true;
        Test.stopTest();
        System.assertEquals(true, ok, 'ok should be true');
    }
    
    /** US Person Account tests */
    @isTest static void test1 () {
        Account acc = DataFactoryAccount.createPersonAccounts(1)[0];
        RESTUSLeads.USWebLeadDTO dto = getData('Test 1', acc.PersonEmail);

        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        request.addHeader('httpMethod', 'POST');
        request.requestUri = '/services/apexrest/web-leads/us';       
        RestContext.request = request; 
        RestContext.response= response;
        
        Test.startTest();
        RESTUSLeads.post(dto, null, null);
        Test.stopTest();

        Lead[] leads  = [select Id, Title, OwnerId, AccountId__c from Lead];
        System.assertEquals(1, leads.size(), 'Test1a: There should be one and only one lead');
        Lead lead = leads[0];
        System.assertEquals(acc.Id, lead.AccountId__c, 'Test1b: Wrong account');        
        System.assertNotEquals(null, lead.ownerId, 'Test1c: Owner cannot be blank');        
    }

    /** US Trade Account tests */
    @isTest static void test2 () {
        Account acc = DataFactoryAccount.createBusinessAccounts(1)[0];
        Contact con = DataFactoryContact.createContacts(acc.Id, 1)[0];
        RESTUSLeads.USWebLeadDTO dto = getData('Test 2', con.EMail);
        dto.company = 'ACME Co';

        List<RESTUSLeads.ProductDTO> products = new List<RESTUSLeads.ProductDTO>();
        RESTUSLeads.ProductDTO product = new RESTUSLeads.ProductDTO();
        product.productCode = '111';
        product.productName = 'Producto';
        product.quantity = 1;
        product.unit = 'MT2';
        products.add(product);

        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        request.addHeader('httpMethod', 'POST');
        request.requestUri = '/services/apexrest/web-leads/us';               
        RestContext.request = request; 
        RestContext.response= response;
        
        Test.startTest();
        RESTUSLeads.post(dto, products, null);
        Test.stopTest();

        Lead[] leads  = [select Id, Title, AccountId__c, ContactId__c from Lead];
        System.assertEquals(1, leads.size(), 'Test2a: There should be one and only one lead');
        
        Lead lead = leads[0];
        System.assertEquals(acc.Id, lead.AccountId__c, 'Test2b: Wrong account');        
        System.assertEquals(con.Id, lead.ContactId__c, 'Test 2c: Wrong contact');

        List<ProductListItem__c> dbProducts = [select Id from ProductListItem__c];
        System.assertEquals(1, dbProducts.size(), 'Test 2d: Wrong product list size');

    }

    /** US Retail Account tests witth files attached */
    @isTest static void test3 () {
        Account acc = DataFactoryAccount.createPersonAccounts(1)[0];
        RESTUSLeads.USWebLeadDTO dto = getData('Test 3', acc.PersonEmail);
        OAttachmentDTO file = new OAttachmentDTO();
        file.fileName = 't1.txt';
        file.content = 'Hello world!';
        List<OAttachmentDTO> files = new List<OAttachmentDTO>();
        files.add(file);

        RestRequest request = new RestRequest(); 
        RestResponse response = new RestResponse();
        request.addHeader('httpMethod', 'POST');
        request.requestUri = '/services/apexrest/web-leads/us';       
        //request.requestBody = Blob.valueOf(JsonMsg);
        RestContext.request = request; 
        RestContext.response= response;
        
        Test.startTest();
        RESTUSLeads.post(dto, null, files);
        Test.stopTest();
        
        Lead[] leads  = [select Id, Title, AccountId__c, ContactId__c from Lead];
        System.assertEquals(1, leads.size(), 'Test3a: There should be one and only one lead');
        Lead lead = leads[0];
        List<ContentVersion> versions = OAttachmentsService.getSObjectAttachments(lead.Id);
        System.assertEquals(1, versions.size(), 'Test3b: There should be one attachment');        
    }


    private static RESTUSLeads.USWebLeadDTO getData(String title, String email) {
        // Sales_Office__c salesOffice = [SELECT id FROM Sales_Office__c LIMIT 1];

        RESTUSLeads.USWebLeadDTO dto = new RESTUSLeads.USWebLeadDTO();
        dto.company = '';
        dto.lastname = 'Pearson';
        dto.firstname = 'Susan';
        dto.email = email;
        dto.profile = 'Consumer';
        dto.countryCode = 'US';
        dto.Street = '200 Franklin Turnpike';
        dto.stateName = 'New Jersey';
        dto.Town = 'Waldwick';
        dto.postCode = '07463';
        dto.mobile = '222 333 222';
        dto.website = 'Contact Form';
        dto.campaign = 'Christmas 2021';
        dto.comments = 'Full kitchen';
        dto.title = title;
        dto.appointmentType = 'V';
        dto.showroom = '3031';
        return dto;
    }
    
} // class