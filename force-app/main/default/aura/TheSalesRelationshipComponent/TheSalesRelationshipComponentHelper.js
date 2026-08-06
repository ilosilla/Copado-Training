({
  //only runs once, to avoid strange behaviours
  //runs after account and user data has loaded
  setUpForm: function (cmp) {
    //console.log("|| setUpForm ||");
    if (cmp.get("v.isFormDataLoaded") &&
      cmp.get("v.isAccountDataLoaded") && cmp.get("v.isUserDataLoaded")) {

      if (!cmp.get("v.isSetUpFormExecuted")) {
        if (cmp.get("v.mode") == "New") {
          this.prepopulateFields(cmp);
          this.updateSalesRelationhipName(cmp, cmp.get("v.account.Id"), cmp.get("v.user.Default_Sales_Organization__c"));
          this.getSalesOfficePicklistValues(cmp, cmp.find('Sales_Org__c').get("v.value"), cmp.find('Distribution_Channel__c').get("v.value"));
        } else {
          if (cmp.get("v.salesOfficeEditable")) {
            let formFields = cmp.get("v.formFields");
            this.getSalesOfficePicklistValues(cmp, formFields.Sales_Org__c.value, formFields.Distribution_Channel__c.value);
          }
          this.prepopulateFieldsEdit(cmp);
        }

        cmp.set("v.reRender", false);//triggers dependant picklists update
        cmp.set("v.isSetUpFormExecuted", true);//prevents from executing more than once
        cmp.set("v.showSpinner", false);//hides spinner after form is loeaded
        // Agregado Juan Manuel 09-04
        cmp.set("v.enableSubmit", true);
        this.checkIsRestricted(cmp,cmp.get("v.user.Default_Sales_Organization__c"));
      }
    }
  },
  //Retrieves a list with pairs: value - label, for those sales orgs available to the user
  getUserSalesOrgs: function (cmp, fieldName) {
    //console.log('|| getUserSalesOrgs ||');
    if (cmp.get("v.user")[fieldName] != null) {

      var action = cmp.get("c.getUserSoOptions");
      var userInfo = fieldName == 'Sales_Org__c' ? cmp.get("v.user").Sales_Org__c.split(";") : cmp.get("v.user").Distribution_channel__c.split(";");
      action.setParams({
        userSalesOrgs: userInfo,
        fieldName: fieldName
      });
      action.setCallback(this, function (response) {
        var state = response.getState();
        var serverResponse = response.getReturnValue();

        if (state === "SUCCESS") {

          if (fieldName == 'Sales_Org__c') {
            cmp.set("v.userSalesOrgs", serverResponse);
            cmp.set("v.selectedSalesOrg", cmp.get("v.user").Default_Sales_Organization__c);
          } else if (fieldName == 'Distribution_channel__c') {
            cmp.set("v.userDistChannels", serverResponse);
            cmp.set("v.selectedDistChannel", cmp.get("v.user").Distribution_channel_default__c);
          }

        }
        else if (state === "INCOMPLETE") {
          //console.log("STATUS INCOMPLETE");
        }
        else if (state === "ERROR") {
          var errors = response.getError();
        }
      });

      $A.enqueueAction(action);

    }

    else {

      cmp.find("notificationsLibrary").showNotice({
        "variant": "warning",
        "header": "You will probably need to fix something in your User before creating or editing a Sales Relationship",
        "title": 'Error',
        "message": 'The following fields are required: [Sales Organization][Distribution Channel]',
        closeCallback: function () {
          $A.get("e.force:closeQuickAction").fire();
        }
      });

    }

  },

  //Keeps in sync custom and standard Sales Org picklists
  updateStandardSalesOrgPicklist: function (cmp, newValue, sourceId) {
    //console.log('|| updateStandardSalesOrgPicklist ||');
    //set flag to false, so render.js will set it to true later triggeriing the rerender on dependent picklists
    cmp.set("v.reRender", false);//triggers dependent picklist update      
    if (sourceId == 'salesorg') {
      cmp.find("Sales_Org__c").set("v.value", newValue);
    } else if (sourceId == 'distChannel') {
      cmp.find("Distribution_Channel__c").set("v.value", newValue);
    }

  },

  //Updates Name as a concatenation of Account name and Sales Org
  updateSalesRelationhipName: function (cmp, aAccountId, aSalesOrgPle) {
    //console.log("|| updateSalesRelationhipName ||");
    var action = cmp.get("c.getFieldLabels");
    action.setParams({
      accountId: aAccountId,
      salesOrgPle: aSalesOrgPle
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      var serverResponse = response.getReturnValue();
      if (state === "SUCCESS") {
        var salesOrgLabel = (serverResponse.salesOrgLabel != null) ? serverResponse.salesOrgLabel : '';
        // Agregado Juan Manuel Martinez 01-08
        /* 	El nombre sigue el formato: [PP-OOO-DD] NOMBRE DE LA ORGV
            PP es el código del país (GB, FR, etc)
  OOO es el código de la ORG.V.
  DD es el código del canal.
        */

        let userCountryCode = cmp.get("v.user.CountryCode"); //
        let distributionChannelCode = cmp.find('Distribution_Channel__c').get("v.value"); //

        let newName = '[' + userCountryCode + '-' + aSalesOrgPle + '-' + distributionChannelCode + '] ' + salesOrgLabel;
        cmp.find("Name").set("v.value", newName);
      }
      else if (state === "INCOMPLETE") {
        console.log("STATUS INCOMPLETE");
      }
      else if (state === "ERROR") {
        var errors = response.getError();
        console.error('errors => ' + errors);
      }
    });
    $A.enqueueAction(action);
  },

  getSalesOfficePicklistValues: function (cmp, salesOrgValue, distributionChannelValue) {

    //console.log("|| getSalesOfficePicklistValues ||");

    var action = cmp.get("c.retrieveSalesOfficePicklistValues");
    action.setParams({
      salesOrgCode: salesOrgValue,
      distributionChannelCode: distributionChannelValue
    });

    action.setCallback(this, function (response) {

      var state = response.getState();
      var serverResponse = response.getReturnValue();

      if (state === "SUCCESS") {

        var emptyOption = { "value": "", "label": "--None--" };
        serverResponse.unshift(emptyOption);

        cmp.set("v.salesOfficeOptions", serverResponse);

      }
      else if (state === "INCOMPLETE") {
        //console.log("STATUS INCOMPLETE");
      }
      else if (state === "ERROR") {
        var errors = response.getError();
        console.error('errors => ' + errors);
      }

    });    
    $A.enqueueAction(action);

  },

  prepopulateFields: function (cmp) {
    console.log('|| prepopulateFields ||');

    let userRecord = cmp.get("v.user");

    cmp.find("salesorg").set("v.value", userRecord.Default_Sales_Organization__c);
    cmp.find("Sales_Org__c").set("v.value", userRecord.Default_Sales_Organization__c);
    cmp.find("distChannel").set("v.value", userRecord.Distribution_channel_default__c);
    cmp.find("Distribution_Channel__c").set("v.value", userRecord.Distribution_channel_default__c);
    cmp.find("Account_Org__c").set("v.value", cmp.get("v.account.Id"));
    cmp.find("accountName").set("v.value", cmp.get("v.account.Name"));
    cmp.set("v.selectedSalesOffice", userRecord.Sales_Office__c);

    // Workaround para setear el force:inputField en caso de mobile
    if ($A.get("$Browser.formFactor") != 'DESKTOP') {
      let salesRel = cmp.get("v.salesRel");
      salesRel.Commercial__c = userRecord.Id;
      salesRel.Commercial__r = { "sobjectType": "User", "Name": userRecord.Name };
      cmp.set("v.salesRel", salesRel);
      cmp.find("Commercial__c").set("v.value", salesRel.Commercial__c);
    } else {
      cmp.find("Commercial__c").set("v.value", userRecord.Id);
    }

  },

  prepopulateFieldsEdit: function (cmp) {

    let fields = cmp.get("v.formFields");

    cmp.set("v.userSalesOrgs", [{
      'label': fields.Sales_Org__c.displayValue,
      'value': fields.Sales_Org__c.value
    }]);
    cmp.set("v.userDistChannels", [{
      'label': fields.Distribution_Channel__c.displayValue,
      'value': fields.Distribution_Channel__c.value
    }]);

    cmp.set("v.selectedSalesOrg", fields.Sales_Org__c.value);
    cmp.set("v.selectedDistChannel", fields.Distribution_Channel__c.value);

    cmp.find("accountName").set("v.value", fields.Account_Org__r.displayValue);

    if (!cmp.get("v.userIsAdmin")) {
      cmp.set("v.salesOfficeOptions", [{
        'label': fields.Sales_Office__c.displayValue,
        'value': fields.Sales_Office__c.value
      }]);
    }

    cmp.set("v.selectedSalesOffice", fields.Sales_Office__c.value);

    if ($A.get("$Browser.formFactor") != 'DESKTOP') {
      let salesRel = cmp.get("v.salesRel");
      salesRel.Commercial__c = fields.Commercial__c.value;
      salesRel.Commercial__r = { "sobjectType": "User", "Name": fields.Commercial__r.displayValue };
      cmp.set("v.salesRel", salesRel);
    }

  },

  enableErrorField: function (cmp, field) {
    if (field == 'Sales_Office__c') {
      cmp.set("v.showError", true);
    } else {
      $A.util.addClass(cmp.find(field), 'slds-has-error');
      $A.util.addClass(cmp.find('formHelp-' + field), 'slds-show');
      $A.util.removeClass(cmp.find('formHelp-' + field), 'slds-hide');
    }

  },
  disableErrorField: function (cmp, field) {
    if (field == 'salesOffice') {
      cmp.set("v.showError", false);
    } else {
      $A.util.removeClass(cmp.find(field), 'slds-has-error');
      $A.util.removeClass(cmp.find('formHelp-' + field), 'slds-show');
      $A.util.addClass(cmp.find('formHelp-' + field), 'slds-hide');
    }
  },

  //If any error happens then a notification is shown instead of a toast because
  //the toast renders behind the modal, but we do not want to close the modal and lose
  //user input. For success we close the modal and show a toast
  insertSalesRelation: function (cmp, evt, jsonObject) {
    console.log('insertSalesRelation');

    var action = cmp.get("c.saveSalesRelation");
    var hasRestriction = false;
    action.setParams({
      jsonString: JSON.stringify(jsonObject),
      mode: cmp.get("v.mode"),
      sendToSap: !hasRestriction
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      var serverResponse = response.getReturnValue();
      cmp.set("v.enableSubmit", true); // Agregado Juan Manuel 09-04
      console.log('RESULTADO')
      console.log(state)

      if (state === "SUCCESS") {
        if (hasRestriction == true) {
          console.log('ENVIO EMAIL');
          this.sendRestrictionMessage(cmp, evt);
        }
        var notificationService = cmp.find("notificationsLibrary");
        if (serverResponse.success) {
          var toastMessage;
          if (cmp.get("v.mode") == 'New') {
            toastMessage = $A.get("$Label.c.SAP_Acc_Info_Created");
          } else {
            toastMessage = $A.get("$Label.c.SAP_Acc_Info_Saved");
          }
          notificationService.showToast({
            "variant": "success",
            "mode": 'dismissible',
            "title": "Saved",
            "message": toastMessage,
            "messageData": [
              {
                url: '/' + serverResponse.companyId,
                label: cmp.find("Name").get("v.value")
              }
            ]
          });
          this.manageNavigation(cmp, false);
        } else {

          let variant, header, title;

          if (serverResponse.errorTitle == 'duplicate') {
            variant = "warning";
            header = "WARNING!";
            title = '';
          } else {
            variant = "error";
            header = "ERROR!";
            title = serverResponse.errorTitle;
          }

          notificationService.showNotice({
            "variant": variant,
            "header": header,
            "title": title,
            "message": serverResponse.errorMessage,
            closeCallback: function () {
            }
          });
        }
      }
      else if (state === "INCOMPLETE") {
        //console.log("STATUS INCOMPLETE");
      }
      else if (state === "ERROR") {
        var errors = response.getError();
      }
    });
    $A.enqueueAction(action);
    cmp.set("v.enableSubmit", false); // Agregado Juan Manuel 09-04

  },

  manageNavigation: function (cmp, cancelButtonPressed) {
    //console.log('|| manageNavigation ||');
    let recordId = cmp.get("v.recordId");

    //if we are on the quick action modal...
    if (cmp.get("v.sObjectName") == "Account") {
      //refresh the undelying account layout
      $A.get('e.force:refreshView').fire();
      $A.get("e.force:closeQuickAction").fire();
    } else {
      //if user clicked cancel button...
      if (cancelButtonPressed) {
        cmp.set("v.enableSubmit", false);
        if ($A.get("$Browser.formFactor") != 'DESKTOP') {
          var pageReference = {
            "type": "standard__recordPage",
            "attributes": {
              "recordId": recordId,
              "objectApiName": "Sales_Relationship__c",
              "actionName": "view"
            }
          };

          cmp.find("navService").navigate(pageReference, true);

        } else {
          var workspaceAPI = cmp.find("workspace");
          workspaceAPI.getFocusedTabInfo().then(function (response) {
            workspaceAPI.closeTab({ tabId: response.tabId });
          })
            .catch(function (error) {
                console.log(error);
            });
        }

      }
      //if we are on the NEW action redirect subtab to the newly created record
      else if (cmp.get("v.mode") == 'New') {
        var pageReference = {
          "type": "standard__recordPage",
          "attributes": {
            "recordId": recordId,
            "objectApiName": objectApiName,
            "actionName": "view"
          }
        };
        cmp.find("navService").navigate(pageReference, true);
      }
      //if we are on the UPDATE action refresh other subtabs and close current subtab 
      else {

        if ($A.get("$Browser.formFactor") != 'DESKTOP') {
          var pageReference = {
            "type": "standard__recordPage",
            "attributes": {
              "recordId": recordId,
              "objectApiName": "Sales_Relationship__c",
              "actionName": "view"
            }
          };

          cmp.find("navService").navigate(pageReference, true);

        } else {
          var workspaceAPI = cmp.find("workspace");
          var subtabs = [];
          var currentTab;
          workspaceAPI.getAllTabInfo().then(function (response) {
            for (var x in response) {
              for (var y in response[x].subtabs) {
                //we do not want to refresh current subtab
                if (response[x].subtabs[y].focused == false) {
                  subtabs.push(response[x].subtabs[y].tabId);
                } else {
                  currentTab = response[x].subtabs[y].tabId;
                }
              }
            }
            if (!$A.util.isEmpty(subtabs)) {
            }
            for (var z in subtabs) {
              workspaceAPI.refreshTab({
                tabId: subtabs[z]//,
                //includeAllSubtabs: false
              });
            }
            workspaceAPI.getFocusedTabInfo().then(function (response) {
              //workspaceAPI.closeTab({tabId: currentTab});
              workspaceAPI.closeTab({ tabId: response.tabId });
            });
          })
            .catch(function (error) {
              //console.log('error => ' + error);
            });

        }

      }
    }
  },

  //Right after the account data loads we run a verification to let the user know in advance 
  //whether there is any issue that may keep him from creating a sales relationship
  verifyAccount: function (cmp) {
    var action = cmp.get("c.validateAccount");
    action.setParams({
      accountId: cmp.get("v.account.Id")
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      var serverResponse = response.getReturnValue();

      if (state === "SUCCESS") {
        if (!serverResponse.success) {
          cmp.find("notificationsLibrary").showNotice({
            "variant": "warning",
            "header": $A.get("$Label.c.SAP_Acc_Info_FixBefore"),
            "title": serverResponse.errorTitle,
            "message": serverResponse.errorMessage,
            closeCallback: function () {
              $A.get("e.force:closeQuickAction").fire();
            }
          });

        } else {
          //console.log("Account Verification OK!!");
        }

      }
      else if (state === "INCOMPLETE") {
        //console.log("STATUS INCOMPLETE");
      }
      else if (state === "ERROR") {
        var errors = response.getError();
        //console.log(errors);
      }
    });
    $A.enqueueAction(action);
  },

  checkAccountData: function (cmp, hlpr) {

    var action = cmp.get("c.checkAccountData");
    var recordId = cmp.get("v.recordId");
    var closeQuickAction = $A.get("e.force:closeQuickAction");

    action.setParams({
      recordId: recordId
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      console.log(response);
      var serverResponse = response.getReturnValue();
      if (state === "SUCCESS") {
        cmp.set("v.accountChecks", serverResponse);
      }
    });

    $A.enqueueAction(action);
 },

  checkUserHasAccess: function (cmp, hlpr) {

    var action = cmp.get("c.userHasAccess");
    var recordId = cmp.get("v.recordId");
    var closeQuickAction = $A.get("e.force:closeQuickAction");

    action.setParams({
      recordId: recordId
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      var serverResponse = response.getReturnValue();
      console.log(serverResponse);
      if (state === "SUCCESS") {
        var hasEditAccess = (serverResponse == 1);
        cmp.set("v.userHasAccess", hasEditAccess);
        console.log('RESPONSE DEL SERVER: ');
        console.log(serverResponse);
        if (serverResponse == 2) {
            cmp.set("v.showSpinner", false);
            cmp.set("v.warningMessage", $A.get("$Label.c.Insufficient_Permissions_Error"));
            cmp.set("v.warningHeader", $A.get("$Label.c.SAP_Acc_Info_Permission"));
        } else if (serverResponse == 3) {
            cmp.set("v.showSpinner", false);
            cmp.set("v.warningHeader", $A.get("$Label.c.Warning"));
            cmp.set("v.warningMessage", $A.get("$Label.c.SAP_No_Access"));
        } else if (serverResponse == 4) {
            cmp.set("v.showSpinner", false);
            cmp.set("v.warningHeader", $A.get("$Label.c.Warning"));
            cmp.set("v.warningMessage", $A.get("$Label.c.sap_down"));
        } else if (serverResponse == 5) { // SIRET NOT VALID
          cmp.set("v.showSpinner", false);
          cmp.set("v.warningHeader", $A.get("$Label.c.Warning"));
          cmp.set("v.warningMessage", $A.get("$Label.c.Not_valid_vat"));
        } else if (serverResponse == 6) { // DATA NOT CORRECTED
          cmp.set("v.showSpinner", false);
          cmp.set("v.warningHeader", $A.get("$Label.c.Warning"));
          cmp.set("v.warningMessage", $A.get("$Label.c.tr0008_0001"));
        } else if (serverResponse == 7) { // DATA DISCARDED
          cmp.set("v.showSpinner", false);
          cmp.set("v.warningHeader", $A.get("$Label.c.Warning"));
          cmp.set("v.warningMessage", $A.get("$Label.c.tr0008_0002"));
        }
      }

      else if (state === "INCOMPLETE") {
        //console.log("STATUS INCOMPLETE");
      }

      else if (state === "ERROR") {
        var errors = response.getError();
        //console.log(errors);
      }

    });

    $A.enqueueAction(action);
  },

  sendRestrictionMessage: function (cmp, hlpr) {
    cmp.set("v.showspinner", true);
    var action = cmp.get("c.sendRestrictionMessage");
    action.setParams({
      salesOrg: cmp.find('Sales_Org__c').get("v.value"),
      channel: cmp.find('Distribution_Channel__c').get("v.value"),
      salesOffice: cmp.get("v.selectedSalesOffice"),
      commercialId: cmp.find('Commercial__c').get("v.value"),
      userId: cmp.get("v.user").Id,
      accountId: cmp.get("v.account.Id")
    });
    action.setCallback(this, function (response) {
      var state = response.getState();
      var serverResponse = response.getReturnValue();
      if (state === "SUCCESS") {
        var notificationService = cmp.find("notificationsLibrary");
          var toastMessage;
          toastMessage = $A.get("$Label.c.restricted_message_sent");
          notificationService.showToast({
            "variant": "success",
            "mode": 'dismissible',
            "title": "Request sent",
            "message": toastMessage
          });
          this.manageNavigation(cmp, false);
      }
      else if (state === "INCOMPLETE") {
        //console.log("STATUS INCOMPLETE");
      }
      else if (state === "ERROR") {
        var errors = response.getError();
        console.log(errors);
      }
      cmp.set("v.showspinner", false);

    });

    $A.enqueueAction(action);
  },

  checkUserCanEditSalesOffice: function (cmp, hlpr) {

    var action = cmp.get("c.salesOfficeEditable");

    action.setCallback(this, function (response) {
      var state = response.getState();
      var serverResponse = response.getReturnValue();
      if (state === "SUCCESS") {
        cmp.set("v.salesOfficeEditable", serverResponse);
      }
      else if (state === "INCOMPLETE") {
        //console.log("STATUS INCOMPLETE");
      }
      else if (state === "ERROR") {
        var errors = response.getError();
      }

    });

    $A.enqueueAction(action);
  },

  checkSalesOrgRestricted: function (cmp, hlpr) {

    var action = cmp.get("c.checkSalesOrgRestricted");

    action.setCallback(this, function (response) {
      var state = response.getState();
      var serverResponse = response.getReturnValue();
      console.log('SALES ORGS RESTRICTED');
      console.log(serverResponse);
      if (state === "SUCCESS") {
        cmp.set("v.salesOrgsRestricted", serverResponse);
      }
      else if (state === "INCOMPLETE") {
        //console.log("STATUS INCOMPLETE");
      }
      else if (state === "ERROR") {
        var errors = response.getError();
      }

    });

    $A.enqueueAction(action);
  },

  checkIsRestricted: function (cmp, salesOrg) {
    if (cmp.get("v.salesOrgsRestricted").includes(salesOrg) == true) {
      cmp.set("v.restrictCreationMessage", true);
      cmp.set("v.orgRestriction", true);
    }

    var salesOrg = cmp.find('Sales_Org__c').get("v.value");
    var channel = cmp.find('Distribution_Channel__c').get("v.value");
    var salesOffice = cmp.get("v.selectedSalesOffice");

    if (salesOrg != '' && channel != '' && salesOffice != '') {
      cmp.set("v.enablerestrictCreationMessage", true);
    } else {
      cmp.set("v.enablerestrictCreationMessage", false);
    }
  },

  // Destruye y vuelve a crear un component lightning:inputField.
  // Workaround para lookups en mobile ya que lightning:inputField permite que se le setee el value solo una vez
  // Entonces para que el valor pueda ser seteado se destruye el componente actual y se lo vuelve a crear
  replaceComponent: function (cmp, fieldName, fieldValue) {
    //console.log("#### replaceComponent: " + fieldName);
    let oldCmp = cmp.find(fieldName);

    if (oldCmp != undefined) {
      oldCmp.destroy();

      let container = cmp.find(fieldName + '-container');

      if (container != undefined) {
        $A.createComponent(
          'lightning:inputField',
          {
            'fieldName': fieldName,
            'aura:id': fieldName,
            'disabled': cmp.get("v.mode") == 'Edit',
            'class': 'slds-hide',
            'value': fieldValue
          },

          (newComponent) => {
            container.set('v.body', [newComponent]);
          }
        );
      }
    }
  }


})