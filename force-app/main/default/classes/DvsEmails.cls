public class DvsEmails {
    /**
     * Envía un email a los responsables de crear cuentas en Porcelanosa Exportación 008
     */
    public static void sendDvsConfirmationRequest(Map<String, String> company, String accountId, String dvsAction) {
        Account acc = new AccountsSelector().selectById(accountId);
        User usr = [SELECT Id, Name, Email FROM User WHERE Id =: UserInfo.getUserId()];
        
        String textSubject = Label.dvs_confirm_mail_Title + ' - ' + acc.Name;
        String link = '<a href="' + URL.getOrgDomainUrl().toExternalForm() + '/' + acc.Id + '">'+ Label.dict_click_here + '</a>';
        String textHeader = '<html><head><style>'
                + 'body { font-family: Helvetica, Tahoma, Sans-serif; color: #666; font-weight: 200; } '
                + 'a { color: #666; } '
                + 'table {border-collapse:collapse;padding:0px;margin:0px;border-spacing:0;mso-table-lspace:0pt;mso-table-rspace:0pt;border:1px solid DimGray;} '
                + 'th,td {border-spacing:0;border-collapse:collapse !important;padding:5px;border:1px solid DimGray;}'
                + '.row-header {background-color: #eff1f3;  font-weight: bold; width: 300px;} '
                + '.error-banner {border-style:none; background-color: #ed676e; color: white;  margin: 20px 0px; } '
                + '.error-banner td {border-style:none; padding: 30px !important;} '
                + '.info-banner {border-style:none; background-color: #DDE9F5; margin: 20px 0px; } '
                + '.info-banner td {border-style:none;; padding: 30px !important;} '
                +  '</style></head><body><br />';

                String table = '';
                String textBody = '';
                if (dvsAction == 'UNKNOWN') {
                    textBody = Label.dvs_confirm_noresults;
                    table = '<table>' +
                    '<thead>' +
                        '<tr>' +
                            '<th class="row-header">Field</th>' +
                            '<th class="row-header">SF Data</th>' +
                        '</tr>' +
                    '</thead>' +
                    '<tbody>' +
                        '<tr>' +
                            '<th>Name</th><td><a href="' + URL.getOrgDomainUrl().toExternalForm() + '/' + acc.Id + '">' + acc.Name + '</a></td>' +
                        '</tr>' +
                        '<tr>' +
                            '<th>Street</th><td>' + acc.BillingStreet + '</td>'+
                        '</tr>' +
                        '<tr>' +
                            '<th>Postal Code</th><td>' + acc.BillingPostalCode + '</td>' +
                        '</tr>' +
                        '<tr>' +
                            '<th>City</th><td>' + acc.BillingCity + '</td>' +
                        '</tr>' +
                        '<tr>' +
                            '<th>Country</th><td>' + acc.BillingCountry + '</td>' +
                        '</tr>' +
                        '<tr>' +
                            '<th>Siret</th><td>' + acc.VAT_Number__c + '</td>' +
                        '</tr>' +
                        '<tr>' +
                            '<th>Siren</th><td>' + acc.VAT_Number_2__c + '</td>' +
                        '</tr>' +
                    '</tbody>' +
                '</table>';
                } else if (company != null){
                    textBody = Label.dvs_confirm_email_body;
                    table = '<table>' +
                        '<thead>' +
                            '<tr>' +
                                '<th class="row-header">' + Label.dict_field + '</th>' +
                                '<th class="row-header">' + Label.dict_existing_data + '</th>' +
                                '<th class="row-header">' + Label.dict_official_data + '</th>' +
                            '</tr>' +
                        '</thead>' +
                        '<tbody>' +
                            '<tr>' +
                                '<th>' + Label.dict_name + '</th><td><a href="' + URL.getOrgDomainUrl().toExternalForm() + '/' + acc.Id + '">' + acc.Name + '</a></td><td>' + company.get(ModalResultFieldLabels.GLOBAL_NAME_FIELD_LABEL) + '</td>' +
                            '</tr>' +
                            '<tr>' +
                                '<th>Street</th><td>' + acc.BillingStreet + '</td><td>' + company.get(ModalResultFieldLabels.GLOBAL_STREET_FIELD_LABEL) + '</td>' +
                            '</tr>' +
                            '<tr>' +
                                '<th>' + Label.dict_postal_code + '</th><td>' + acc.BillingPostalCode + '</td><td>' + company.get(ModalResultFieldLabels.GLOBAL_POSTALCODE_FIELD_LABEL) + '</td>' +
                            '</tr>' +
                            '<tr>' +
                                '<th>' + Label.dict_city + '</th><td>' + acc.BillingCity + '</td><td>' + company.get(ModalResultFieldLabels.GLOBAL_CITY_FIELD_LABEL) + '</td>' +
                            '</tr>' +
                            '<tr>' +
                                '<th>' + Label.dict_country + '</th><td>' + acc.BillingCountry + '</td><td>' + company.get(ModalResultFieldLabels.GLOBAL_COUNTRY_FIELD_LABEL) + '</td>' +
                            '</tr>' +
                            '<tr>' +
                                '<th>Siret</th><td>' + acc.VAT_Number__c + '</td><td>' + company.get(ModalResultFieldLabels.FR_SIRET_FIELD_LABEL) + '</td>' +
                            '</tr>' +
                            '<tr>' +
                                '<th>Siren</th><td>' + acc.VAT_Number_2__c + '</td><td>' + company.get(ModalResultFieldLabels.FR_SIREN_FIELD_LABEL) + '</td>' +
                            '</tr>' +
                        '</tbody>' +
                    '</table>';
                }
        String endText = '<br />Salesforce Team' +
                    '</body></html>';

        textBody = textBody.replace('{1}', link);
        textBody = textBody.replace('{2}', table);

        List<User> accountingUsers = getAccountingMembers(acc.BillingCountryCode);
        List<String> emailsToSend = new List<String>();
        for (User aux : accountingUsers) {
            emailsToSend.add(aux.Email);
        }
        Mail mail = new Mail();
        mail.setGeneric();
        mail.setHtml(MailUtils.addHTMLTags(textHeader + textBody + endText));
        mail.setSubject(textSubject);
        mail.setTo(emailsToSend);
        mail.send();
    }

    /**
     * Envía un email a los responsables de crear cuentas en Porcelanosa Exportación 008
     */
    public static void sendDvsConfirmation( String accountId, String userToInform) {
        Account acc = new AccountsSelector().selectById(accountId);
        User usr = [SELECT Id, Name, Email FROM User WHERE Id =: userToInform];
        
        String textSubject = Label.dvs_confirmed_validation + ' - ' + acc.Name;
        String link = '<a href="' + URL.getOrgDomainUrl().toExternalForm() + '/' + acc.Id + '">'+ Label.dict_click_here + '</a>';
        String textHeader = '<html><head><style>'
                + 'body { font-family: Helvetica, Tahoma, Sans-serif; color: #666; font-weight: 200; } '
                + 'a { color: #666; } '
                + 'table {border-collapse:collapse;padding:0px;margin:0px;border-spacing:0;mso-table-lspace:0pt;mso-table-rspace:0pt;border:1px solid DimGray;} '
                + 'th,td {border-spacing:0;border-collapse:collapse !important;padding:5px;border:1px solid DimGray;}'
                + '.row-header {background-color: #eff1f3;  font-weight: bold; width: 300px;} '
                + '.error-banner {border-style:none; background-color: #ed676e; color: white;  margin: 20px 0px; } '
                + '.error-banner td {border-style:none; padding: 30px !important;} '
                + '.info-banner {border-style:none; background-color: #DDE9F5; margin: 20px 0px; } '
                + '.info-banner td {border-style:none;; padding: 30px !important;} '
                +  '</style></head><body><br />';

                String textBody = Label.dvs_confirmated_body;
                String table = '<table>' +
                    '<thead>' +
                        '<tr>' +
                            '<th class="row-header">' + Label.dict_field + '</th>' +
                            '<th class="row-header">' + Label.dict_existing_data + '</th>' +
                        '</tr>' +
                    '</thead>' +
                    '<tbody>' +
                        '<tr>' +
                            '<th>' + Label.dict_name + '</th><td><a href="' + URL.getOrgDomainUrl().toExternalForm() + '/' + acc.Id + '">' + acc.Name + '</a></td>' +
                        '</tr>' +
                        '<tr>' +
                            '<th>Street</th><td>' + acc.BillingStreet + '</td>'+
                        '</tr>' +
                        '<tr>' +
                            '<th>' + Label.dict_postal_code + '</th><td>' + acc.BillingPostalCode + '</td>' +
                        '</tr>' +
                        '<tr>' +
                            '<th>' + Label.dict_city + '</th><td>' + acc.BillingCity + '</td>' +
                        '</tr>' +
                        '<tr>' +
                            '<th>' + Label.dict_country + '</th><td>' + acc.BillingCountry + '</td>' +
                        '</tr>' +
                        '<tr>' +
                            '<th>Siret</th><td>' + acc.VAT_Number__c + '</td>' +
                        '</tr>' +
                        '<tr>' +
                            '<th>Siren</th><td>' + acc.VAT_Number_2__c + '</td>' +
                        '</tr>' +
                    '</tbody>' +
                '</table>';
        String endText = '<br />Salesforce Team' +
                    '</body></html>';

        textBody = textBody.replace('{1}', table);

        List<String> emailsToSend = new List<String>{usr.Email};
        Mail mail = new Mail();
        mail.setGeneric();
        mail.setHtml(MailUtils.addHTMLTags(textHeader + textBody + endText));
        mail.setSubject(textSubject);
        mail.setTo(emailsToSend);
        mail.send();
    }

    public static List<User> getAccountingMembers(String countryCode) {
        Set<Id> ids = new Set<Id>();
        String groupName = 'accounting_department_' + countryCode.toLowerCase();
        Group[] groups = [select Id, DeveloperName from Group where DeveloperName = :groupName];
        if (groups.size() > 0) {
            for (GroupMember member : [select UserOrGroupId from GroupMember where GroupId = :groups[0].Id]) {
                ids.add(member.UserOrGroupId);
            }
        }

        List<User> users = new UsersSelector().selectById(ids);
        return users;
    }

    public static Boolean isAccountingMember(Id userId, String countryCode) {
        List<User> usersAccounting = getAccountingMembers(countryCode);
        Boolean result = false;

        for (User aux : usersAccounting) {
            if (aux.Id == userId) {
                result = true;
                break;
            }
        }

        return result;
    }
}