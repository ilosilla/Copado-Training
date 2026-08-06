/**
* @author Ivan Losilla Perez
* @date October-2020
*
* @group Utils
* @group-content ../../ApexDocContent/MailUtils.htm
*
* @description Class wich has methods to use on Mailing processes.
*/
public class MailUtils {

    /**
    * @description returns a list of the email accounts of the object Ids passed
    * @param objectIds List of Ids
    * @return List of email accounts
    *
    * @example 
    * List<Id> listIds = new List<Id>{'0010E00000xlYJDQA2','0010E00000xlYJDQA2'};
    * List<String> mailList = MailUtils.getMail(listIds);
    */
    public static List<String> getMail(List<Id> objectIds) {
        return getMailMap(objectIds).values();
    }

     /**
    * @description returns a list of the email account of the object Id passed
    * @param objectIds Single Id
    * @return List of email account
    *
    * @example 
    * Id objectId = '0010E00000xlYJDQA2';
    * List<String> mail = MailUtils.getMail(objectId);
    */
    public static List<String> getMail(Id objectId) {
        return getMail(new List<Id>{objectId});
    }

    public static Map<Id,String> getMailMap(List<Id> objectIds) {
        String objectType = null;
        Map<String,List<Id>> mapIds = new Map<String,List<Id>>();
        List<Id> idsAux = new List<Id>();
        Map<Id,String> results = new Map<Id,String>();

        for (Id objectId : objectIds) {
            objectType = objectId.getSObjectType().getDescribe().getName();
            if (mapIds.containsKey(objectType)) {
                idsAux = mapIds.get(objectType);
            }
            idsAux.add(objectId);
            mapIds.put(objectType, idsAux);
            idsAux = new List<Id>();
        }

        for (String option : mapIds.keySet()) {
            results.putAll(getMailByObjectType(mapIds.get(option), option));
        }

        return results;
    }

    private static Map<Id,String> getMailMap(Id objectId) {
        return getMailMap(new List<Id>{objectId});
    }

    private static Map<Id,String> getMailByObjectType(List<Id> listIds, String objectType) {
        Map<Id,String> mapMails = new Map<Id,String>();

        switch on ObjectType {
            when 'Account' {
                List<Account> accList = [SELECT Id, IsPersonAccount, PersonEmail, Business_Email__c FROM Account WHERE Id IN :listIds];
                for (Account acc : accList) {
                    if (acc.IsPersonAccount == true) {
                        mapMails.put(acc.Id, acc.PersonEmail);
                    } else {
                        mapMails.put(acc.Id, acc.Business_Email__c);
                    }
                }
            }
            when 'Contact' {
                List<Contact> contList = [SELECT Id, Email FROM Contact WHERE Id IN :listIds];
                for (Contact cont : contList) {
                    mapMails.put(cont.Id, cont.Email);
                }
            }
            when 'User' {
                List<User> usrList = [SELECT Id, Email FROM User WHERE Id IN :listIds];
                for (User usr : usrList) {
                    mapMails.put(usr.Id, usr.Email);
                }
            }
        }
        return mapMails;
    }

     /**
    * @description checks if an email address is a valid one
    * @param email email address
    * @return True or False, depending if it's a valid email address
    *
    * @example 
    * String mail = 'test@test.com';
    * Boolean isValid = MailTest.validateEmail(mail);
    */
    public static Boolean validateEmail(String email) {
        Boolean res = true;
 
        String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$'; // source: http://www.regular-expressions.info/email.html
        Pattern MyPattern = Pattern.compile(emailRegex);
        Matcher MyMatcher = MyPattern.matcher(email);

        if (!MyMatcher.matches()) 
            res = false;
        return res;	
    }

     /**
    * @description given a list of email addresses, returns a list with only the valid ones
    * @param email List of email addresses
    * @return List of valid email addresses
    *
    * @example 
    * List<String> listEmails = new List<String>{'test@test.com','adsasd@.com'}
    * List<String> validEmails = MailUtils.keepValidEmails(listEmails); //will return only test@test.com
    */
    public static List<String> keepValidEmails(List<String> emails) {
        List<String> keepList = new List<String>();

        for (String email : emails) {
            if (validateEmail(email) == true) {
                keepList.add(email);
            }
        }

        return keepList;
    }

    public static Object getSobjectField(Sobject sObj, String fieldRef) {

        Sobject sObjNode    = sObj;
        //  fieldRef is relative to the sobject and may include relationshipNames
        //      Handle use cases:
        //          fld0                - fld0 on Sobject passed as argument
        //          fld0.fld1           - fld1 is on sobject fld0
        //          fld0.fld1. ... fldN - fldN is on sobject fldN-1
        String[] fieldList  = fieldRef.split('\\.');

        for (Integer i=0; i < fieldList.size() -1; i++) {
            sObjNode    = (Sobject) sObjNode.getSobject(fieldList[i]);  // intermediate fields are sobjects
            if (sObjNode == null) return null;
        }
        return sObjNode.get(fieldList[fieldList.size()-1]); // use fldN
    }

    public static Boolean sendBatch(List<Mail> mailsList) {
        List<Messaging.SingleEmailmessage> mailsListAux = new List<Messaging.Singleemailmessage>();
        for (Mail singleMail : mailsList) {
            mailsListAux.add(singleMail.getEmail());
        }

        Messaging.sendEmailResult[] sendEmailResults = Messaging.sendEmail(mailsListAux);

        for(Messaging.SendEmailResult sendEmailResult: sendEmailResults){
            if(!sendEmailResult.isSuccess()){
                System.debug('**************** Email Send Error *************************');
                System.debug(sendEmailResults);
            }
        }
        return true;
    }

    /**
     * Adds html/head/body tags and styles
     */
    public static String addHTMLTags(String section) {
        String result = '<html><head><style>'
            + 'body { font-family: Helvetica, Tahoma, Sans-serif; color: #666; font-weight: 200; } '
            + 'a { color: #666; } '
            + 'table {border-collapse:collapse;padding:0px;margin:0px;border-spacing:0;mso-table-lspace:0pt;mso-table-rspace:0pt;border:1px solid DimGray;} '
            + 'th,td {border-spacing:0;border-collapse:collapse !important;padding:10px;border:1px solid DimGray;}'
            + '.row-header {background-color: #eff1f3;  font-weight: bold;} '
            + '.col-header {background-color: #666;  font-weight: bold; color: white;} '
            + '.error-banner {border-style:none; background-color: #ed676e; color: white;  margin: 20px 0px; } '
            + '.error-banner td {border-style:none; padding: 30px !important;} '
            + '.info-banner {border-style:none; background-color: #DDE9F5; margin: 20px 0px; } '
            + '.info-banner td {border-style:none;; padding: 30px !important;} '
            +  '</style></head><body>'
            +  section
            +  '</body></html>';
        return result;
    }

    /**
     * Converts a Map<String,String> to a table adding a style to the table tag
     */
    public static String mapToTable(Map<String, String> content, String style) {
        String html = '';
        Set<String> keys = content.keySet();
        for (String key :keys ) {
            String value = content.get(key);
            html += '<tr><td class="row-header">' + key + '</td><td>' + value + '</td></tr>';
        }
        html = '<table style="' + style +'">' + html + '</table>';
        return html;
    }


    /**
     * Converts a Map<String,String> to a table
     */
    public static String mapToTable(Map<String, String> content) {
        return mapToTable(content, '');
    }
}