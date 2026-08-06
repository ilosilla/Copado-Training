({
    onPageInit : function (component, event, helper) {
        var options = [
            { id: true, label: $A.get("$Label.c.dict_yes").toUpperCase() },
            { id: false, label: $A.get("$Label.c.dict_no").toUpperCase() },
        ];
        component.set("v.yesnoOptions", options);

    }, // hadleInit

    onRecordLoad : function (component, event, helper) {        
        var recordUi = event.getParam("recordUi");
        component.set("v.createMode", recordUi.createMode);        
        var currentPhase = component.get("v.currentPhase");
        if (currentPhase == "init") {
            helper.readCustomProjectData(component, recordUi.record.id);            
            helper.setTableColumns(component);
        } else  {
            helper.setupScreen(component);            
            helper.displayAttachmentsWarning(component, true);
        }
    },

    handleOnIsActiveChange: function(component, event, helper) {
        var isActive = component.get("v.isActive");
        var currentPhase = component.get("v.currentPhase");
        if (isActive && (currentPhase != 'init')) {
            var tabset = component.find("tabset1");
            if (tabset!=null) {
                tabset.set("v.selectedTabId", "CPDetailsTab");
            }
        }
    },

    handleSave : function(component, event, helper) {
        var btn = component.find('submitButton').getElement();
        if (btn) btn.click();
    }, // handleSave

    handleMainSubmit : function(component, event, helper) {
        event.preventDefault();
        var customProject = event.getParam('fields');
        customProject.Id = component.get("v.customProjectId");
        customProject.ProductManager__c = component.get("v.productManager");
        customProject.Opportunity__c = component.get("v.opportunityId");
        // Si hay que validar en el servidor, esto se puede llamar desde el helper en el callback de la validación
        // helper.saveCustomProject(component, customProject);
        if (helper.validateProject(component)) {
            component.set("v.showSpinner", true);
            component.set("v.currentPhase", "submit");
            component.find('dataForm').submit(customProject);
        }
    }, // handleMainSubmit

    handleOnSuccess : function(component, event, helper) {
        // The master record has been saved. Now save the request lines.
        var oldId = component.get("v.customProjectId");
        var record = event.getParam("response");
        var recordId = record.id;         
        if (oldId == null) {
            helper.displayAttachmentsWarning(component, false);
        }
        component.set("v.customProjectId", recordId);
        helper.saveRequestLines(component, recordId);
    }, // handleSave

    handleTabClick : function(component, event, helper) {
        component.set("v.isExpanded", false);
        component.set("v.isUploading", false);
    },

    handleOnError: function(component, event, helper) {
        component.set("v.showSpinner", false);
    }, // handleOnError

    handleClose: function(component) {
        component.set('v.isActive', false);
    },

    handleUploadFinished : function(component, event, helper) {
        var uploadedFiles = event.getParam("files");
        alert("Files uploaded : " + uploadedFiles.length);
        // Get the file name
        uploadedFiles.forEach(file =>alert(file.name + file.documentId));
    },

    addRequestLine : function(component, event, helper) {
        helper.addNewRequestLine(component);
    },

    closeEditionPanel : function(component, event, helper) {
        component.set('v.isExpanded', false);
        component.set('v.isUploading', false);
    },

    /**
     * ============================================================================
     * Form dynamics
     * ============================================================================
     */
     handleStageChange: function(component, event, helper) {
        helper.setStageProperties(component);
    },

    handleTypeChange : function(component, event, helper) {
        helper.setFieldProperties(component);
    },

    handleVanityChange : function(component, event, helper) {
        helper.setVanityProperties(component);
    },

    handleHolesChange :  function(component, event, helper) {
        helper.setSpreadProperties(component);
    },

    handleSinkTypeChange :  function(component, event, helper) {
        helper.setSinkProperties(component);
    },

    handleSinkOverflowChange : function(component, event, helper) {
        helper.setOverflowProperties(component);
    }, 
    
    handleCabinetryChange : function(component, event, helper) {
        helper.setCabinetryProperties(component);
    }, 

    handleWaterfallChange : function(component, event, helper) {
        helper.setWaterfallProperties(component);
    }, 

    handleBuildingChange : function(component, event, helper) {
        helper.setBuildingProperties(component);
    }, 
    
    handleMaterialChange : function(component, event, helper) {
        helper.setMaterialProperties(component);
    }, 

    handleRequestChange: function(component, event, helper) {
        helper.setRequestFormProperties(component);
    },

    /**
     * Upload files management
     * vvvvvvvvvvvvvvvvvvvvvvv
     */
    handleUploadFile : function (component, event, helper) {
        var full = component.get("v.hasFullAccess");
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
        helper.setAttachmentFlags(component, attachments);
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
    }, // handleDeleteFileClick

   handleDeleteFileClick : function (component, event, helper) {
        var fullAccess = component.get("v.hasFullAccess");
        var dt = component.find("attachmentsDT");
        var rows = dt.getSelectedRows();
        if (rows.length == 0) {
            helper.displayEmptySelectionToast(component);
            return;
        }
        for (var i = 0; i< rows.length; i++) {
            var row = rows[i];
            if (!fullAccess && (row.documentType == 'QUOTE' || row.documentType == 'DRAWING')) {
                component.find('notifLib').showToast({
                    "variant": "error" ,
                    "title": $A.get("$Label.c.dict_error") + '!',
                    "message": $A.get("$Label.c.opp_cpNoDeleteFiles")
                });                                
                return;
            }
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
                var rows = [].push(row);
                helper.downloadAttachments(component, rows);
                break;
            case 'view':
                var url = helper.buildDownloadURL(row.id);
                window.open(url);
                break;
        }
    }, // handleFileAction
  
    /**
     * Custom Project Request Form methods
     * vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
     */
    handleRequestSubmit : function(component, event, helper) {    
        event.preventDefault(); 
        //var fields = event.getParam('fields');
        var record = component.get("v.currentRequest");
        /*
        if (record.ProductDescription__c) {
            component.find('formMessage').setError('Esto es un error');
            return;  
        }
        */
        var lineNo = record.lineNo;
        var lines = component.get("v.requestLines");
        if (lineNo == -1) {
            record.lineNo = lines.length + 1;
            lines.push(record);
        } else {
            lines[lineNo - 1] = record;
        }
        component.set("v.requestLines", lines);
        component.set('v.isExpanded',false);
    },
  
    handleRowAction : function(component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        var lineNo = row.lineNo - 1;
        switch (action.name) {
            case 'edit':
                if (lineNo != null && lineNo >= 0) {
                    helper.editRequestLine(component, lineNo);
                }
                break;
            case 'delete':
                if (lineNo != null && lineNo >= 0) {
                    helper.deleteRequestLine(component, lineNo);
                }
                break;
            case 'undelete':
                if (lineNo != null && lineNo >= 0) {
                    helper.undeleteRequestLine(component, lineNo);
                }
                break;    
        }        
    }, // handleRowAction
  
})