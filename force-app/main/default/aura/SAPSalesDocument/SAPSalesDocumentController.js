({
    docChange : function(component, event, helper) {
        var docData = component.get("v.docData");
        if (docData) {
            helper.customiseForm(component, docData.docType);
            helper.getSAPDocument(component, docData.docNumber, docData.docType, docData.accountId);
        }
    },
    downloadPDF : function(component, event, helper) {
        var docData = component.get("v.docData");
        if (docData) {
            helper.downloadDocument(component, docData.docType, docData.docNumber);
        }

    },
    openHeader : function(component, event, helper) {
        var cmpTarget = component.find('modalBox');                
        $A.util.removeClass(cmpTarget, 'slds-hide');                    
    },

    closeHeader : function(component, event, helper) {
        var cmpTarget = component.find('modalBox');                
        $A.util.addClass(cmpTarget, 'slds-hide');                    
    }

})