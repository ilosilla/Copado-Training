public class ReviewSmsComponentController {
    @AuraEnabled 
    public static MarketingActions__c getLastReviewSMS(String relatedId){
        return MarketingActions.getLastAction(relatedId, 'REVIEWSMS');
    } //getLastReviewSMS
    
    @AuraEnabled 
    public static MarketingActions__c createReviewSMS(String relatedId, String sendTo, String relatedCountry){
      try {
        Id accId = Id.valueOf(relatedId);
        Account acc = AccountUtil.getData(new Set<Id>{accId})[0];

        if (acc != null) {
          if (acc.IsPersonAccount) {
            String contactId = Id.valueOf(acc.PersonContactId);
            return MarketingActions.createReviewSMS(relatedId, contactId, sendTo, relatedCountry);
          } else {
            return MarketingActions.createReviewSMS(relatedId, sendTo, relatedCountry);
          }
        }
        return null;
      } catch (Exception exc) {
        SystemUtils.debugWarning('REVIEWSMS', 'Review no enviado', exc);
        return null;
      }
    } //createReviewSMS
    
    @AuraEnabled 
    public static Boolean checkValidPhone(String phone){
        Boolean isValid = true;
        Pattern MyPattern = Pattern.compile(RegexLibrary.REGEX_VALIDATE_PHONE);
        Matcher MyMatcher = MyPattern.matcher(phone);
    
        if (!MyMatcher.matches()) {
            isValid = false;
        }
        return isValid;
    } //checkValidPhone
    
    @AuraEnabled 
    public static Boolean canReviewSMS(String relatedId){
        Boolean canSendSMS = false;
        Map<String,Boolean> listReviewSMSCountries = CountrySettings.getReviewSms();
        Account acc = [Select Id, Owner.CountryCode from Account where Id =: relatedId];
        UserRecordAccess hasEditAcces = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId =: Userinfo.getUserId() AND RecordId =: relatedId];
        
        if (listReviewSMSCountries.containsKey(acc.Owner.CountryCode) && listReviewSMSCountries.get(acc.Owner.CountryCode) == true) {
            canSendSMS = true;
            if (hasEditAcces.HasEditAccess == false) {
                canSendSMS = false;
            }
        }
        return canSendSMS;
    } //createReviewSMS
}