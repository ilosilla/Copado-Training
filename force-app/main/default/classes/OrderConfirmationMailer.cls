/**
 * Purpose: Build and send the standard order confirmation email for a Salesforce Order.
 * 
 * Ramón, March 2026
 *
 * Design notes:
 * - The class is business-oriented and focused on order confirmation emails.
 * - The current implementation is optimized for the B2B confirmation flow, but the class name remains generic for future reuse.
 * - Order data will be loaded lazily during send(), not in the constructor.
 * - Manual recipients are additive; default recipients will only be resolved when none were added manually.
 * - MailBuilder is used internally to render and send the final email. 
 * 
 * Example:
 * 
 * With default recipients and content:
 * new OrderConfirmationMailer(orderId).send()
 *
 * With manual recipients and custom content:
 * new OrderConfirmationMailer(orderId)
 *     .addTo('customer@company.com')
 *     .addCc('sales@porcelanosa-usa.com')
 *     .setSignature('Porcelanosa Los Angeles\n1301 South State College Boulevard Suite E')
 *     .send();
 */
public without sharing class OrderConfirmationMailer {

    private static final String PAYMENT_METHOD_CREDIT = 'CREDIT';
    private static final String PAYMENT_METHOD_CARD = 'CARD';
    private static final String EMAIL_LANGUAGE = 'en_US';

    /* ========================================================= */
    /* PUBLIC DTOs                                               */
    /* ========================================================= */

    public class OrderConfirmationMailerException extends Exception {}

    /* ========================================================= */
    /* PRIVATE STATE                                             */
    /* ========================================================= */

    private class OrderContext {
        private Order orderRecord;
        private Account accountRecord;
        private OrderDeliveryGroup deliveryGroup;
        private List<OrderItem> orderItems = new List<OrderItem>();
        private String billingName;
        private String shippingName;
        private List<String> billingAddressLines = new List<String>();
        private List<String> shippingAddressLines = new List<String>();
        private Date expectedDeliveryDate;
        private String paymentMethodLabel;
        private String formattedTotalAmount;
        private String defaultSignature;
        private String defaultFooter;
    }

    private Id orderId;
    private List<String> manualToEmails = new List<String>();
    private List<String> manualCcEmails = new List<String>();
    private List<String> manualBccEmails = new List<String>();
    private String subject;
    private String signature;
    private String footer;
    private OrderContext orderContext;

    /* ========================================================= */
    /* PUBLIC METHODS (API)                                      */
    /* ========================================================= */

    public OrderConfirmationMailer(Id orderId) {
        if (orderId == null) {
            throw new OrderConfirmationMailerException('Order Id is required.');
        }

        this.orderId = orderId;
    }

    public OrderConfirmationMailer addTo(String email) {
        if (String.isBlank(email)) {
            throw new OrderConfirmationMailerException('Recipient email is required.');
        }

        this.manualToEmails.add(email.trim());
        return this;
    }

    public OrderConfirmationMailer addTo(List<String> emails) {
        if (emails == null) {
            throw new OrderConfirmationMailerException('Recipient email list cannot be null.');
        }

        for (String email : emails) {
            this.addTo(email);
        }

        return this;
    }

    public OrderConfirmationMailer addCc(String email) {
        if (String.isBlank(email)) {
            throw new OrderConfirmationMailerException('CC email is required.');
        }

        this.manualCcEmails.add(email.trim());
        return this;
    }

    public OrderConfirmationMailer addCc(List<String> emails) {
        if (emails == null) {
            throw new OrderConfirmationMailerException('CC email list cannot be null.');
        }

        for (String email : emails) {
            this.addCc(email);
        }

        return this;
    }

    public OrderConfirmationMailer addBcc(String email) {
        if (String.isBlank(email)) {
            throw new OrderConfirmationMailerException('BCC email is required.');
        }

        this.manualBccEmails.add(email.trim());
        return this;
    }

    public OrderConfirmationMailer addBcc(List<String> emails) {
        if (emails == null) {
            throw new OrderConfirmationMailerException('BCC email list cannot be null.');
        }

        for (String email : emails) {
            this.addBcc(email);
        }

        return this;
    }

    public OrderConfirmationMailer setSubject(String subject) {
        if (String.isBlank(subject)) {
            throw new OrderConfirmationMailerException('Subject is required.');
        }

        this.subject = subject.trim();
        return this;
    }

    public OrderConfirmationMailer setSignature(String signature) {
        if (String.isBlank(signature)) {
            throw new OrderConfirmationMailerException('Signature is required.');
        }

        this.signature = signature.trim();
        return this;
    }

    public OrderConfirmationMailer setFooter(String footer) {
        if (String.isBlank(footer)) {
            throw new OrderConfirmationMailerException('Footer is required.');
        }

        this.footer = footer.trim();
        return this;
    }

    public void send() {
        this.validateBeforeSend();
        this.setOrderContext();
        this.buildMailBuilder().send();
    }

    /* ========================================================= */
    /* PRIVATE METHODS                                           */
    /* ========================================================= */

    private void setOrderContext() {
        if (this.orderContext != null) {
            return;
        }

        OrderContext context = new OrderContext();
        context.orderRecord = (Order) new OrdersSelector().selectSingle(this.orderId);

        if (context.orderRecord == null) {
            throw new OrderConfirmationMailerException('Order not found: ' + String.valueOf(this.orderId));
        }

        if (context.orderRecord.AccountId != null) {
            context.accountRecord = new AccountsSelector().selectById(context.orderRecord.AccountId);
        }

        context.deliveryGroup = new OrderDeliveryGroupsSelector().selectByOrderId(this.orderId);
        context.orderItems = new OrderItemsSelector().selectByOrderId(this.orderId);
        context.billingName = this.normalizeDisplayName(context.accountRecord?.Name);
        context.shippingName = this.normalizeDisplayName(this.resolveShippingName(context));
        context.billingAddressLines = this.formatAddressLines(this.buildBillingAddress(context));
        context.shippingAddressLines = this.formatAddressLines(this.buildShippingAddress(context));
        context.expectedDeliveryDate = this.resolveExpectedDeliveryDate(context);
        context.paymentMethodLabel = this.resolvePaymentMethodLabel(context);
        context.formattedTotalAmount = this.formatAmount(
            context.orderRecord.GrandTotalAmount != null ? context.orderRecord.GrandTotalAmount : context.orderRecord.TotalAmount,
            context.orderRecord.CurrencyIsoCode
        );
        context.defaultSignature = this.resolveDefaultSignature(context.orderRecord.SalesOrg__c);
        context.defaultFooter = this.resolveDefaultFooter();
        this.orderContext = context;
    }

    @TestVisible
    private MailBuilder buildMailBuilder() {
        this.setOrderContext();

        MailBuilder builder = new MailBuilder()
            .setTheme(MailBuilder.Themes.B2B)
            .showLogo()
            .setSubject(this.resolveSubject());

        this.applyManualRecipients(builder);

        builder
            .addHeader1('Order confirmation')
            .addParagraph(this.buildIntroParagraph())
            .addDefinitionList(this.buildHeaderSummaryItems())
            .addHeader2('Order items');

        List<List<String>> orderItemRows = this.buildOrderItemRows();
        if (orderItemRows.isEmpty()) {
            builder.addParagraph('No order items were found for this order.');
        } else {
            builder.addTable(this.buildOrderItemColumns(), orderItemRows);
        }

        String resolvedSignature = this.resolveSignature();
        if (String.isNotBlank(resolvedSignature)) {
            builder.addSignature(resolvedSignature);
        }

        String resolvedFooter = this.resolveFooter();
        if (String.isNotBlank(resolvedFooter)) {
            builder.addFooter(resolvedFooter);
        }

        return builder;
    }

    private void validateBeforeSend() {
        if (this.manualToEmails.isEmpty()) {
            throw new OrderConfirmationMailerException('At least one recipient is required.');
        }
    }

    private void applyManualRecipients(MailBuilder builder) {
        if (!this.manualToEmails.isEmpty()) {
            builder.addTo(this.manualToEmails);
        }

        if (!this.manualCcEmails.isEmpty()) {
            builder.addCc(this.manualCcEmails);
        }

        if (!this.manualBccEmails.isEmpty()) {
            builder.addBcc(this.manualBccEmails);
        }
    }

    private Map<String, String> buildHeaderSummaryItems() {
        this.setOrderContext();

        Map<String, String> items = new Map<String, String>();
        this.putHeaderSummaryItem(items, 'Order number', this.orderContext.orderRecord.OrderNumber);
        this.putHeaderSummaryItem(
            items,
            'Delivery date',
            this.orderContext.expectedDeliveryDate != null ? this.orderContext.expectedDeliveryDate.format() : ''
        );
        this.putHeaderSummaryItem(items, 'Payment method', this.orderContext.paymentMethodLabel);
        this.putHeaderSummaryItem(items, 'Total amount', this.orderContext.formattedTotalAmount);
        this.putHeaderSummaryItem(
            items,
            'Bill to',
            this.buildAddressValue(this.orderContext.billingName, this.orderContext.billingAddressLines)
        );
        this.putHeaderSummaryItem(
            items,
            'Ship to',
            this.buildAddressValue(this.orderContext.shippingName, this.orderContext.shippingAddressLines)
        );

        return items;
    }

    private void putHeaderSummaryItem(Map<String, String> items, String label, String value) {
        if (String.isBlank(value)) {
            return;
        }

        items.put(label, value.trim());
    }

    private Date resolveExpectedDeliveryDate(OrderContext context) {
        if (context.deliveryGroup?.DesiredDeliveryDate != null) {
            return context.deliveryGroup.DesiredDeliveryDate;
        }

        return context.orderRecord.DeliveryDate__c;
    }

    private String resolvePaymentMethodLabel(OrderContext context) {
        String paymentModel = context.orderRecord.PaymentModel__c;

        if (paymentModel == PAYMENT_METHOD_CARD) {
            return 'Credit card';
        }

        if (paymentModel == PAYMENT_METHOD_CREDIT) {
            return 'Customer credit';
        }

        return String.isBlank(paymentModel) ? '' : paymentModel;
    }

    private String formatAmount(Decimal amount, String currencyCode) {
        if (amount == null) {
            return '';
        }

        String formattedAmount = amount.setScale(2).format();
        return String.isBlank(currencyCode) ? formattedAmount : currencyCode + ' ' + formattedAmount;
    }

    private String resolveShippingName(OrderContext context) {
        if (String.isNotBlank(context.deliveryGroup?.DeliverToName)) {
            return context.deliveryGroup.DeliverToName;
        }

        return '';
    }

    private String resolveSubject() {
        if (String.isNotBlank(this.subject)) {
            return this.subject;
        }

        String orderNumber = this.orderContext.orderRecord.OrderNumber;
        return String.isBlank(orderNumber) ? 'Order confirmation' : 'Order confirmation - ' + orderNumber;
    }

    private String resolveSignature() {
        if (String.isNotBlank(this.signature)) {
            return this.signature;
        }

        return this.orderContext.defaultSignature;
    }

    private String resolveFooter() {
        if (String.isNotBlank(this.footer)) {
            return this.footer;
        }

        return this.orderContext.defaultFooter;
    }

    private String buildIntroParagraph() {
        return 'Thank you for your order. We confirm that it has been successfully received and is being processed. Please use the order number below for any future reference.';
    }

    @TestVisible
    private List<String> buildOrderItemColumns() {
        return new List<String>{ 'SKU', 'Product', 'Quantity', 'Net amount' };
    }

    @TestVisible
    private List<List<String>> buildOrderItemRows() {
        this.setOrderContext();

        List<List<String>> rows = new List<List<String>>();

        for (OrderItem orderItem : this.orderContext.orderItems) {
            rows.add(new List<String>{
                this.resolveOrderItemSku(orderItem),
                this.resolveOrderItemName(orderItem),
                this.formatOrderItemQuantity(orderItem),
                this.formatAmount(orderItem.TotalLineAmount, orderItem.CurrencyIsoCode)
            });
        }

        return rows;
    }

    private String resolveOrderItemSku(OrderItem orderItem) {
        if (String.isNotBlank(orderItem.StockKeepingUnit__c)) {
            return orderItem.StockKeepingUnit__c;
        }

        if (String.isNotBlank(orderItem.ProductCode__c)) {
            return orderItem.ProductCode__c;
        }

        return '';
    }

    private String resolveOrderItemName(OrderItem orderItem) {
        if (String.isNotBlank(orderItem.CustomName__c)) {
            return orderItem.CustomName__c;
        }

        if (String.isNotBlank(orderItem.ProductName__c)) {
            return orderItem.ProductName__c;
        }

        return '';
    }

    private String formatOrderItemQuantity(OrderItem orderItem) {
        if (orderItem == null || orderItem.Quantity == null) {
            return '';
        }

        if (String.isBlank(orderItem.SalesUnit__c)) {
            return this.formatQuantity(orderItem.Quantity);
        }

        String formattedQuantity = UnitLabelsCommons.formatQuantity(orderItem.Quantity, orderItem.SalesUnit__c);
        String unitLabel = this.formatOrderItemUnitLabel(orderItem.SalesUnit__c, orderItem.Quantity);
        return (formattedQuantity + ' ' + unitLabel).trim();
    }

    private String formatOrderItemUnitLabel(String unitCode, Decimal quantity) {
        UnitLabelsCommons.UnitLabelsDTO unitLabels = UnitLabelsCommons.getUnitLabels(unitCode, EMAIL_LANGUAGE);
        String unitLabel = quantity != null && quantity == 1
            ? unitLabels.singular
            : unitLabels.plural;

        if (String.isBlank(unitLabel)) {
            return '';
        }

        return unitLabel;
    }

    private String formatQuantity(Decimal quantity) {
        if (quantity == null) {
            return '';
        }

        String formattedQuantity = String.valueOf(quantity.setScale(2, RoundingMode.HALF_UP));

        if (formattedQuantity.endsWith('.00')) {
            return formattedQuantity.substring(0, formattedQuantity.length() - 3);
        }

        if (formattedQuantity.endsWith('0')) {
            return formattedQuantity.substring(0, formattedQuantity.length() - 1);
        }

        return formattedQuantity;
    }

    private List<String> formatAddressLines(AddressDTO address) {
        if (address == null) {
            return new List<String>();
        }

        AddressFormatter formatter = new AddressFormatter(address).excludeCountryName();
        return formatter.format();
    }

    private String normalizeDisplayName(String value) {
        if (String.isBlank(value)) {
            return '';
        }

        return value.trim().toUpperCase();
    }

    private String buildAddressValue(String name, List<String> addressLines) {
        if (String.isBlank(name) && (addressLines == null || addressLines.isEmpty())) {
            return '';
        }

        List<String> lines = new List<String>();

        if (String.isNotBlank(name)) {
            lines.add(name.trim());
        }

        if (addressLines != null) {
            for (String addressLine : addressLines) {
                if (String.isNotBlank(addressLine)) {
                    lines.add(addressLine.trim());
                }
            }
        }

        return String.join(lines, '\n');
    }

    private String resolveDefaultSignature(String salesOrg) {
        if (String.isBlank(salesOrg)) {
            return '';
        }

        List<PorcelanosaAddress__c> addresses = new PorcelanosaAddressesSelector().selectBySalesOrg(new Set<String>{ salesOrg });
        if (addresses.isEmpty()) {
            return '';
        }

        PorcelanosaAddress__c showroom = this.selectSignatureAddress(addresses);
        AddressDTO address = AddressDTO.readPorcelanosaAddress(showroom);
        List<String> signatureLines = new List<String>();

        if (String.isNotBlank(showroom.Name)) {
            signatureLines.add(showroom.Name.trim());
        }

        signatureLines.addAll(new AddressFormatter(address).excludeCountryName().format());

        String contactLine = this.buildSignatureContactLine(showroom);
        if (String.isNotBlank(contactLine)) {
            signatureLines.add(contactLine);
        }

        return String.join(signatureLines, '\n');
    }

    private PorcelanosaAddress__c selectSignatureAddress(List<PorcelanosaAddress__c> addresses) {
        if (addresses == null || addresses.isEmpty()) {
            return null;
        }

        for (PorcelanosaAddress__c addressRecord : addresses) {
            if (addressRecord != null && String.isNotBlank(addressRecord.NBK_Address_Type__c)
                && addressRecord.NBK_Address_Type__c.contains('B2B-Warehouse')) {
                return addressRecord;
            }
        }

        return addresses[0];
    }

    private String buildSignatureContactLine(PorcelanosaAddress__c showroom) {
        List<String> contactParts = new List<String>();

        if (String.isNotBlank(showroom.NBK_Phone__c)) {
            contactParts.add(showroom.NBK_Phone__c.trim());
        }

        String emailAddress = this.resolveShowroomEmail(showroom);
        if (String.isNotBlank(emailAddress)) {
            contactParts.add(emailAddress);
        }

        return String.join(contactParts, ' | ');
    }

    private String resolveShowroomEmail(PorcelanosaAddress__c showroom) {
        if (String.isNotBlank(showroom.Email__c)) {
            return showroom.Email__c.trim();
        }

        return '';
    }

    private String resolveDefaultFooter() {
        return 'PORCELANOSA © '
            + String.valueOf(Date.today().year())
            + '. This is an automated confirmation email for your order. '
            + 'Please do not reply to this message. For assistance, contact your sales representative.';
    }

    private AddressDTO buildBillingAddress(OrderContext context) {
        AddressDTO address = new AddressDTO();
        address.street = context.orderRecord.BillingStreet;
        address.city = context.orderRecord.BillingCity;
        address.state = context.orderRecord.BillingState;
        address.stateCode = context.orderRecord.BillingStateCode;
        address.postCode = context.orderRecord.BillingPostalCode;
        address.country = context.orderRecord.BillingCountry;
        address.countryCode = context.orderRecord.BillingCountryCode;

        return address;
    }

    private AddressDTO buildShippingAddress(OrderContext context) {
        if (context.deliveryGroup != null) {
            return AddressDTO.readFromOrderDeliveryGroup(context.deliveryGroup);
        }

        AddressDTO address = new AddressDTO();
        address.street = context.orderRecord.ShippingStreet;
        address.city = context.orderRecord.ShippingCity;
        address.state = context.orderRecord.ShippingState;
        address.stateCode = context.orderRecord.ShippingStateCode;
        address.postCode = context.orderRecord.ShippingPostalCode;
        address.country = context.orderRecord.ShippingCountry;
        address.countryCode = context.orderRecord.ShippingCountryCode;

        return address;
    }
}