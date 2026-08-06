/**
* @author 		Nubika
* @date 		November 2022
* @group 		
* @description 	Send sms & email reminder to appointment date
*/
global with sharing class NBK_ScheduleSendReminder implements Schedulable {
    private EmailTemplate templateVirtual;
    private EmailTemplate templateShowroom;

    global void execute(SchedulableContext sc) {
        //ajustar hora para no depender de now()
        Datetime startDateTime = Datetime.newInstance(Date.today().addDays(1),Time.newInstance(0, 0, 0, 0));
        //mañana a las 00:00
        Datetime endDateTime = startDateTime.addDays(1).addHours(2);
        //pasado mañana a las 02:00
        list<Event> events = [SELECT Event_type__c, StartDateTime, EndDateTime, Id,
                                                                    TYPEOF Who
                                                                        WHEN Lead
                                                                        THEN Email, CountryCode__c, MobilePhone
                                                                    END,
                                                                    TYPEOF Owner
                                                                        WHEN User
                                                                        THEN Id, Email, Sales_Office_Text__c, Sales_Office__c, Name, FirstName, LastName
                                                                    END
                              FROM Event
                              WHERE (Event_type__c = 'Showroom' OR Event_type__c = 'Virtual') AND
                              (StartDateTime > :startDateTime AND EndDateTime < :endDateTime)];

        if (!events.isEmpty()){
            // BUSQUEDA BUSINESSHOURS
            List<String> salesOfficeList = new List<String>();

            for(Event e : events){
                User ownerUser = e.Owner;
                salesOfficeList.add(ownerUser.Sales_Office__c);
            }
            // System.debug('salesOfficeList ' + salesOfficeList);
            // System.debug('Busines list ' + [SELECT NBK_Business_Hours__r.TimeZoneSidKey ,NBK_SalesOffice__r.SalesOffice__c FROM PorcelanosaAddress__c]);

            List<PorcelanosaAddress__c> businessList = [SELECT NBK_Business_Hours__r.TimeZoneSidKey ,NBK_SalesOffice__r.SalesOffice__c
                                                        FROM PorcelanosaAddress__c
                                                        WHERE NBK_SalesOffice__r.SalesOffice__c IN : salesOfficeList];

            // System.debug('Busines list ' + businessList[0].NBK_Business_Hours__r.TimeZoneSidKey);

            //BUSQUEDA TEMPLATE
            templateVirtual = [SELECT Id, Name, Subject, HtmlValue
                                FROM EmailTemplate
                                WHERE developername = 'NBK_EMAILTEMPLATEVIRTUAL_1666882409044' LIMIT 1];
            templateShowroom = [SELECT Id, Name, Subject, HtmlValue
                                FROM EmailTemplate
                                WHERE developername = 'NBK_EMAILTEMPLATE_1666879478296' LIMIT 1];

            List<OrgWideEmailAddress> orgs = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Appointment'];

            for (Event e : events){
                // EMAIL INFO
                emailInfo email = new emailInfo();
                User ownerUser = e.Owner;
                Lead l = e.Who;
                email.comercialName = e.Owner.Name;
                email.comercialFirstName = e.Owner.FirstName;
                email.comercialLastName = e.Owner.LastName;
                email.appointmentType = e.Event_type__c;
                email.dateSelected =  e.StartDateTime;
                email.comercialId = e.Owner.id;
                email.comercialEmail = e.Owner.Email;
                email.showroomName = ownerUser.Sales_Office_Text__c;
                email.targetEmail = e.Who.Email;
                for (PorcelanosaAddress__c pAddress : businessList){
                    if (ownerUser.Sales_Office__c == pAddress.NBK_SalesOffice__r.SalesOffice__c){
                        email.timezone = pAddress.NBK_Business_Hours__r.TimeZoneSidKey;
                    }
                }

                // SMS INFO
                Request req = new Request();
                req.comercialId = e.Owner.id;
                req.country = l.CountryCode__c;
                req.phone = l.MobilePhone;
                req.selectedDatetime = e.StartDateTime;
                req.comercialEmail = ownerUser.Email;
                req.timezone = email.timezone;
                
                try{
                    if(email.appointmentType == 'Showroom'){
                        sendEmail(email, templateShowroom, orgs);
                    } else if(email.appointmentType == 'Virtual'){
                        sendEmail(email, templateVirtual, orgs);
                    }
                    sendSMS(req);
                } catch(Exception err){
                    system.debug('ERROR ' + err);
                }
            }
        }
    }

    public void sendSMS(Request appointmentInfo){
        if(appointmentInfo != null){
            String body = 'Your appointment has been scheduled for ' + appointmentInfo.selectedDatetime.format('MM-dd-yyyy',appointmentInfo.timezone) + ' at the following time ' + appointmentInfo.selectedDatetime.format('h:mm a', appointmentInfo.timezone) + ' for any questions, please contact ' + appointmentInfo.comercialEmail;
            String country;
            if(String.isBlank(appointmentInfo.country)){
                country = 'US';
            } else {
                country = Nb2b_GlobalConstants.COUNTRYISOCODES.get(appointmentInfo.country);
            }
            SMS usasms = new SMS(appointmentInfo.phone, body, country);
            usasms.send();
        }
    }

    public void sendEmail(emailInfo emailList, EmailTemplate template, List<OrgWideEmailAddress> orgs){
        if(emailList != null){
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            String HTMLbody;

            // Asignamos la Email Template de acuerdo al idioma del usuario
            if(emailList.appointmentType == 'Virtual'){
                template = this.templateVirtual;
    
                HTMLbody = template.HtmlValue;
                HTMLbody = HTMLbody.replace('(Sales rep first name)', emailList.comercialFirstName);

            } else if(emailList.appointmentType == 'Showroom') {
                template = templateShowroom;
                HTMLbody = template.HtmlValue;
                HTMLbody = HTMLbody.replace('(Showroom name)', emailList.showroomName);
            }
            String fullName = emailList.comercialFirstName + ' ' + emailList.comercialLastName;
            // String urlImage = '<img src="'+ Url.getSalesforceBaseUrl() + '/resource/1667915367000/imageWebAppointments?" width="40%" />';
            // HTMLbody = HTMLbody.replace('(Time and Date)', emailList[0].dateSelected.format('yyyy-MM-dd HH:mm'));
            HTMLbody = HTMLbody.replace('(Time and Date)', emailList.dateSelected.format('MM-dd-yyyy h:mm a',emailList.timezone));
            HTMLbody = HTMLbody.replace('(Sales reps name)', fullName);
            HTMLbody = HTMLbody.replace('(Sales reps email)', emailList.comercialEmail);
            HTMLbody = HTMLbody.replace('(Sales reps name assigned)', fullName);
            // HTMLbody = HTMLbody.replace('(urlImage)', urlImage);
            list<String> toAdresses = new list<String>();
            toAdresses.add(emailList.targetEmail);

            email.setSubject(template.Subject);
            email.setToAddresses(toAdresses);
            email.setTemplateId(template.id);
            email.setHtmlBody(HTMLbody);

            if(!orgs.isEmpty()){
				email.setOrgWideEmailAddressId(orgs[0].Id);
            }
            email.setTargetObjectId(UserInfo.getUserId());
            email.setTreatTargetObjectAsRecipient(false);
            Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        }
    }

    public class emailInfo {
        public String comercialName;
        public String comercialFirstName;
        public String comercialLastName;
        public String appointmentType;
        public Datetime dateSelected;
        public String comercialId;
        public String comercialEmail;
        public String showroomName;
        public String targetEmail;
        public String timezone;
    }

    public class Request {
        public Id comercialId;
        public String country;
        public String phone;
        public Datetime selectedDatetime;
        public String comercialEmail;
        public String timezone;
    }
}