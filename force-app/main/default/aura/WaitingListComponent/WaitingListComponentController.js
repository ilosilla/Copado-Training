({
	onLoad : function(component, event, helper) {
        helper.loadData(component);
    },
    handleRefresh : function(component, event, helper) {
        helper.refreshWaitingPersons(component);
        helper.setTableColumns(component);
    },
    handleRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        component.set("v.selectedRow", row);
        
        switch (action.name) {
            case 'editEntry':
                component.set("v.formSelected", "editEntry");
                component.set("v.formSelectedTitle", 'Edit Entry');
                var modal = component.find('modalForms');
                var backdrop = component.find('backdropId');
                $A.util.toggleClass(modal, 'slds-fade-in-open');
                $A.util.toggleClass(backdrop, 'slds-backdrop_open');
                break;
            case 'assignSalesperson':
                var userId = $A.get("$SObjectType.CurrentUser.Id");
                
                component.set("v.formSelected", "assignSalesperson");
                component.set("v.formSelectedTitle", $A.get('$Label.c.wlist_assignSalespersonTitle'));
               	var modal = component.find('modalForms');
                var backdrop = component.find('backdropId');
                $A.util.toggleClass(modal, 'slds-fade-in-open');
                $A.util.toggleClass(backdrop, 'slds-backdrop_open');
                
                if (row.Salesperson__c != null ){
                    component.find("inputSearchSalesman").set("v.value", row.Salesperson__c);
                } else {
                 	component.find("inputSearchSalesman").set("v.value", userId);   
                }
                helper.salesmanSelected(component, userId);
                break;
            case 'assist':
                component.set("v.formSelected", "assist");
                component.set("v.formSelectedTitle", $A.get('$Label.c.wlist_assistTitle'));
               	var modal = component.find('modalForms');
                var backdrop = component.find('backdropId');
                $A.util.toggleClass(modal, 'slds-fade-in-open');
                $A.util.toggleClass(backdrop, 'slds-backdrop_open');
                
                if (row.Salesperson__c != null ){
                    component.find("inputSearchSalesman").set("v.value", row.Salesperson__c);
                }/* else {
                  	var userId = $A.get("$SObjectType.CurrentUser.Id");
                 	component.find("inputSearchSalesman").set("v.value", userId);
                    helper.salesmanSelected(component, userId);
                }*/
                break;
            case 'completed':
                helper.changeWaitingPersonStatus(component, 'COMPLETED');
                break;
            case 'lost':
                helper.changeWaitingPersonStatus(component, 'LOST');
                break;
            case 'inprogress':
                helper.changeWaitingPersonStatus(component, 'INPROGRESS');
                break;
            case 'toAccount':
                component.set("v.formSelected", 'transformEntry');
                component.set("v.formSelectedTitle", $A.get('$Label.c.dict_createPrivateAccount') + '/' + $A.get('$Label.c.dict_contact'));
               	var modal = component.find('modalForms');
                var backdrop = component.find('backdropId');
                $A.util.toggleClass(modal, 'slds-fade-in-open');
                $A.util.toggleClass(backdrop, 'slds-backdrop_open');
                break;
        }
    },
    handleCloseModals: function(component, event, helper){
        helper.closeModals(component);
    },
    onChangeSalesOfficeFilter : function(component, event, helper) {
        component.set("v.waitingPersonStatusFilter","WAITING");
        // Tranform date to local timezone
        var mydate = new Date().toLocaleDateString('fr-CA', {timeZone: $A.get("$Locale.timezone")});
        component.set("v.selectedDate", mydate);
        if ($A.get("$Browser.isPhone") == false) {
            component.find("filterDate").set("v.value", mydate);   
        }
        component.set("v.newPersonDisabled", false);
        component.set("v.selectedSalesOffice", component.find("salesOfficeFilter").get("v.value"));
        helper.refreshWaitingPersons(component);
        helper.setTableColumns(component);
        helper.getUsers(component);
    },
    onChangeDateFilter : function(component, event, helper) {
        component.set("v.waitingPersonStatusFilter","WAITING");
        component.set("v.selectedDate",component.find("filterDate").get("v.value"));
        helper.checkNewEntryButton(component);
        helper.refreshWaitingPersons(component);
        helper.setTableColumns(component);
        helper.getUsers(component);
    },
    handleOpenNewPersonModal : function(component, event, helper) {
        component.set("v.formSelected", 'newWListEntry');
        component.set("v.formSelectedTitle", $A.get('$Label.c.dict_addEntry'));
        var modal = component.find('modalForms');
        var backdrop = component.find('backdropId');
        var salesOfficeSelected = component.get("v.selectedSalesOffice");
        var salesOfficesData = component.get("v.salesOfficesData");

        var userSalesOffice = JSON.parse(JSON.stringify(salesOfficesData.filter(function (el) {
            return el.SalesOffice__c == salesOfficeSelected;
        })));

        component.find("SalesOffice__c").set("v.value", userSalesOffice.length > 0 ? userSalesOffice[0].Id : null);
        $A.util.toggleClass(modal, 'slds-fade-in-open');
        $A.util.toggleClass(backdrop, 'slds-backdrop_open');
    },
    handleSalesmanSelected: function(component, event, helper){
        var selectedOptionValue = event.getParam("value");
        helper.salesmanSelected(component, selectedOptionValue);
    },
    handleAssignSalesperson : function(component, event, helper){
        helper.assignSalesperson(component);
    },
    handleAssistCustomer : function(component, event, helper){
        helper.assistCustomer(component);
    },
    handleSuccessForm : function(component, event, helper) {
        var formSubmitted = component.get("v.formSelected");
        var titleMessage = 'Added!';
        var bodyMessage = '';
        
        switch (formSubmitted) {
            case 'editEntry':
                bodyMessage = $A.get('$Label.c.wlist_updated_entry');
                break;
            case 'newWListEntry':
                bodyMessage = $A.get('$Label.c.wlist_createdEntry');
                break;
            case 'newPersonAccount':
                bodyMessage = $A.get('$Label.c.wlist_createdPrivateAccount');
                break;
            case 'newContact':
                bodyMessage = $A.get('$Label.c.wlist_createdContact');
                break;
        }
        
        helper.showSuccessMessage(component, titleMessage, bodyMessage);
        component.set("v.savingSomething", false);
        helper.closeModals(component);        
        helper.refreshWaitingPersons(component);
    },
    handleEnableSaveForm : function(component, event, helper) {
        component.set("v.savingSomething", false);
    },
    filterWaiting : function(component, event, helper) {
        helper.filterTable(component, 'WAITING');
    },
    filterInProgress : function(component, event, helper) {
        helper.filterTable(component, 'INPROGRESS');
    },
    filterCompleted : function(component, event, helper) {
        helper.filterTable(component, 'COMPLETED');
    },
    filterLost : function(component, event, helper) {
        helper.filterTable(component, 'LOST');
    },
    handleToSecondStage : function(component, event, helper) {
        var aux = component.get("v.transformSelectedValue");
        var entrySelected = component.get("v.selectedRow");
        if (aux == 'transformToAccount') {
            component.set("v.formSelected", "newPersonAccount");
            component.set("v.formSelectedTitle", $A.get('$Label.c.dict_createPrivateAccount'));
            var valueSelected = component.get("v.selectedSalesOffice");
            var salesOffices = component.get("v.salesOfficesData");
            var salesOfficeSelectedId = salesOffices.findIndex(item => item.SalesOffice__c == valueSelected);
            if (salesOfficeSelectedId >= 0) {
                component.find("toAccountPersonMailingCountryCode").set("v.value", salesOffices[salesOfficeSelectedId].CountryCode__c);   
            }
            component.find("toAccountFirstName").set("v.value", entrySelected.FirstName__c);
            component.find("toAccountLastName").set("v.value", entrySelected.LastName__c);
            component.find("toAccountPhone").set("v.value", entrySelected.Phone__c);
            component.find("toAccountPersonEmail").set("v.value", entrySelected.Email__c);
        }
        if (aux == 'transformToContact') {
            component.set("v.formSelected", "newContact");
            component.set("v.formSelectedTitle", 'Create Contact');
            component.find("toContactFirstName").set("v.value", entrySelected.FirstName__c);
            component.find("toContactLastName").set("v.value", entrySelected.LastName__c);
            component.find("toContactPhone").set("v.value", entrySelected.Phone__c);
            component.find("toContactPersonEmail").set("v.value", entrySelected.Email__c);
        }

    },
    handleToFirstStage : function(component, event, helper) {
        component.set("v.formSelected", "transformEntry");
        component.set("v.formSelectedTitle", $A.get('$Label.c.dict_createPrivateAccount') + '/' + $A.get('$Label.c.dict_contact'));
    },
    handleSubmitNewAccount : function(component, event, helper) {
        event.preventDefault();
        var accountFields = event.getParam('fields');
        component.set("v.savingSomething", true);
        helper.createNewPersonAccount(component, accountFields);
    },
    handleSubmitNewContact : function(component, event, helper) {
        event.preventDefault();
        var contactFields = event.getParam('fields');
        component.set("v.savingSomething", true);
        helper.createNewContact(component, contactFields);   
    },
    handleSubmitNewWLEntry : function(component, event, helper) {
        event.preventDefault();
        var contactFields = event.getParam('fields');
        component.set("v.savingSomething", true);
        helper.createNewWLEntry(component, contactFields);   
    }
})