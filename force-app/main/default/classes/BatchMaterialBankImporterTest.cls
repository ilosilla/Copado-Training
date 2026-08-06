@isTest public  class BatchMaterialBankImporterTest {
    
    @testSetup static void testSetup() {
        SystemSettings__c ss = SystemSettings.getSystemSettings();
        ss.SAPAPI__c = 'https:/dymmy-ai.com/';
        ss.SAPCPIAPIKey__c = '321321321321';
        Database.Upsert(ss);
    }

    @isTest static void test001() {
        Test.setMock(HttpCalloutMock.class, new Mocker());
        Test.startTest();
        BatchMaterialBankImporter.executeNow();
        Test.stopTest();
        SYS_BatchJournal__c[] journals = [select Name from SYS_BatchJournal__c];
        Assert.areNotEqual(0, journals.size(), 'A journal was expected');
    }
    public class Mocker implements HttpCalloutMock {
        
        public Boolean testError = false;
        public String dirContent = 
            '{'+
            '    "folder": "/inbox",'+
            '    "totalItems": 1,'+
            '    "items": ['+
            '        {'+
            '            "name": "MGT_DailyLeads_1_20251008075536.xml",'+
            '            "type": "file",'+
            '            "size": 350234,'+
            '            "modified": "2025-10-08T07:55:00Z",'+
            '            "url": "/processed/MGT_DailyLeads_1_20251008075536.xml"'+
            '        }'+
            '    ]'+
            '}';

        public String fileContent =
            '<?xml version=\'1.0\' encoding=\'utf-8\'?>' +
            '<root>' +
            '    <row>' +
            '        <CONSIGNEE>7936</CONSIGNEE>' +
            '        <CREATEDATE>10-06-2025 07:48:49</CREATEDATE>' +
            '        <row>' +
            '            <ORDERDATE>2025-10-03</ORDERDATE>' +
            '            <CONTACT1NAME>Shawna Boyd</CONTACT1NAME>' +
            '            <EntityId>305977</EntityId>' +
            '            <CONTACT1EMAIL>shawna@boydinteriordesign.com</CONTACT1EMAIL>' +
            '            <CONTACT1PHONE>772-285-5281</CONTACT1PHONE>' +
            '            <STREET1>4435 W Montgomery Ave</STREET1>' +
            '            <Company>Boyd Interior Design LLC</Company>' +
            '            <City>Tampa</City>' +
            '            <State>Florida</State>' +
            '            <Zip>33616-1040</Zip>' +
            '            <Country>US</Country>' +
            '            <CompanyPractice>Interior Design Firm: Residential</CompanyPractice>' +
            '            <Title>Interior Designer III</Title>' +
            '            <row>' +
            '                <ORDERID>0042906920326</ORDERID>' +
            '                <row>' +
            '                    <ProjectName>Bayshore</ProjectName>' +
            '                    <QTYORIGINAL>1.0000</QTYORIGINAL>' +
            '                    <SKU>100340697</SKU>' +
            '                    <Name>BALI JIMBARAN 14,7x14,7,0,85</Name>' +
            '                    <MBShipped>Y</MBShipped>' +
            '                    <MBSKU>100561099</MBSKU>' +
            '                    <SerialSKU />' +
            '                    <Color />' +
            '                    <ProjectType>Residential</ProjectType>' +
            '                    <ProjectPhase>Schematic Design</ProjectPhase>' +
            '                    <ProjectDescription>Bayshore is a Residential project currently in ' +
            '                        the Schematic Design phase located in Tampa, FL. The estimated ' +
            '                        project completion date is June 2026 and the size is 0 - 5K sq ft. ' +
            '                        The approximate budget is $10K - $50K.</ProjectDescription>' +
            '                    <ProjectLocation>Florida</ProjectLocation>' +
            '                    <ProjectCity>Tampa</ProjectCity>' +
            '                    <ProjectSize>0 - 5K sq ft</ProjectSize>' +
            '                    <ProjectBudget>$10K - $50K</ProjectBudget>' +
            '                    <ExpectedProjectCompletionMonth>June</ExpectedProjectCompletionMonth>' +
            '                    <ExpectedProjectCompletionYear>2026</ExpectedProjectCompletionYear>' +
            '                </row>' +
            '            </row>' +
            '        </row>' +
            '    </row>' +
            '</root>';

        public HttpResponse respond(HttpRequest request) {            
            // Set up mock HTTP response     
            request.getBody();
            HttpResponse mockResponse = new HttpResponse();
            mockResponse.setStatusCode(200);
            if (request.getEndpoint()?.endsWith('/')) {
                mockResponse.setBody(this.dirContent);
            } else {
                mockResponse.setBody(this.fileContent);
            }
            return mockResponse;
        }
    }

}