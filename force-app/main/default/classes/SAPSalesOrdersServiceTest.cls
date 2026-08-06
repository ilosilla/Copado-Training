@IsTest public with sharing class SAPSalesOrdersServiceTest {

    @testSetup static void setupTestData() {
        DataFactoryAccount.createBusinessAccounts(1);
    }
    @IsTest static void testReadPricesFromSAP() {
        SAPOrderHeaderDTO header = new SAPOrderHeaderDTO();
        header.Version = '2.1';
        header.OperationType = '20';
        header.Index = 0;
        header.m_Date = Date.today();
        header.RequestedBy = '0002101523';
        header.SalesOrg = '603';
        header.Channel = '10';
        header.Reference = 'PO24-00001';

        SAPOrderItemDTO item = new SAPOrderItemDTO();
        item.Sequence = 10;
        item.ProductCode = '100202546';
        item.Unit = 'BOX';
        item.Quantity = 6;
        header.Items = new List<SAPOrderItemDTO>{ item };

        // Arrange
        Test.setMock(HttpCalloutMock.class, new SAPProxyMock());

        // Act
        Test.startTest();
        SAPSalesOrdersService.SAPOrderResultDTO result =  SAPSalesOrdersService.readPricesFromSAP(header);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, result);
        System.assertEquals('USD', result.currencyCode);

        // Goods
        System.assertEquals(312.83, result.goodsNetAmount);
        System.assertEquals(30.50, result.goodsTax);

        // Shipping
        System.assertEquals(50, result.shippingNetAmount);
        System.assertEquals(0, result.shippingTax);

        // Total
        System.assertEquals(
            312.83 + 30.50 + 50,
            result.totalAmount
        );

        // Lines
        System.assertEquals(2, result.lines.size());

        SAPSalesOrdersService.SAPOrderLineDTO line = result.lines[0];
        System.assertEquals('100202546', line.stockKeepingUnit);
        System.assertEquals(false, line.isShipping);
    }

    private class SAPProxyMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('x-csrf-token', 'toctoctoc');
            res.setHeader('set-cookie', 'cooookie');
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody(
                '[{' +
                '  "index": 1,' +
                '  "success": true,' +
                '  "sapOrder": {' +
                '    "header": {' +
                '      "currency": "USD"' +
                '    },' +
                '    "items": [' +
                '      {' +
                '        "itmNumber": 10,' +
                '        "material": "000000000100202546",' +
                '        "shortText": "Test product",' +
                '        "reqQty": 3,' +
                '        "salesUnit": "CS",' +
                '        "netPrice": 5.98,' +
                '        "condUnit": "FT2",' +
                '        "condPUnt": 1,' +
                '        "netValue": 312.83,' +
                '        "taxAmount": 30.50' +
                '      },' +
                '      {' +
                '        "itmNumber": 20,' +
                '        "material": "FLETE-001",' +
                '        "shortText": "Shipping",' +
                '        "reqQty": 1,' +
                '        "salesUnit": "UN",' +
                '        "netPrice": 50,' +
                '        "condUnit": "UN",' +
                '        "condPUnt": 1,' +
                '        "netValue": 50,' +
                '        "taxAmount": 0' +
                '      }' +
                '    ]' +
                '  }' +
                '}]'
            );

            return res;
        }
    }
}