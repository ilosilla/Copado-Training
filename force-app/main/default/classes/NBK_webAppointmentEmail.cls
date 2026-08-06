/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 10-27-2022
 * @last modified by  : EHG@nubika.com
**/
public class NBK_webAppointmentEmail {
	@InvocableMethod(callout=true label='Send Wen Appointment Email')
    public static void execute(List<emailInfo> emailList){
        try{
            if(!emailList.isEmpty()){
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                Id templateId;
                User comercial = [SELECT Name, FirstName, LastName, Country,CountryCode FROM User WHERE Id = :emailList[0].comercialId LIMIT 1];
                // Asignamos la Email Template de acuerdo al idioma del usuario
                List<EmailTemplate> template = new List<EmailTemplate>();
                String HTMLbody;

                if(emailList[0].appointmentType == 'Virtual'){
                    template = [SELECT Id, Name, Subject, HtmlValue
                                FROM EmailTemplate
                                WHERE developername = 'NBK_EMAILTEMPLATEVIRTUAL_1666882409044' LIMIT 1];

                    HTMLbody = template[0].HtmlValue;
                    HTMLbody = HTMLbody.replace('(Sales rep first name)', comercial.FirstName);


                } else if(emailList[0].appointmentType == 'Showroom') {
                    String templateName = 'NBK_EMAILTEMPLATE_' + comercial.CountryCode.toUpperCase();
                    System.debug('TEMPLATE DEVELOPERNAME');
                    System.debug(templateName);
                    template = [SELECT Id, Name, Subject, HtmlValue
                                FROM EmailTemplate
                                WHERE developername =: templateName LIMIT 1];
                                System.debug(template);

                    if (template.isEmpty()) {
                        System.debug('No se encontró la plantilla para el país del comercial, se asigna la plantilla US por defecto');
                        template = [SELECT Id, Name, Subject, HtmlValue
                                    FROM EmailTemplate
                                    WHERE developername = 'NBK_EMAILTEMPLATE_US' LIMIT 1];
                    }
                    HTMLbody = template[0].HtmlValue;
                    HTMLbody = HTMLbody.replace('(Showroom name)', emailList[0].showroomName);
                }
                String fullName = comercial.FirstName + ' ' + comercial.LastName;
                // String urlImage = '<img src="'+ Url.getSalesforceBaseUrl() + '/resource/1667915367000/imageWebAppointments?" width="40%" />';
                // HTMLbody = HTMLbody.replace('(Time and Date)', emailList[0].dateSelected.format('yyyy-MM-dd HH:mm'));
                /* CAMBIO DE FECHAS ANTERIOR
                HTMLbody = HTMLbody.replace('(Time and Date)', emailList[0].dateSelected.format('MM-dd-yyyy h:mm a',emailList[0].businessHour.TimeZoneSidKey));
                */
                String fechaSel = emailList[0].fechaHoraStr;
                System.debug('fechaSel:'+fechaSel);
                Datetime eventStartDate = Datetime.valueOf(fechaSel);
                HTMLbody = HTMLbody.replace('(Time and Date)', eventStartDate.format('MM-dd-yyyy h:mm a'));

                HTMLbody = HTMLbody.replace('(Sales reps name)', fullName);
                HTMLbody = HTMLbody.replace('(Sales reps email)', emailList[0].comercialEmail);
                HTMLbody = HTMLbody.replace('(Sales reps name assigned)', fullName);
                // HTMLbody = HTMLbody.replace('(urlImage)', urlImage);
                list<String> toAdresses = new list<String>();
                toAdresses.add(emailList[0].targetEmail);

                email.setSubject(template[0].Subject);
                email.setToAddresses(toAdresses);
                email.setTemplateId(template[0].Id);
                email.setHtmlBody(HTMLbody);

                // List<OrgWideEmailAddress> orgs = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Appointment'];
                List<OrgWideEmailAddress> orgs = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Appointment'];
                if(!orgs.isEmpty()){
                    email.setOrgWideEmailAddressId(orgs[0].Id);
                }
                email.setTargetObjectId(UserInfo.getUserId());
                email.setTreatTargetObjectAsRecipient(false);
                Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
                System.debug('Send Email end');

            }
        }catch(Exception ex){
            System.debug('ERROR EN SENDEMAIL: '+ex.getMessage());
            Logger.error('[APPOINTMENT_MANAGER_SEND_EMAIL]: ' + ex.getMessage());
            Logger.saveLog();
        }

    }

    public class emailInfo {
        @InvocableVariable(required=true)
        public String appointmentType;
        @InvocableVariable(required=true)
        public Datetime dateSelected;
        @InvocableVariable(required=true)
        public String comercialId;
        @InvocableVariable(required=true)
        public String comercialEmail;
        @InvocableVariable(required=true)
        public String showroomName;
        @InvocableVariable(required=true)
        public String targetEmail;
        @InvocableVariable(required=true)
        public BusinessHours businessHour;
        @InvocableVariable(required=true)
        public String fechaHoraStr;
    }
}