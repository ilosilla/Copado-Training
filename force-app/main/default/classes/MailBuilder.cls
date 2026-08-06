/**
 * Purpose: Build and send themed HTML emails through a fluent Apex API without exposing raw HTML to callers.
 * 
 * Ramón, march 2026
 *
 * Design notes:
 * - The public API only exposes semantic content methods and a final send().
 * - HTML is stored internally as independent blocks to keep composition simple.
 * - Salesforce User recipients are resolved in a single bulk query right before send.
 * - The class generates both HTML and plain text bodies from the same internal content.
 *
 * Example:
 * new MailBuilder()
 *     .setToCurrentUser()
 *     .setSubject('Order confirmation')
 *     .setTheme(MailBuilder.Themes.CORPORATE)
 *     .addHeader1('Order confirmed')
 *     .addParagraphHtml('Your order has been created successfully.')
 *     .addBulletList(new List<String>{
 *         'Order: 12345',
 *         'Status: Confirmed',
 *         'Date: 24/03/2026'
 *     })
 *     .addTable(
 *         new List<String>{'SKU', 'Name', 'Quantity'},
 *         new List<List<String>>{
 *             new List<String>{'PT-XL-001', 'Porcelain Tile XL Matte White', '48 boxes'},
 *             new List<String>{'TR-900-AC', 'Trim Aluminium Satin 90cm', '12 units'}
 *         }
 *     )
 *     .addButton('View order', 'https://example.com/orders/12345')
 *     .send();
 */
public class MailBuilder {

    private static final String EMAIL_REGEX = '^[A-Z0-9._%+\\-]+@[A-Z0-9.\\-]+\\.[A-Z]{2,}$';
    private static final String URL_REGEX = '^(?i)https?://[^\\s]+$';
    private static final String DEFAULT_LOGO_URL = 'https://porcelanosa.file.force.com/sfc/dist/version/download/?oid=00D1r000001FmuC&ids=068Vg00000aY44Y&d=%2Fa%2FVg000004OVLJ%2FzjEPIcLDLWH80r1vadqRDFs_4z.n7QIMJQYWvXaBBE4&asPdf=false';
    private static final String LOGO_CONTAINER_STYLE = 'margin:0 0 32px 0;padding:0;text-align:center;';
    private static final String LOGO_IMAGE_STYLE = 'display:block;width:180px;max-width:180px;height:auto;border:0;outline:none;text-decoration:none;margin:0 auto;';

    /* ========================================================= */
    /* PUBLIC DTOs                                               */
    /* ========================================================= */

    public class MailBuilderException extends Exception {}

    public enum Themes {
        STANDARD,
        CORPORATE,
        B2B,
        SUCCESS,
        WARNING,
        MINIMAL
    }

    /* ========================================================= */
    /* PRIVATE STATE                                             */
    /* ========================================================= */

    private class RecipientBucket {
        private List<String> emails = new List<String>();
        private List<Id> userIds = new List<Id>();
    }

    private class DefinitionListTheme {
        private String containerStyle;
        private String itemStyle;
        private String labelStyle;
        private String valueStyle;

        private DefinitionListTheme(
            String containerStyle,
            String itemStyle,
            String labelStyle,
            String valueStyle
        ) {
            this.containerStyle = containerStyle;
            this.itemStyle = itemStyle;
            this.labelStyle = labelStyle;
            this.valueStyle = valueStyle;
        }
    }

    private class ThemeDefinition {
        private String bodyStyle;
        private String containerStyle;
        private String topAccentStyle;
        private String header1Style;
        private String header2Style;
        private String paragraphStyle;
        private String dividerStyle;
        private String buttonStyle;
        private String buttonContainerStyle;
        private String signatureStyle;
        private String footerStyle;
        private String linkStyle;
        private DefinitionListTheme definitionList;
        private String tableStyle;
        private String tableHeaderRowStyle;
        private String tableHeaderCellStyle;
        private String tableRowHeaderCellStyle;
        private String tableCellStyle;

        private ThemeDefinition(
            String bodyStyle,
            String containerStyle,
            String topAccentStyle,
            String header1Style,
            String header2Style,
            String paragraphStyle,
            String dividerStyle,
            String buttonStyle,
            String buttonContainerStyle,
            String signatureStyle,
            String footerStyle,
            String linkStyle,
            DefinitionListTheme definitionList,
            String tableStyle,
            String tableHeaderRowStyle,
            String tableHeaderCellStyle,
            String tableRowHeaderCellStyle,
            String tableCellStyle
        ) {
            this.bodyStyle = bodyStyle;
            this.containerStyle = containerStyle;
            this.topAccentStyle = topAccentStyle;
            this.header1Style = header1Style;
            this.header2Style = header2Style;
            this.paragraphStyle = paragraphStyle;
            this.dividerStyle = dividerStyle;
            this.buttonStyle = buttonStyle;
            this.buttonContainerStyle = buttonContainerStyle;
            this.signatureStyle = signatureStyle;
            this.footerStyle = footerStyle;
            this.linkStyle = linkStyle;
            this.definitionList = definitionList;
            this.tableStyle = tableStyle;
            this.tableHeaderRowStyle = tableHeaderRowStyle;
            this.tableHeaderCellStyle = tableHeaderCellStyle;
            this.tableRowHeaderCellStyle = tableRowHeaderCellStyle;
            this.tableCellStyle = tableCellStyle;
        }
    }

    private class ResolvedUserEmails {
        private Map<Id, String> emailsByUserId = new Map<Id, String>();
    }

    private RecipientBucket toRecipients = new RecipientBucket();
    private RecipientBucket ccRecipients = new RecipientBucket();
    private RecipientBucket bccRecipients = new RecipientBucket();

    private String subject;
    private String themeName = String.valueOf(Themes.STANDARD);
    private Boolean shouldShowLogo = false;
    private String logoUrl = DEFAULT_LOGO_URL;
    private List<String> htmlBlocks = new List<String>();

    /* ========================================================= */
    /* PUBLIC METHODS (API)                                      */
    /* ========================================================= */

    public MailBuilder setTo(String email) {
        this.toRecipients = new RecipientBucket();
        return this.addTo(email);
    }

    public MailBuilder setTo(List<String> emails) {
        this.toRecipients = new RecipientBucket();
        return this.addTo(emails);
    }

    public MailBuilder addTo(String email) {
        this.addEmailToBucket(this.toRecipients, email);
        return this;
    }

    public MailBuilder addTo(List<String> emails) {
        this.addEmailsToBucket(this.toRecipients, emails);
        return this;
    }

    public MailBuilder setCc(String email) {
        this.ccRecipients = new RecipientBucket();
        return this.addCc(email);
    }

    public MailBuilder setCc(List<String> emails) {
        this.ccRecipients = new RecipientBucket();
        return this.addCc(emails);
    }

    public MailBuilder addCc(String email) {
        this.addEmailToBucket(this.ccRecipients, email);
        return this;
    }

    public MailBuilder addCc(List<String> emails) {
        this.addEmailsToBucket(this.ccRecipients, emails);
        return this;
    }

    public MailBuilder setBcc(String email) {
        this.bccRecipients = new RecipientBucket();
        return this.addBcc(email);
    }

    public MailBuilder setBcc(List<String> emails) {
        this.bccRecipients = new RecipientBucket();
        return this.addBcc(emails);
    }

    public MailBuilder addBcc(String email) {
        this.addEmailToBucket(this.bccRecipients, email);
        return this;
    }

    public MailBuilder addBcc(List<String> emails) {
        this.addEmailsToBucket(this.bccRecipients, emails);
        return this;
    }

    public MailBuilder setToUser(Id userId) {
        this.toRecipients = new RecipientBucket();
        return this.addToUser(userId);
    }

    public MailBuilder setToCurrentUser() {
        return this.setToUser(UserInfo.getUserId());
    }

    public MailBuilder setToUsers(Set<Id> userIds) {
        this.toRecipients = new RecipientBucket();
        return this.addToUsers(userIds);
    }

    public MailBuilder addToUser(Id userId) {
        this.addUserIdToBucket(this.toRecipients, userId);
        return this;
    }

    public MailBuilder addToUsers(Set<Id> userIds) {
        this.addUserIdsToBucket(this.toRecipients, userIds);
        return this;
    }

    public MailBuilder setCcUser(Id userId) {
        this.ccRecipients = new RecipientBucket();
        return this.addCcUser(userId);
    }

    public MailBuilder setCcUsers(Set<Id> userIds) {
        this.ccRecipients = new RecipientBucket();
        return this.addCcUsers(userIds);
    }

    public MailBuilder addCcUser(Id userId) {
        this.addUserIdToBucket(this.ccRecipients, userId);
        return this;
    }

    public MailBuilder addCcUsers(Set<Id> userIds) {
        this.addUserIdsToBucket(this.ccRecipients, userIds);
        return this;
    }

    public MailBuilder setBccUser(Id userId) {
        this.bccRecipients = new RecipientBucket();
        return this.addBccUser(userId);
    }

    public MailBuilder setBccUsers(Set<Id> userIds) {
        this.bccRecipients = new RecipientBucket();
        return this.addBccUsers(userIds);
    }

    public MailBuilder addBccUser(Id userId) {
        this.addUserIdToBucket(this.bccRecipients, userId);
        return this;
    }

    public MailBuilder addBccUsers(Set<Id> userIds) {
        this.addUserIdsToBucket(this.bccRecipients, userIds);
        return this;
    }

    public MailBuilder setSubject(String subject) {
        if (String.isBlank(subject)) {
            throw new MailBuilderException('Subject is required.');
        }

        this.subject = subject.trim();
        return this;
    }

    public MailBuilder setTheme(String themeName) {
        if (String.isBlank(themeName)) {
            throw new MailBuilderException('Theme name is required.');
        }

        this.themeName = this.normalizeThemeName(themeName);
        this.getThemeDefinition();
        return this;
    }

    public MailBuilder setTheme(Themes themeName) {
        if (themeName == null) {
            throw new MailBuilderException('Theme name is required.');
        }

        return this.setTheme(String.valueOf(themeName));
    }

    public MailBuilder addHeader1(String text) {
        if (String.isBlank(text)) {
            throw new MailBuilderException('Header 1 text is required.');
        }

        ThemeDefinition theme = this.getThemeDefinition();
        this.htmlBlocks.add('<h1 style="' + theme.header1Style + '">' + this.escapeHtml(text.trim()) + '</h1>');
        return this;
    }

    public MailBuilder addHeader2(String text) {
        if (String.isBlank(text)) {
            throw new MailBuilderException('Header 2 text is required.');
        }

        ThemeDefinition theme = this.getThemeDefinition();
        this.htmlBlocks.add('<h2 style="' + theme.header2Style + '">' + this.escapeHtml(text.trim()) + '</h2>');
        return this;
    }

    public MailBuilder addParagraph(String text) {
        if (String.isBlank(text)) {
            throw new MailBuilderException('Paragraph text is required.');
        }

        ThemeDefinition theme = this.getThemeDefinition();
        this.htmlBlocks.add('<p style="' + theme.paragraphStyle + '">' + this.escapeHtml(text.trim()) + '</p>');
        return this;
    }

    public MailBuilder addParagraphHtml(String html) {
        if (String.isBlank(html)) {
            throw new MailBuilderException('Paragraph HTML is required.');
        }

        ThemeDefinition theme = this.getThemeDefinition();
        this.htmlBlocks.add('<p style="' + theme.paragraphStyle + '">' + html.trim() + '</p>');
        return this;
    }

    public MailBuilder addDivider() {
        ThemeDefinition theme = this.getThemeDefinition();
        this.htmlBlocks.add('<div style="' + theme.dividerStyle + '"></div>');
        return this;
    }

    public MailBuilder addSpacer() {
        this.htmlBlocks.add('<div style="height:24px;line-height:24px;font-size:24px;">&nbsp;</div>');
        return this;
    }

    public MailBuilder addBulletList(List<String> items) {
        if (items == null || items.isEmpty()) {
            throw new MailBuilderException('Bullet list items are required.');
        }

        ThemeDefinition theme = this.getThemeDefinition();
        List<String> listItems = new List<String>();

        for (String item : items) {
            if (String.isBlank(item)) {
                throw new MailBuilderException('Bullet list items cannot be blank.');
            }

            listItems.add('<li style="margin:0 0 8px 0;">' + this.escapeHtml(item.trim()) + '</li>');
        }

        this.htmlBlocks.add(
            '<ul style="' + theme.paragraphStyle + 'padding-left:20px;margin:0 0 16px 20px;">'
            + String.join(listItems, '')
            + '</ul>'
        );
        return this;
    }

    public MailBuilder addDefinitionList(Map<String, String> items) {
        if (items == null || items.isEmpty()) {
            throw new MailBuilderException('Definition list items are required.');
        }

        ThemeDefinition theme = this.getThemeDefinition();
        List<String> rows = new List<String>();

        for (String label : items.keySet()) {
            if (String.isBlank(label)) {
                throw new MailBuilderException('Definition list labels cannot be blank.');
            }

            String value = items.get(label);
            String safeValue = this.renderEscapedMultilineText(value);

            rows.add(
                '<tr style="' + theme.definitionList.itemStyle + '">'
                + '<td style="' + theme.definitionList.labelStyle + '">' + this.escapeHtml(label) + ': </td>'
                + '<td style="' + theme.definitionList.valueStyle + '">' + safeValue + '</td>'
                + '</tr>'
            );
        }

        this.htmlBlocks.add(
            '<table role="presentation" cellspacing="0" cellpadding="0" border="0" style="' + theme.definitionList.containerStyle + '">'
            + String.join(rows, '')
            + '</table>'
        );
        return this;
    }

    public MailBuilder addTable(List<List<String>> rows) {
        return this.addTable(null, rows, false);
    }

    public MailBuilder addTable(List<List<String>> rows, Boolean firstColumnIsRowHeader) {
        return this.addTable(null, rows, firstColumnIsRowHeader);
    }

    public MailBuilder addTable(List<String> columnLabels, List<List<String>> rows) {
        return this.addTable(columnLabels, rows, false);
    }

    public MailBuilder addTable(List<String> columnLabels, List<List<String>> rows, Boolean firstColumnIsRowHeader) {
        this.htmlBlocks.add(this.renderTableBlock(columnLabels, rows, firstColumnIsRowHeader));
        return this;
    }

    public MailBuilder addFooter(String text) {
        if (String.isBlank(text)) {
            throw new MailBuilderException('Footer text is required.');
        }

        ThemeDefinition theme = this.getThemeDefinition();
        this.htmlBlocks.add('<p style="' + theme.footerStyle + '">' + this.escapeHtml(text.trim()) + '</p>');
        return this;
    }

    public MailBuilder addSignature(String text) {
        if (String.isBlank(text)) {
            throw new MailBuilderException('Signature text is required.');
        }

        ThemeDefinition theme = this.getThemeDefinition();
        String signatureHtml = this.escapeHtml(text.trim());
        signatureHtml = signatureHtml.replace('\r\n', '\n');
        signatureHtml = signatureHtml.replace('\r', '\n');
        signatureHtml = signatureHtml.replace('\n', '<br />');

        this.htmlBlocks.add('<div style="' + theme.signatureStyle + '">' + signatureHtml + '</div>');
        return this;
    }

    public MailBuilder addLink(String label, String url) {
        if (String.isBlank(label)) {
            throw new MailBuilderException('Link label is required.');
        }

        if (String.isBlank(url)) {
            throw new MailBuilderException('Link URL is required.');
        }

        String trimmedUrl = url.trim();
        if (!Pattern.compile(URL_REGEX).matcher(trimmedUrl).matches()) {
            throw new MailBuilderException('Link URL must be a valid absolute HTTP or HTTPS URL.');
        }

        ThemeDefinition theme = this.getThemeDefinition();
        this.htmlBlocks.add(
            '<p style="' + theme.paragraphStyle + '">'
            + '<a href="' + this.escapeHtml(trimmedUrl) + '" target="_blank" style="' + theme.linkStyle + '">'
            + this.escapeHtml(label.trim())
            + '</a>'
            + '</p>'
        );
        return this;
    }

    public MailBuilder showLogo() {
        this.shouldShowLogo = true;
        this.logoUrl = DEFAULT_LOGO_URL;
        return this;
    }

    public MailBuilder showLogo(String logoUrl) {
        if (String.isBlank(logoUrl)) {
            throw new MailBuilderException('Logo URL is required.');
        }

        String trimmedLogoUrl = logoUrl.trim();
        if (!Pattern.compile(URL_REGEX).matcher(trimmedLogoUrl).matches()) {
            throw new MailBuilderException('Logo URL must be a valid absolute HTTP or HTTPS URL.');
        }

        this.shouldShowLogo = true;
        this.logoUrl = trimmedLogoUrl;
        return this;
    }

    public MailBuilder addButton(String label, String url) {
        if (String.isBlank(label)) {
            throw new MailBuilderException('Button label is required.');
        }

        if (String.isBlank(url)) {
            throw new MailBuilderException('Button URL is required.');
        }

        String trimmedUrl = url.trim();
        if (!Pattern.compile(URL_REGEX).matcher(trimmedUrl).matches()) {
            throw new MailBuilderException('Button URL must be a valid absolute HTTP or HTTPS URL.');
        }

        ThemeDefinition theme = this.getThemeDefinition();
        this.htmlBlocks.add(
            '<div style="' + theme.buttonContainerStyle + '">'
            + '<a href="' + this.escapeHtml(trimmedUrl) + '" target="_blank" style="' + theme.buttonStyle + '">'
            + this.escapeHtml(label.trim())
            + '</a>'
            + '</div>'
        );
        return this;
    }

    public void send() {
        this.validateBeforeSend();

        Messaging.SingleEmailMessage emailMessage = this.buildEmailMessage();
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.Email[] { emailMessage });

        if (!results.isEmpty() && !results[0].isSuccess()) {
            String errorMessage = 'Email sending failed.';

            if (results[0].getErrors() != null && !results[0].getErrors().isEmpty()) {
                errorMessage = results[0].getErrors()[0].getMessage();
            }

            throw new MailBuilderException(errorMessage);
        }
    }

    /* ========================================================= */
    /* PRIVATE METHODS                                           */
    /* ========================================================= */

    @testVisible
    private String renderHtmlBody() {
        ThemeDefinition theme = this.getThemeDefinition();
        String logoBlock = this.renderLogoBlock();
        String topAccentBlock = this.renderTopAccentBlock(theme);

        return '<!DOCTYPE html>'
            + '<html>'
            + '<body style="' + theme.bodyStyle + '">'
            + '<table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="border-collapse:collapse;">'
            + '<tr>'
            + '<td align="center" style="padding:24px;">'
            + '<table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="' + theme.containerStyle + '">'
            + '<tr>'
            + '<td style="padding:32px 28px 32px 28px;">'
            + topAccentBlock
            + logoBlock
            + String.join(this.htmlBlocks, '')
            + '</td>'
            + '</tr>'
            + '</table>'
            + '</td>'
            + '</tr>'
            + '</table>'
            + '</body>'
            + '</html>';
    }

    @testVisible
    private String renderPlainTextBody() {
        String plainText = this.renderHtmlBody();

        plainText = plainText.replaceAll('(?i)<br\\s*/?>', '\n');
        plainText = plainText.replaceAll('(?i)</h1>', '\n\n');
        plainText = plainText.replaceAll('(?i)</h2>', '\n\n');
        plainText = plainText.replaceAll('(?i)</p>', '\n\n');
        plainText = plainText.replaceAll('(?i)</div>', '\n');
        plainText = plainText.replaceAll('(?i)</li>', '\n');
        plainText = plainText.replaceAll('(?i)</tr>', '\n');
        plainText = plainText.replaceAll('(?i)</table>', '\n');
        plainText = plainText.replaceAll('<[^>]+>', '');

        plainText = plainText.replace('&nbsp;', ' ');
        plainText = plainText.replace('&amp;', '&');
        plainText = plainText.replace('&lt;', '<');
        plainText = plainText.replace('&gt;', '>');
        plainText = plainText.replace('&quot;', '"');
        plainText = plainText.replace('&#39;', '\'');

        plainText = plainText.replaceAll('[ \\t]+', ' ');
        plainText = plainText.replaceAll('\\n\\s*\\n\\s*\\n+', '\n\n');

        return plainText.trim();
    }

    @testVisible
    private Messaging.SingleEmailMessage buildEmailMessage() {
        ResolvedUserEmails resolvedUserEmails = this.resolveUserEmails();
        Set<String> seenEmails = new Set<String>();

        List<String> toAddresses = this.collectRecipientEmails(this.toRecipients, resolvedUserEmails, seenEmails);
        List<String> ccAddresses = this.collectRecipientEmails(this.ccRecipients, resolvedUserEmails, seenEmails);
        List<String> bccAddresses = this.collectRecipientEmails(this.bccRecipients, resolvedUserEmails, seenEmails);

        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
        emailMessage.setSubject(this.subject);
        emailMessage.setHtmlBody(this.renderHtmlBody());
        emailMessage.setPlainTextBody(this.renderPlainTextBody());
        emailMessage.setToAddresses(toAddresses);
        emailMessage.setSaveAsActivity(false);
        emailMessage.setUseSignature(false);

        if (!ccAddresses.isEmpty()) {
            emailMessage.setCcAddresses(ccAddresses);
        }

        if (!bccAddresses.isEmpty()) {
            emailMessage.setBccAddresses(bccAddresses);
        }

        return emailMessage;
    }

    private ResolvedUserEmails resolveUserEmails() {
        ResolvedUserEmails resolvedUserEmails = new ResolvedUserEmails();
        Set<Id> allUserIds = new Set<Id>();

        allUserIds.addAll(this.toRecipients.userIds);
        allUserIds.addAll(this.ccRecipients.userIds);
        allUserIds.addAll(this.bccRecipients.userIds);

        if (allUserIds.isEmpty()) {
            return resolvedUserEmails;
        }

        Map<Id, User> usersById = new Map<Id, User>([
            SELECT Id, Email
            FROM User
            WHERE Id IN :allUserIds
        ]);

        for (Id userId : allUserIds) {
            if (!usersById.containsKey(userId)) {
                throw new MailBuilderException('User not found: ' + String.valueOf(userId));
            }

            User userRecord = usersById.get(userId);
            if (String.isBlank(userRecord.Email)) {
                throw new MailBuilderException('User does not have an email address: ' + String.valueOf(userId));
            }

            this.validateEmailAddress(userRecord.Email);
            resolvedUserEmails.emailsByUserId.put(userId, userRecord.Email.trim());
        }

        return resolvedUserEmails;
    }

    private void validateBeforeSend() {
        if (String.isBlank(this.subject)) {
            throw new MailBuilderException('Subject is required.');
        }

        Boolean hasToRecipients = !this.toRecipients.emails.isEmpty() || !this.toRecipients.userIds.isEmpty();
        if (!hasToRecipients) {
            throw new MailBuilderException('At least one To recipient is required.');
        }

        this.getThemeDefinition();
    }

    private String escapeHtml(String value) {
        if (value == null) {
            return '';
        }

        String escapedValue = value;
        escapedValue = escapedValue.replace('&', '&amp;');
        escapedValue = escapedValue.replace('<', '&lt;');
        escapedValue = escapedValue.replace('>', '&gt;');
        escapedValue = escapedValue.replace('"', '&quot;');
        escapedValue = escapedValue.replace('\'', '&#39;');

        return escapedValue;
    }

    private String renderEscapedMultilineText(String value) {
        if (value == null) {
            return '';
        }

        String normalizedValue = value.replace('\r\n', '\n').replace('\r', '\n');
        return this.escapeHtml(normalizedValue).replace('\n', '<br />');
    }
    private String renderLogoBlock() {
        if (this.shouldShowLogo != true) {
            return '';
        }

        return '<div style="' + LOGO_CONTAINER_STYLE + '">'
            + '<img src="' + this.escapeHtml(this.logoUrl) + '" alt="Logo" style="' + LOGO_IMAGE_STYLE + '" />'
            + '</div>';
    }

    private String renderTopAccentBlock(ThemeDefinition theme) {
        if (String.isBlank(theme.topAccentStyle)) {
            return '';
        }

        return '<div style="' + theme.topAccentStyle + '">&nbsp;</div>';
    }

    private String renderTableBlock(List<String> columnLabels, List<List<String>> rows, Boolean firstColumnIsRowHeader) {
        this.validateTableData(columnLabels, rows);

        ThemeDefinition theme = this.getThemeDefinition();
        Integer columnCount = rows[0].size();
        Boolean hasColumnLabels = columnLabels != null && !columnLabels.isEmpty();
        Boolean useRowHeader = firstColumnIsRowHeader == true;
        List<String> htmlRows = new List<String>();

        if (hasColumnLabels) {
            List<String> headerCells = new List<String>();

            for (String columnLabel : columnLabels) {
                headerCells.add('<th style="' + theme.tableHeaderCellStyle + '">' + this.escapeHtml(columnLabel.trim()) + '</th>');
            }

            htmlRows.add(
                '<tr style="' + theme.tableHeaderRowStyle + '">'
                + String.join(headerCells, '')
                + '</tr>'
            );
        }

        for (List<String> row : rows) {
            List<String> cells = new List<String>();

            for (Integer index = 0; index < columnCount; index++) {
                String cellValue = row[index] == null ? '' : row[index];

                if (useRowHeader && index == 0) {
                    cells.add('<th scope="row" style="' + theme.tableRowHeaderCellStyle + '">' + this.escapeHtml(cellValue.trim()) + '</th>');
                    continue;
                }

                cells.add('<td style="' + theme.tableCellStyle + '">' + this.escapeHtml(cellValue.trim()) + '</td>');
            }

            htmlRows.add('<tr>' + String.join(cells, '') + '</tr>');
        }

        return '<table role="presentation" cellspacing="0" cellpadding="0" border="0" style="' + theme.tableStyle + '">'
            + String.join(htmlRows, '')
            + '</table>';
    }

    private void validateTableData(List<String> columnLabels, List<List<String>> rows) {
        if (rows == null || rows.isEmpty()) {
            throw new MailBuilderException('Table rows are required.');
        }

        Integer columnCount = null;

        if (columnLabels != null && !columnLabels.isEmpty()) {
            columnCount = columnLabels.size();

            for (String columnLabel : columnLabels) {
                if (String.isBlank(columnLabel)) {
                    throw new MailBuilderException('Table column labels cannot be blank.');
                }
            }
        }

        for (List<String> row : rows) {
            if (row == null || row.isEmpty()) {
                throw new MailBuilderException('Table rows cannot be null or empty.');
            }

            if (columnCount == null) {
                columnCount = row.size();
            }

            if (row.size() != columnCount) {
                throw new MailBuilderException('All table rows must have the same number of columns.');
            }
        }
    }

    private ThemeDefinition getThemeDefinition() {
        Map<String, ThemeDefinition> themeCatalog = this.getThemeCatalog();

        if (!themeCatalog.containsKey(this.themeName)) {
            throw new MailBuilderException('Unsupported theme: ' + this.themeName);
        }

        return themeCatalog.get(this.themeName);
    }

    private String normalizeThemeName(String themeName) {
        String normalizedThemeName = themeName.trim().toUpperCase();

        if (normalizedThemeName == 'DEFAULT') {
            return this.getDefaultThemeName();
        }

        return normalizedThemeName;
    }

    private String getDefaultThemeName() {
        return String.valueOf(Themes.STANDARD);
    }

    private void addEmailToBucket(RecipientBucket bucket, String email) {
        if (String.isBlank(email)) {
            throw new MailBuilderException('Email address is required.');
        }

        String normalizedEmail = this.validateEmailAddress(email);
        if (!bucket.emails.contains(normalizedEmail)) {
            bucket.emails.add(normalizedEmail);
        }
    }

    private void addEmailsToBucket(RecipientBucket bucket, List<String> emails) {
        if (emails == null) {
            throw new MailBuilderException('Email list cannot be null.');
        }

        for (String email : emails) {
            this.addEmailToBucket(bucket, email);
        }
    }

    private void addUserIdToBucket(RecipientBucket bucket, Id userId) {
        if (userId == null) {
            throw new MailBuilderException('User Id is required.');
        }

        if (!bucket.userIds.contains(userId)) {
            bucket.userIds.add(userId);
        }
    }

    private void addUserIdsToBucket(RecipientBucket bucket, Set<Id> userIds) {
        if (userIds == null) {
            throw new MailBuilderException('User Id set cannot be null.');
        }

        for (Id userId : userIds) {
            this.addUserIdToBucket(bucket, userId);
        }
    }

    private String validateEmailAddress(String email) {
        String normalizedEmail = email == null ? null : email.trim();

        if (String.isBlank(normalizedEmail)) {
            throw new MailBuilderException('Email address is required.');
        }

        if (!Pattern.compile(EMAIL_REGEX).matcher(normalizedEmail.toUpperCase()).matches()) {
            throw new MailBuilderException('Invalid email address: ' + normalizedEmail);
        }

        return normalizedEmail;
    }

    private List<String> collectRecipientEmails(
        RecipientBucket bucket,
        ResolvedUserEmails resolvedUserEmails,
        Set<String> seenEmails
    ) {
        List<String> dedupedEmails = new List<String>();

        for (String email : bucket.emails) {
            this.addDedupedEmail(dedupedEmails, seenEmails, email);
        }

        for (Id userId : bucket.userIds) {
            this.addDedupedEmail(dedupedEmails, seenEmails, resolvedUserEmails.emailsByUserId.get(userId));
        }

        return dedupedEmails;
    }

    private void addDedupedEmail(List<String> emails, Set<String> seenEmails, String email) {
        String normalizedKey = email.trim().toLowerCase();

        if (!seenEmails.contains(normalizedKey)) {
            seenEmails.add(normalizedKey);
            emails.add(email.trim());
        }
    }

    private Map<String, ThemeDefinition> getThemeCatalog() {
        return new Map<String, ThemeDefinition>{
            this.getDefaultThemeName() => this.createThemeDefinition(
                'margin:0;padding:0;background-color:#f5f7fb;font-family:Arial,Helvetica,sans-serif;',
                'max-width:640px;width:100%;background-color:#ffffff;border:1px solid #dfe3eb;border-collapse:separate;',
                '',
                'margin:0 0 16px 0;font-size:28px;line-height:34px;color:#1f2937;font-weight:bold;',
                'margin:0 0 12px 0;font-size:20px;line-height:26px;color:#111827;font-weight:bold;',
                'margin:0 0 16px 0;font-size:15px;line-height:24px;color:#374151;',
                'border-top:1px solid #e5e7eb;margin:24px 0;',
                'display:inline-block;background-color:#2563eb;color:#ffffff;text-decoration:none;padding:12px 20px;border-radius:4px;font-size:14px;font-weight:bold;',
                'margin:24px 0 8px 0;',
                'margin:28px 0 0 0;padding:18px;background-color:#f9fafb;border:1px solid #e5e7eb;font-size:14px;line-height:22px;color:#374151;text-align:left;',
                'margin:28px 0 0 0;padding-top:18px;border-top:1px solid #e5e7eb;font-size:12px;line-height:18px;color:#6b7280;text-align:center;',
                'color:#2563eb;text-decoration:underline;font-weight:bold;',
                this.createDefinitionListTheme(
                    'width:100%;border-collapse:collapse;margin:0 0 16px 0;',
                    'border-bottom:1px solid #e5e7eb;',
                    'padding:10px 12px 10px 0;font-size:14px;line-height:20px;color:#111827;font-weight:bold;vertical-align:top;',
                    'padding:10px 0;font-size:14px;line-height:20px;color:#374151;vertical-align:top;'
                ),
                'width:100%;border-collapse:collapse;margin:0 0 16px 0;border:1px solid #e5e7eb;',
                'background-color:#f9fafb;',
                'padding:12px;border:1px solid #e5e7eb;font-size:13px;line-height:18px;color:#111827;font-weight:bold;text-align:left;',
                'padding:12px;border:1px solid #e5e7eb;font-size:14px;line-height:20px;color:#111827;font-weight:bold;text-align:left;vertical-align:top;',
                'padding:12px;border:1px solid #e5e7eb;font-size:14px;line-height:20px;color:#374151;text-align:left;vertical-align:top;'
            ),
            String.valueOf(Themes.CORPORATE) => this.createThemeDefinition(
                'margin:0;padding:0;background-color:#ecefed;font-family:Arial,Helvetica,sans-serif;',
                'max-width:640px;width:100%;background-color:#ffffff;border-top:5px solid #c8a24b;border-left:1px solid #d9ddd8;border-right:1px solid #d9ddd8;border-bottom:1px solid #d9ddd8;border-collapse:separate;',
                '',
                'margin:0 0 16px 0;font-size:30px;line-height:36px;color:#3f4952;font-weight:normal;font-family:Georgia,Times New Roman,serif;',
                'margin:0 0 12px 0;font-size:21px;line-height:28px;color:#3f4952;font-weight:bold;',
                'margin:0 0 16px 0;font-size:15px;line-height:24px;color:#4c5660;',
                'border-top:1px solid #d6dbd6;margin:28px 0;',
                'display:inline-block;background-color:#22384c;color:#ffffff;text-decoration:none;padding:13px 24px;border-radius:0;font-size:14px;font-weight:bold;',
                'margin:24px 0 8px 0;',
                'margin:28px 0 0 0;padding-top:18px;border-top:1px solid #d6dbd6;font-size:14px;line-height:23px;color:#4c5660;text-align:left;',
                'margin:30px 0 0 0;padding-top:18px;border-top:1px solid #d6dbd6;font-size:12px;line-height:18px;color:#6a7075;text-align:center;',
                'color:#5f7486;text-decoration:underline;font-weight:normal;',
                this.createDefinitionListTheme(
                    'width:100%;border-collapse:collapse;margin:0 0 16px 0;background-color:#fbfbfa;',
                    'border-bottom:1px solid #dddeda;',
                    'padding:12px 12px 12px 16px;font-size:13px;line-height:20px;color:#a9832e;font-weight:bold;vertical-align:top;text-transform:uppercase;letter-spacing:0.3px;',
                    'padding:12px 16px 12px 0;font-size:14px;line-height:20px;color:#4c5660;vertical-align:top;'
                ),
                'width:100%;border-collapse:collapse;margin:0 0 16px 0;border:1px solid #d6dbd6;',
                'background-color:#eef3f7;',
                'padding:12px;border:1px solid #DCE1E6;font-size:12px;line-height:18px;color:#22384c;font-weight:normal;text-align:left;text-transform:uppercase;letter-spacing:0.4px;',
                'padding:12px;border:1px solid #DCE1E6;font-size:14px;line-height:20px;color:#3f4952;font-weight:bold;text-align:left;vertical-align:top;background-color:#f3f4f1;',
                'padding:12px;border:1px solid #DCE1E6;font-size:14px;line-height:20px;color:#4c5660;text-align:left;vertical-align:top;background-color:#ffffff;'
            ),
            String.valueOf(Themes.B2B) => this.createThemeDefinition(
                'margin:0;padding:0;background-color:#f6f8fa;font-family:Arial,Helvetica,sans-serif;',
                'max-width:640px;width:100%;background-color:#ffffff;border-top:5px solid #2f6fa3;border-left:1px solid #dbe2e8;border-right:1px solid #dbe2e8;border-bottom:1px solid #dbe2e8;border-collapse:separate;',
                '',
                'margin:0 0 16px 0;font-size:30px;line-height:36px;color:#3f4952;font-weight:normal;font-family:Georgia,Times New Roman,serif;',
                'margin:0 0 12px 0;font-size:24px;line-height:30px;color:#3f4952;font-weight:normal;font-family:Georgia,Times New Roman,serif;',
                'margin:0 0 16px 0;font-size:15px;line-height:24px;color:#37414b;',
                'border-top:1px solid #dbe2e8;margin:28px 0;',
                'display:inline-block;background-color:#22384c;color:#ffffff;text-decoration:none;padding:13px 24px;border-radius:0;font-size:14px;font-weight:bold;',
                'margin:24px 0 8px 0;',
                'margin:28px 0 0 0;padding-top:18px;border-top:1px solid #dbe2e8;font-size:14px;line-height:23px;color:#37414b;text-align:left;',
                'margin:30px 0 0 0;padding-top:18px;border-top:1px solid #dbe2e8;font-size:12px;line-height:18px;color:#7a8691;text-align:center;',
                'color:#4d6f8d;text-decoration:underline;font-weight:normal;',
                this.createDefinitionListTheme(
                    'width:100%;border-collapse:collapse;margin:0 0 16px 0;background-color:#ffffff;',
                    'border-bottom:1px solid #e1e7ec;',
                    'padding:12px 28px 12px 0;font-size:14px;line-height:20px;color:#37414b;font-weight:bold;vertical-align:top;white-space:nowrap;width:1%;',
                    'padding:12px 0 12px 8px;font-size:14px;line-height:20px;color:#37414b;vertical-align:top;'
                ),
                'width:100%;border-collapse:collapse;margin:0 0 16px 0;border:1px solid #dbe2e8;',
                'background-color:#eef3f7;',
                'padding:12px;border:1px solid #dbe2e8;font-size:12px;line-height:18px;color:#213547;font-weight:bold;text-align:left;text-transform:uppercase;letter-spacing:0.4px;',
                'padding:12px;border:1px solid #dbe2e8;font-size:14px;line-height:20px;color:#213547;font-weight:bold;text-align:left;vertical-align:top;background-color:#f7fafc;',
                'padding:12px;border:1px solid #dbe2e8;font-size:14px;line-height:20px;color:#37414b;text-align:left;vertical-align:top;background-color:#ffffff;'
            ),
            String.valueOf(Themes.SUCCESS) => this.createThemeDefinition(
                'margin:0;padding:0;background-color:#f3fbf6;font-family:Arial,Helvetica,sans-serif;',
                'max-width:640px;width:100%;background-color:#ffffff;border:1px solid #cfe8d7;border-collapse:separate;',
                '',
                'margin:0 0 16px 0;font-size:28px;line-height:34px;color:#166534;font-weight:bold;',
                'margin:0 0 12px 0;font-size:20px;line-height:26px;color:#15803d;font-weight:bold;',
                'margin:0 0 16px 0;font-size:15px;line-height:24px;color:#355b43;',
                'border-top:1px solid #d1fae5;margin:24px 0;',
                'display:inline-block;background-color:#16a34a;color:#ffffff;text-decoration:none;padding:12px 20px;border-radius:4px;font-size:14px;font-weight:bold;',
                'margin:24px 0 8px 0;',
                'margin:28px 0 0 0;padding:18px;background-color:#f3fbf6;border:1px solid #dcfce7;font-size:14px;line-height:22px;color:#355b43;text-align:left;',
                'margin:28px 0 0 0;padding-top:18px;border-top:1px solid #dcfce7;font-size:12px;line-height:18px;color:#5b6f62;text-align:center;',
                'color:#15803d;text-decoration:underline;font-weight:bold;',
                this.createDefinitionListTheme(
                    'width:100%;border-collapse:collapse;margin:0 0 16px 0;',
                    'border-bottom:1px solid #dcfce7;',
                    'padding:10px 12px 10px 0;font-size:14px;line-height:20px;color:#166534;font-weight:bold;vertical-align:top;',
                    'padding:10px 0;font-size:14px;line-height:20px;color:#355b43;vertical-align:top;'
                ),
                'width:100%;border-collapse:collapse;margin:0 0 16px 0;border:1px solid #dcfce7;',
                'background-color:#16a34a;',
                'padding:12px;border:1px solid #dcfce7;font-size:13px;line-height:18px;color:#ffffff;font-weight:bold;text-align:left;',
                'padding:12px;border:1px solid #dcfce7;font-size:14px;line-height:20px;color:#166534;font-weight:bold;text-align:left;vertical-align:top;background-color:#f3fbf6;',
                'padding:12px;border:1px solid #dcfce7;font-size:14px;line-height:20px;color:#355b43;text-align:left;vertical-align:top;'
            ),
            String.valueOf(Themes.WARNING) => this.createThemeDefinition(
                'margin:0;padding:0;background-color:#fff8ed;font-family:Arial,Helvetica,sans-serif;',
                'max-width:640px;width:100%;background-color:#ffffff;border:1px solid #f2d3a2;border-collapse:separate;',
                '',
                'margin:0 0 16px 0;font-size:28px;line-height:34px;color:#b45309;font-weight:bold;',
                'margin:0 0 12px 0;font-size:20px;line-height:26px;color:#c2410c;font-weight:bold;',
                'margin:0 0 16px 0;font-size:15px;line-height:24px;color:#7c4a12;',
                'border-top:1px solid #fed7aa;margin:24px 0;',
                'display:inline-block;background-color:#ea580c;color:#ffffff;text-decoration:none;padding:12px 20px;border-radius:4px;font-size:14px;font-weight:bold;',
                'margin:24px 0 8px 0;',
                'margin:28px 0 0 0;padding:18px;background-color:#fff7ed;border:1px solid #fed7aa;font-size:14px;line-height:22px;color:#7c4a12;text-align:left;',
                'margin:28px 0 0 0;padding-top:18px;border-top:1px solid #fed7aa;font-size:12px;line-height:18px;color:#8a6130;text-align:center;',
                'color:#c2410c;text-decoration:underline;font-weight:bold;',
                this.createDefinitionListTheme(
                    'width:100%;border-collapse:collapse;margin:0 0 16px 0;',
                    'border-bottom:1px solid #ffedd5;',
                    'padding:10px 12px 10px 0;font-size:14px;line-height:20px;color:#9a3412;font-weight:bold;vertical-align:top;',
                    'padding:10px 0;font-size:14px;line-height:20px;color:#7c4a12;vertical-align:top;'
                ),
                'width:100%;border-collapse:collapse;margin:0 0 16px 0;border:1px solid #fed7aa;',
                'background-color:#ea580c;',
                'padding:12px;border:1px solid #fed7aa;font-size:13px;line-height:18px;color:#ffffff;font-weight:bold;text-align:left;',
                'padding:12px;border:1px solid #fed7aa;font-size:14px;line-height:20px;color:#9a3412;font-weight:bold;text-align:left;vertical-align:top;background-color:#fff7ed;',
                'padding:12px;border:1px solid #fed7aa;font-size:14px;line-height:20px;color:#7c4a12;text-align:left;vertical-align:top;'
            ),
            String.valueOf(Themes.MINIMAL) => this.createThemeDefinition(
                'margin:0;padding:0;background-color:#ffffff;font-family:Arial,Helvetica,sans-serif;',
                'max-width:640px;width:100%;background-color:#ffffff;border-collapse:separate;',
                '',
                'margin:0 0 16px 0;font-size:26px;line-height:32px;color:#111111;font-weight:normal;',
                'margin:0 0 12px 0;font-size:18px;line-height:24px;color:#111111;font-weight:normal;',
                'margin:0 0 14px 0;font-size:15px;line-height:24px;color:#333333;',
                'border-top:1px solid #d4d4d4;margin:20px 0;',
                'display:inline-block;background-color:#111111;color:#ffffff;text-decoration:none;padding:10px 18px;border-radius:0;font-size:14px;font-weight:normal;',
                'margin:20px 0 8px 0;',
                'margin:28px 0 0 0;padding:18px;border:1px solid #d4d4d4;font-size:14px;line-height:22px;color:#333333;text-align:left;',
                'margin:28px 0 0 0;padding-top:18px;border-top:1px solid #d4d4d4;font-size:12px;line-height:18px;color:#666666;text-align:center;',
                'color:#111111;text-decoration:underline;font-weight:normal;',
                this.createDefinitionListTheme(
                    'width:100%;border-collapse:collapse;margin:0 0 16px 0;',
                    'border-bottom:1px solid #ebebeb;',
                    'padding:10px 12px 10px 0;font-size:14px;line-height:20px;color:#111111;font-weight:normal;vertical-align:top;',
                    'padding:10px 0;font-size:14px;line-height:20px;color:#333333;vertical-align:top;'
                ),
                'width:100%;border-collapse:collapse;margin:0 0 16px 0;border:1px solid #d4d4d4;',
                'background-color:#f5f5f5;',
                'padding:12px;border:1px solid #d4d4d4;font-size:13px;line-height:18px;color:#111111;font-weight:bold;text-align:left;',
                'padding:12px;border:1px solid #d4d4d4;font-size:14px;line-height:20px;color:#111111;font-weight:bold;text-align:left;vertical-align:top;background-color:#fafafa;',
                'padding:12px;border:1px solid #d4d4d4;font-size:14px;line-height:20px;color:#333333;text-align:left;vertical-align:top;'
            )
        };
    }

    private ThemeDefinition createThemeDefinition(
        String bodyStyle,
        String containerStyle,
        String topAccentStyle,
        String header1Style,
        String header2Style,
        String paragraphStyle,
        String dividerStyle,
        String buttonStyle,
        String buttonContainerStyle,
        String signatureStyle,
        String footerStyle,
        String linkStyle,
        DefinitionListTheme definitionList,
        String tableStyle,
        String tableHeaderRowStyle,
        String tableHeaderCellStyle,
        String tableRowHeaderCellStyle,
        String tableCellStyle
    ) {
        return new ThemeDefinition(
            bodyStyle,
            containerStyle,
            topAccentStyle,
            header1Style,
            header2Style,
            paragraphStyle,
            dividerStyle,
            buttonStyle,
            buttonContainerStyle,
            signatureStyle,
            footerStyle,
            linkStyle,
            definitionList,
            tableStyle,
            tableHeaderRowStyle,
            tableHeaderCellStyle,
            tableRowHeaderCellStyle,
            tableCellStyle
        );
    }

    private DefinitionListTheme createDefinitionListTheme(
        String containerStyle,
        String itemStyle,
        String labelStyle,
        String valueStyle
    ) {
        return new DefinitionListTheme(containerStyle, itemStyle, labelStyle, valueStyle);
    }
}