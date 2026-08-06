({
  doInit: function (cmp, evt, hlpr) {
    cmp.set("v.needsCheckbox", false);
    cmp.set("v.enableSubmit", false);
  },
  handleOnAccountLoad: function (cmp, evt, hlpr) {
    hlpr.checkCanReview(cmp);
    hlpr.checkPhoneValid(cmp);
  },
  handleCanReview: function (cmp, evt, hlpr) {
    hlpr.getLastReviewSMS(cmp);
  },
  handleLastActionLoad: function (cmp, evt, hlpr) {
    var marketingAction = cmp.get("v.lastAction");
    var phone = cmp.get("v.account.Phone");
    var mainMessage = '';
    var askMessage = '';
    var lang = $A.get("$Locale.language");

    // First Review SMS
    if (marketingAction == null) {
      mainMessage = $A.get("$Label.c.ReviewSmsFirst");
      askMessage = $A.get("$Label.c.ReviewSmsAskSend");
      mainMessage = mainMessage.replace('#PHONE', phone);
      console.log('Submit enabled');
      cmp.set("v.enableSubmit", true);
    } else {
      cmp.set("v.needsCheckbox", true);
      var labelCheckbox = $A.get("$Label.c.ReviewSMSCheckbox");
      labelCheckbox = labelCheckbox.replace('#PHONE', phone);
      cmp.find("sendConfirmation").set("v.label", labelCheckbox);
      mainMessage = $A.get("$Label.c.ReviewSmsSecondFast");
      mainMessage = mainMessage.replace('#ACTIONPHONE', marketingAction.SendTo__c);
      mainMessage = mainMessage.replace('#DATE', hlpr.formatDate(marketingAction.DateRequested__c));
      askMessage = $A.get("$Label.c.ReviewSmsAskSend");
      cmp.set("v.enableSubmit", false);
    }
    cmp.set("v.mainText", mainMessage);
    cmp.set("v.askText", askMessage);
    cmp.set("v.showSpinner", false);
  },
  handleOnSubmit: function (cmp, evt, hlpr) {
    if (cmp.get("v.needsCheckbox") == false || (cmp.get("v.needsCheckbox") == true && cmp.find("sendConfirmation").get("v.value") == true)) {
      hlpr.saveReviewSMS(cmp);
    }
  },
  handleOnCancel: function (cmp, evt, hlpr) {
    $A.get('e.force:refreshView').fire();
    $A.get("e.force:closeQuickAction").fire();
  },
  handleConfirmationChange: function (cmp, evt) {
    if (cmp.get("v.needsCheckbox") == true) {
      if (cmp.find("sendConfirmation").get("v.value") == true) {
        cmp.set("v.enableSubmit", true);
      } else {
        cmp.set("v.enableSubmit", false);
      }
    } else {
      cmp.set("v.enableSubmit", true);
    }
  }
})