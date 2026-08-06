import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getCountryLocale } from 'c/libAddressCommons';
import hasApprovalPermission from "@salesforce/customPermission/CASEApproveCollections";
import LightningAlert from 'lightning/alert';
import LightningPrompt from 'lightning/prompt';
import Id from '@salesforce/user/Id';
import objectCreatedLabel from '@salesforce/label/c.dict_objectCreated';
import caseLabel from '@salesforce/label/c.dict_case';
import LightningConfirm from 'lightning/confirm';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

// Controller methods
import readInvoiceData from '@salesforce/apex/CaseInvoiceSearchController.readInvoiceData';
import readCaseParameters from '@salesforce/apex/SAPCasesController.readCaseParameters';
import saveSAPCase from '@salesforce/apex/SAPCasesController.saveSAPCase';
import createSAPCollection from '@salesforce/apex/SAPCasesController.createSAPCollection';
import requestApproval from  '@salesforce/apex/SAPCasesController.requestApproval';


// Labels (i18n)
import { LABELS } from './labels';

export default class CaseCollectionLWC extends NavigationMixin(LightningElement) {

    // =======================================================================================
    // API
    // =======================================================================================
    @api recordId;
    @api invoiceNumber;
    @api invoiceData;

    @api
        save() {
            this.handleSaveClick();
        }

    labels = LABELS

    // Collection items grid definition
    columns = [
        { label: this.labels.dict_product_code, fieldName: 'productCode',
            cellAttributes: {
                style: {fieldName: 'style'},
                iconName: { fieldName: 'iconName' },
                iconPosition: 'right'
            }
        },
        { label: this.labels.dict_productName, fieldName: 'productName', cellAttributes: {style: {fieldName: 'style'}}},
        { label: this.labels.dict_stock_program, fieldName: 'isStockProgram', type: 'boolean', cellAttributes: {style: {fieldName: 'style'}}},
        { label: this.labels.dict_quantity_invoiced, fieldName: 'invString', cellAttributes: { style: {fieldName: 'style'}, alignment: 'right' } },
        { label: this.labels.tr0009_111, fieldName: 'colString', cellAttributes: { style: {fieldName: 'style'}, alignment: 'right' } }, // To Collect
        { label: this.labels.dict_stocked, fieldName: 'confString', cellAttributes: { style: {fieldName: 'style'}, alignment: 'right' } },
        { type: 'button', typeAttributes: {
            label: this.labels.dict_collect,
            name: 'COLLECT',
            disabled: {fieldName: 'isDisabled'}
        }}
    ];

    // { label: 'BOX to Collect', fieldName: 'colBoxes', type: 'number', cellAttributes: { style: {fieldName: 'style'}, alignment: 'right' } },
    // { label: 'PCS to Collect', fieldName: 'colPieces', type: 'number',  cellAttributes: { style: {fieldName: 'style'}, alignment: 'right' } },


    // Labels
    lblTabDetails = this.labels.dict_details;
    lblTabProducts = this.labels.dict_products;

    // Component data
    cmpData = new Object();

    addressObjectId;           // Account Id or Contact Point Address ID for the address
    initialAddressId;

    // COmponent variables
    sapInvoice; // = '6215100036';
    SAPOrderNumber=null;
    SAPDeliveryNumber = null;
    SAPDeliveryStatus = null;
    SAPGoodsPosted = false;
    SAPCreditNoteNumber = null;
    loaded = false;
    currentInvoice = '';
    saveAndNew = false;
    error;
    errorTheme = 'error';
    //wiredData = [];
    invoiceDTO = {};
    collectionAddress = {};
    isLoading = true;
    items = new Array();
    customer;
    salesOrg;
    salesOffice;
    hasWarning = false;
    userId = Id;
    defaultSubject;
    accountId;
    showItemForm = false; 
    UserName;
    sapInvoiceRecordTypeId;    
    debugText;
    mainTitle;
    productCountText = '';
    callbackMethod = null;
    showOrderDialog = false;
    showItemsDialog = false;
    hasSpecialProducts = false;
    linesToCollect = 0;

    currentStatus = null;
    statusBarError = false;
    currentItem;
    currentIndex;
    steps = new Array();
    errorList;
    openAddressesDialog = false;
    formattedAddress;
    approvalRequestedWarning;

    warehouseOptions = [];
    selectedReturnWarehouse = '';

    // Fields not bound in the form (tracked with internal variables)
    customerReturns = false;
    creditRequired = true;
    refundCustomer = false;
    restockFee = true;

    get numItems() {
        return this.items.length;
    }

    get customerReturnsDisabled() {  return this.isCaseInSAP || !this.invoiceDTO.customerReturns;}
    get isCaseInSAP() { return (this.SAPOrderNumber != null && this.SAPOrderNumber != undefined)};
    get isCaseReadonly() { return (this.currentStatus != this.STATUS_NEW);  }
    get hasDeliveryNote() { return (this.SAPDeliveryNumber?.length > 1);}
    get disableDate() { return (this.customerReturns || this.isCaseInSAP); }
    get creditNotIssuedFlag() {
        return !this.creditRequired;
    }

    get isNew() { return (this.currentStatus == this.STATUS_NEW);}
    get isApproved() { return (this.currentStatus == this.STATUS_APPROVED);}
    get isReady() { return (this.currentStatus == this.STATUS_READY);}
    get isCollected() { return (this.currentStatus == this.STATUS_COLLECTED);}
    get isInvoiced() { return (this.currentStatus == this.STATUS_INVOICED);}
    get isClosed() { return (this.currentStatus == this.STATUS_CLOSED);}
    get isRejected() { return (this.currentStatus == this.STATUS_REJECTED);}

    get isNewRecord() { return !this.recordId; }

    get rejectionClass() {
        if (this.isRejected) {
            return 'slds-col slds-size_2-of-2';
        } else {
            return 'slds-hide slds-col slds-size_2-of-2';
        }
    }    

    // Approval variables
    // -----------------------------------

    get isApprover() {
        return hasApprovalPermission;
    }

    get failsPolicy() {
        return this.invoiceDTO.daysWarning ||this.hasSpecialProducts ;
    }

    get approvalDisabled() {
        return (!this.isApprover && this.linesToCollect == 0 && !this.invoiceDTO.daysWarning);
    }

    get canApproveItself() {
        return (this.isApprover || !this.failsPolicy);
    }

    // hasSpecialProducts
    get approvalText() {
        if (this.failsPolicy) {
            return this.labels.tr0009_112; // Then, click on the button below to request approval (the collection does not meet our returns policy).
        } else if (this.linesToCollect === 0) {
            return this.labels.tr0009_113; // Approval might be needed if the products returned are special order products.
        } else if (this.hasSpecialProducts) {
            return this.labels.tr0009_114; // Then, click on the button below to request approval (special order products returned).
        } 
        return this.labels.tr0009_115; // Then, click on the button below to approve it.        
    }
    get needsApproval() {
        if (!this.isNew || this.isApprover) {
            return false;
        } else {
            return this.hasSpecialProducts || (this.invoiceDTO.daysWarning && this.hasRealProducts);
        }
    }

    get sapAddressId() {
        return this.labels.tr0009_105.replace('{sapId}', this.collectionAddress.SAPId);
    }

    get warehouseDisabled() {
        return this.isCaseInSAP || this.warehouseOptions.length === 0;
    }

    get warehouseVisible() {
        return this.warehouseOptions.length > 0;
    }

    //Section classes
    baseClass = "slds-section__title slds-theme_shade";
    activeClass = "slds-section__title slds-theme_info";
    detailsClass = this.baseClass;
    instructionsClass = this.baseClass;

    STATUS_REJECTED = 'Rejected';
    STATUS_NEW = 'New';
    STATUS_APPROVED = 'Approved';
    STATUS_READY = 'Ready';
    STATUS_COLLECTED = 'Collected';
    STATUS_INVOICED = 'Invoiced';
    STATUS_CLOSED = 'Closed';

    AUTOMATIC_STATUS = this.STATUS_READY + ';' + this.STATUS_COLLECTED + ';' + this.STATUS_INVOICED + ';' + this.STATUS_CLOSED + ';';

    HINT_NEW        = this.labels.tr0009_116; // Please enter all the details of the collection and select the products you wish to include.
    HINT_APPROVED   = this.labels.tr0009_117; // Please complete the collection instructions and click the button below to create the SAP Returns Order.
    HINT_READY      = this.HINT_READY_1;
    HINT_COLLECTED  = this.labels.tr0009_118; // The received items have been inspected and those in good condition have been restocked...
    HINT_INVOICED   = this.labels.tr0009_119; // The credit note has been issued...
    HINT_CLOSED     = this.labels.tr0009_120; // Case closed: The goods have been received...
    HINT_REJECTED   = this.labels.tr0009_121; // The collection has been rejected...

    HINT_READY_1    = this.labels.tr0009_122; // The case has been forwarded to SAP...
    HINT_READY_2    = this.labels.tr0009_123; // A Delivery Note has been issued in SAP...

    // =======================================================================================
    // WIRED
    // =======================================================================================

    // Reads some constants from the server (like the collection record type id)
    @wire(readCaseParameters)
        wiredParams({ error, data }) {
            if (data) {
                this.error = undefined;
                this.sapInvoiceRecordTypeId = data.sapInvoiceRecordTypeId;
            } else if (error) {
                this.error = error;
                this.errorTheme = 'error';
                this.sapInvoiceRecordTypeId = undefined;
            }
        }

    // =======================================================================================
    // LIFECYCLE HOOKS
    // =======================================================================================

    connectedCallback() {
        if (!this.recordId) {
            if (this.invoiceData) {
                this.mainTitle = this.labels.tr0009_124; // 'New Case: Collection';
                this.sapInvoice = this.invoiceNumber;
                this.invoiceDTO = this.invoiceData;
                this.setInvoiceInfo();
                this.currentInvoice = this.sapInvoice;
                this.setProductCount();    
            }   
        }
    }

    renderedCallback(event) {
    }

    stringifyEvent(e) {
        const obj = {};
        for (let k in e) {
          obj[k] = e[k];
        }
        return JSON.stringify(obj, (k, v) => {
          if (v instanceof Node) return 'Node';
          if (v instanceof Window) return 'Window';
          return v;
        }, ' ');
      }

    // Case loaded
    handleRecordLoad(event) {
        if (this.recordId) {
            try {     
                let caseFields = event.detail.records[this.recordId].fields;
                this.defaultSubject = caseFields.Subject.value;                
                this.mainTitle = this.defaultSubject;
                this.sapInvoice = caseFields.SAPInvoice__c.value;
                this.customerReturns = caseFields.CustomerReturns__c.value;
                this.creditRequired = caseFields.CreditRequired__c.value;
                this.refundCustomer = caseFields.RefundCustomer__c.value;
                this.restockFee = caseFields.RestockFee__c.value;
                this.currentStatus = caseFields.Status.value;      
                this.buildStatusPath(event.detail.picklistValues.Status);                
                if (caseFields.ContactPointAddress__c.value == null) {
                    this.addressObjectId = caseFields.AccountId.value;
                } else {
                    this.addressObjectId = caseFields.ContactPointAddress__c.value;
                }
                this.initialAddressId = this.addressObjectId;                
                this.SAPOrderNumber = caseFields.SAPOrderNumber__c.value;
                this.SAPDeliveryNumber = caseFields.SAPDeliveryNumber__c.value;
                this.SAPDeliveryStatus = caseFields.SAPDeliveryStatus__c.value;
                this.SAPCreditNoteNumber = caseFields.SAPCreditNote__c.value;
                this.SAPGoodsPosted = caseFields.SAPGoodsPosted__c.value;
                this.selectedReturnWarehouse = caseFields.SAPWarehouse__c.value;
                this.setApprovalRequestedWarning(caseFields.ApprovalRequested__c.value);
                this.readSAPInvoice();
            } catch (ex) {     
                this.clog('Error received in handleRecordLoad ' + ex + ' o ' + JSON.stringify(ex));
            }            
        } else { 
            if (this.sapInvoiceRecordTypeId && this.sapInvoiceRecordTypeId == event.detail.layout.recordTypeId) {                
                this.currentStatus = event.detail.picklistValues.Status.defaultValue.value;
                this.buildStatusPath(event.detail.picklistValues.Status);                
                this.setStatusFlags();
                this.setApprovalRequestedWarning(undefined);           
                this.loaded = true;
                this.isLoading = false;                
            }    
        }
    } // handleLoad

    // =======================================================================================
    // EVENT HANDLERS
    // =======================================================================================

    /**
     * Account address has been read
     */
    handleCollectionAddressReady(event) {
        this.collectionAddress = event.detail;
    }

    /**
     * Change address button
     */
    handleAddressChange(event) {
        this.openAddressesDialog = true;
    }

    handleAddressCancel(event) {
        this.openAddressesDialog = false;
    }

    handleAddressSelect(event) {
        this.openAddressesDialog = false;
        this.collectionAddress = event.detail; 
        this.collectionAddress.Locale = getCountryLocale(this.collectionAddress.CountryCode);        
        this.addressObjectId = this.collectionAddress.Id;
        var cpaField = this.template.querySelector('[data-id="ContactPointAddress"]');
        if (this.collectionAddress.isContactPoint) {
            cpaField.value = this.collectionAddress.Id;
        } else {
            cpaField.value = null;
        }
    }

    /**
     * User has cancelled the operation in CaseInvoiceSearch component.    
     */
    handleCancel(event) {
        this.closeCurrentTab();
    } 

    /**
     * Receives the SAP invoice handleCollectionAdd by the user from CaseInvoiceSearch component. 
     */
    handleContinue(event) {
        var dto = event.detail;
        this.sapInvoice = dto.invoiceNumber;
        this.invoiceDTO = dto.invoiceData;
        if (this.invoiceDTO) {
            this.setInvoiceInfo();
            this.setWarehouses();
        }
    }
    
    /**
     * Full Collection button click
     */
    handleFullClick(event) {
        this.items.forEach(item => {
            if (item.lineOK) {
                item.colBoxes = item.invBoxes;
                item.colPieces = item.invPieces;
                item.collected = item.invoiced;
                this.formatQuantities(item);
            }
        });
        this.items = [...this.items];
        this.setProductCount();
    }

    /**
     * Reset button click
     */
    handleResetClick(event) {
        this.items.forEach(item => {
            item.colBoxes = 0;
            item.colPieces = 0;
            item.collected = 0;
            this.formatQuantities(item);
        });
        this.items = [...this.items];
        this.setProductCount();
    }
    
    /**
     * Data table row action (edit item)
     */
    handleRowAction(event) {
        if (event.detail.action.name == 'COLLECT') {
            this.collectItem(event.detail.row);
        }
    } // handleRowAction
    
    /**
     * Cancel edition
     */
    handleCancelClick(event) {
        this.dispatchEvent(new CustomEvent('cancelevent', {}));    
    }

    /**
     * Save and new
     */
    handleSaveAndNewClick(event) {
        this.saveAndNew = true;
        this.saveHandler();
    }
    
    /**
     * Save
     */
    handleSaveClick() {
        this.saveAndNew = false;
        this.saveHandler();
    }

    /**
     * Checks if all fields are ok and submits the form
     */
    saveHandler() {
        var submitButton = this.template.querySelector('[data-id="submitButton"]');
        if(submitButton) {
            this.callbackMethod = null;
            if (this.checkFieldsValidity()) {
                submitButton.click();
            } else {
                // Sets teh first tab as active
                this.template.querySelector('lightning-tabset').activeTabValue = this.lblTabDetails;
            }
        }
    } // saveHandler

    /**
     * Checks all required fgields have a value
     */
    checkFieldsValidity() {
        const allValid = [...this.template.querySelectorAll('lightning-input-field')].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            const fieldOK = (!inputCmp.required || (inputCmp.value != null));
            return validSoFar && fieldOK;
        }, true);
        return allValid;
    }

    /**
     * record-edit-form submit
     */
    handleSubmit(event){
        this.isLoading = true;
        event.preventDefault();       // stop the form from submitting
        let fields = event.detail.fields; 
        this.saveCase(fields);
    }     
        
    /**
     * record-edit-form errors 
     */
    handleErrors(event) {
        this.isLoading = false;
    }
    
    /**
     * record-edit-form success
     */
    handleSuccess(event){        
        const updatedRecord = event.detail.id;   
        var caseNumber = event.detail.fields.CaseNumber.value;
        var message = objectCreatedLabel;
        message = message.replace('{0}', caseLabel);
        message = message.replace('{1}', caseNumber);
        this.showNotification(message);
        if (this.saveAndNew) {
            this.resetForm();
            this.saveAndNew = false;
            this.isLoading = false;  
        } else {
            this.navigateToCasePage(updatedRecord);  
        }        
        //this.closeCurrentTab();
    }    

    //////////////////////////////////////////////////////////////
    // CREATE SAP RETURNS ORDER
    //////////////////////////////////////////////////////////////
    handleCreateOrderButton() {
        this.error = new Array();            
        let SAPOrderNumberField = this.template.querySelector("lightning-input-field[data-id='SAPCreditNumber']");
        if (SAPOrderNumberField.value != null) {
            this.error.push(this.labels.tr0009_125); // There's already a SAP returns order number set
            this.errorTheme = 'warning'; 
            return;
        } 

        // Valida almacén
        if (this.warehouseOptions.length > 1 && this.selectedReturnWarehouse === null) {
            this.error.push(this.labels.tr0009_157); // Please enter a collection date before creating the returns order
            this.errorTheme = 'error';     
            return;
        }

        if (!this.customerReturns) {
            let collectionDate = this.template.querySelector("lightning-input-field[data-id='CollectionDate__c']");
            if (!collectionDate.value) {
                this.error.push(this.labels.tr0009_126); // Please enter a collection date before creating the returns order
                this.errorTheme = 'error';     
                return;
            }
        }

        // Warning si no credit note
        this.confirmOrderCreation();
    }

    async confirmOrderCreation() {
        let text = this.labels.tr0009_127; // This action will save the case and create a returns order in SAP.
    
        if (this.restockFee) {
            text += ' ' + this.labels.tr0009_128; // Please note a RESTOCKING FEE WILL BE APPLIED.
        } else {
            text += ' ' + this.labels.tr0009_129; // Please note NO RESTOCKING FEE WILL BE APPLIED.
        }
    
        text += ' ' + this.labels.tr0009_130; // Future modifications will need to be made directly in SAP. Continue?
    
        const result = await LightningConfirm.open({
            message: text,
            variant: 'header',
            label: this.labels.tr0009_131, // SAP Returns Order
            theme: 'Warning'
        });
    
        if (result) {
            var submitButton = this.template.querySelector('[data-id="submitButton"]');
            if (submitButton) {
                this.callbackMethod = this.createReturnsOrder;
                this.saveAndNew = false;
                submitButton.click();
            }
        }
    }
        
    createReturnsOrder() {
        createSAPCollection({ caseId: this.recordId })
        .then((result) => {                  
            this.SAPOrderNumber = result.orderNumber;            
            const restockingCharges = result.restockingCharges;            
            this.currentStatus = this.STATUS_READY; 
            const orderField = this.template.querySelector('[data-id="SAPOrderNumber"]');
            if (orderField) {
                orderField.value = this.SAPOrderNumber;
            }
            this.notifyOrderCreated(result.orderNumber, restockingCharges);
        })
        .catch((error) => {
            console.error('==> Error in caseCollectionLWC.createReturnsOrder (1): ' + error);
            console.error('==> Error in caseCollectionLWC.createReturnsOrder (2): ' + JSON.stringify(error));
            this.errorTheme = 'error';
            this.error = error;
        })
        .finally(() => {
            this.isLoading = false;
        });            
    } // createReturnsOrder

    /**
     * Handles clicks on the path
     */
    handleStatusPathClick(event) {
        const newStatus = event.target.value;
        this.statusBarError = false;
        this.error = '';

        if (this.isCaseInSAP && (newStatus == this.STATUS_NEW || newStatus == this.STATUS_APPROVED)) {
            this.showToast(this.labels.tr0009_132, 'warning', 'dismissible'); // Status unreachable (case already in SAP)
            this.statusBarError = true;
            this.errorTheme = 'warning';

        } else if (newStatus == this.STATUS_APPROVED && !this.Approved__c && !this.isApprover) {
            this.showToast(this.labels.tr0009_133, 'warning', 'dismissible'); // Please request approval from an authorized user by clicking the designated button
            this.statusBarError = true;

        } else if (newStatus == this.STATUS_NEW && this.currentStatus == this.STATUS_APPROVED) {
            this.confirmRemoveApproval();

        } else if (this.AUTOMATIC_STATUS.includes(newStatus)) {
            this.showToast(this.labels.tr0009_134, 'warning', 'dismissible'); // This is an automatic status. The system will determine it as the collection progresses in SAP.
            this.statusBarError = true;

        } else if (newStatus == this.STATUS_REJECTED) {
            this.setRejectedStatus();

        } else {
            this.currentStatus = newStatus;
        }

        this.setStatusFlags();
    }

    handleApproveButton() {
        this.currentStatus = this.STATUS_APPROVED;
        this.setStatusFlags();
    }    

    handleRequestApprovalButton() {
        this.confirmRequestApproval();
    }

    async confirmRequestApproval() {
        let text = this.labels.tr0009_135; // The case will be saved and an email will be sent...
        const result = await LightningConfirm.open({
            message: text,
            variant: 'header',
            label: this.labels.dict_approval_request, // Approval Request
            theme: 'Warning'
        });
        if (result) {     
            var submitButton = this.template.querySelector('[data-id="submitButton"]');
            if (submitButton) {
                this.callbackMethod = this.doRequestApproval;
                this.saveAndNew = false;
                submitButton.click();
            }        
        }
    }
    
    async confirmRemoveApproval() {
        let text = this.labels.tr0009_136; // By reverting to the NEW status...
        const result = await LightningConfirm.open({
            message: text,
            variant: 'header',
            label: this.labels.dict_confirmation, // Confirmation
            theme: 'Warning'
        });
        if (result) {
            this.currentStatus = this.STATUS_NEW;
            this.setStatusFlags();
        }
    }

    doRequestApproval() {
        requestApproval({ caseId: this.recordId })
        .then((result) => {  
            this.showToast(this.labels.tr0009_153, "success", "dismissible");
            this.setApprovalRequestedWarning(result);
        })
        .catch((error) => {
            this.errorTheme = 'error';
            this.error = error;
        })
        .finally(() => {
            this.isLoading = false;
        });            
    } // createReturnsOrder

    handleReadyButton() {
        this.currentStatus = this.STATUS_READY;
        this.setStatusFlags();
    }    

    handleCollectButton() {
        this.currentStatus = this.STATUS_COLLECTED;
        this.setStatusFlags();
    }    

    handleCloseButton() {
        this.currentStatus = this.STATUS_CLOSED;
        this.setStatusFlags();
    }    

    handleCustomerReturnsChange(event) {   
        this.customerReturns = event.target.checked;
        //this.setCustomerReturnsFields(event.target.checked);
    }

    handleCreditRequiredChange(event) {
        this.creditRequired = event.target.checked;
        // this.setCreditRequiredFields(event.target.checked);
    }

    handleRefundChange(event) {
        this.refundCustomer = event.target.checked;
    }

    handleRestockFeeChange(event) {
        this.restockFee = event.target.checked;
    }

    handleWarehouseChange(event) {
        this.selectedReturnWarehouse = event.detail.value;
    }

    // =======================================================================================
    // METHODS
    // =======================================================================================

    setRejectedStatus() {
        LightningPrompt.open({
            label: this.labels.tr0009_137, // Collection Rejected!
            theme: 'warning',
            message: this.labels.tr0009_138 // Please enter the reason why the case has been rejected
        }).then((result) => {
            if (result) {
                this.currentStatus = this.STATUS_REJECTED;
                var rrField = this.template.querySelector('[data-id="RejectionReason"]');
                if (rrField) {
                    rrField.value = result; 
                }        
            } else {
                this.showToast(this.labels.tr0009_139, 'warning', 'dismissible'); // Status not updated...
            }
        });
    }
    
    resetErrors() {
        this.error = null;
    }    

    setUnboundFields(fields) {
        fields.IsCollection__c = true;
        fields.RecordTypeId = this.sapInvoiceRecordTypeId;
        fields.SAPInvoice__c = this.sapInvoice;
        fields.Id = this.recordId;        
        fields.CreditRequired__c = this.creditRequired;
        fields.RefundCustomer__c = this.refundCustomer;
        fields.CustomerReturns__c = this.customerReturns;
        fields.RestockFee__c = this.restockFee;
        fields.GoodsReceived__c = this.goodsReceived;
        fields.GoodsChecked__c = this.goodsChecked;
        fields.Status = this.currentStatus;
        fields.SAPWarehouse__c = this.selectedReturnWarehouse;
        fields.Approved__c = false;
    }

    buildStatusPath(picklistValues) {
        if (this.steps.length == 0 && picklistValues) {
            // this.currentStatus = this.getStatusValue();
            this.steps = [];
            for (let i = 0; i < picklistValues.values.length; i++) {
                var step = {};
                step.label = picklistValues.values[i].label;
                step.value = picklistValues.values[i].value;
                this.steps.push(step);
            }
        }
    }

    setStatusFlags() {
        if (this.currentStatus) {
            this.setStatusClasses();
        }
    }

    setStatusClasses() {        
        this.detailsClass = this.isNew ? this.activeClass : this.baseClass;
        this.instructionsClass = this.isApproved ? this.activeClass : this.baseClass;               
    }

    setProductCount() {
        var nLines = this.countCollectionLines();
        if (nLines === 0) {
            this.productCountText = this.labels.tr0009_140; // No products included in the collection yet
        } else {
            this.productCountText = this.labels.tr0009_141.replace('{0}', nLines); // {0} lines included in the collection
        }
    }

    readSAPInvoice() {
        if (this.sapInvoice != this.currentInvoice) {
            readInvoiceData({ invoiceNumber: this.sapInvoice, caseId: this.recordId })
                .then((result) => {                    
                    this.invoiceDTO = result;
                    console.log('ME LLEGA EL DATO QUE ESPERO A ' + this.invoiceDTO.customerReturns);
                    this.setInvoiceInfo();
                    this.currentInvoice = this.sapInvoice;
                    this.setProductCount(); 
                    this.setWarehouses();  
                })
                .catch((error) => {
                    this.error = error;
                    this.errorTheme = 'error';
                    alert(JSON.stringify(error));
                    this.showErrorNotification(this.error.body.message);                
                })
                .finally(() => {
                    this.isLoading = false;
                });
        }
    }

    /**
     * Displays the SAP invoice information read from the server
     */
    setInvoiceInfo() {  
        if (this.invoiceDTO.accountId) {
            this.accountId = this.invoiceDTO.accountId;            
        } 
        if (!this.recordId) {
            this.defaultSubject = this.invoiceDTO.accountName + ' ' + this.labels.dict_collection.toUpperCase();  
            this.addressObjectId = this.accountId;
        }          
        this.customer = '[' + this.invoiceDTO.invoiceHeader.SAPCustomer + '] ' + this.invoiceDTO.accountName;
        this.salesOrg = '[' + this.invoiceDTO.invoiceHeader.salesOrg + '] ' + this.invoiceDTO.salesOrgName;
        this.salesOffice = '[' + this.invoiceDTO.invoiceHeader.salesOffice + '] ' + this.invoiceDTO.salesOfficeName;
        this.items = new Array();  
        this.setInvoiceItems(this.invoiceDTO.invoiceLines);
        this.setStatusFlags();
    } // setInvoiceInfo

    setWarehouses() {
        const warehouses = Array.isArray(this.invoiceDTO?.returnWarehouses)
            ? this.invoiceDTO.returnWarehouses
            : [];

        this.warehouseOptions = warehouses
            .filter(warehouse => typeof warehouse === 'string' && warehouse.trim().length > 0)
            .map(warehouse => {
                const value = warehouse.trim();
                return {
                    label: value,
                    value: value
                };
            });

        if (this.warehouseOptions.length === 0) {
            this.selectedReturnWarehouse = '';
            return;
        }

        const selectedExists = this.warehouseOptions.some(
            option => option.value === this.selectedReturnWarehouse
        );

        // Assign default only when there's just one wearehosue
        if (!selectedExists && this.warehouseOptions.length === 1) {
            this.selectedReturnWarehouse = this.warehouseOptions[0].value;
        }
    }

    /**
     * Prepares data for the items data table
     */
    setInvoiceItems(lines) {
        this.items = [];
        for (let i = 0; i<lines.length; i++) {
            const item = {...lines[i]};
            this.formatQuantities(item);
            item.style = 'font-weight:normal;';
            this.items.push(item);
        }
    }

    formatQuantities(item) {
        item.invString = this.formatQuantity(item.invoiced, item.unitLabel);
        item.colString = this.formatQuantity(item.collected, item.unitLabel);
        item.confString = this.formatQuantity(item.confirmed, item.unitLabel);
    }

    formatQuantity(quantity, unit) {
        let f = '';
        if (quantity != 0) {
            f = quantity.toFixed(2) + ' ' + unit;
        }
        return f;
    }

    saveCase(fields) {
        // some default values
        this.isLoading = true;
        this.resetErrors();
        this.setUnboundFields(fields);
        let invLines = this.setQuantitiesToCollect();
        saveSAPCase({ sapCase: fields, strItems: JSON.stringify(invLines)})
            .then((result) => {
                this.recordId = result.Id;
                this.mainTitle = 'Edit "' + this.defaultSubject + '"';
                notifyRecordUpdateAvailable([{recordId: this.recordId}]);
                if (this.callbackMethod == null) {
                    if (this.isNew||this.isApproved) {                        
                        this.showNotification(this.labels.tr0009_142); // Please remember to attach any relevant files...
                    }
                    this.isLoading = false;
                    this.closeCurrentTab();
                } else {                    
                    this.callbackMethod();
                }
            })
            .catch((error) => {
                this.isLoading = false;
                this.errorTheme = 'error';
                this.error = error;
                if (typeof error === 'string') {                    
                    console.error('==> Error in saveCase(): ' + error);
                } else {
                    console.error('==> Error in saveCase(): ' + JSON.stringify(error));
                }
            });            
    }

    countCollectionLines() {
        this.linesToCollect = 0;
        this.hasSpecialProducts = false;
        this.hasRealProducts = false;
        var nLines = 0;
        try {
            for (var i = 0; i < this.items.length; i++) {
                var line = this.items[i];
                if (line.collected > 0) {
                    if (!line.isStockProgram && !line.isService) {
                        this.hasSpecialProducts = true;
                    }
                    if (!line.isService) {
                        this.hasRealProducts = true;
                    }
                    nLines++;
                }
            }
        } catch(error) {}
        this.linesToCollect = nLines;
        return nLines;
    }

    setQuantitiesToCollect() {
        var clonedLines = new Array();
        // clonedLines = this.invoiceDTO.invoiceLines.map((x) => x);
        for (var i = 0; i < this.invoiceDTO.invoiceLines.length; i++) {
            var clonedLine =  Object.assign({}, this.invoiceDTO.invoiceLines[i]);
            var item = this.getItem(clonedLine.lineNo);
            if (item) {
                clonedLine.colBoxes = item.colBoxes;
                clonedLine.colPieces = item.colPieces;
                clonedLine.collected = item.collected;
            }
            clonedLines.push(clonedLine);
        }
        return clonedLines;
    }

    getItem(lineNo) {
        for (let item of this.items) {
            if (item.lineNo == lineNo) {
                return item;
            }
        }
        return undefined;
    }

     resetForm() {
        const inputFields = this.template.querySelectorAll(
            'lightning-input-field'
        );
        if (inputFields) {
            inputFields.forEach(field => {
                field.reset();
            });
        }
        this.sapInvoice = undefined;
     }

    collectItem(item) {
        this.currentItem = item;
        if (this.currentItem) {
            this.setCurrentItemIndex();
            if (!this.currentItem.lineOK) {
                this.productNotFoundAlert(this.currentItem.productCode);
            } else {    
                this.editcurrentItem();    
            }
        }            
    }

    editcurrentItem() {        
        this.setCurrentItemStyle('font-weight:bold;');
        this.showItemForm = true;
     }

    handleEditContinue(event) {
        const item = event.detail;
        this.acceptEditedItem(item);
        this.showItemForm = false;        
    }


    handleEditNext(event) {
        const item = event.detail;
        this.acceptEditedItem(item);        
        if (this.currentIndex < this.items.length - 1) {
            this.currentIndex++;
            this.currentItem = this.items[this.currentIndex];
            this.editcurrentItem();
        }
    }

    handleEditPrevious(event) {
        const item = event.detail;
        this.acceptEditedItem(item);        
        if (this.currentIndex > 0) {
            this.currentIndex--;
            this.currentItem = this.items[this.currentIndex];
            this.editcurrentItem();
        }
    }

    acceptEditedItem(item) {        
        this.currentItem.colBoxes = item.colBoxes;
        this.currentItem.colPieces = item.colPieces;
        this.currentItem.collected = item.collected;
        this.currentItem.colString = this.formatQuantity(this.currentItem.collected, this.currentItem.unitLabel);
        this.currentItem.style = '';
        this.items[this.currentIndex] = this.currentItem;
        this.items = [...this.items];      
        this.setProductCount();  
    }


    handleEditCancel(event) {
        this.setCurrentItemStyle('');
        this.showItemForm = false;
    }

    setCurrentItemStyle(style) {        
        this.items[this.currentIndex].style = style;
        let dtable = this.template.querySelector('lightning-datatable');
        dtable.data = this.items;        
    }

    async notifyOrderCreated(orderNumber, restockingCharges) {
        let message = 'Returs Order #' + orderNumber + ' created in SAP.';
        
        let charges = (1*restockingCharges).toFixed(2);
        if (restockingCharges > 0) {
            message += ' A restocking fee of ' + charges + ' has been applied.';
        } else {
            message += ' No restocking fee has been applied.';
        }
        await LightningAlert.open({
            message: message,
            theme: 'success', 
            label: 'SAP Order Created', 
        });

    }

    async productNotFoundAlert(productCode) {
        var message = this.labels.tr0009_143.replace('{0}', productCode); // This line cannot be collected because Salesforce does not have information about this product ({0})...                    
        await LightningAlert.open({
            message: message,
            theme: 'error', 
            label: 'Error!', 
        });
    }

     getLine(lineNumber) {
        var result = null;
        for (let i = 0; i < this.invoiceDTO.invoiceLines.length; i++) {
            if (this.invoiceDTO.invoiceLines[i].lineNo === lineNumber) {
                result = this.invoiceDTO.invoiceLines[i];
            }       
        }
        return result;
     }

     setCurrentItemIndex() {
        this.currentIndex = -1;
        for (var i = 0; i < this.items.length; i++) {
            if (this.currentItem.lineNo == this.items[i].lineNo) {
                this.currentIndex = i;
                return;
            }
        }
     }

    navigateToCasePage(caseId) {
        this.hasLoaded = false;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: caseId,
                objectApiName: 'Case',
                actionName: 'view'
            }
        }, true );
       /*
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: caseId,
                objectApiName: 'Case',
                actionName: 'view'
            }
        }).then((url) => {window.open(url,'_self');} );        
        */
    }

    showToast(message, variant, mode) {
        const evt = new ShowToastEvent({
            title: '',
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }

    showNotification(message) {
        const evt = new ShowToastEvent({
            title: message,
            message: '',
            variant: 'success',
        });
        this.dispatchEvent(evt);
    }

    /**
     * Displays a toast with an error
     */
    showErrorNotification(message) {
        const evt = new ShowToastEvent({
            title: message,
            message: '',
            variant: 'error',
            mode: 'sticky'
        });
        this.dispatchEvent(evt);          
    }    
    
    closeCurrentTab() {
        this.isLoading = false;
        this.dispatchEvent(new CustomEvent('close', {}));    
    }

    defineVariable(v, defaultV) {
        if (v == undefined) {
            return defaultV;
        } else {
            return v;
        }
    }

    showStatusErrorToast(errors) {
        let toast = this.template.querySelector('c-lib-toast');
        toast.type = 'error';
        let header = this.labels.tr0009_144; // Can't change the status because of the following error:
        if (errors.length > 1) {
            header = this.labels.tr0009_145; // Can't change status because of the following errors:
        }
        toast.header = header;
        toast.messageList = errors;
        toast.showToast();
    }
    
    setApprovalRequestedWarning(dtime) {      
        if (this.currentStatus == this.STATUS_NEW) {
            if (dtime != undefined && dtime != null) {
                const requested = new Date(dtime);
                this.approvalRequestedWarning = this.labels.tr0009_147.replace('{0}', requested.toLocaleString()); 
                // [Approval requested {0}]
            } else {
                this.approvalRequestedWarning = this.labels.tr0009_146; 
                // [Approval not requested yet]
            }
        } else {
            this.approvalRequestedWarning = '';
        }
    }
    clog(str) {
        console.log('[CLOG] ' + str);
    }

}