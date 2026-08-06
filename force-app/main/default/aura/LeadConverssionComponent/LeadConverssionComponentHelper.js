({

    /**
     * ********************************************
     * SERVER ACTIONS
     * ********************************************
     */
    prepareConversion : function(component, leadId) {
        component.set('v.showSpinner', true);
        var action = component.get("c.prepareConversion");
        action.setParams({
            leadId : leadId
        });   
        action.setCallback(this, response => this.prepareConversionCallback(component, response));
        $A.enqueueAction(action);                    
    },

    readAccountInfo : function(component) {    
        var accountId = component.get('v.theLead.AccountId__c');
        if (accountId != null && accountId.length > 0) {        
            var action = component.get("c.readAccountInfo");
            action.setParams({
                accountId : accountId.toString()
            });            
            action.setCallback(this, response => this.readAccountInfoCallback(component, response));
            $A.enqueueAction(action);                    
        } else {
            this.clearAccountField(component);
        }
    },

    convertLead : function(component) {
        component.set('v.errorList', []);
        component.set('v.showSpinner', true);
        var leadId = component.get('v.recordId');        
        var newAccount = component.get('v.createNewAccount');
        var newContact = component.get('v.createNewContact');
        var accountId = null;
        var contactId = null;
        if (!newAccount) {
            accountId = component.get('v.theLead.AccountId__c');
            contactId = component.get('v.contactId');
        }
        if (newContact == null) {
            newContact = false;
        }
        var oppId = component.get('v.selectedOpportunity');
        var oppName = component.get('v.theLead.Opportunity_Name__c');
        var noOpportunity = component.get('v.dontCreateOpp');        
        var convertProducts = component.get('v.convertProducts');
        var convertAvailableProducts = component.get('v.convertAvailableProducts');
        var action = component.get("c.convertLead");
        action.setParams({
            leadId : leadId,
            accountId: accountId,
            contactId: contactId,
            newContact: newContact,
            opportunityId : oppId, 
            opportunityName: oppName,
            noOpportunity : noOpportunity,
            convertProducts : convertProducts,
            convertAvailableProducts : convertAvailableProducts
        });           
        action.setCallback(this, response => this.convertLeadCallback(component, response));
        $A.enqueueAction(action);
    },

    /**
     * *******************************************
     * CALLBACKS
     * *******************************************
     */
    prepareConversionCallback : function(component, response) {
        var state = response.getState();        
        if(state === "SUCCESS") {  
            var dto = response.getReturnValue();   
            this.showConversionData(component, dto);
        } else if (state === "ERROR") {
            component.set('v.showSpinner', false);              
            this.handleErrors(component, response.getError());        
        }
    },

    readAccountInfoCallback : function(component, response) {
        var opps = new Array();
        var contacts = new Array();
        var state = response.getState();  
        if (state === "SUCCESS") {  
            var dto = response.getReturnValue();                
            opps = dto.opportunities;            
            contacts = dto.contacts;      
            component.set('v.isPersonAccount', dto.isPersonAccount);      
            component.set('v.opportunityList', this.buildOpportunitiesList(opps, component.get('v.warningsList')));
            this.setDefaultSelectedOpp(component);
            component.set('v.contactList', this.buildContactsList(contacts, null));                                
            this.setAccountProperties(component);
        }
        component.set('v.showSpinner', false);
    },

    convertLeadCallback : function(component, response) {
        component.set('v.showSpinner', false);
        var state = response.getState();   
        if (state === "SUCCESS") {  
            var dto = response.getReturnValue();  
            component.set('v.showContent', false);
            component.set('v.leadConverted', true);
            component.set('v.cResult', dto);
        } else if (state === "ERROR") {
            var errorList = [];
            var errors = response.getError();
            if (errors && Array.isArray(errors) && errors.length > 0) {                
                if (errors[0].pageErrors != null) {                    
                    for (let i = 0; i < errors[0].pageErrors.length; i++) {
                        errorList.push(errors[0].pageErrors[i].message);
                    }
                }
                if (errors[0].fieldErrors != null && errors[0].fieldErrors.Description != null) {
                    for (let i = 0; i < errors[0].fieldErrors.Description.length; i++) {
                        errorList.push(errors[0].fieldErrors.Description[i].message);
                    }
                } 
                if (errors[0].message != null) {
                    errorList.push(errors[0].message);
                }
                component.set('v.errorList', [errorList]);
            }            
        }
    },

    /**
     * *******************************************
     * PRIVATE METHODS
     * *******************************************
     */
    showConversionData : function(component, dto) {
        console.log('CONVERSION ---------------');
        console.log(dto.opportunities);
        console.log(dto);
        if (dto.errors.length > 0) {
            component.set('v.errorList', dto.errors);
            component.set('v.enableEdit', true);            
        } else {
            component.set('v.theLead', dto.lead);   
            component.set('v.warningsList', dto.warnings);
            var oppList = dto.opportunities;
            component.set('v.opportunityList', this.buildOpportunitiesList(oppList, component.get('v.warningsList')));
            this.setDefaultSelectedOpp(component);                   
            component.set('v.showContent', true);
            component.set('v.enableEdit', false);
            component.set('v.isPersonAccount', dto.isPersonAccount);        
            component.set('v.usePersonAccount', dto.usePersonAccount);        
            component.set('v.contactList', this.buildContactsList(dto.contacts, dto.contactId));            
            component.set('v.createNewAccount', (!dto.accountId));
            component.set('v.createNewContact', (!dto.isPersonAccount && !dto.contactId ));
            component.set('v.hasProductList', dto.hasProductList);
            component.set('v.convertProducts', dto.hasProductList);
            if (dto.lead.Company == null) {
                component.set("v.createNewLabel", $A.get("$Label.c.lead_new_private"));
            } else {
                component.set("v.createNewLabel", $A.get("$Label.c.lead_new_acc_contact"));
            }
            this.setAccountProperties(component);   
            if (!dto.isConvertible) {
                this.leadNonConvertible(component);
            }    
        }
        component.set('v.showSpinner', false);        
    },

    buildContactsList : function(contacts, contactId) {
        for (var i=0; i < contacts.length; i++) {
            contacts[i].selected = (contacts[i].Id == contactId);
        }
        return contacts;
    },

    buildOpportunitiesList : function (theList, warningList) {
        var none = new Object();
        none.Id = null;
        none.Name = $A.get('$Label.c.lead_new_opportunity');
        theList.forEach(function( elem, idx ) {
            if (elem.IsClosed == true) {
                elem.Name = '* ' + elem.Name;
            }
        });
        if (warningList.length > 0) {
            return theList;
        }
        return [none].concat(theList);
    },
    
    validateLead : function(component) {
        // Client-side validations only
        var messages = [];
        var isPersonAccount = component.get('v.isPersonAccount');      
        var createNew = component.get('v.createNewAccount');
        var accountId = component.get('v.theLead.AccountId__c');
        var newContact = component.get('v.createNewContact');
        var contactId = component.get('v.contactId');
        var Opportunity_Name__c = component.get('v.theLead.Opportunity_Name__c');
        var dontCreateOpp = component.get('v.dontCreateOpp');
        var selectedOpp = component.get('v.selectedOpportunity');
        var theLead = component.get('v.theLead');

        if ((isPersonAccount || theLead.Company == null) && !theLead.RoomTypeFilled__c && !dontCreateOpp) {
            messages.push($A.get('$Label.c.lead_no_room_info'));
        }
        if (!dontCreateOpp && !selectedOpp && !Opportunity_Name__c) {
            messages.push($A.get('$Label.c.lead_opp_require'));            
        }
        if (!createNew && (accountId == null || accountId == '')) {
            messages.push($A.get('$Label.c.lead_error_account_null'));
        }
        if (!(isPersonAccount || contactId || newContact)) {
            messages.push($A.get('$Label.c.lead_error_contact_null'));
        }
        component.set('v.errorList', messages);    
        return (messages.length == 0);
    },

    clearAccountField : function(component) {
        var oppList = this.buildOpportunitiesList([], component.get('v.warningsList'));
        component.set('v.opportunityList', oppList);      
        component.set("v.contactList", new Array());
        this.setAccountProperties(component);    
    },

    setAccountProperties: function(component) {
        var newAccountChecked = component.get("v.createNewAccount");
        var newContactChecked = component.get("v.createNewContact");
        var contacts = component.get('v.contactList');
        var account = component.get("v.theLead.AccountId__c");        
        var hasAccount = (account != null && account != undefined && account.length > 0);
        var company = component.get('v.theLead.Company');
        var isPersonAccount = component.get("v.isPersonAccount");

        var disableAccountField = newAccountChecked;
        var disableContactField = newAccountChecked || newContactChecked || (contacts.length == 0)
        var disableContactBox = (!hasAccount && (!newAccountChecked || !company));
        disableContactBox = (disableContactBox || (hasAccount && isPersonAccount));

        component.set('v.disableAccount', disableAccountField);        
        component.set('v.disableContact', disableContactField);        
        component.set('v.disableNewContact', disableContactBox);        

        if (!hasAccount && !newAccountChecked && newContactChecked) {
            component.set('v.createNewContact', false);
        }

    },

    leadNonConvertible : function(component) {
        $A.get('e.force:closeQuickAction').fire();
        component.find('notifLib').showNotice({
            "variant": "info",
            "header": "Info",
            "message":"Leads assigned to dealers can't be converted!",
            closeCallback: function() {}
        });      
    },

    handleErrors : function(component, errors) {
        var errorMessage;
        if (errors && Array.isArray(errors) && errors.length > 0) {
            errorMessage = errors[0].message;
        }
        $A.get('e.force:closeQuickAction').fire();
        component.find('notifLib').showNotice({
            "variant": "error",
            "header": "Something has gone wrong!",
            "message":errorMessage,
            closeCallback: function() {}
        });      
    }, // handleErrors     

    setDefaultSelectedOpp : function(component) {
        var warnings = component.get('v.warningsList');
        var opps = component.get('v.opportunityList');
        if (warnings.length == 0) {
            component.set('v.selectedOpportunity', null);     
        } else {
            if (opps.length == 0) {
                component.set('v.selectedOpportunity', null);     
            } else {
                component.set('v.selectedOpportunity', opps[0].Id); 
            }
        }
    }

})