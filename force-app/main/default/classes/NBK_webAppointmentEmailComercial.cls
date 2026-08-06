/**
 * @description  :
 * @author       : Nubika Team <example@nubika.com>
 * @version      : 1.0.0
 * @date         : 13-11-2023
 * @group        :
 * @see          :
**/
public class NBK_webAppointmentEmailComercial {

	@InvocableMethod(callout=true label='Send Appointment Email Comercial')
	public static void execute(List<LeadInfo> leadInfo){
			try{
					if(!leadInfo.isEmpty()){
							if(leadInfo[0].leadId != null){
									//recuperar Lead con id por parametro
									List<Lead> listLeads = [SELECT Id,Opportunity_Name__c,FirstName,LastName,Title,Company,
																									MobilePhone,Email,Status,LeadSource,Owner.Email,Owner.Name,Owner.Id,Owner.FirstName,LeadType__c,LeadSubtype__c,
																									Postcode__c,City__c,State__c,Description
																							FROM Lead
																									WHERE Id =: leadInfo[0].leadId];

									if(listLeads != null && !listLeads.isEmpty()){
											Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
											EmailTemplate template = new EmailTemplate();
											template = [SELECT Id, Name, Subject, HtmlValue
															FROM EmailTemplate
															WHERE developername = 'NBK_AppointmentComercial' LIMIT 1];

											String HTMLbody = template.HtmlValue;

											//FECHA Y HORA CONVERSION
											DateTime dt = DateTime.valueOf(leadInfo[0].fechaHoraS);
											String fechaConvert = String.valueOf(dt.format('MM/dd/YYYY'));

											String mailBody;
											mailBody = getLeadBody(listLeads[0]);
											String body = '<p>Dear ' + listLeads[0].Owner.FirstName + ', you have a new appointment from our website</p>' +
											+ '<p>Please review the details below and follow the link to go to the CRM.</p>'
											+ '<p>WEB APPOINTMENT scheduled by a new Lead at '+fechaConvert+'</p>'
											+ mailBody +
											+ '<p>Thank you,</p>'
											+ '<p>CRM Team<br/>Porcelanosa USA</p>';

											HTMLbody = HTMLbody.replace('((body))', body);

											list<String> toAdresses = new list<String>();
											toAdresses.add(listLeads[0].Owner.Email);

											email.setSubject('New Web Appointment Scheduled at '+fechaConvert);
											email.setToAddresses(toAdresses);
											email.setHtmlBody(HTMLbody);
											//List<OrgWideEmailAddress> orgs = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Appointment'];
											List<OrgWideEmailAddress> orgs = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Salesforce CRM'];
											if(!orgs.isEmpty()){
													email.setOrgWideEmailAddressId(orgs[0].Id);
											}
											 email.setTargetObjectId(UserInfo.getUserId());
											email.setTreatTargetObjectAsRecipient(false);
											Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
											System.debug('Send Email end');

									}
							}
					}
			}catch(Exception ex){
					System.debug('ERROR EN SENDEMAIL: '+ex.getMessage());
					Logger.error('[APPOINTMENT_MANAGER_SEND_EMAIL_COMERCIAL]: ' + ex.getMessage());
					Logger.saveLog();
			}

	}

	public static String getLeadBody(Lead lead) {
			String url =  URL.getOrgDomainUrl().toExternalForm() + '/' + lead.Id;

			String description = '';
			if (String.isNotEmpty(lead.Description)) {
					description = lead.Description.replace('\n', '<br/>');
			}
			Map<String, String> m = new Map<String, String>();
			m.put('Lead Name', '<a href="' + url + '">' + lead.Opportunity_Name__c + '</a>');
			m.put('Name', lead.FirstName + ' ' + lead.LastName);
			//m.put('Title', lead.Title);
			//m.put('Company', lead.Company);
			m.put('Phone', lead.MobilePhone);
			m.put('EMail', lead.Email);
			m.put('Status', lead.Status);
			m.put('Source', lead.LeadSource);
			m.put('Owner', lead.owner.Name);
			m.put('Type', lead.LeadType__c);
			m.put('Subtype', lead.LeadSubtype__c);
			m.put('Location', lead.Postcode__c + ' ' + lead.City__c + ' (' + lead.State__c + ')');
			m.put('Description', description);
			String table = MailUtils.mapToTable(m, 'width:700px;,border: 1px solid;');

			return table;
	}

	public class LeadInfo {
			@InvocableVariable
			public Id leadId;
			@InvocableVariable
			public String fechaHoraS;
	}

}