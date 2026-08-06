({
    /**
     * SERVER INTERACTION #1:
     * ======================
     * Method to load the custom request when loading the object
     */
     readKitchenData : function(component, opportunityId, kitchenId) {       
        component.set("v.showSpinner", true);
        var action = component.get("c.readKitchenData");
        action.setParams({
            opportunityId : opportunityId,
            kitchenId : kitchenId
        });            
        action.setCallback(this, response => this.readKitchenDataCallback(component, response));
        $A.enqueueAction(action);                    
    }, // readCustomProjectData

    readKitchenDataCallback : function(component, response) { 
        var state = response.getState();
        if (state === "SUCCESS") {  
            var createMode = component.get("v.createMode");
            component.set("v.currentPhase", "loaded");
            var dto = response.getReturnValue();                
            if (dto != null) {
                this.setAttachments(component, dto.attachments);
                if (component.get("v.createMode") == true) {
                    var currencyField = component.find("currencyCode");
                    currencyField.set("v.value", dto.currencyCode);
                }
                component.set("v.oppOwner", dto.opportunity.Owner.Name);  
                component.set("v.oppCloseDate", dto.opportunity.CloseDate);  
                component.set("v.managersList", dto.managers);
                component.set("v.designersList", dto.designers);
                component.set("v.location", dto.location);
                component.set("v.userName", dto.userName);
                if (dto.isNew) {
                    component.find("currencyCode").set("v.value", dto.currencyCode);
                }
                this.setupScreen(component);

            } 
        } else if (state === "ERROR") {
            component.set("v.isActive", false);
            this.handleException(component, response.getError());
        }
        component.set("v.showSpinner", false);              
    }, // setComponentData

  /**
     * SERVER INTERACTION #2:
     * ======================
     * Executes after uploading a file
     */
    afterUploadFile : function (component, contentIds, contentType) {
        var pid = component.get("v.kitchenId");
        var action = component.get("c.afterUploadFile");
        action.setParams({
            projectId : pid, 
            contentIds : contentIds,
            contentType : contentType
        });            
        action.setCallback(this, response => this.afterUploadFileCallback(component, response));
        $A.enqueueAction(action);                    
    }, // afterUploadFile

    afterUploadFileCallback : function(component, response) {
        // por el momento, nada
        var state = response.getState();
        if (state === "SUCCESS") {   
        } else if (state === "ERROR") {
        }
    }, // saveRequestLinesCallback     

      /**
     * SERVER INTERACTION #3
     * ======================
     * DEeletes attachments
     */
    deleteFiles : function (component, ids) {
        component.set("v.showSpinner", true);
        var pid = component.get("v.kitchenId")
        var action = component.get("c.deleteAttachments");
        action.setParams({
            projectId : pid, 
            documentIds : ids
        });            
        action.setCallback(this, response => this.deleteFilesCallback(component, response));
        $A.enqueueAction(action);                    
    }, // deleteFiles

    deleteFilesCallback : function(component, response) {
        component.set("v.showSpinner", true);
        var state = response.getState();
        if (state === "SUCCESS") {   
            this.purgeAttachments(component);
        } else if (state === "ERROR") {
        }
    }, // deleteFilesCallback



    /***************************************************************/
    setupScreen : function(component) {
        this.setInstallationFields(component);
        this.setCurrencyFields(component);
        var manager = component.find("KitchenManager__c").get("v.value");
        this.setManagers(component, manager);
        var designer = component.find("KitchenDesigner__c").get("v.value");
        this.setDesigners(component, designer);
        var attachments = component.get("v.attachments");
        this.setAttachmentsLabel(component, attachments.length );
    },

    kitchenSaved : function(component) {
        component.set("v.isActive", false);
        component.set("v.showSpinner", false);
        var createMode = component.get("v.createMode");
        var action = "MODIFY";
        if (createMode) {
            action = "INSERT";
        }
        component.set("v.createMode", false);
        this.fireComponentEvent(component, action, component.get("v.kitchenId"));                        
    },

    validateProject : function (component) {
        var isCorrect = true;
        var errorList = [];
        this.showAppErrors(component, errorList);
        return isCorrect;
    },

    setManagers : function(component, managerId) {        
        var options = [];
        var defaultOption = null;
        var list = component.get("v.managersList");
        for (var i = 0; i < list.length; i++) {
            var opt = new Object();
            opt.value = list[i].Id;
            opt.label = list[i].Name;
            opt.selected = (opt.value == managerId);
            if (opt.selected) {
                defaultOption = opt.value;
            }
            if (defaultOption == null) {
                defaultOption = opt.value;
            }
            options.push(opt);
        }
        component.set('v.managers', options);
        component.set("v.kManager", defaultOption);
    },

    setDesigners : function(component, designerId) {        
        var defaultItem = null;
        var designers = [];
        var designersList = component.get("v.designersList");
        var managerId = component.get("v.kManager");
        if (managerId != null) {
            for (var i = 0; i < designersList.length; i++) {
                if (designersList[i].Manager__c == managerId) {
                    var opt = new Object();
                    opt.value = designersList[i].Designer__c;
                    opt.label = designersList[i].Designer__r.Name;
                    opt.selected = (opt.value == designerId);
                    if (defaultItem == null) {
                        defaultItem = opt.value;
                    }
                    if (opt.selected) {
                        defaultItem = opt.value;
                    }
                    designers.push(opt);
                }
            }
        }
        component.set('v.designers', designers);
        component.set("v.kDesigner", defaultItem);
    },

    handleException : function(component, errors) {
        var errorMessage;
        if (errors && Array.isArray(errors) && errors.length > 0) {
            errorMessage = errors[0].message;
        }
        $A.get("e.force:closeQuickAction").fire();
        component.find("notifLib").showNotice({
            "variant": "error",
            "header": "Something has gone wrong!",
            "message": errorMessage,
            closeCallback: function() {}
        });      
    }, // handleErrors   
    
    showAppErrors : function(component, errors) {
        if (errors.length > 0) {
            var errorText = '';
            for (var i = 0; i < errors.length; i++) {
                errorText += '\n   - ' + errors[i];
            }
            component.find("notifLib").showToast({
                "mode" : "sticky",
                "variant": "error",
                "title": $A.get('$Label.c.app_review_errors'),
                "message": errorText
            });                
        }        
    },

    setInstallationFields : function(component) {
        var fld = component.find("Installation__c");
        var val = fld.get("v.value");
        var target = component.find("EstimatedInstallation__c");
        target.set("v.required", (val == 'YES'));
    },

    setCurrencyFields : function(component) {
        var ccode = component.find("currencyCode").get("v.value");
        var text = $A.get("$Label.c.dict_currencyHelpTex");
        component.set("v.amountsHelpText", text.replace('&1', ccode));
    },

    fireComponentEvent : function(component, command, arg) {
        var cmpEvent = component.getEvent("cmpCommand");
        cmpEvent.setParams({
            "command" : command, 
            "arg" : arg
        });
        cmpEvent.fire();
    },

    /******************************************************************
     * Attachment functions
     ******************************************************************/

    setAttachments : function (component, files) {
        this.setAttachmentsLabel(component, files.length );
        this.setAttachmentsColumns(component);
        for (var i = 0; i<files.length; i++) {
            files[i].contentDescription = this.getContentDescription(files[i].documentType);   
            files[i].url = this.buildFileURL(files[i].id);
        }
        component.set("v.attachments", files);
    }, // setAttachments    



    buildFileURL : function(fileId) {
        return window.location.host + '/lightning/r/ContentDocument/' + fileId + '/view';
    }, // buildFileURL

    buildDownloadURL : function(fileId) {
        return window.location.protocol + '//' + window.location.host + '/sfc/servlet.shepherd/document/download/' + fileId;
    }, // buildFileURL    

    getContentDescription : function(docType) {
        var description = "";
        switch (docType) {
            case "QUOTE":
                description = $A.get("$Label.c.opp_cpFileQuote");
                break;

            case "DRAWING":
                description = $A.get("$Label.c.opp_cpFileDrawing");
                break;

            default:
                description = $A.get("$Label.c.opp_cpFileOther");
                break;
        }        
        return description;    
    }, // getContentDescription
    
    setAttachmentsLabel : function (component, numFiles) {
        var label = $A.get("$Label.c.dict_files") + " (" + numFiles +")";
        var tabLabel = component.find("CPFilesTab").get("v.label");
        if (tabLabel) {
            tabLabel[0].set("v.value", label);
        }
    },
    
    setAttachmentsColumns : function(component) {
        var cols = new Array();

        var actions = [
            //{ label: $A.get("$Label.c.dict_edit"), name: "edit" }
        ];

        // Id, Title, Description, CreatedDate, FileExtension, FileType f

        /*cols.push({
            "label": "Id",
            "fieldName": "Id",
            "hideDefaultActions": true
        });*/

        cols.push({
            label: "File",
            fieldName: "url",
            type: "url", 
            hideDefaultActions: true,
            cellAttributes: { iconName: "utility:attach", class: "highlighted-column" },
            typeAttributes: {label: { fieldName : "fileName", target: "_blank"} }
        });

        cols.push({
            label: '', 
            iconName: 'utility:download',
            type: 'button-icon', 
            initialWidth: 50, 
            typeAttributes: { title: 'Click to download', name: 'download', iconName: 'action:download', variant: 'bare'}
        });            

        cols.push({
            label: "Uploaded",
            fieldName: "createdDate",
            type: "date",
            typeAttributes: "",
            hideDefaultActions: true
        });

        cols.push({
            label: "Created By",
            fieldName: "createdBy",
            typeAttributes: "",
            hideDefaultActions: true
        });

        cols.push({
            label: "Content Type",
            fieldName: "contentDescription",
            typeAttributes: "",
            hideDefaultActions: true
        });

        /*
        cols.push({
            type: "action",
            typeAttributes: { rowActions: actions } 
        });
        */

        component.set("v.attColumns", cols);
    }, //  setAttachmentsLabel

    purgeAttachments : function (component) {
        component.set("v.showSpinner", false);
        var deleted = component.find("attachmentsDT").getSelectedRows();    
        var attachments = component.get("v.attachments");
        for (var i=0; i<deleted.length; i++) {
            var index = attachments.indexOf(deleted[i]);
            if (index >= 0) {
                attachments.splice(index, 1);
            }
        }
        component.set("v.attachments", attachments);
        this.setAttachmentsLabel(component, attachments.length);
    },

    displayEmptySelectionToast : function(component) {
        component.find('notifLib').showToast({
            "variant": "warning" ,
            "title": $A.get("$Label.c.dict_warning") + '!',
            "message": $A.get("$Label.c.dict_emptySelection")
        });                                
    },

    downloadAttachments : function(component, rows) {
        var fl = document.getElementById("fakeLink");
        for (var i=0; i<rows.length; i++) {
            var url = this.buildDownloadURL(rows[i].id);
            fl.setAttribute("href", url);
            fl.click();   
        }
    },

})