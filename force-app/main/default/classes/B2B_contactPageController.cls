/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-25-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class B2B_contactPageController {

    @AuraEnabled
    public static void sendMailtoSupport(String body){
        system.debug('sendMailtoSupport ' + body);
        String toEmail;
        list<Account> mail = new list<Account>();
        User usr;
        Id strUser = userInfo.getUserId();
        usr = [SELECT Contact.Account.OwnerId, ContactId, Contact.Name, Contact.Email,Contact.Phone, Contact.MobilePhone 
               FROM User WHERE id = :strUser LIMIT 1];
        if(Test.isRunningTest()){ 
        	toEmail = 'test@test.com';
            String template = 'Test Template';
            String bodyTest = 'Test Body';
        } else {
        	mail = [SELECT Owner.Email, Id, Name FROM Account WHERE OwnerId = :usr.Contact.Account.OwnerId];
            if(!mail.isEmpty()){
                toEmail = mail[0].Owner.Email;
            } else {
                String userCountryCode = [SELECT CountryCode FROM User WHERE Id = :userinfo.getUserId()].CountryCode;
        		toEmail = [SELECT SupportMail__c FROM b2b_contactMailing__c WHERE CountryCode__c = :userCountryCode LIMIT 1].SupportMail__c;
            }
        }


        if(!string.isBlank(toEmail)){
            Messaging.SingleEmailMessage email;
            email = new Messaging.SingleEmailMessage();
            String HTMLbody;
            HTMLbody = Label.B2B_ContactEmailTxt;
            String baseURL;
            baseURL = Label.B2B_OrgURL; 
           
            String mailTo;
            mailTo = 'mailto:';
            String phone;
            if(usr.Contact.Phone != null){
                phone = usr.Contact.Phone;
            }
            if(usr.Contact.MobilePhone != null){
                phone = usr.Contact.MobilePhone;
            }
            if(!mail.isEmpty()){
                HTMLbody = HTMLbody.replace('#CLIENTURL', baseURL+'/'+mail[0].Id);
                HTMLbody = HTMLbody.replace('#ACCOUNT', mail[0].Name);
            }
            if(!Test.isRunningTest()){
            	
            	HTMLbody = HTMLbody.replace('#CONTACTURL', baseURL+'/'+usr.ContactId);
            	HTMLbody = HTMLbody.replace('#CONTACT', usr.Contact.Name);
            	HTMLbody = HTMLbody.replace('#EMAILURL', mailTo+usr.Contact.Email);
            	HTMLbody = HTMLbody.replace('#EMAIL', usr.Contact.Email);
                HTMLbody = HTMLbody.replace('#PHONE', phone);
            }else {
                HTMLbody = HTMLbody.replace('#CLIENTURL', baseURL);
            	HTMLbody = HTMLbody.replace('#ACCOUNT', baseURL);
                HTMLbody = HTMLbody.replace('#CONTACTURL', baseURL);
            	HTMLbody = HTMLbody.replace('#CONTACT', baseURL);
            	HTMLbody = HTMLbody.replace('#EMAILURL', baseURL);
            	HTMLbody = HTMLbody.replace('#EMAIL', baseURL);	
                HTMLbody = HTMLbody.replace('#PHONE', baseURL);
                HTMLbody = HTMLbody.replace('#CONTACTURL', 'test');
            	HTMLbody = HTMLbody.replace('#CONTACT', 'test');
            	HTMLbody = HTMLbody.replace('#EMAILURL', 'test');
                HTMLbody = HTMLbody.replace('#EMAIL', baseURL);	
                HTMLbody = HTMLbody.replace('#PHONE', baseURL);
                HTMLbody = HTMLbody.replace('#CONTACTURL', 'test');
            	HTMLbody = HTMLbody.replace('#CONTACT', 'test');
            	HTMLbody = HTMLbody.replace('#EMAILURL', 'test');
                HTMLbody = HTMLbody.replace('#CLIENTURL', baseURL);
            	HTMLbody = HTMLbody.replace('#ACCOUNT', baseURL);
                HTMLbody = HTMLbody.replace('#CONTACTURL', baseURL);
            	HTMLbody = HTMLbody.replace('#CONTACT', baseURL);
            }
			HTMLbody = HTMLbody.replace('#MESSAGE', body);
			
            list<String> toAdresses;
            toAdresses = new list<String>();
            //Añadir a toAdresses el mail al que tenemos que notificar Owner del contacto? Usuario logado? o la custom setting
            toAdresses.add(toEmail);

            email.setToAddresses(toAdresses);
            email.setHtmlBody(HTMLbody);
       
            Messaging.SendEmailResult [] r;
            r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        }
    }

}