/**
* @author Ivan Losilla Perez
* @date 10-2020
*
* @group Mail
* @group-content ../../ApexDocContent/MailMails.htm
*
* @description Methods wich sends emails to users
*/
public class InstallationMails {
    /******************************************** OPEN INSTALLATIONS LIST **********************************************/
    /**
     * @description Sends Open Installation Emails to the users with Installations, and their Managers
     */
    @InvocableMethod(label='Open Installations' description='Sends emails of the opened installations.' category='InstallationRequest__c')
    public static void openInstallations() {
        openInstallations(false,'test@test.com');
    }
    
    /**
     * @description Sends Open Installation Emails to the mail set, to debug
     */
    public static void openInstallationsDebug(String mailDebug) {
        openInstallations(true, mailDebug);
    }

    private static void openInstallations(Boolean debugSetting, String debugMail) {
        Map<Id,List<InstallationRequest__c>> mapINSR = new Map<Id,List<InstallationRequest__c>>();
        Map<Id,List<InstallationOrder__c>> mapINSO = new Map<Id,List<InstallationOrder__c>>();
        List<Mail> mailsToSend = new List<Mail>();
        List<InstallationRequest__c> auxListInsr = new List<InstallationRequest__c>();
        List<InstallationOrder__c> auxListInso = new List<InstallationOrder__c>();
        Set<Id> usrList = new Set<Id>();
        Map<Id,Set<Id>> hierarchy = UserUtils.getHierarchyUsers();
        
        List<InstallationRequest__c> insrList = [SELECT Id,
                                                        Name,   
                                                        Owner.Name,
                                                        Opportunity__r.Account.Name, 
                                                        AccountId__c,
                                                        Description__c,
                                                        InstallerAccount__c,
                                                        LastTransition__c,
                                                        Opportunity__c,
                                                        OwnerId,
                                                        Owner.UserRole.Id,
                                                        Owner.UserRole.ParentRoleId,
                                                        Owner.Email,
                                                        InstallerAccount__r.name,
                                                        Opportunity__r.Address__c,
                                                        Opportunity__r.Postcode__c,
                                                        Opportunity__r.City__c,
                                                        State__c 
                                                        FROM InstallationRequest__c  where State__c not in : InstallationUtil.closedStateRequest];
        List<InstallationOrder__c> insoList = [SELECT Id,
                                                        Name,
                                                        Installation_Request__r.Opportunity__r.Account.name,
                                                        Installation_Request__r.Opportunity__r.Address__c,
                                                        Installation_Request__r.Opportunity__r.Postcode__c,
                                                        Installation_Request__r.Opportunity__r.City__c,
                                                        Installation_Request__r.Name,
                                                        Installation_Request__r.InstallerAccount__r.name,
                                                        Owner.Name,
                                                        Owner.UserRole.Id,
                                                        Owner.UserRole.ParentRoleId,
                                                        Owner.Email,
                                                        State__c,
                                                        OwnerId,
                                                        StartDate__c,
                                                        EndDate__c
                                                        FROM InstallationOrder__c  where State__c not in : InstallationUtil.closedStateOrder];

        // We mount on mapINSR each user and the Installation Request that has to appear on the email (normal users and managers)
        for (InstallationRequest__c insr : insrList) {
            if (mapINSR.containsKey(insr.OwnerId) == false){
                mapINSR.put(insr.OwnerId, new List<InstallationRequest__c>());
            }
            auxListInsr = mapINSR.get(insr.OwnerId);
            auxListInsr.add(insr);
            mapINSR.put(insr.OwnerId, auxListInsr);
            usrList.add(insr.OwnerId);

            for (Id parent : hierarchy.keySet()) {
                if (hierarchy.get(parent).contains(insr.OwnerId)) {
                    if (mapINSR.containsKey(parent) == false){
                        mapINSR.put(parent, new List<InstallationRequest__c>());
                    }
                    auxListInsr = mapINSR.get(parent);
                    auxListInsr.add(insr);
                    mapINSR.put(parent, auxListInsr);
                    usrList.add(parent);
                }
            }
        }
        
        // We mount on mapINSO each user and the Installation Order that has to appear on the email (normal users and managers)
        for (InstallationOrder__c inso : insoList) {
            if (mapINSO.containsKey(inso.OwnerId) == false){
                mapINSO.put(inso.OwnerId, new List<InstallationOrder__c>());
            }
            auxListInso = mapINSO.get(inso.OwnerId);
            auxListInso.add(inso);
            mapINSO.put(inso.OwnerId, auxListInso);
            usrList.add(inso.OwnerId);

            for (Id parent : hierarchy.keySet()) {
                if (hierarchy.get(parent).contains(inso.OwnerId)) {
                    if (mapINSO.containsKey(parent) == false){
                        mapINSO.put(parent, new List<InstallationOrder__c>());
                    }
                    auxListInso = mapINSO.get(parent);
                    auxListInso.add(inso);
                    mapINSO.put(parent, auxListInso);
                    usrList.add(parent);
                }
            }
        }
        
        // We get the email address of each user
        Map<Id,User> usersData = new Map<Id,User>([Select Id, FirstName, LastName, Name, Email, CountryCode from User where Id in : usrList]);
        
        //Prepare each of the mails that are going to be sent
        List<String> mailToUser = new List<String>();
        String userName = '';
        String userCountryCode = '';
        Map<String, InstallationSettings__c> mapInsSettings = InstallationSettings.getInstallationSettings();
        
        Mail auxMail = null;
        for (Id usrId : usrList) {
            auxMail = new Mail();
            if ((mapINSR.get(usrId) == null || mapINSR.get(usrId).size() == 0) && (mapINSO.get(usrId) == null || mapINSO.get(usrId).size() == 0)) {
                continue;
            }

            mailToUser = new List<String>{usersData.get(usrId).Email};
            userName = usersData.get(usrId).FirstName;
            userCountryCode = usersData.get(usrId).CountryCode;

            // Check if the country has the Bcc Developers checked
            if (mapInsSettings.containsKey(userCountryCode) && mapInsSettings.get(userCountryCode) != null && mapInsSettings.get(userCountryCode).bccDevelopers__c == true && debugSetting == false) {
                auxMail.setBcc(auxMail.developerMail);
            }
            
            auxMail.setHtml(openInstallationsUserMail(userName,mailToUser,mapINSR.get(usrId),mapINSO.get(usrId)));
            auxMail.setGeneric(); // It will come from a generic email address
            if (debugSetting == false) {
                auxMail.setTo(mailToUser);
                auxMail.setSubject(Label.open_installations);
            } else {
                auxMail.setSubject(Label.open_installations + ' - would be sent TO ' + mailToUser);
                auxMail.setTo(new List<String>{debugMail});
            }
            mailsToSend.add(auxMail);
        }
        //Sending all mails at the same time - If not, there is a Governor limit of 10 Mails
        MailUtils.sendBatch(mailsToSend);
    }

    /**
    * @description Creates the Mail to send, with the body, addresses, etc.
    * @param List<String> List of addresses we send the info
    * @param List<InstallationRequest__c> List of Installation Request to appear on the email
    * @param List<InstallationOrder__c> List of Installation Order to appear on the email
    * @return 
    *
    * @example 
    */
    private static String openInstallationsUserMail(String userName, List<String> sendToAddress, List<InstallationRequest__c> listInsr,List<InstallationOrder__c> listInso) {
        String mailBody = '';
        mailBody += MailHtml.createHeader(Label.dear + ' ' + userName + ',');
        mailBody += MailHtml.createHeader(Label.ins_header_openinstallations);
        if (listInsr != null) {
            mailBody += openInsrHtml(listInsr) + '<br/><br/>';
        }
        if (listInso != null) {
            mailBody += openInsoHtml(listInso);
        }

        return MailStyles.internalStyle() + mailBody;
    }

    private static String openInsrHtml(List<InstallationRequest__c> listRequests) {
        String mailBody = '';
        mailBody += MailHtml.createTitle(Label.open_requests);
        mailBody += '<table>';
        mailBody += '<tr>' +
                        '<th><b>' + Label.ins_request.toupperCase() + '/' + Label.town.toupperCase() + '</b></th>' + 
                        '<th><b>' + Label.sales_rep.toupperCase() + '</b></th>' + 
                        '<th><b>' + Label.account.toupperCase() + '</b></th>' + 
                        '<th><b>' + Label.installer.toupperCase() + '</b></th>' + 
                        '<th><b>' + Label.stage.toupperCase() + '</b></th>' + 
                        '<th><b>' + Label.days_current_stage.toupperCase() + '</b></th>' + 
                        '<th><b>' + Label.next_action.toupperCase() + '</b></th>' + 
                    '</tr>';
        for(InstallationRequest__c insr : listRequests) {
            Long diffDaysString = SystemUtils.getdiffDays(insr.LastTransition__c,system.now());

            mailBody += '<tr>' +
                            '<td class="gray"><b>' +
                                '<a href="' + URL.getOrgDomainUrl().toExternalForm() + '/' + insr.Id + '">' + insr.Name + '</a>' +
                                '<br/>' + insr.Opportunity__r.Postcode__c + ' - ' + insr.Opportunity__r.City__c +
                            '</b></td>' + 
                            '<td>' +
                                insr.Owner.Name +
                            '</td>' + 
                            '<td>' +
                                insr.Opportunity__r.Account.Name +
                            '</td>' + 
                            '<td>' +
                                insr.InstallerAccount__r.name +
                            '</td>' + 
                            '<td>' +
                                insr.State__c +
                            '</td>' + 
                            '<td>' +
                                (diffDaysString == null ? Label.not_set : String.valueOf(diffDaysString)) +
                            '</td>' + 
                            '<td>' +
                                InstallationUtil.requestNextActionLabel(insr) +
                            '</td>' + 
                        '</tr>';
        }
            
        mailBody += '</table>';
        return mailBody;
    }

    private static String openInsoHtml(List<InstallationOrder__c> listOrders) {
        String mailBody = '';
        mailBody += MailHtml.createTitle(Label.open_orders);
        mailBody += '<table>';
        mailBody += '<tr>' +
                        '<th><b>' + Label.ins_order.toupperCase() + '</b></th>' + 
                        '<th><b>' + Label.sales_rep.toupperCase() + '</b></th>' + 
                        '<th><b>' + Label.account.toupperCase() + '</b></th>' + 
                        '<th><b>' + Label.installer.toupperCase() + '</b></th>' + 
                        '<th><b>' + Label.stage.toupperCase() + '</b></th>' + 
                        '<th><b>' + Label.next_action.toupperCase() + '</b></th>' + 
                    '</tr>';
        for(InstallationOrder__c inso : listOrders) {
            mailBody += '<tr>' +
                            '<td class="gray">' +
                                '<b>' +
                                    '<a href="' + URL.getOrgDomainUrl().toExternalForm() + '/' + inso.Id + '">' + inso.Name + '</a>' +
                                    '<br/>' + inso.Installation_Request__r.Opportunity__r.Postcode__c + ' - ' + inso.Installation_Request__r.Opportunity__r.City__c +
                                '</b>' +
                            '</td>' + 
                            '<td>' +
                                inso.Owner.Name +
                            '</td>' + 
                            '<td>' +
                                inso.Installation_Request__r.Opportunity__r.Account.Name +
                            '</td>' + 
                            '<td>' +
                                inso.Installation_Request__r.InstallerAccount__r.name +
                            '</td>' + 
                            '<td>' +
                                inso.State__c +
                            '</td>' + 
                            '<td>' +
                                InstallationUtil.orderNextActionLabel(inso) +
                            '</td>' + 
                        '</tr>';
        }

        mailBody += '</table>';
        return mailBody;
    }

    /******************************************** STATE CHANGED ON INSTALLATION REQUEST **********************************************/

    /**
    * @description Send an Email to each one of the owners of the Installation Request that have changed to a specific State
    * @param oldListInsr Map of the old value of the Installation Requests
    * @param newListInsr Map of the new value of the Installation Requests
    *
    * @example 
    *   InstallationMails.changeStateInsrMail(Trigger.newMap, Trigger.oldMap);
    */
    public static void changeStateInsrMail(List<InstallationRequest__c> oldListInsr, List<InstallationRequest__c> newListInsr) {
        changeStateInsrMail(oldListInsr, newListInsr, null);
    }

    /**
    * @description Send an Email to the mail set to debug, of the Installation Requests that have changed to a specific State
    * @param oldMapInsr Map of the old value of the Installation Requests
    * @param newMapInsr Map of the new value of the Installation Requests
    * @param debugMail Mail address wich is going to receive the emails
    *
    * @example
    *   InstallationMails.changeStateInsrMailDebug(Trigger.newMap, Trigger.oldMap, 'test.test@test.com');
    */
    public static void changeStateInsrMailDebug(List<InstallationRequest__c> oldListInsr, List<InstallationRequest__c> newListInsr, String debugMail) {
        changeStateInsrMail(oldListInsr, newListInsr, debugMail);
    }
    

    private static void changeStateInsrMail(List<InstallationRequest__c> oldListInsr, List<InstallationRequest__c> newListInsr, String debugMail) {
        try {
            Map<Id, InstallationRequest__c> oldMapInsr = new Map<Id, InstallationRequest__c>();
            Map<Id, InstallationRequest__c> newMapInsr = new Map<Id, InstallationRequest__c>();
            for (InstallationRequest__c insr : oldListInsr) {
                oldMapInsr.put(insr.Id, insr);
            }
            for (InstallationRequest__c insr : newListInsr) {
                newMapInsr.put(insr.Id, insr);
            }

            List<String> stateChangesToMail = new List<String>{'3D Design', 'Quote Preparation'};
            InstallationRequest__c insrold = null;
            InstallationRequest__c insrnew = null;
            List<Id> validInsr = new List<Id>();
            List<Id> ownersIds = new List<Id>();
            Map<String, InstallationSettings__c> mapInsSettings = InstallationSettings.getInstallationSettings();
            List<InstallationRequest__c> insrToMail = new List<InstallationRequest__c>();
            
            for (Id insrId : oldMapInsr.keySet()) {
                insrold = oldMapInsr.get(insrId);
                insrnew = newMapInsr.get(insrId);
                
                if (insrold.State__c != insrnew.State__c && stateChangesToMail.contains(insrnew.State__c) && insrnew.LastModifiedById != insrnew.OwnerId) {
                    insrToMail.add(insrnew);
                    ownersIds.add(insrnew.ownerId);
                }
            }
            
            Map<Id, User> mapUsers = new Map<Id,User>([SELECT Id, FirstName, CountryCode, Email from User where Id in : ownersIds]);

            List<Mail> mailsToSend = new List<Mail>();
            Mail auxMail = null;

            for (InstallationRequest__c insr : insrToMail) {
                auxMail = new Mail();

                auxMail.setHtml(changeStateInsrHtml(insr, mapUsers.get(insr.OwnerId).FirstName));
                auxMail.setGeneric(); // It will come from a generic email address
                // Check if the country has the Bcc Developers checked
                if (mapInsSettings.containsKey(mapUsers.get(insr.OwnerId).CountryCode) && mapInsSettings.get(mapUsers.get(insr.OwnerId).CountryCode) != null && mapInsSettings.get(mapUsers.get(insr.OwnerId).CountryCode).bccDevelopers__c == true && debugMail == null) {
                    auxMail.setBcc(auxMail.developerMail);
                }
                if (debugMail == null) {
                    auxMail.setTo(new List<String>{mapUsers.get(insr.OwnerId).Email});
                    auxMail.setSubject(Label.insr_state_changed);
                } else {
                    auxMail.setTo(new List<String>{debugMail});
                    auxMail.setSubject(Label.insr_state_changed + ' - would be sent TO ' + mapUsers.get(insr.OwnerId).Email);
                }
                mailsToSend.add(auxMail);
            }

            MailUtils.sendBatch(mailsToSend);
        } catch (Exception e) {
            SystemUtils.debugWarning('MAIL CHANGE STATE INSR', 'Mail not sent', e);
        }
    }

    private static String changeStateInsrHtml(InstallationRequest__c insr, String username) {
        String mailBody = '';
        String longTextBody = Label.insr_state_changed_body;
        longTextBody = longTextBody.replace('#LINK', '<a href="' + URL.getOrgDomainUrl().toExternalForm() + '/' + insr.Id + '">' + insr.Name + '</a>');
        longTextBody = longTextBody.replace('#STATE', insr.State__c);
        mailBody += MailHtml.createHeader(Label.dear + ' ' + username + ',');
        mailBody+= longTextBody;
        
        return MailStyles.internalStyle() + mailBody;
    }
}