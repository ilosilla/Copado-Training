({

    handleOnLoad: function (cmp, event, helper) {
        // cmp.set('v.loading', false);
        var updatedRecord = event.getParam('recordUi');        
        cmp.set('v.formTitle', updatedRecord.record.fields['Opportunity_Name__c'].value);
        cmp.set('v.oldAccountId', updatedRecord.record.fields['AccountId__c'].value);
        cmp.set('v.contactId', updatedRecord.record.fields['ContactId__c'].value);
        helper.getContacts(cmp, updatedRecord.record.fields['AccountId__c'].value);
    },

    handleOnSuccess : function(cmp, evt, hlpr){        
        cmp.set('v.loading', false);
        var oppName = cmp.find("oppName").get("v.value");
        $A.get('e.force:closeQuickAction').fire();
        cmp.find('notifLib').showToast({
            'variant': 'success',
            'message': 'Lead "' + oppName + '" updated'
        });
    },

    handleOnError : function(cmp, evt, hlpr){        
        cmp.set('v.loading', false);
    },

    handleOnSubmit : function(cmp, evt, hlpr){      
        cmp.set('v.loading', true);
        //evt.preventDefault();
        //var contactId = cmp.get('v.contactId');
        //alert("Vas a grabar " + contactId );
    },

    handleCancel : function(cmp, evt, hlpr){        
        $A.get('e.force:closeQuickAction').fire();
    },

    handleAccountChange : function(cmp, evt, hlpr) {
        var accountId = evt.getParam("value")[0];
        hlpr.getContacts(cmp, accountId);
    },

    submitForm : function(cmp, evt, hlpr) {
        var btn = cmp.find('submitButton').getElement();
        var id = cmp.get('v.contactId');
        cmp.find('ContactId__c').set('v.value', id);
        if (btn) {
            btn.click();
        }
    }

})