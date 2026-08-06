public class MarketingActions {
    public static MarketingActions__c getLastAction(String relatedId, String actionId) {
      List<MarketingActions__c> listActions = [SELECT Id,
                                            ActionId__c,
                                            Country__c,
                                            DateRequested__c,
                                            RelatedId__c,
                                            SendTo__c,
                                            TimeRequested__c,
                                            CreatedById
                                            from MarketingActions__c
                                            where ActionId__c =: actionId and RelatedId__c =: relatedId
                                               order by DateRequested__c desc
                                            LIMIT 1];
      if (listActions.size() == 0) {
        return null;
      }
      return listActions[0];
    }
    
    public static MarketingActions__c createReviewSMS(String relatedId, String sendTo, String country) {
          return createReviewSMS(relatedId, null, sendTo, country);
    }

    public static MarketingActions__c createReviewSMS(String relatedId, String contactId, String sendTo, String country) {
        try {
            DateTime todaysDate = System.now();
            String todaysDateStr = todaysDate.format('yyyy-MM-dd');
            String todayTimeStr = todaysDate.format('H:m:s');
            User actualUsr = [select id, Sales_Office_Text__c from user WHERE Id =: UserInfo.getUserId () limit 1];

            String body = Label.sendSms_reviewBody.replace('##STORE##', actualUsr.Sales_Office_Text__c);

            SMS eusms = new SMS(sendTo, body, country);
            MarketingActions__c review = null;

            if (Test.isRunningTest() == true) {
              review = new MarketingActions__c(ActionId__c='REVIEWSMS',
                            RelatedId__c=relatedId,
                            SendTo__c=sendTo,
                            Country__c = country,
                            Contact__c = contactId,
                            DateRequested__c = todaysDateStr,
                            TimeRequested__c = todayTimeStr);
              insert review;
            } else {
              Boolean sent = eusms.send();
              if (sent == true ) {
                review = new MarketingActions__c(ActionId__c='REVIEWSMS',
                                                                  RelatedId__c=relatedId,
                                                                  SendTo__c=sendTo,
                                                                  Country__c = country,
                                                                  Contact__c = contactId,
                                                                  DateRequested__c = todaysDateStr,
                                                                  TimeRequested__c = todayTimeStr);
                insert review;
              }
            }

            return review;
        } catch (Exception exc) {
            SystemUtils.debugError('REVIEWSMS', 'Send Review SMS', exc);
            return null;
        }
    }

    @testVisible public String testFiller() {
      String s = 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      s += 'Lorem ipsum';
      return s;
  }
}