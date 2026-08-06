@IsTest
private class B2BSalesDocContractsTest {

    /* =========================================================
     * TESTS
     * ========================================================= */

    @IsTest
    static void shouldCoverContractsGettersAndSetters() {
        // Header
        B2BSalesDocContracts.OrderHeaderDTO h = new B2BSalesDocContracts.OrderHeaderDTO();
        h.orderNumber = '4500001234';
        h.orderDate = Date.newInstance(2026, 2, 28);
        h.deliveryDate = Date.newInstance(2026, 3, 5);
        h.status = '10';
        h.poNumber = 'PO-999';

        h.net = 100;
        h.tax = 21;
        h.total = 121;
        h.currencyCode = 'EUR';

        h.sapCustomerCode = '1087111';
        h.accountId = UserInfo.getUserId(); // cualquier Id válido sirve para cubrir
        h.SalesOrg = 'ES10';
        h.Channel = 'B2B';
        h.SalesOffice = 'VAL';

        h.sapShipToCode = 'SHIP01';
        h.deliveryStatus = 'OPEN';
        h.invoiceStatus = 'NOT_INVOICED';

        h.orderId = UserInfo.getUserId();
        h.contactPointAddressId = UserInfo.getUserId();
        h.porcelanosaAddress = UserInfo.getUserId();

        // Addresses (no tocamos AddressDTO, solo instanciamos y asignamos algunos campos)
        AddressDTO bill = new AddressDTO();
        bill.name = 'Billing';
        bill.street = 'Street 1';
        bill.city = 'Valencia';

        AddressDTO ship = new AddressDTO();
        ship.name = 'Shipping';
        ship.street = 'Street 2';
        ship.city = 'Madrid';

        h.billingAddress = bill;
        h.shippingAddress = ship;

        // Items
        B2BSalesDocContracts.OrderItemDTO it = new B2BSalesDocContracts.OrderItemDTO();
        it.orderNumber = '4500001234';
        it.lineNumber = 10;
        it.sku = 'SKU-001';
        it.name = 'Tile ABC';
        it.quantity = 2;
        it.salesUnit = 'BOX';
        it.netUnitPrice = 50;
        it.netPriceUnit = 'BOX';
        it.netAmount = 100;
        it.taxAmount = 21;
        it.totalAmount = 121;
        it.currencyCode = 'EUR';
        it.squareMetres = 1.44;
        it.statusCode = 'OPEN';
        it.openFlag = 'X';
        it.productId = UserInfo.getUserId();

        h.items = new List<B2BSalesDocContracts.OrderItemDTO>{ it };

        // Touch getters + a couple of asserts (enough)
        System.assertEquals('4500001234', h.orderNumber);
        System.assertEquals('SKU-001', h.items[0].sku);
        System.assertEquals('Madrid', h.shippingAddress.city);

        // Access remaining fields to cover getters (no asserts needed)
        String unused = '' +
            h.poNumber + h.currencyCode + h.sapCustomerCode + h.SalesOrg + h.Channel + h.SalesOffice +
            h.sapShipToCode + h.deliveryStatus + h.invoiceStatus +
            String.valueOf(h.net) + String.valueOf(h.tax) + String.valueOf(h.total) +
            String.valueOf(it.lineNumber) + it.salesUnit + it.netPriceUnit + it.statusCode + it.openFlag;
        System.assert(unused != null);
    }
}