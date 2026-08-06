@isTest
private class MailBuilderTest {

    private static final String PRIMARY_EMAIL = 'primary@example.com';
    private static final String SECONDARY_EMAIL = 'secondary@example.com';
    private static final String CC_EMAIL = 'cc@example.com';
    private static final String BCC_EMAIL = 'bcc@example.com';

    @isTest
    static void buildEmailMessage_rendersExpectedHtmlAndRecipients() {
        MailBuilder builder = new MailBuilder()
            .setTo(new List<String>{ PRIMARY_EMAIL, PRIMARY_EMAIL })
            .addTo(SECONDARY_EMAIL)
            .setCc(PRIMARY_EMAIL.toUpperCase())
            .addCc(new List<String>{ CC_EMAIL })
            .setBcc(new List<String>{ BCC_EMAIL })
            .addBcc(SECONDARY_EMAIL.toUpperCase())
            .setSubject('Order confirmation')
            .setTheme(MailBuilder.Themes.CORPORATE)
            .showLogo()
            .addHeader1('Order confirmation')
            .addHeader2('Order lines')
            .addParagraph('Unsafe <b>tag</b> & quote')
            .addParagraphHtml('Inline <b>HTML</b>')
            .addSpacer()
            .addDivider()
            .addBulletList(new List<String>{ 'Item one', 'Item two' })
            .addDefinitionList(new Map<String, String>{
                'Order' => 'WEB-2026-00428',
                'Status' => 'Confirmed'
            })
            .addTable(
                new List<String>{ 'SKU', 'Name', 'Quantity' },
                new List<List<String>>{
                    new List<String>{ 'PT-XL-001', 'Porcelain Tile XL Matte White', '48 boxes' },
                    new List<String>{ 'TR-900-AC', 'Trim Aluminium Satin 90cm', '12 units' }
                },
                true
            )
            .addButton('Open order', 'https://example.com/orders/WEB-2026-00428')
            .addLink('Track your order', 'https://example.com/orders/WEB-2026-00428/track')
            .addSignature('Porcelanosa Los Angeles\n1301 South State College Boulevard Suite E\nAnaheim, CA 92806\n+1 714-772-3183 | info@porcelanosa-usa.com')
            .addFooter('PORCELANOSA © 2026. This is an automated confirmation email for your order.');

        Messaging.SingleEmailMessage emailMessage = builder.buildEmailMessage();
        String htmlBody = builder.renderHtmlBody();
        String plainTextBody = builder.renderPlainTextBody();

        System.assertEquals('Order confirmation', emailMessage.getSubject());
        System.assertEquals(2, emailMessage.getToAddresses().size(), 'Expected two unique To recipients.');
        System.assert(emailMessage.getToAddresses().contains(PRIMARY_EMAIL));
        System.assert(emailMessage.getToAddresses().contains(SECONDARY_EMAIL));
        System.assertEquals(1, emailMessage.getCcAddresses().size(), 'Expected one unique Cc recipient.');
        System.assertEquals(CC_EMAIL, emailMessage.getCcAddresses()[0]);
        System.assertEquals(1, emailMessage.getBccAddresses().size(), 'Expected one unique Bcc recipient.');
        System.assertEquals(BCC_EMAIL, emailMessage.getBccAddresses()[0]);

        System.assert(htmlBody.contains('porcelanosa.file.force.com'), 'Expected default logo URL in HTML.');
        System.assert(htmlBody.contains('Unsafe &lt;b&gt;tag&lt;/b&gt; &amp; quote'), 'Expected escaped paragraph HTML.');
        System.assert(htmlBody.contains('Inline <b>HTML</b>'), 'Expected raw HTML paragraph content.');
        System.assert(htmlBody.contains('<th scope="row"'), 'Expected first table column rendered as row header.');
        System.assert(htmlBody.contains('Track your order'), 'Expected link label in HTML.');
        System.assert(htmlBody.contains('Porcelanosa Los Angeles<br />1301 South State College Boulevard Suite E'), 'Expected signature line breaks in HTML.');
        System.assert(htmlBody.contains('PORCELANOSA © 2026'), 'Expected footer text in HTML.');

        System.assert(plainTextBody.contains('Unsafe <b>tag</b> & quote'), 'Expected plain text fallback to decode escaped text.');
        System.assert(plainTextBody.contains('Track your order'), 'Expected link label in plain text fallback.');
        System.assert(plainTextBody.contains('Open order'), 'Expected button label in plain text fallback.');
        System.assert(plainTextBody.contains('Porcelanosa Los Angeles'), 'Expected signature in plain text fallback.');
    }

    @isTest
    static void send_resolvesCurrentUserAndDeduplicatesAcrossBuckets() {
        Id currentUserId = UserInfo.getUserId();
        String currentUserEmail = [SELECT Email FROM User WHERE Id = :currentUserId LIMIT 1].Email;

        MailBuilder builder = new MailBuilder()
            .setToUser(currentUserId)
            .setToUsers(new Set<Id>{ currentUserId })
            .addToUser(currentUserId)
            .addToUsers(new Set<Id>{ currentUserId })
            .setCcUser(currentUserId)
            .setCcUsers(new Set<Id>{ currentUserId })
            .addCcUser(currentUserId)
            .addCcUsers(new Set<Id>{ currentUserId })
            .setBccUser(currentUserId)
            .setBccUsers(new Set<Id>{ currentUserId })
            .addBccUser(currentUserId)
            .addBccUsers(new Set<Id>{ currentUserId })
            .setSubject('Default theme alias test')
            .setTheme('DEFAULT')
            .showLogo('https://example.com/custom-logo.png')
            .addParagraph('Current user email test')
            .addTable(
                new List<List<String>>{
                    new List<String>{ 'Primary contact', 'Current user' }
                },
                true
            );

        Messaging.SingleEmailMessage previewMessage = builder.buildEmailMessage();

        System.assertEquals(1, previewMessage.getToAddresses().size(), 'Expected only one resolved recipient after deduplication.');
        System.assertEquals(currentUserEmail, previewMessage.getToAddresses()[0]);
        System.assert(isNullOrEmpty(previewMessage.getCcAddresses()), 'Expected empty Cc after deduplication against To.');
        System.assert(isNullOrEmpty(previewMessage.getBccAddresses()), 'Expected empty Bcc after deduplication against To.');
        System.assert(builder.renderHtmlBody().contains('https://example.com/custom-logo.png'), 'Expected overridden logo URL in HTML.');

        Test.startTest();
        builder.send();
        Integer emailInvocations = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(1, emailInvocations, 'Expected one email invocation.');
    }

    @isTest
    static void buildEmailMessage_supportsB2bThemeAndSignature() {
        MailBuilder builder = new MailBuilder()
            .setTo(PRIMARY_EMAIL)
            .setSubject('B2B order status')
            .setTheme('B2B')
            .addHeader1('Order ready for pickup')
            .addParagraph('Your order is now ready for pickup at your selected showroom.')
            .addTable(
                new List<String>{ 'SKU', 'Product', 'Quantity' },
                new List<List<String>>{
                    new List<String>{ '100202546', 'Capri Stone 18"X47"', '7 boxes' }
                }
            )
            .addButton('View order', 'https://example.com/orders/B2B-1001')
            .addLink('Continue shopping', 'https://example.com/store')
            .addSignature('Porcelanosa Los Angeles\n1301 South State College Boulevard Suite E\nAnaheim, CA 92806\n+1 714-772-3183 | info@porcelanosa-usa.com')
            .addFooter('PORCELANOSA © 2026. All rights reserved.');

        String htmlBody = builder.renderHtmlBody();

        System.assert(htmlBody.contains('padding-top:18px;border-top:1px'), 'Expected B2B signature block style.');
        System.assert(htmlBody.contains('background-color'), 'Expected B2B button style.');
        System.assert(htmlBody.contains('Continue shopping'), 'Expected B2B link in HTML.');
    }

    @isTest
    static void validations_throwExpectedExceptions() {
        try {
            new MailBuilder().setTo(PRIMARY_EMAIL).send();
            System.assert(false, 'Expected missing subject validation.');
        } catch (MailBuilder.MailBuilderException ex) {
            System.assertEquals('Subject is required.', ex.getMessage());
        }

        try {
            new MailBuilder().setSubject('Missing recipients').send();
            System.assert(false, 'Expected missing recipients validation.');
        } catch (MailBuilder.MailBuilderException ex) {
            System.assertEquals('At least one To recipient is required.', ex.getMessage());
        }

        try {
            new MailBuilder().addTo('invalid-email');
            System.assert(false, 'Expected invalid email validation.');
        } catch (MailBuilder.MailBuilderException ex) {
            System.assertEquals('Invalid email address: invalid-email', ex.getMessage());
        }

        try {
            new MailBuilder().setTheme('NOT_A_THEME');
            System.assert(false, 'Expected invalid theme validation.');
        } catch (MailBuilder.MailBuilderException ex) {
            System.assertEquals('Unsupported theme: NOT_A_THEME', ex.getMessage());
        }

        try {
            new MailBuilder().addButton('Open order', 'ftp://example.com');
            System.assert(false, 'Expected invalid button URL validation.');
        } catch (MailBuilder.MailBuilderException ex) {
            System.assertEquals('Button URL must be a valid absolute HTTP or HTTPS URL.', ex.getMessage());
        }

        try {
            new MailBuilder().addLink('Track your order', '/relative-path');
            System.assert(false, 'Expected invalid link URL validation.');
        } catch (MailBuilder.MailBuilderException ex) {
            System.assertEquals('Link URL must be a valid absolute HTTP or HTTPS URL.', ex.getMessage());
        }

        try {
            new MailBuilder().showLogo('/not-valid');
            System.assert(false, 'Expected invalid logo URL validation.');
        } catch (MailBuilder.MailBuilderException ex) {
            System.assertEquals('Logo URL must be a valid absolute HTTP or HTTPS URL.', ex.getMessage());
        }

        try {
            new MailBuilder().addSignature('   ');
            System.assert(false, 'Expected missing signature validation.');
        } catch (MailBuilder.MailBuilderException ex) {
            System.assertEquals('Signature text is required.', ex.getMessage());
        }

        try {
            new MailBuilder().addTable(
                new List<String>{ 'SKU', 'Name' },
                new List<List<String>>{
                    new List<String>{ 'PT-XL-001', 'Porcelain Tile XL Matte White' },
                    new List<String>{ 'TR-900-AC' }
                }
            );
            System.assert(false, 'Expected table column validation.');
        } catch (MailBuilder.MailBuilderException ex) {
            System.assertEquals('All table rows must have the same number of columns.', ex.getMessage());
        }
    }

    @isTest
    static void buildEmailMessage_throwsWhenUserDoesNotExist() {
        Id fakeUserId = (Id) '005000000000000AAA';

        try {
            new MailBuilder()
                .setToUser(fakeUserId)
                .setSubject('Missing user')
                .addParagraph('Body')
                .buildEmailMessage();

            System.assert(false, 'Expected user resolution to fail.');
        } catch (MailBuilder.MailBuilderException ex) {
            System.assert(ex.getMessage().startsWith('User not found:'), 'Unexpected exception message: ' + ex.getMessage());
        }
    }

    private static Boolean isNullOrEmpty(List<String> values) {
        return values == null || values.isEmpty();
    }
}