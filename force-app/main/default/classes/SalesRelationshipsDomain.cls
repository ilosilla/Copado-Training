public class SalesRelationshipsDomain {
    public static Boolean isRestrictedOrg(String salesOrg) {
        Boolean result = false;
        List<Sales_org__c> restrictedOrgs = [select id, RestrictedForSAP__c, SalesOrg__c from Sales_Org__c where SalesOrg__c =: salesOrg and RestrictedForSAP__c = true];

        if (restrictedOrgs.size() > 0) {
            result = true;
        }
        return result;
    }

    public static List<Sales_org__c> getRestrictedOrgs() {
        List<Sales_org__c> restrictedOrgs = [select id, RestrictedForSAP__c, SalesOrg__c from Sales_Org__c where RestrictedForSAP__c = true];

        return restrictedOrgs;
    }

    // Devuelve los usuarios que pueden ampliar a la org 008
    public static List<User> getRestrictedOrgExtendors(String salesOrg) {
        String namePermission = 'SAP_ACCOUNT_CREATION_' + salesOrg;
        List<PermissionSetAssignment> hasPermissions = [SELECT PermissionSet.Name, AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name =: namePermission];
        List<User> users = new List<User>();
        Set<Id> userIds = new Set<Id>();
        List<String> emailTo = new List<String>();
        if (hasPermissions.size() > 0) {
            for (PermissionSetAssignment gMember : hasPermissions) {
                userIds.add(gMember.AssigneeId);
            }
            users = new UsersSelector().selectById(userIds);
        }

        return users;
    }

    /**
     * Envía un email a los responsables de crear cuentas en Porcelanosa Exportación 008
     */
    public static void sendRestrictedOrgRequestExportacion(String salesOrg, String channel, String salesOffice, String commercialId, String userId, String accountId) {
        Account acc = [SELECT Id, Name, Sap_id__c, Business_Email__c FROM Account WHERE Id =: accountId];
        User usr = [SELECT Id, Name, Email FROM User WHERE Id =: userId];
        User commercial = [SELECT Id, Name, Email FROM User WHERE Id =: commercialId];

        Map<String, String> salesOrgOptions = new Map<String, String>();
        for (Schema.PicklistEntry a : (new User()).getSObjectType().getDescribe().fields.getMap().get('Default_Sales_organization__c').getDescribe().getPickListValues())
        { 
            salesOrgOptions.put(a.getValue(), a.getLabel()); 
        }

        Map<String, String> channelOptions = new Map<String, String>();
        for (Schema.PicklistEntry a : (new User()).getSObjectType().getDescribe().fields.getMap().get('Distribution_channel_default__c').getDescribe().getPickListValues())
        { 
            channelOptions.put(a.getValue(), a.getLabel()); 
        }

        Map<String, String> salesOfficeOptions = new Map<String, String>();
        for (Schema.PicklistEntry a : (new User()).getSObjectType().getDescribe().fields.getMap().get('Sales_Office__c').getDescribe().getPickListValues())
        { 
            salesOfficeOptions.put(a.getValue(), a.getLabel()); 
        }
        
        String textSubject = 'SALESFORCE EXTENSION APPROVAL 008 - ' + acc.Name;
        String textBody = '<html><head><style>'
                + 'body { font-family: Helvetica, Tahoma, Sans-serif; color: #666; font-weight: 200; } '
                + 'a { color: #666; } '
                + 'table {border-collapse:collapse;padding:0px;margin:0px;border-spacing:0;mso-table-lspace:0pt;mso-table-rspace:0pt;border:1px solid DimGray;} '
                + 'th,td {border-spacing:0;border-collapse:collapse !important;padding:5px;border:1px solid DimGray;}'
                + '.row-header {background-color: #eff1f3;  font-weight: bold; width: 300px;} '
                + '.error-banner {border-style:none; background-color: #ed676e; color: white;  margin: 20px 0px; } '
                + '.error-banner td {border-style:none; padding: 30px !important;} '
                + '.info-banner {border-style:none; background-color: #DDE9F5; margin: 20px 0px; } '
                + '.info-banner td {border-style:none;; padding: 30px !important;} '
                +  '</style></head><body>';
        textBody += '<br />' +
                'Your approval is needed for the account detailed below. Please <a href="{!ApprovalRequest.External_URL}">click here</a> to review and create the account if everything is correct.' +
                '<br />' +
                '<br />' +
                '<br />' +
                'The details of the extension can be found below:' +
                '<br />' +
                '<br />' +
                '<table>' +
                    '<tbody>' +
                        '<tr>' +
                            '<th class="row-header">Sales Org</th>' +
                            '<td>' + salesOrgOptions.get(salesOrg) + ' [ ' + salesOrg + ']</a></td>' +
                        '</tr>' +
                        '<tr>' +
                            '<th class="row-header">Distribution Channel</th>' +
                            '<td>' + channelOptions.get(channel) + ' [' + channel + ']</a></td>' +
                        '</tr>' +
                        '<tr>' +
                            '<th class="row-header">Sales Office</th>' +
                            '<td>' + salesOfficeOptions.get(salesOffice) + ' [' + salesOffice + ']</a></td>' +
                        '</tr>' +
                        '<tr>' +
                            '<th class="row-header">Commercial</th>' +
                            '<td>' + commercial.Name + '</a></td>' +
                        '</tr>' +
                    '</tbody>' +
                '</table>' +
                '<br />' +
                'The details of the Account can be found below:' +
                '<br />' +
                '<br />' +
                '<table>' +
                    '<tbody>' +
                        '<tr>' +
                            '<th class="row-header">Account Name</th>' +
                            '<td><a href="' + URL.getOrgDomainUrl().toExternalForm() + '/' + acc.Id + '">' + acc.Name + '</a></td>' +
                        '</tr>' +
                        '<tr>' +
                            '<th class="row-header">Business Email</th>' +
                            '<td>' + acc.Business_Email__c + '</td>' +
                        '</tr>' +
                        '<tr>' +
                            '<th class="row-header">Requested by</th>' +
                            '<td>' + usr.Name + '</td>' +
                        '</tr>' +
                    '</tbody>' +
                '</table>' +
                '<br />' +
                '<br />' +
                '<br />' +
                'Salesforce Team' +
                '</body></html>';

        // Se envia email a las personas en el grupo CREATE_ACCOUNT_008
        List<GroupMember> groupMembers = [SELECT Id, GroupId, Group.DeveloperName, UserOrGroupId FROM GroupMember where Group.DeveloperName =: 'SAP_ACCOUNT_CREATION_RECEIVERS_008'];

        Set<String> userIds = new Set<String>();
        List<String> emailTo = new List<String>();
        if (groupMembers.size() > 0) {
            for (GroupMember gMember : groupMembers) {
                userIds.add(gMember.UserOrGroupId);
            }
            List<User> users = [SELECT Id, EMail FROM User WHERE Id IN :userIds ];

            for (User aux : users) {
                emailTo.add(aux.Email);
            }
        }

        Mail mail = new Mail();
        mail.setGeneric();
        mail.setHtml(MailUtils.addHTMLTags(textBody));
        mail.setSubject(textSubject);
        mail.setTo(emailTo);
        mail.send();
    }
}