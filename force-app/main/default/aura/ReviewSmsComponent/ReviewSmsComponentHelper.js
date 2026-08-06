({
  getLastReviewSMS: function (cmp) {
    var relatedId = cmp.get("v.recordId");
    var action = cmp.get("c.getLastReviewSMS");
    action.setParams({ relatedId: relatedId });

    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var serverResponse = response.getReturnValue();
        cmp.set("v.lastAction", serverResponse);
        cmp.set("v.changedLastAction", true);
      }
      else if (state === "INCOMPLETE") {
        //console.log("STATUS INCOMPLETE");
      }
      else if (state === "ERROR") {
        var errors = response.getError();
        cmp.find("notificationsLibrary").showToast({
          "variant": "error",
          "title": "Review SMS - ERROR",
          "message": $A.get("$Label.c.ReviewSmsError")
        });
        $A.get("e.force:closeQuickAction").fire();
      }

    });

    $A.enqueueAction(action);
  },
  saveReviewSMS: function (cmp) {
    cmp.set("v.showSpinner", true);
    var relatedId = cmp.get("v.recordId");
    var phone = cmp.get("v.account.Phone");
    var country = cmp.get("v.account.PersonMailingCountryCode");
    var action = cmp.get("c.createReviewSMS");
    action.setParams({ relatedId: relatedId, sendTo: phone, relatedCountry: country });

    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var serverResponse = response.getReturnValue();
        if (serverResponse == null) {
          cmp.find("notificationsLibrary").showToast({
            "variant": "error",
            "title": "Review SMS - ERROR",
            "message": $A.get("$Label.c.ReviewSmsError")
          });
        } else {
          cmp.find("notificationsLibrary").showToast({
            "variant": "success",
            "title": $A.get("$Label.send"),
            "message": $A.get("$Label.c.ReviewSmsSend")
          });
          $A.get("e.force:closeQuickAction").fire();
        }
        cmp.set("v.showSpinner", false);
      }
      else if (state === "INCOMPLETE") {
        //console.log("STATUS INCOMPLETE");
      }
      else if (state === "ERROR") {
        var errors = response.getError();
        cmp.find("notificationsLibrary").showToast({
          "variant": "error",
          "title": "Review SMS - ERROR",
          "message": $A.get("$Label.c.ReviewSmsError")
        });
      }

    });

    $A.enqueueAction(action);
  },
  checkCanReview: function (cmp) {
    var relatedId = cmp.get("v.recordId");
    var action = cmp.get("c.canReviewSMS");
    action.setParams({ relatedId: relatedId });

    action.setCallback(this, function (response) {
      var state = response.getState();
      if (state === "SUCCESS") {
        var serverResponse = response.getReturnValue();
        if (serverResponse == false) {
          cmp.find("notificationsLibrary").showToast({
            "variant": "warning",
            "message": $A.get("$Label.c.ReviewSmsNotEnabled")
          });
          $A.get("e.force:closeQuickAction").fire();
        } else {
          var phone = cmp.get("v.account.Phone");
          if (phone == null) {
            cmp.find("notificationsLibrary").showToast({
              "variant": "warning",
              "message": $A.get("$Label.c.ReviewSmsNoPhone")
            });
            $A.get("e.force:closeQuickAction").fire();
          } else {
            cmp.set("v.canReview", true);
          }
        }
      } else if (state === "INCOMPLETE") {
        //console.log("STATUS INCOMPLETE");
      }
      else if (state === "ERROR") {
        var errors = response.getError();
        cmp.find("notificationsLibrary").showToast({
          "variant": "error",
          "title": "Review SMS - ERROR",
          "message": $A.get("$Label.c.ReviewSmsError")
        });
        $A.get("e.force:closeQuickAction").fire();
      }

    });

    $A.enqueueAction(action);
  },
  checkPhoneValid: function (cmp) {
    var phone = cmp.get("v.account.Phone");
    if (phone) {
      var action = cmp.get("c.checkValidPhone");
      action.setParams({ phone: phone });

      action.setCallback(this, function (response) {
        var state = response.getState();
        if (state === "SUCCESS") {
          var serverResponse = response.getReturnValue();
          if (serverResponse == false) {
            cmp.set("v.validPhone", false);
            var textNoValid = $A.get("$Label.c.ReviewSmsPhoneWarning");
            textNoValid = textNoValid.replace('#PHONE', phone);
            cmp.set("v.validPhoneText", textNoValid);
          } else {
            cmp.set("v.validPhone", true);
          }
        } else if (state === "INCOMPLETE") {
          //console.log("STATUS INCOMPLETE");
        }
        else if (state === "ERROR") {
          var errors = response.getError();
          cmp.find("notificationsLibrary").showToast({
            "variant": "error",
            "title": "Review SMS - ERROR",
            "message": $A.get("$Label.c.ReviewSmsError")
          });
          $A.get("e.force:closeQuickAction").fire();
        }

      });

      $A.enqueueAction(action);
    }
  },
  formatDate: function (dateValue) {
    var lang = $A.get("$Locale.language");

    const d = new Date(dateValue);
    const ye = new Intl.DateTimeFormat(lang, { year: 'numeric' }).format(d);
    const mo = new Intl.DateTimeFormat(lang, { month: 'long' }).format(d);
    const da = new Intl.DateTimeFormat(lang, { day: '2-digit' }).format(d);

    return mo + ' ' + da + ' ' + ye;
  }
})