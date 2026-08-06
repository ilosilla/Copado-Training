/**
* @author 		Ramón Prades
* @date 		November 2021
* @group 		Leads
* @description 	Leads service layer
*/

/*
 * En espera de que Álex me pase el CSV de leads de google para ver wsi tengo el país o como lo puedo sacar.
 * También quiero ver si con el key o el campaign lo puedo saber (el país de origen)
 * 28 nov
 */


public class LeadsService {

    public final static String GOOGLE_LEAD_TYPE = 'Google Ad';

    /**
     * Creates a lead for a US online appointment
     */
    @InvocableMethod(callout=true label='Create US Web Lead')
    public static list<Response> createUSAppointmentLead(list<Request> dto) {
        System.debug('**** createUSAppointmentLead *****:'+dto);
        try{
            if(!dto.isEmpty()){
                List<PorcelanosaSetting__c> thisSettings = [Select Value1__c, Key__c from PorcelanosaSetting__c where Key__c = 'APPOINTER'
                                                            and Subkey__c = 'LOGGER'
                                                            and isActive__c = true
                                                        ];
                if(!thisSettings.isEmpty() && thisSettings[0].Value1__c == 'true'){
                    Logger.info('createUSAppointmentLead ENTRADA DATOS: ' + JSON.serialize(dto[0]));
                    Logger.saveLog();
                }
                String salesOfficeCurrency = 'USD';
                String salesOffName = 'Sales Office';
                if(!String.isBlank(dto[0].salesOfficeName)){
                    String salesOfficeId = dto[0].salesOfficeName;
                    List<Sales_office__c> officeList = new List<Sales_office__c>();
                    officeList = [SELECT Name,CurrencyIsoCode FROM SALES_OFFICE__c WHERE Id = :salesOfficeId];
                    if(!officeList.isempty()){
                        salesOffName = officeList[0].Name;
                        salesOfficeCurrency = officeList[0].CurrencyIsoCode;
                    }
                }

                Map<String, String> countryPicklist = getMapPicklistValues(Lead.CountryCode__c);
                lead lead1 = new Lead();
                //COMPROBAR EN CREACIÓN DE LEAD
                lead1.Source__c = 'USW';
                lead1.FirstName = dto[0].firstname;
                lead1.LastName = dto[0].lastname;
                lead1.Email = dto[0].email;
                lead1.Address__c = dto[0].street;
                if (!String.isEmpty(dto[0].countryCode)) {
                    lead1.CountryCode__c = countryPicklist.get(dto[0].countryCode);
                    if (lead1.CountryCode__c == null) {
                        lead1.CountryCode__c = dto[0].countryCode;
                    }
                } else {
                    lead1.CountryCode__c = 'US';
                }
								System.debug('dto[0].state:'+dto[0].state);
                //lead1.State__c = AddressCommons.getProvinceCode(lead1.CountryCode__c, dto[0].state);
								if(dto[0].state != null && dto[0].countryCode != null){
									AppointmentStates__mdt state = AppointmentStates_Selector.getState(dto[0].state,dto[0].countryCode);
									if(state != null){
										lead1.State__c = state.StateCode__c;
									}
								}
                lead1.AppointmentType__c = setAppointmentType(dto[0].appointmentType);

                list<String> allproducts = new list<String>();
                if (String.isBlank(dto[0].products) == false){
                    allproducts = dto[0].products.split(';');
                }
                String productsMapped;
                for(String product : allproducts){
                    if(product == 'Hardwood-Laminate-LVT'){productsMapped = productsMapped + 'Wood;Laminate;Linkfloor' + ';';
                    } else if(product == 'Baths') {productsMapped = productsMapped + 'Bathtubs;Bathroom;furniture' + ';';
                    } else {
                        if(!String.isBlank(productsMapped)){
                            productsMapped = productsMapped + ';' + product + ';';
                        } else {
                            productsMapped = product + ';';
                        }
                    }
                }
                lead1.ReferredBy__c = dto[0].hearAboutUs;
                lead1.Profile__c = dto[0].profile;
                //EHG cambio balma
                //lead1.Product_Categories__c = productsMapped;
                lead1.Postcode__c = dto[0].postCode;
                lead1.City__c = dto[0].town;
                lead1.MobilePhone = dto[0].mobile;
                lead1.ownerLocked__c = true;
                lead1.LeadType__c = LeadsDomain.APPOINTMENT_TYPE;
                //COMPROBAR EN CREACIÓN DE LEAD
                lead1.LeadSubtype__c = SystemSettings.USAppointmentSubtype;

                /*CAMBIO FECHA HORA POR STRING PARA EVITAR PROBLEMAS CON MOMENTJS*/
                /* ANTERIOR
                Datetime eventStartDate = dto[0].eventStartDate;
                System.debug('**** eventStartDate *****:'+eventStartDate);
                Integer offset = getOffset(Date.newInstance(eventStartDate.year(), eventStartDate.month(), eventStartDate.day()), dto[0].actualBusinessHours.TimeZoneSidKey);
                eventStartDate = eventStartDate.addMinutes(offset);*/

                String fechaSel = dto[0].fechaHoraStr;
                System.debug('fechaSel:'+fechaSel);
                Datetime eventStartDate = Datetime.valueOf(fechaSel);
                /*CAMBIO FECHA HORA*/

                String description = Label.NBK_leadDescription;
                description = description.replace('#STARTDATE', String.valueOf(eventStartDate.format('h aa EEEE d MMMM')));
                description = description.replace('#SALESOFFNAME', salesOffName);
                if(!String.isBlank(dto[0].comments)){
                    description = description + '\n' + Label.NBK_customerComments + ' ' +dto[0].comments;
                }
                // system.debug('FECHA CON FORMAT' + eventStartDate.format('h aa EEEE d MMMM'));
                // system.debug('FECHA SIN FORMAT' + eventStartDate);
                // system.debug('DESCRIPTION ' + description);
                // lead1.Description = dto[0].comments;
                if(productsMapped != null && productsMapped != ''){
                    description = description + '\n'+ 'Products:'+ productsMapped;
                }

                lead1.Description = description;
                LeadHelper helper = new LeadHelper(lead1);
                //COMPROBAR EN CREACIÓN DE LEAD
                helper.setUSWebRequestFields();
                helper.setAccountAndOwner(false);
                lead1.CurrencyIsoCode = salesOfficeCurrency;
                lead1.OwnerId = dto[0].salesrepId;

                if (dto[0].newsletterChecked && lead1.CountryCode__c == 'US') {
                    //add to subscription list
                    MailChimpsService.MailchimpDTO chimpSub = new MailChimpsService.MailchimpDTO();
                    chimpSub.context = lead1.CountryCode__c;
                    // chimpo1.listId = listId;
                    chimpSub.email = dto[0].email;
                    chimpSub.firstname = dto[0].firstname;
                    chimpSub.lastname = dto[0].lastname;
                    chimpSub.firstname = dto[0].mobile;

                    MailchimpsService.addSubscription(chimpSub);
                }
                insert lead1;
                Response response = new Response();
                response.leadId = lead1.Id;
                list<Response> resp = new list<Response>();
                resp.add(response);
                return resp;
            } else {
                return null;
            }
        }catch(Exception ex){Logger.error('[APPOINTMENT_MANAGER_CREATE_LEAD]: ' + ex.getMessage());Logger.saveLog();return null;
        }

    } // createLead

    /**
     * Creates a lead from google ads
     */
    public static Lead createGoogleAdLead(Request dataDTO, GoogleFields fields) {
        Lead l = requestToLead(dataDTO);
        l.LeadType__c = GOOGLE_LEAD_TYPE;
        l.LeadSubtype__c = fields.googleCampaignId;
        l.google_lead_id__c = fields.googleLeadId;
        l.google_form_id__c = fields.googleFormId;
        l.google_campaign_id__c = fields.googleCampaignId;
        l.RecordTYpeId = RecordTypeLibrary.Lead_USWebRequest;
        l.Source__c = fields.googleDomain + 'W';
        LeadHelper helper = new LeadHelper(l);
        helper.setUSWebRequestFields();
        helper.setAccountAndOwner(false);
        l.OwnerId = UserInfo.getUserId();
        if (String.IsNotBlank(fields.defaultUserId)) {l.OwnerId = fields.defaultUserId;}
        insert l;
        return l;
    }

    public static Map<String, String> getMapPicklistValues(Schema.sObjectField field) {
        Map<String, String> result = new Map<String,String>();
        List<Schema.PicklistEntry> entries = ReflectionUtils.getPicklistValues(field);
        for (Schema.PicklistEntry entry : entries) {
            result.put(entry.getLabel(), entry.getValue());
        }
        return result;
    }

    public static void sendAppointmentEmail(List<Event> events) {
        List<Lead> leads = new List<Lead>();
        Map<Id,User> ownersMap = new Map<Id, User>();
        Map<Id,Event> leadEvents = new Map<Id, Event>();
        List<User> ownersList = new List<User>();
        Set<Id> ownerIds = new Set<Id>();

        try {
            if (SystemSettings.USNotifyWebLeads) {
                for (Event evt : events) {
                    leadEvents.put(evt.WhoId, evt);
                }

                leads = new LeadsSelector().selectById(leadEvents.keySet());
                for (Lead ld : leads) {
                    ownerIds.add(ld.ownerId);
                }

                ownersList = [SELECT id, TimeZoneSidKey, name from user where id IN: ownerIds];
                for (User usr : ownersList) {
                    ownersMap.put(usr.Id, usr);
                }

                for (Lead ld : leads) {
                    if (ld.RecordTypeId == RecordTypeLibrary.Lead_USWebRequest &&
                        ld.LeadSubtype__c != LeadsDomain.MATERIAL_BANK_SUBTYPE &&
                        ld.OwnerId != UserInfo.getUserId()
                        ) {
                            String dateTimeEvent = leadEvents.get(ld.Id).StartDateTime.format('MM-dd-yyy hh:mm:ss a', ownersMap.get(ld.ownerId).TimeZoneSidKey);
                            USLeadMailer mailer = new USLeadMailer(ld.Id);
                            mailer.setSubject('WEB APPOINTMENT scheduled by a new Lead at ' + dateTimeEvent);
                            mailer.emailLeadOwner();
                    }
                }
            }
        } catch (Exception ex) {Loggercommons.LogException('APPOINTMENTEMAIL', 'LeadsService class', ex);
        }
    }

    /* <<<<<<<<<<<<<<<<<<<<< PRIVATE METHODS >>>>>>>>>>>>>>>>>>>>> */
    /**
     * Populates a lead from the request object
     * No business logic here, just field assignations.
     */
    public static Lead requestToLead(Request dataDTO) {
        Lead lead1 = new Lead();
        lead1.ownerLocked__c = false;
        Map<String, String> countryPicklist = getMapPicklistValues(Lead.CountryCode__c);
        lead1.FirstName = dataDTO.firstname;
        lead1.LastName = dataDTO.lastname;
        lead1.Company = dataDTO.company;
        lead1.Email = dataDTO.email;
        lead1.Address__c = dataDTO.street;
        lead1.Postcode__c = dataDTO.postCode;
        lead1.City__c = dataDTO.town;
        lead1.MobilePhone = dataDTO.mobile;
        if (!String.isBlank(dataDTO.countryCode)) {lead1.CountryCode__c = countryPicklist.get(dataDTO.countryCode);        }
        lead1.State__c = AddressCommons.getProvinceCode(lead1.CountryCode__c, dataDTO.state);
        lead1.AppointmentType__c = setAppointmentType(dataDTO.appointmentType);
        lead1.ReferredBy__c = dataDTO.hearAboutUs;
        lead1.Profile__c = dataDTO.profile;
         lead1.Description = dataDTO.comments;
        lead1.PreferredContactMethod__c = setPreferredContactMethod(dataDTO.preferredContactMethod);
        lead1.PreferredContactTime__c = dataDTO.preferredContactTime;
        lead1.Operation_Type__c = dataDTO.operationType;

        return lead1;
    } // requestToLead

    private static String setAppointmentType(String appointmentType) {
        String result = '';
        if (String.IsNotEmpty(appointmentType)) {
            if (appointmentType.substring(0,1) == 'V') {result = 'VIRTUAL';} else if (appointmentType.substring(0,1) == 'S') {result = 'SHOWROOM';}
        }
        return result;
    } // setAppointmentType

    private static String setPreferredContactMethod(String method) {
        String result = '';
        if (String.isNotBlank(method)) {
            if (method.containsIgnoreCase('MAIL')) {result = 'EMAIL';
            } else if (method.containsIgnoreCase('PHONE') || method.containsIgnoreCase('MOBIL')) {result = 'PHONE';
            } else  if (method.containsIgnoreCase('SMS')) {result = 'SMS';
            } else {result = 'OTHER';
            }
        }
        return result;
    } // setPreferredContactMethod

    public static String convertOperationType(String opType) {
        String pickListValue = '';
        if (String.IsNotBlank(opType)) {
            if (opType.toUpperCase() == 'NEW') {pickListValue = 'New construction';
            } else if (opType.toUpperCase() == 'REFURB') {pickListValue = 'Refurbishment';
            }
        }
        return pickListValue;
    } // convertOperationType

    @AuraEnabled
    public static Integer getOffset(Date selectedDate, String tz){
        TimeZone targetTimezone = TimeZone.getTimeZone(tz);

        Integer offsetMinutes = (targetTimezone.getOffset(selectedDate) / 1000) / 60;

        return offsetMinutes;
    }

    /*private static String getSalesOfficeId(String code) {
        String officeId = null;
        if (!String.isBlank(code)) {
            List<Sales_Office__c> offices = [select Id from Sales_Office__c where SalesOffice__c = :code];
            if (offices.size() > 0) {
                officeId = offices[0].Id ;
            }
        }
        return officeId;
    }*/

    public class Request {
        @InvocableVariable(required=true)
        public String firstname;
        @InvocableVariable(required=true)
        public String lastName;
        @InvocableVariable(required=true)
        public String email;
        @InvocableVariable(required=true)
        public String mobile;
        @InvocableVariable(required=true)
        public Id salesrepId;
        @InvocableVariable(required=true)
        public String appointmentType;
        @InvocableVariable(required=false)
        public String countryCode;
        @InvocableVariable(required=false)
        public String street;
        @InvocableVariable(required=false)
        public String postCode;
        @InvocableVariable(required=false)
        public String town;
        @InvocableVariable(required=false)
        public String state;
        @InvocableVariable(required=false)
        public String comments;
        @InvocableVariable(required=false)
        public String profile;
        @InvocableVariable(required=false)
        public String hearAboutUs;
        @InvocableVariable(required=false)
        public String products;
        @InvocableVariable(required=false)
        public String company;
        @InvocableVariable(required=false)
        public String preferredContactMethod;
        @InvocableVariable(required=false)
        public String preferredContactTime;
        @InvocableVariable(required=false)
        public String operationType;
        @InvocableVariable(required=false)
        public Boolean newsletterChecked;
        @InvocableVariable(required=true)
        public DateTime eventStartDate;
        @InvocableVariable(required=true)
        public String salesOfficeName;
        @InvocableVariable(required=true)
        public BusinessHours actualBusinessHours;
        @InvocableVariable(required=true)
        public String fechaHoraStr;
    }

    public class GoogleFields {
        public Boolean isTest = false;
        public String googleLeadId;
        public String googleFormId;
        public String googleCampaignId;
        public String googleDomain;
        public String defaultUserId;
    }

    public class Response {
        @InvocableVariable
        public Id leadId;
    }

}