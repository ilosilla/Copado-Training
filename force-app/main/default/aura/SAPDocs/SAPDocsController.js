({
    doInit : function(component, event, helper) {
        helper.getEnclosingTabId(component);
        var docType = component.get('v.pageReference').state.c__t;
        var accountId = component.get('v.pageReference').state.c__a;
        var salesOrg = component.get('v.pageReference').state.c__o;
        var oppId = component.get('v.pageReference').state.c__opp;
        component.set('v.docType', docType);
        component.set('v.accountId', accountId);
        component.set('v.opportunityId', oppId);
        component.set('v.salesOrg', salesOrg);
        var variant = 'ACC';
        if (oppId) {
            variant = 'OPP';
        }
        component.set('v.variant', variant);
        helper.customiseForm(component, docType, salesOrg, accountId, variant);
        helper.getSAPDocuments(component);

    },
    
    documentClick : function(component, event, helper) {
        component.set('v.showTooltip', false);
        var currentDoc = component.get('v.currentDoc');        
        if (currentDoc) {
            currentDoc.setAttribute('aria-selected', false);
        }
        currentDoc = event.currentTarget;
        currentDoc.setAttribute('aria-selected', true);
        component.set('v.currentDoc', currentDoc);
        component.set('v.showDocument', true);
        var compo = component.find('documentComp');
        if (compo) {
            var params = {};
            params.docType = component.get('v.docType');
            params.accountId = component.get('v.accountId');
            params.docNumber =  currentDoc.id;
            compo.set('v.docData', params);
        }
    },

    refreshList : function(component, event, helper) {
        helper.getSAPDocuments(component);
    },

    changeOrder : function(component, event, helper) {
        if (event.currentTarget) {
            helper.sortList(component, event.currentTarget.id)
        }        
        /*
        var id = event.currentTarget.id + "-icon";
        component.find(id).set("v.iconName",'utility:arrowup');
        */
        //component.find("firstButton").set("v.iconName",'utility:error');
    } // changeOrder
})