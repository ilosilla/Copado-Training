({
    /**
     * SERVER INTERACTION #1:
     * ======================
     * Method to load the custom request when loading the object
     */
     readCustomProjectData : function(component, projectId) {        
        component.set("v.showSpinner", true);
        var action = component.get("c.readCustomProjectData");
        action.setParams({
            opportunityId : component.get("v.opportunityId"),
            customProjectId : projectId
        });            
        action.setCallback(this, response => this.readCustomProjectDataCallback(component, response));
        $A.enqueueAction(action);                    
    }, // readCustomProjectData

    readCustomProjectDataCallback : function(component, response) { 
        var state = response.getState();
        if (state === "SUCCESS") {  
            component.set("v.currentPhase", "loaded");
            var dto = response.getReturnValue();                
            if (dto != null) {
                this.setAttachments(component, dto.attachments);
                if (component.get("v.createMode") == true) {
                    var currencyField = component.find("currencyCode");
                    currencyField.set("v.value", dto.currencyCode);
                }
                component.set("v.oppOwner", dto.opportunity.Owner.Name);                
                component.set("v.managers", dto.productManagers);
                component.set("v.hasFullAccess", (dto.isAdmin||dto.isProductManager||dto.isProjectsStaff));
                //component.set("v.hasFullAccess", false);
                component.set("v.requestLines", this.transformRequestLines(dto.requestLines));
                component.set("v.location", dto.location);
                component.set("v.userName", dto.userName);
                this.setupScreen(component);
                this.displayAttachmentsWarning(component, true);
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
     * Saves the custom object
     * NOT USED FOR THE MOMENT
     */
     saveCustomProject : function (component, customProject) {
        component.set("v.showSpinner", true);
        // Valida el customProject        
        /*
        var action = component.get("c.saveCustomProject");
        action.setParams({
            customProject : customProject
        });            
        action.setCallback(this, response => this.saveCustomProjectCallback(component, response));
        $A.enqueueAction(action);                    
        */
       // hace la grabación si todo ok
        this.fireComponentEvent(component, dto.command, dto.arg);
        component.set("v.isActive", false);
     }, // saveCustomProject

     saveCustomProjectCallback : function(component, response) {
        component.set("v.showSpinner", false);              
        var state = response.getState();
        if (state === "SUCCESS") {  
            var dto = response.getReturnValue();  
            if (dto.success) {
                this.fireComponentEvent(component, dto.command, dto.arg);
                component.set("v.isActive", false);
            }
        } else if (state === "ERROR") {
            var errors = response.getError();
            if (errors && Array.isArray(errors) && errors.length > 0) {
                alert(errors[0].message);
            }   
            component.set("v.isActive", false);
        }
     }, // saveCustomProjectCallback

    /**
     * SERVER INTERACTION #3:
     * ======================
     * Saves the custom object request form
     */
     saveRequestLines : function (component, projectId) {
        var action = component.get("c.saveRequestLines");
        var requestLines = component.get("v.requestLines");
        var deleteLines = [];
        var updateLines = [];
        for (var i = 0; i < requestLines.length; i++) {
            if (requestLines[i].isDeleted) {
                if (requestLines[i].Id != null) {
                    deleteLines.push(requestLines[i]);
                }
            } else {
                updateLines.push(requestLines[i]);
            }
        }
        action.setParams({
            projectId : projectId,
            requestLines : updateLines,
            deleteLines : deleteLines
        });            
        action.setCallback(this, response => this.saveRequestLinesCallback(component, response));
        $A.enqueueAction(action);                    
    }, // saveRequestLines

    saveRequestLinesCallback : function(component, response) {
        component.set("v.showSpinner", false);              
        var state = response.getState();
        if (state === "SUCCESS") {                          
            var lines = response.getReturnValue();  
            component.set("v.requestLines", lines);            
            component.set("v.isActive", false);
            component.set("v.showSpinner", false);
            var createMode = component.get("v.createMode");
            var action = "MODIFY";
            if (createMode) {
                action = "INSERT";
            }
            component.set("v.createMode", false);
            this.fireComponentEvent(component, action, component.get("v.customProjectId"));                        
        } else if (state === "ERROR") {
            var errors = response.getError();
            if (errors && Array.isArray(errors) && errors.length > 0) {
                alert(errors[0].message);
            }   
            component.set("v.isActive", false);
        }
     }, // saveRequestLinesCallback

  /**
     * SERVER INTERACTION #4:
     * ======================
     * Executes after uploading a file
     */
    afterUploadFile : function (component, contentIds, contentType) {
        var pid = component.get("v.customProjectId")
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
     * SERVER INTERACTION #5:
     * ======================
     * Deletes the selected files
     */
    deleteFiles : function (component, ids) {
        component.set("v.showSpinner", true);
        var pid = component.get("v.customProjectId")
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


     /******************** END OF SERVER INTERACTIONS *****************/

     validateProject : function (component) {
         var isCorrect = true;
         var errorList = [];
        // Projects needs to have at least a request item
        // except semi custom projects        
        var isSemiCustom = component.find("SemiCustom__c").get("v.value");
        if (!isSemiCustom) {
            var items = component.get("v.requestLines");
            if (items.length == 0) {
                isCorrect = false;
                errorList.push($A.get('$Label.c.opp_cpSaveError1'));
            }
        }
        this.showAppErrors(component, errorList);
        return isCorrect;
     },

    setupScreen : function(component) {
        this.setFieldProperties(component);
        this.setSpreadProperties(component);
        this.setSinkProperties(component);
        this.setCabinetryProperties(component);
        this.setWaterfallProperties(component);
        this.setBuildingProperties(component);
        this.setStageProperties(component);
        this.setMaterialProperties(component);
    }, 

    fireComponentEvent : function(component, command, arg) {
        var cmpEvent = component.getEvent("cmpCommand");
        cmpEvent.setParams({
            "command" : command, 
            "arg" : arg
        });
        cmpEvent.fire();
    },

    transformRequestLines : function(requestLines) {
        var result = [];
        for (var i = 0; i < requestLines.length; i++) {
            requestLines[i].lineNo = i+1;
            requestLines[i].isDeleted= false;  
            requestLines[i].displayIconName = "";  
        }
        return requestLines;
    }, // transformRequestLines

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

    setFieldProperties : function(component) {
        var projectTypeField = component.find("ProjectType__c");
        var isSemiCustomField = component.find("SemiCustom__c");
        var vanityTypeField = component.find("VanityType__c");        
        var vanityByField = component.find("VanityBy__c");        

        var projectType = projectTypeField.get("v.value");
        var isSemiCustom = isSemiCustomField.get("v.value");
        if (projectType != null && projectType.toUpperCase() == "KRION") {
            isSemiCustomField.set("v.disabled", false);
        } else {
            isSemiCustom = false;
            isSemiCustomField.set("v.value", isSemiCustom);
            isSemiCustomField.set("v.disabled", true);
        }        
        vanityTypeField.set("v.disabled", !isSemiCustom);
        if (!isSemiCustom) {
            vanityTypeField.set("v.value", null);
        } else {            
            component.find("FaucetHoles__c").set("v.value", null);
            component.find("FaucetSpread__c").set("v.value", null);    
            component.find("SinkModelNo__c").set("v.value", null);
            component.find("SinkType__c").set("v.value", null);
            component.find("SinkDescription__c").set("v.value", null);
        }

        // Sing and Faucet Info
        component.find("FaucetHoles__c").set("v.disabled", isSemiCustom);
        component.find("FaucetSpread__c").set("v.disabled", isSemiCustom);
        component.find("SinkModelNo__c").set("v.disabled", isSemiCustom);
        component.find("SinkType__c").set("v.disabled", isSemiCustom);
        component.find("SinkDescription__c").set("v.disabled", isSemiCustom);
        this.setVanityProperties(component);
    }, // setFieldProperties

    setVanityProperties : function(component) {
        var vanityTypeField = component.find("VanityType__c");        
        var vanityByField = component.find("VanityBy__c"); 
        var vtype = vanityTypeField.get("v.value");
        if ((vtype == "KOLE")||(vtype == "RAS")) {
            vanityByField.set("v.disabled", false);
        } else {
            vanityByField.set("v.disabled", true);
            vanityByField.set("v.value", null);
        }
    }, // setVanityProperties

    setSpreadProperties : function(component) {
        var holesField = component.find("FaucetHoles__c");
        var spreadField = component.find("FaucetSpread__c");
        var holes = holesField.get("v.value");
        if (holes ==  "N/A" || holes ==  "1") {
            spreadField.set("v.disabled", false);
        } else {
            spreadField.set("v.disabled", true);
            spreadField.set("v.value", null);
        }
    }, // setSpreadProperties

    setSinkProperties : function(component) {
        var sinkTypeField = component.find("SinkType__c");
        var sinkType = sinkTypeField.get("v.value");
        var isKrion = (sinkType && sinkType.toUpperCase().includes("KRION"));        
        var isCustom = (sinkType && sinkType.toUpperCase().includes("CUSTOM"));        
        component.set("v.isKrionSink", isKrion);
        component.set("v.isCustomSink", isCustom);   
        if (!isKrion) {
            component.find("SinkModelNo__c").set("v.value", null);
            component.find("SinkDescription__c").set("v.value", null);
        }
        if (!isCustom) {
            component.find("CustomSinkSize__c").set("v.value", null);
            component.find("SinkOverflow__c").set("v.value", null);
            component.find("OverflowLocation__c").set("v.value", null);
        }        
    }, // setSinkTypeProperties

    setOverflowProperties : function(component) {
        var overflow = component.find("SinkOverflow__c").get("v.value");
        component.find("OverflowLocation__c").set("v.disabled", (overflow != "YES"));
        if (overflow != "YES") {
            component.find("OverflowLocation__c").set("v.value", null);
        }
    }, // setOverflowProperties
    
    setCabinetryProperties : function(component) {
        var cabinetry = component.find("CustomCabinetry__c").get("v.value");
        component.find("RelatedOpportunity__c").set("v.disabled", (cabinetry != "YES"));
    }, // setCabinetryProperties

    setWaterfallProperties : function(component) {
        var waterfall = component.find("WaterfallLegs__c").get("v.value");
        component.find("LegsNumber__c").set("v.disabled", (waterfall != "YES"));
    }, // setCabinetryProperties

    setBuildingProperties:  function(component) {
        var building = component.find("BuildingType__c").get("v.value");
        var isBuilding = false;
        if (building) {
            isBuilding = (building.toUpperCase().includes("BUILDING"));
        }        
        component.find("FloorNumber__c").set("v.disabled", !isBuilding);
        component.find("Elevator__c").set("v.disabled", !isBuilding);
        if (!isBuilding) {
            component.find("FloorNumber__c").set("v.value", null);
            component.find("Elevator__c").set("v.value", null);    
        }
    }, // setBuildingProperties

    setStageProperties : function(component) {        
        var stage = component.find("Stage__c").get("v.value");
        var required = (stage == ' PAYMENT-RECEIVED' || stage == 'DEPOSIT');
        component.find('IsMaterialInStock__c').set('v.required', required);
        var disabled = (stage != 'PAYMENT-RECEIVED');
        component.find('MaterialOrdered__c').set('v.disabled', disabled);
    },

    setMaterialProperties : function(component) {
        var released = component.find('MaterialReleased__c').get('v.value');
        var required = (released == 'YES');
        component.find('FabricatorSAPOrder__c').set('v.required', required);
        component.find('MatReleaseDetails__c').set('v.required', required);
    },

    setRequestFormProperties : function(component) {
        var edge = component.find("Edge__c").get("v.value");
        var backs = component.find("BacksplashDetail__c").get("v.value");
        component.find("EdgeThickness__c").set("v.required", (edge!==""));
        component.find("BacksplashHeight__c").set("v.required", (backs!==""));
    },

    addNewRequestLine : function(component) {        
        var line = {};
        line.lineNo = -1;
        line.ProductDescription__c = "";
        line.ColorName__c = "";
        line.Finish__c = "";
        line.Edge__c = "";
        line.EdgeThickness__c = "";
        line.BacksplashDetail__c = "";
        line.BacksplashHeight__c = "";
        line.Underlayment__c = "";
        component.set("v.submitRequestLabel", $A.get("$Label.c.dict_addItem"));
        component.set("v.currentRequest", line);
        component.set("v.isExpanded",true);
        this.setRequestFormProperties(component);
    },

    editRequestLine : function(component, index) {        
        var lines = component.get("v.requestLines");
        var line = lines[index];
        if (!line.isDeleted) {
            component.set("v.submitRequestLabel", $A.get("$Label.c.dict_updateItem"));
            component.set("v.currentRequest", line);
            component.set("v.isExpanded",true);
        } else {
            this.showToast(component, "warning", $A.get("$Label.c.dict_itemIsDeleted"));
        }
    },    

    showToast : function(component, variant, message) {
        component.find("notifLib").showToast({
            "variant": variant,
            "title": "",
            "message": message
        });
    },

    handleShowNotice : function(component) {
        component.find("notifLib").showNotice({
            "variant": "error",
            "header": "Something has gone wrong!",
            "message": "Unfortunately, there was a problem updating the record."
        });
    },    
    
    deleteRequestLine : function(component, index) {        
        var lines = component.get("v.requestLines");
        lines[index].isDeleted = true;
        lines[index].displayIconName = "utility:delete";  
        component.set("v.requestLines", lines);
    },    

    undeleteRequestLine : function(component, index) {        
        var lines = component.get("v.requestLines");
        lines[index].isDeleted = false;
        lines[index].displayIconName = "";  
        component.set("v.requestLines", lines);
    },    


    setTableColumns : function(component) {
        var cols = new Array();

        var actions = [
            { label: $A.get("$Label.c.dict_edit"), name: "edit" },
            { label: $A.get("$Label.c.dict_delete"), name: "delete" },
            { label: $A.get("$Label.c.dict_undelete"), name: "undelete"}
        ];

        /*cols.push({
            label:  "lineNo",
            fieldName: "lineNo",
            type: "text",
            cellAttributes: { class: "highlighted-column"}
        });*/

        cols.push({
            "label": " ",
            "fieldName": "",
            "hideDefaultActions": true,
            "fixedWidth": 50,
            "cellAttributes": {"iconName": {"fieldName": "displayIconName"}}
        }),

        cols.push({
            label:  "Product",
            fieldName: "ProductDescription__c",
            type: "text",
            cellAttributes: { class: "highlighted-column"}
        });

        cols.push({
            label:  "Color",
            fieldName: "ColorName__c",
            type: "text"
        });

        cols.push({
            label:  "Finish",
            fieldName: "Finish__c",
            type: "text"
        });

        cols.push({
            label:  "Edge",
            fieldName: "Edge__c",
            type: "text"
        });

        cols.push({
            label:  "Edge Thickness",
            fieldName: "EdgeThickness__c",
            type: "text"
        });

        cols.push({
            label:  "Backsplash",
            fieldName: "BacksplashDetail__c",
            type: "text"
        });

        cols.push({
            label:  "Backsplash Height",
            fieldName: "BacksplashHeight__c",
            type: "text"
        });

        cols.push({
            label:  "Underlayment",
            fieldName: "Underlayment__c",
            type: "text"
        });

        cols.push({
            type: "action",
            typeAttributes: { rowActions: actions } 
        });

        component.set("v.dtColumns", cols);
    }, // setTableColumns

    setAttachments : function (component, files) {
        this.setAttachmentsLabel(component, files.length );
        this.setAttachmentsColumns(component);
        for (var i = 0; i<files.length; i++) {
            files[i].contentDescription = this.getContentDescription(files[i].documentType);   
            files[i].url = this.buildFileURL(files[i].id);
        }
        component.set("v.attachments", files);
        this.setAttachmentFlags(component, files);
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
        this.setAttachmentFlags(component, attachments);
        this.setAttachmentsLabel(component, attachments.length);
    },

    setAttachmentFlags : function(component, attachments) {
        var hasQuote = false;
        var hasDrawing = false;        
        for (var i=0; i<attachments.length; i++) {
            switch (attachments[i].documentType) {
                case 'QUOTE':
                    hasQuote = true;
                    break;
                case 'DRAWING':
                    hasDrawing = true;
                    break;
            } 
        }
        component.set("v.hasQuote", hasQuote.toString());
        component.set("v.hasDrawing", hasDrawing.toString());
    },

    downloadAttachments : function(component, rows) {
        var fl = document.getElementById("fakeLink");
        for (var i=0; i<rows.length; i++) {
            var url = this.buildDownloadURL(rows[i].id);
            fl.setAttribute("href", url);
            fl.click();   
        }
    },

    displayAttachmentsWarning : function(component, persistent) {
        var mode = "dismissable";
        if (persistent) {
            mode = "sticky";
        }
        var cid = component.get("v.customProjectId");
        var attachments = component.get("v.attachments");
        if (cid != null && (attachments.length == 0)) {
            component.find('notifLib').showToast({
                "mode": mode,
                "variant": "warning",
                "header": $A.get("$Label.c.dict_important") + "!",
                "message": $A.get("$Label.c.opp_cpDrawingWarning")
            });
        } 
    }, // displayDrawingsWarning

    displayEmptySelectionToast : function(component) {
        component.find('notifLib').showToast({
            "variant": "warning" ,
            "title": $A.get("$Label.c.dict_warning") + '!',
            "message": $A.get("$Label.c.dict_emptySelection")
        });                                
    },

    dummy : function() {
        // Por la  coma
    }


})