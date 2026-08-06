/*
Open points:
- Translations (labels)
- Error / Success Messages (labels)
- Global variables (requiredFields)
- Edit action (should be allowed for the admin? Which fields?)
*/

({
  doInit: function (cmp, evt, hlpr) {
    if (cmp.get("v.mode") == 'New') {
      cmp.set("v.displayMode", $A.get("$Label.c.New"));
    } else {
      cmp.set("v.displayMode", $A.get("$Label.c.Edit"));
    }

    hlpr.checkUserHasAccess(cmp, hlpr);
    hlpr.checkAccountData(cmp, hlpr);
    hlpr.checkUserCanEditSalesOffice(cmp, hlpr);
    hlpr.checkSalesOrgRestricted(cmp, hlpr);

    //New action invoked from Recently Viewed List on Sales Relationship Home Page
    if (cmp.get("v.sObjectName") == 'Sales_Relationship__c' &&
      $A.util.isUndefined(cmp.get("v.recordId"))) {
      var notificationService = cmp.find("notificationsLibrary");
      notificationService.showToast({
        "variant": "error",
        "mode": "sticky",
        "title": "Operation not Allowed",
        "message": "Go to the account to create Sales Relationships"
      });
      hlpr.manageNavigation(cmp, true);
    }

    if (cmp.get("v.mode") == 'Edit') {
      cmp.set("v.isAccountDataLoaded", true);
      hlpr.setUpForm(cmp);
    }
  },

  //handler for Account related element force:recordData
  handleOnAccountLoad: function (cmp, evt, hlpr) {
    // No funciona para edicion porque no se proporciona un id de cuenta para el force:recordData.
    // Hay que setear isAccountDataLoaded en init si estamos en modo de edicion.
    // console.log("Account => " + JSON.stringify(cmp.get("v.account")));
    cmp.set("v.isAccountDataLoaded", true);

    var potential = cmp.get("v.account.Potential__c");
    if (potential) {
      var notificationService = cmp.find("notificationsLibrary");
      notificationService.showToast({
        "variant": "warning",
        "mode": "sticky",
        "title": $A.get("$Label.c.sys_oper_disabled"),
        "message": $A.get("$Label.c.acc_nosap_potential")
      });
      hlpr.manageNavigation(cmp, true);
    } // if potential
    if (cmp.get("v.userHasAccess")) {
      hlpr.verifyAccount(cmp);
    }
    hlpr.setUpForm(cmp);
  },

  //handler for User related element force:recordData
  handleOnUserLoad: function (cmp, evt, hlpr) {
    console.log("## handleOnUserLoad ##");
    //console.log("user => "+JSON.stringify(cmp.get("v.user")));
    //console.log('User Profile => '+cmp.get("v.user").Profile.Name);

    cmp.set("v.userIsAdmin", cmp.get("v.user.Profile.Name") == $A.get("$Label.c.System_Administrator"));
    //console.log('User Is Admin => '+cmp.get("v.userIsAdmin"));

    // Agregado, Comprobacion temporal para usuarios que no tienen country code
    // Este campo es necesario para el nombre de la relacion de ventas.
    if (cmp.get("v.user.CountryCode") == null) {
      cmp.find("notificationsLibrary").showNotice({
        "variant": "warning",
        "header": $A.get("$Label.c.SAP_Acc_Info_Warning"),
        "title": $A.get('$Label.c.Error'),
        "message": $A.get("$Label.c.SAP_Acc_Info_UserCountry"),
        closeCallback: function () {
          $A.get("e.force:closeQuickAction").fire();
        }
      });
    }

    if (cmp.get("v.mode") == 'New') {
      hlpr.getUserSalesOrgs(cmp, "Sales_Org__c");
      hlpr.getUserSalesOrgs(cmp, "Distribution_channel__c");
    }

    cmp.set("v.isUserDataLoaded", true);
    hlpr.setUpForm(cmp);

  },

  //handler for Sales Relationship related element lightning:recordEditForm
  handleOnFormload: function (cmp, evt, hlpr) {
    var mode = cmp.get("v.mode");
    if (mode == 'Edit') {
      cmp.set("v.formFields", evt.getParam("recordUi").record.fields);
    }
    cmp.set("v.isFormDataLoaded", true);
    hlpr.setUpForm(cmp);
  },

  handleOnInputChange: function (cmp, evt, hlpr) {
    cmp.set("v.restrictCreationMessage", false);
    var sourceId = evt.getSource().getLocalId();
    var newValue = evt.getSource().get("v.value");

    //requiredFields could be loaded as global js variable using static resource
    const requiredFields = new Set(['Name', 'Account_Org__c', 'Sales_Org__c', 'Sales_Office__c', 'Distribution_Channel__c']);
    //copy picklists values
    if (sourceId == 'salesorg' || sourceId == 'distChannel') {
      hlpr.updateStandardSalesOrgPicklist(cmp, cmp.find(sourceId).get("v.value"), sourceId);
    }
    /* Calcularemos el nombre de l relación en el trigger
    if (sourceId == 'Account_Org__c' || sourceId == 'salesorg' || sourceId == 'distChannel') {
      hlpr.updateSalesRelationhipName(cmp, cmp.find('Account_Org__c').get("v.value"), cmp.find('Sales_Org__c').get("v.value"));
    }
    */
    //dinamiacally remove error related css 
    /*
    if (requiredFields.has(sourceId) && newValue != "" && newValue != null) {
      hlpr.disableErrorField(cmp, sourceId);
    }
    */
    // if salesOrg combobox or Distribution_Channel__c were modified, retrieve picklist values for SalesOffice
    if (sourceId == 'salesorg' || sourceId == 'distChannel') {
      cmp.set("v.selectedSalesOffice", '');
      //console.log('Sales_Org__c value' + cmp.find('Sales_Org__c').get("v.value"));
      //console.log('Distribution_Channel__c value ' + cmp.find('Distribution_Channel__c').get("v.value"));
      hlpr.getSalesOfficePicklistValues(cmp, cmp.find('Sales_Org__c').get("v.value"), cmp.find('Distribution_Channel__c').get("v.value"));

    }

    if (sourceId == 'salesOffice') {
      hlpr.disableErrorField(cmp, sourceId);
    }

    hlpr.checkIsRestricted(cmp,cmp.find('Sales_Org__c').get("v.value"));

  },

  onSaveClick : function(cmp, evt, hlpr) {
    var btn = cmp.find('submitButton').getElement();
    if (btn) {
        btn.click();
    }
  },

  //Submit action for lightning:recordEditForm
  handleOnSubmit: function (cmp, evt, hlpr) {

    console.log("## handleOnSubmit ##");
    //console.log("fields => "+JSON.stringify(evt.getParam("fields")));
    evt.preventDefault();//Prevent standar save functionality 
    var fields = evt.getParam("fields");
    var hasError = false;

    const requiredFields = new Set(['Name', 'Account_Org__c', 'Sales_Org__c', 'Sales_Office__c', 'Distribution_Channel__c']);
    //console.log("requiredFields=> "+requiredFields);

    for (var key in fields) {
      //console.log("key => "+key);
      if (requiredFields.has(key)) {
        //console.log("value => "+fields[key]);
        if (fields[key] == null || fields[key] == '') {
          hlpr.enableErrorField(cmp, key);
          hasError = true;
        } else {
          //this could be removed, it's being run during handleOnInputChange...
          hlpr.disableErrorField(cmp, key);
        }
      }
    }
    if (!hasError) {
      hlpr.insertSalesRelation(cmp, evt, fields);
    }

  },

  onSendRestrictionMessage: function (cmp, evt, hlpr) {
    hlpr.sendRestrictionMessage(cmp, evt);
  },

  //this is run when we do not set evt.preventDefault() on handleOnSubmit
  handleOnSuccess: function (cmp, evt, hlpr) {
    console.log("## handleOnSuccess ##");
    //console.log("evt.getParams => "+JSON.stringify(evt.getParams()));
    var record = evt.getParam("response");
    var toastMessage;
    if (cmp.get("v.mode") == 'New') {
      toastMessage = $A.get("$Label.c.SAP_Acc_Info_Created");
    } else {
      toastMessage = $A.get("$Label.c.SAP_Acc_Info_Saved");
    }

    var notificationService = cmp.find("notificationsLibrary");
    notificationService.showToast({
      "variant": "success",
      "mode": "dismissible",
      "title": "Saved",
      "message": toastMessage,
      "messageData": [
        {
          url: '/' + record.id,
          label: record.fields.Name.value
        }
      ]
    });

    hlpr.manageNavigation(cmp, false);
  },
  //Cancel button
  handleOnCancel: function (cmp, evt, hlpr) {
    console.log('## handleOnCancel ##');
    hlpr.manageNavigation(cmp, true);

  },

  //this is run when we do not set evt.preventDefault() on handleOnSubmit
  handleOnError: function (cmp, evt, hplr) {
    console.log('## handleOnError ##');
    //console.log("evt.getParams => "+JSON.stringify(evt.getParams()));

    if (cmp.get("v.userHasAccess")) {
      var saveError = evt.getParams("error");
      var notificationService = cmp.find("notificationsLibrary");

      notificationService.showNotice({
        "variant": "error",
        "header": "Something has gone wrong!",
        "title": saveError.message,
        "message": saveError.detail,
        closeCallback: function () {
          hlpr.manageNavigation(cmp, true);
        }
      });
    }

  },
  //makes Spinner attribute true for display loading spinner
  showSpinner: function (component, event, helper) {
    component.set("v.spinner", true);
  },

  closeComponent: function (component, event, helper) {
    helper.manageNavigation(component, true);
    $A.get("e.force:closeQuickAction").fire();
  },
  //makes Spinner attribute to false for hide loading spinner
  hideSpinner: function (component, event, helper) {
    component.set("v.spinner", false);
  }

})
        //var isDefined = !$A.util.isUndefined(cmp.get("v.label"));
        //var isEmpty = $A.util.isEmpty(cmp.get("v.label"));
/*var workspaceAPI = cmp.find("workspace");
workspaceAPI.getFocusedTabInfo().then(function(response) {
    console.log('getFocusedTabInfo=>'+JSON.stringify(response));
    console.log('tabId => '+response.tabId);
    console.log('isSubtab => '+response.isSubtab);
    console.log('subTab URL => '+response.url);
    console.log('action => '+response.pageReference.attributes.actionName);

})
.catch(function(error) {
    console.log('error => '+error);
});*/
        //console.log("recordUi"+JSON.stringify(evt.getParam("recordUi")));