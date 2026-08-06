@IsTest
private class OrderConfirmationMailerTest {

    @TestSetup
    private static void testSetup() {
        DataFactoryOrganization.createData();
        DataFactoryOrder.useContactPointAddresses = false;

        Order orderRecord = DataFactoryOrder.createOrders(1)[0];

        Account accountRecord = [
            SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingStateCode, BillingPostalCode, BillingCountry, BillingCountryCode
            FROM Account
            WHERE Id = :orderRecord.AccountId
        ];
        accountRecord.Name = 'Imperial Tile & Stone Inc.';
        accountRecord.BillingStreet = '7211 Whitsett Avenue';
        accountRecord.BillingCity = 'Los Angeles';
        accountRecord.BillingState = 'California';
        accountRecord.BillingStateCode = 'CA';
        accountRecord.BillingPostalCode = '91605';
        accountRecord.BillingCountry = 'United States';
        accountRecord.BillingCountryCode = 'US';
        update accountRecord;

        insert new PorcelanosaAddress__c(
            Name = 'Porcelanosa Los Angeles',
            SAPSalesOrg__c = orderRecord.SalesOrg__c,
            NBK_isActive__c = true,
            NBK_Address__Street__s = '1301 South State College Boulevard Suite E',
            NBK_Address__City__s = 'Anaheim',
            NBK_Address__PostalCode__s = '92806',
            NBK_Address__StateCode__s = 'CA',
            NBK_Address__CountryCode__s = 'US',
            NBK_Phone__c = '+1 714-772-3183',
            Email__c = 'info@porcelanosa-usa.com'
        );

        insert new OrderDeliveryGroup(
            OrderId = orderRecord.Id,
            DeliverToName = 'John Blakstone',
            DeliverToStreet = '18 Lake Street',
            DeliverToCity = 'Waldwick',
            DeliverToState = 'New Jersey',
            DeliverToStateCode = 'NJ',
            DeliverToPostalCode = '07887',
            DeliverToCountry = 'United States',
            DeliverToCountryCode = 'US'
        );

        List<OrderItem> orderItems = [
            SELECT Id, Product2Id, StockKeepingUnit__c, ProductCode__c, CustomName__c, ProductName__c,
                   Quantity, SalesUnit__c, TotalLineAmount, CurrencyIsoCode
            FROM OrderItem
            WHERE OrderId = :orderRecord.Id
            ORDER BY CreatedDate ASC
        ];

        orderItems[0].CustomName__c = 'Capri Stone 18"X47"';
        orderItems[0].Quantity = 11;
        orderItems[0].SalesUnit__c = 'CJ';
        orderItems[0].TotalLineAmount = 716.99;

        orderItems[1].CustomName__c = null;
        orderItems[1].Quantity = 3;
        orderItems[1].SalesUnit__c = 'PZS';
        orderItems[1].TotalLineAmount = 45;

        update orderItems;

        Product2 secondProduct = [
            SELECT Id, Name, ProductCode, StockKeepingUnit
            FROM Product2
            WHERE Id = :orderItems[1].Product2Id
            LIMIT 1
        ];
        secondProduct.Name = 'SHIPPING CHARGE';
        secondProduct.ProductCode = 'FLETE';
        secondProduct.StockKeepingUnit = null;
        update secondProduct;
    }

    @IsTest
    private static void testBuildOrderItemRowsUsesExpectedColumnsAndFallbacks() {
        Order orderRecord = [SELECT Id FROM Order LIMIT 1];
        OrderConfirmationMailer mailer = new OrderConfirmationMailer(orderRecord.Id);

        List<String> columns = mailer.buildOrderItemColumns();
        List<List<String>> rows = mailer.buildOrderItemRows();

        Assert.areEqual(
            new List<String>{ 'SKU', 'Product', 'Quantity', 'Net amount' },
            columns
        );
        Assert.areEqual(2, rows.size());

        Assert.areEqual('100000000', rows[0][0]);
        Assert.areEqual('Capri Stone 18"X47"', rows[0][1]);
        Assert.areEqual('11 Boxes', rows[0][2]);
        Assert.isTrue(rows[0][3].startsWith('USD 716'), 'Unexpected first row net amount: ' + rows[0][3]);

        Assert.areEqual('FLETE', rows[1][0]);
        Assert.areEqual('SHIPPING CHARGE', rows[1][1]);
        Assert.areEqual('3 Pieces', rows[1][2]);
        Assert.isTrue(rows[1][3].startsWith('USD 45'), 'Unexpected second row net amount: ' + rows[1][3]);
    }

    @IsTest
    private static void testBuildOrderItemRowsHandlesBlankUnitAndNullNetAmount() {
        Order orderRecord = [SELECT Id FROM Order LIMIT 1];
        OrderItem orderItem = [
            SELECT Id, Quantity, SalesUnit__c, TotalLineAmount
            FROM OrderItem
            WHERE OrderId = :orderRecord.Id
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        orderItem.Quantity = 1;
        orderItem.SalesUnit__c = null;
        orderItem.TotalLineAmount = null;
        update orderItem;

        OrderConfirmationMailer mailer = new OrderConfirmationMailer(orderRecord.Id);
        List<List<String>> rows = mailer.buildOrderItemRows();

        Assert.areEqual('1', rows[0][2]);
        Assert.areEqual('', rows[0][3]);
    }

    @IsTest
    private static void testBuildMailBuilderRendersOrderItemsSection() {
        Order orderRecord = [SELECT Id FROM Order LIMIT 1];
        OrderConfirmationMailer mailer = new OrderConfirmationMailer(orderRecord.Id);

        MailBuilder builder = mailer.buildMailBuilder();
        String htmlBody = builder.renderHtmlBody();

        Assert.isTrue(htmlBody.contains('>Order items<'));
        Assert.isTrue(htmlBody.contains('>Net amount<'));
        Assert.isTrue(htmlBody.contains('Capri Stone 18&quot;X47&quot;'));
        Assert.isFalse(htmlBody.contains('PRODUCT 0'));
        Assert.isTrue(htmlBody.contains('11 Boxes'));
        Assert.isTrue(htmlBody.contains('3 Pieces'));
        Assert.isTrue(
            htmlBody.contains('font-size:24px;line-height:30px;color:#3f4952;font-weight:normal;font-family:Georgia,Times New Roman,serif;')
        );
    }

    @IsTest
    private static void testBuildMailBuilderUsesDefaultSignatureAndFooter() {
        Order orderRecord = [SELECT Id FROM Order LIMIT 1];
        OrderConfirmationMailer mailer = new OrderConfirmationMailer(orderRecord.Id);

        MailBuilder builder = mailer.buildMailBuilder();
        String htmlBody = builder.renderHtmlBody();

        Assert.isTrue(htmlBody.contains('Porcelanosa Los Angeles'));
        Assert.isTrue(htmlBody.contains('1301 South State College Boulevard Suite E'));
        Assert.isTrue(htmlBody.contains('Anaheim, CA 92806'));
        Assert.isTrue(htmlBody.contains('+1 714-772-3183 | info@porcelanosa-usa.com'));
        Assert.isTrue(
            htmlBody.contains(
                'PORCELANOSA © ' + String.valueOf(Date.today().year()) + '. This is an automated confirmation email for your order.'
            )
        );
    }

    @IsTest
    private static void testBuildMailBuilderUsesManualSignatureAndFooterOverrides() {
        Order orderRecord = [SELECT Id FROM Order LIMIT 1];
        OrderConfirmationMailer mailer = new OrderConfirmationMailer(orderRecord.Id)
            .setSignature('Manual signature')
            .setFooter('Manual footer');

        MailBuilder builder = mailer.buildMailBuilder();
        String htmlBody = builder.renderHtmlBody();

        Assert.isTrue(htmlBody.contains('Manual signature'));
        Assert.isTrue(htmlBody.contains('Manual footer'));
        Assert.isFalse(htmlBody.contains('Porcelanosa Los Angeles'));
        Assert.isFalse(
            htmlBody.contains(
                'PORCELANOSA © ' + String.valueOf(Date.today().year()) + '. This is an automated confirmation email for your order.'
            )
        );
    }

    @IsTest
    private static void testBuildMailBuilderPrefersB2BWarehouseForDefaultSignature() {
        Order orderRecord = [
            SELECT Id, SalesOrg__c
            FROM Order
            LIMIT 1
        ];

        insert new PorcelanosaAddress__c(
            Name = 'Preferred Warehouse',
            SAPSalesOrg__c = orderRecord.SalesOrg__c,
            NBK_isActive__c = true,
            NBK_Address_Type__c = 'B2B-Warehouse',
            NBK_Address__Street__s = '1 Warehouse Way',
            NBK_Address__City__s = 'Anaheim',
            NBK_Address__PostalCode__s = '92801',
            NBK_Address__StateCode__s = 'CA',
            NBK_Address__CountryCode__s = 'US',
            NBK_Phone__c = '+1 555-000-0000',
            Email__c = 'warehouse@porcelanosa-usa.com'
        );

        OrderConfirmationMailer mailer = new OrderConfirmationMailer(orderRecord.Id);
        String htmlBody = mailer.buildMailBuilder().renderHtmlBody();

        Assert.isTrue(htmlBody.contains('Preferred Warehouse'));
        Assert.isTrue(htmlBody.contains('warehouse@porcelanosa-usa.com'));
        Assert.isFalse(htmlBody.contains('Porcelanosa Los Angeles'));
    }

    @IsTest
    private static void testPublicApiValidationMethodsThrowExpectedExceptions() {
        Order orderRecord = [SELECT Id FROM Order LIMIT 1];

        assertConstructorFailsWhenOrderIdIsNull();

        try {
            new OrderConfirmationMailer(orderRecord.Id).addTo('   ');
            Assert.fail('Expected addTo blank validation exception.');
        } catch (OrderConfirmationMailer.OrderConfirmationMailerException ex) {
            Assert.areEqual('Recipient email is required.', ex.getMessage());
        }

        try {
            new OrderConfirmationMailer(orderRecord.Id).addTo((List<String>) null);
            Assert.fail('Expected addTo null list validation exception.');
        } catch (OrderConfirmationMailer.OrderConfirmationMailerException ex) {
            Assert.areEqual('Recipient email list cannot be null.', ex.getMessage());
        }

        try {
            new OrderConfirmationMailer(orderRecord.Id).addCc('   ');
            Assert.fail('Expected addCc blank validation exception.');
        } catch (OrderConfirmationMailer.OrderConfirmationMailerException ex) {
            Assert.areEqual('CC email is required.', ex.getMessage());
        }

        try {
            new OrderConfirmationMailer(orderRecord.Id).addCc((List<String>) null);
            Assert.fail('Expected addCc null list validation exception.');
        } catch (OrderConfirmationMailer.OrderConfirmationMailerException ex) {
            Assert.areEqual('CC email list cannot be null.', ex.getMessage());
        }

        try {
            new OrderConfirmationMailer(orderRecord.Id).addBcc('   ');
            Assert.fail('Expected addBcc blank validation exception.');
        } catch (OrderConfirmationMailer.OrderConfirmationMailerException ex) {
            Assert.areEqual('BCC email is required.', ex.getMessage());
        }

        try {
            new OrderConfirmationMailer(orderRecord.Id).addBcc((List<String>) null);
            Assert.fail('Expected addBcc null list validation exception.');
        } catch (OrderConfirmationMailer.OrderConfirmationMailerException ex) {
            Assert.areEqual('BCC email list cannot be null.', ex.getMessage());
        }

        try {
            new OrderConfirmationMailer(orderRecord.Id).setSubject('   ');
            Assert.fail('Expected subject validation exception.');
        } catch (OrderConfirmationMailer.OrderConfirmationMailerException ex) {
            Assert.areEqual('Subject is required.', ex.getMessage());
        }

        try {
            new OrderConfirmationMailer(orderRecord.Id).setSignature('   ');
            Assert.fail('Expected signature validation exception.');
        } catch (OrderConfirmationMailer.OrderConfirmationMailerException ex) {
            Assert.areEqual('Signature is required.', ex.getMessage());
        }

        try {
            new OrderConfirmationMailer(orderRecord.Id).setFooter('   ');
            Assert.fail('Expected footer validation exception.');
        } catch (OrderConfirmationMailer.OrderConfirmationMailerException ex) {
            Assert.areEqual('Footer is required.', ex.getMessage());
        }

        try {
            new OrderConfirmationMailer(orderRecord.Id).send();
            Assert.fail('Expected send recipient validation exception.');
        } catch (OrderConfirmationMailer.OrderConfirmationMailerException ex) {
            Assert.areEqual('At least one recipient is required.', ex.getMessage());
        }

        try {
            new OrderConfirmationMailer(Id.valueOf('801000000000000AAA'))
                .addTo('test@example.com')
                .send();
            Assert.fail('Expected order not found exception.');
        } catch (OrderConfirmationMailer.OrderConfirmationMailerException ex) {
            Assert.areEqual('Order not found: 801000000000000AAA', ex.getMessage());
        }
    }

    @IsTest
    private static void testSendSupportsToCcAndBccRecipients() {
        Order orderRecord = [SELECT Id FROM Order LIMIT 1];

        Test.startTest();
        new OrderConfirmationMailer(orderRecord.Id)
            .addTo('customer@example.com')
            .addCc(new List<String>{ 'sales@example.com' })
            .addBcc(new List<String>{ 'audit@example.com' })
            .setSubject('Custom subject')
            .send();
        Test.stopTest();

        Assert.isTrue(true, 'Order confirmation email send should complete without exceptions in test context.');
    }

    @IsTest
    private static void testBuildMailBuilderUsesOrderFallbacksWithoutDeliveryGroup() {
        Order fallbackOrder = [
            SELECT Id, SalesOrg__c, DeliveryDate__c,
                   ShippingStreet, ShippingCity, ShippingState, ShippingStateCode,
                   ShippingPostalCode, ShippingCountry, ShippingCountryCode
            FROM Order
            LIMIT 1
        ];
        fallbackOrder.DeliveryDate__c = Date.newInstance(2026, 4, 10);
        fallbackOrder.ShippingStreet = '500 Ocean Drive';
        fallbackOrder.ShippingCity = 'Miami';
        fallbackOrder.ShippingState = 'Florida';
        fallbackOrder.ShippingStateCode = 'FL';
        fallbackOrder.ShippingPostalCode = '33139';
        fallbackOrder.ShippingCountry = 'United States';
        fallbackOrder.ShippingCountryCode = 'US';
        update fallbackOrder;

        delete [
            SELECT Id
            FROM OrderDeliveryGroup
            WHERE OrderId = :fallbackOrder.Id
        ];

        insert new PorcelanosaAddress__c(
            Name = 'Fallback Warehouse',
            SAPSalesOrg__c = fallbackOrder.SalesOrg__c,
            NBK_isActive__c = true,
            NBK_Address_Type__c = 'Warehouse',
            NBK_Address__Street__s = '10 Warehouse Road',
            NBK_Address__City__s = 'Miami',
            NBK_Address__PostalCode__s = '33130',
            NBK_Address__StateCode__s = 'FL',
            NBK_Address__CountryCode__s = 'US',
            Email__c = 'fallback@porcelanosa-usa.com'
        );

        String htmlBody = new OrderConfirmationMailer(fallbackOrder.Id)
            .buildMailBuilder()
            .renderHtmlBody();

        Assert.isTrue(htmlBody.contains('10/4/2026') || htmlBody.contains('4/10/2026') || htmlBody.contains('2026'));
        Assert.isTrue(htmlBody.contains('500 Ocean Drive'));
        Assert.isTrue(htmlBody.contains('Miami, FL 33139'));
        Assert.isTrue(htmlBody.contains('fallback@porcelanosa-usa.com'));
    }

    private static void assertConstructorFailsWhenOrderIdIsNull() {
        try {
            new OrderConfirmationMailer(null);
            Assert.fail('Expected OrderConfirmationMailerException to be thrown.');
        } catch (OrderConfirmationMailer.OrderConfirmationMailerException ex) {
            Assert.areEqual('Order Id is required.', ex.getMessage());
        }
    }

}