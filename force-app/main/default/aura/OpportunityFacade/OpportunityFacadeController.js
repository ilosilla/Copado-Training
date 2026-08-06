({
    handleInit : function (component, event, helper) {
    }, // handleInit

    handleOnLoad : function (component, event, helper) { 
        var opportunityId = component.get("v.opportunityId");
        var currentOpportunityId = component.get("v.currentOpportunityId");
        var recordUi = event.getParam("recordUi");
        component.set("v.createMode", recordUi.createMode);
        var facadeId = recordUi.record.id;
        var currentPhase = component.get("v.currentPhase");
        if (currentPhase == "init" && opportunityId != currentOpportunityId) {            
            helper.readFacadeData(component, opportunityId, facadeId);            
        }  else {
            helper.setupScreen(component);            
            component.set("v.showSpinner", false);        
        }
    },

    handleOnIsActiveChange: function(component, event, helper) {
        var isActive = component.get("v.isActive");
        if (isActive) {
            var currentPhase = component.get("v.currentPhase");
            if (currentPhase != 'init') {
                var tabset = component.find("tabset1");
                if (tabset!=null) {
                    tabset.set("v.selectedTabId", "FDetailsTab");
                }
            }
        }
    },

    handleStageChange : function (component, event, helper) {
        helper.setStageFields(component);
    },

    handleClose: function(component) {
        component.set('v.isActive', false);
    },
    
    handleTabClick : function(component, event, helper) {
    },

    handleSave : function(component, event, helper) {
        var btn = component.find('submitButton').getElement();
        if (btn) btn.click();
    }, // handleSave

    handleMainSubmit : function(component, event, helper) {
        event.preventDefault();
        var facade = event.getParam('fields');
        facade.Id = component.get("v.facadeId");
        facade.Manager__c = component.get("v.manager");        
        facade.Opportunity__c = component.get("v.opportunityId");
        if (helper.validateProject(component)) {
            component.set("v.showSpinner", true);
            component.find('facadeForm').submit(facade);
        }
    }, // handleMainSubmit

    handleOnSuccess : function(component, event, helper) {
        var oldId = component.get("v.facadeId");
        var record = event.getParam("response");
        var recordId = record.id;         
        component.set("v.facadeId", recordId);
        helper.dataSaved(component);
    }, // handleSave

    handleOnError : function(component, event, helper) {
        component.set("v.showSpinner", false);
    }, // handleSave


    /************************************************************************
     * FIELD CHANGE HANDLERS
     ************************************************************************/
     handleManagerChange : function(component, event, helper) {
         helper.setDesigners(component, null);
     },

     handleInstallationChange : function(component, event, helper) {
         helper.setInstallationFields(component);
     },

     handleBuildingChange : function(component, event, helper) {
        helper.setBuildingProperties(component);
    }, 

    handleCurrencyChange : function(component, event, helper) {
        helper.setCurrencyFields(component);
    },

    /************************************************************************
     * Upload files management
     ************************************************************************/

    handleUploadFile : function (component, event, helper) {
        var full = true; //component.get("v.hasFullAccess");
        component.set("v.selectedContentType", "OTHER");
        component.set("v.isUploading", true);
    }, // handleUploadFile
    
    handleUploader : function (component, event, helper) {
        var ids = [];
        var user = $A.get("$SObjectType.CurrentUser");
        var attachments = component.get("v.attachments");
        var user = component.get("v.userName");
        var uploadedFiles = event.getParam("files");
        for (var i = 0; i<uploadedFiles.length; i++) {
            var ofile = {};
            ofile.Id = uploadedFiles[i].documentId;
            ofile.fileName = uploadedFiles[i].name;
            ofile.url = helper.buildFileURL(ofile.Id);
            ofile.createdDate = new Date();
            ofile.createdBy = user;
            ofile.documentType = component.get("v.selectedContentType");
            ofile.contentDescription = helper.getContentDescription(ofile.documentType);
            ofile.contentVersionId = uploadedFiles[i].contentVersionId;
            attachments.push(ofile);
            ids.push(ofile.contentVersionId);
        }
        component.set("v.attachments", attachments);
        helper.setAttachmentsLabel(component, attachments.length );
        helper.afterUploadFile(component, ids, component.get("v.selectedContentType"));
        var message = $A.get("$Label.c.dict_filesAdded");
        message.replace('{1}', uploadedFiles.length);
        component.set("v.isUploading", false);
        component.find('notifLib').showToast({
            "title": "", // $A.get("$Label.c.dict_success") + "!",
            "message": message
        });        
    }, // handleUploader

    handleDownloadFileClick : function (component, event, helper) {
        var dt = component.find("attachmentsDT");
        var rows = dt.getSelectedRows();
        if (rows.length == 0) {
            helper.displayEmptySelectionToast(component);
            return;
        }
        helper.downloadAttachments(component, rows);
    }, // handleDownloadFileClick

   handleDeleteFileClick : function (component, event, helper) {
        var dt = component.find("attachmentsDT");
        var rows = dt.getSelectedRows();
        if (rows.length == 0) {
            helper.displayEmptySelectionToast(component);
            return;
        }
        component.set("v.showFileDelete", true);
    }, // handleDeleteFileClick

    onModalPromptEvent : function(component, event, helper) {
        var command = event.getParam("command");
        if (command == 'DELETE-FILE') {
            component.set("v.showFileDelete", false);            
            if (event.getParam("arg")) {                
                var dt = component.find("attachmentsDT");
                var rows = dt.getSelectedRows();    
                var ids = [];
                for (var i=0; i< rows.length; i++) {    
                    ids.push(rows[i].id);                    
                }
                helper.deleteFiles(component, ids);                
            } 
        }
    },
    
    handleFileAction : function(component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        switch (action.name) {
            case 'download':
                var rows = [];
                rows.push(row);
                helper.downloadAttachments(component, rows);
                break;
            case 'view':
                var url = helper.buildDownloadURL(row.id);
                window.open(url);
                break;
        }
    }, // handleFileAction

    closeEditionPanel : function(component, event, helper) {
        component.set('v.isExpanded', false);
        component.set('v.isUploading', false);
    },

})