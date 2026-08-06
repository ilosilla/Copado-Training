/**
* @author Ivan Losilla Perez
* @date January 2021
*
* @group Mail
* @group-content ../../ApexDocContent/OpportunityMails.htm
*
* @description Methods wich sends emails to users
*/
public class OpportunityMails {
  /******************************************** OPPORTUNITY APPROVAL COUNTRY **********************************************/
  /**
  * @description check if an Opportunity is not a valid creation looking at the Opportunity country
  * and the Owner countries field, and sends an email.
  * @param listOpportunities List of all the opportunities
  *
  */

  public static void alertNotValidCreation(Set<Id> opportunityIds) {
      try {
        List<Opportunity> listOpportunities = new OpportunitiesSelector().selectById(opportunityIds);
          Set<Id> ownersIds = new Set<Id>();
          for (Opportunity opp : listOpportunities) {
              ownersIds.add(opp.OwnerId);
          }
          Map<Id,User> listOwners = UserUtils.getMapUserData(ownersIds);

          List<Opportunity> notValidOpportunityList = filterValidOpportunitysByCountry(listOpportunities, listOwners);

          if (notValidOpportunityList.size() > 0) {
            Map<String, List<String>> opportunitySettingsMails = OpportunitySettings.getCreateValidationMailsTo();
            List<Mail> mailsToSend = new List<Mail>();
            
            for (Opportunity opp : notValidOpportunityList) {
                User aux = listOwners.get(opp.OwnerId);
                String userCountry = aux.CountryCode;
                if (opportunitySettingsMails.containsKey(userCountry)) {
                    Mail auxMail = new Mail();
                    auxMail.setHtml(alertNotValidCreationHtml(opp, listOwners.get(opp.OwnerId)));
                    auxMail.setGeneric(); // It will come from a generic email address
                    auxMail.setTo(opportunitySettingsMails.get(userCountry));
                    auxMail.setSubject(Label.opportunity_created_not_valid_title);
                    mailsToSend.add(auxMail);
                } 
              }
              MailUtils.sendBatch(mailsToSend);
          }
      } catch (Exception e) {
          SystemUtils.debugWarning('MAIL ALERT VALID CREATION', 'Mail not sent', e);
      }
  }

  private static String alertNotValidCreationHtml(Opportunity opp, User owner) {
    Schema.DescribeFieldResult fieldResult = Opportunity.countryCode__c.getDescribe();
    List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
    Map<String,String> mapValueLabel = new Map<String,String>();
    for( Schema.PicklistEntry v : values) {
        mapValueLabel.put(v.getValue(),v.getLabel());
    }

    String mailBody = '';
    String longTextBody = Label.opportunity_created_not_valid;
    longTextBody = longTextBody.replace('#LINK', '<a href="' + URL.getOrgDomainUrl().toExternalForm() + '/' + opp.Id + '">LINK</a>');
    longTextBody = longTextBody.replace('#COUNTRY', mapValueLabel.get(opp.countryCode__c));
    longTextBody = longTextBody.replace('#OWNER', owner.Name);
    mailBody+= longTextBody;
    
    return MailStyles.internalStyle() + mailBody;
  }

  private static List<Opportunity> filterValidOpportunitysByCountry(List<Opportunity> listOpportunities, Map<Id,User> mapOwners) {
      List<Opportunity> result = new List<Opportunity>();
      for (Opportunity opp : listOpportunities) {
          User aux = mapOwners.get(opp.OwnerId);
          if (aux != null && !UserUtils.isAdministrator(aux) && !String.isEmpty(opp.countryCode__c)) {
            List<String> country = new List<String>{opp.countryCode__c};
            if (aux.countries__c != null && aux.countries__c.split(';').size() > 0 && ListUtils.anyOn(aux.countries__c.split(';'), country) == false) {
                result.add(opp);
            }
          }
      }

      return result;
  }
}