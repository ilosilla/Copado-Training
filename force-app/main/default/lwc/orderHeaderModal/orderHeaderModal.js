/**
 * 
 * OrderHeaderModal
 * 
 * Ramón, March 2024
 * 
 * Modal window to edit the sales order header
 * 
 * Translation Prefix: tr0005
 * 
 */
import { api, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import { getRecord } from 'lightning/uiRecordApi';
import { getCountryLocale } from 'c/libAddressCommons';
import LightningConfirm from 'lightning/confirm';
import { LABELS } from './labels';

import RECORD_TYPE_NAME from '@salesforce/schema/RecordType.Name';
const _FIELDS = [RECORD_TYPE_NAME];
const STATUS_ACTIVATED = 'activated';

export default class OrderHeaderModal extends LightningModal {

    labels = LABELS;
    
    //====================================================
    // API
    //====================================================
    @api 
        get order() {
            return this._order;
        }
        set order(value) {
            this._order = {...value};  
            this.selectedSalesOffice = this._order.SalesOffice__c;            
        }

    
    //====================================================
    // Vars
    //====================================================
    _order;
    originalOrder;
    salesAreas = [];
    salesAreaOptions = [];
    selectedSalesArea;
    selectedSalesOffice;
    salesOrgDefaults = {};
    offices = [];
    officeOptions = {};
    debugText;
    deliveryDateError = '';
    salesOfficeError = '';
    
    // Address related variables
    openAddressesDialog = false;
    initialAddressId;
    selectedAddressId;
    shippingObject = {};
    recordTypeName;

    // Form dynamics variables
    showAddressesDialog = false;
    showSpinner = true;

    //====================================================
    // Properties
    //====================================================

    get isReadonly() {
        return (this._order.Status?.toLowerCase() === STATUS_ACTIVATED);
    }

    get isEditable() {
        return !this.isReadonly;
    }

    get isCollection() {
        return this._order.Type.startsWith('Z018');
    }
    
    get windowTitle() {
        let title = '';
        if (this.isReadonly) {
            title = (this.isCollection ? this.labels.tr0005_019 : this.labels.tr0005_001);
        } else {
            if (this._order?.Id) {
                title = (this.isCollection ? this.labels.tr0005_018 : this.labels.tr0005_002);
                
            } else {
                title = (this.isCollection ? this.labels.tr0005_017 : this.labels.tr0005_003); // New Order;
            }
        }
        return title.replace('{0}', this._order.OrderNumber);
    }

    get deliveryInstructionsTitle() {
        return (this.isCollection ? this.labels.tr0005_020 : this.labels.tr0005_009);
    }

    get orderNumber() {
        return this._order.OrderNumber??'<' + this.labels.tr0005_003 + '>';
    }

    get isReady() {
        return !this.showSpinner;
    }

    get shippingName() {
        return this.shippingObject?.Name ?? '';
    }

    get recordTypeId() {
        return this._order.RecordTypeId;
    }

    get deliveryDateClass() {
        let ddclass = "";
        if (this.deliveryDateError) {
            ddclass = "slds-has-error";
        } 
        return ddclass;
    }

    get sapIdString() {
        let result = '--';
        if (this._order?.Status?.toLowerCase() === STATUS_ACTIVATED) {
            result = (this._order.Sap_Id__c ?? this.labels.tr0005_013);
        }
        return result;
    }


    //====================================================
    // Events
    //====================================================
    handleRecordLoad(event) {
        if (this._order.AccountId) {
            //const caseFields = event.detail.records[this.recordId].fields;
            const queryLib = this.template.querySelector("[data-id = 'query-lib']");
            if (queryLib) {
                queryLib.querySalesAreas(this._order.AccountId);
            }
            if (this._order.NBK_Contact_Point_Address__c != null) {
                this.initialAddressId = this._order.NBK_Contact_Point_Address__c;
            } else {
                this.initialAddressId = this._order.AccountId;
            }
            this.selectedAddressId = this.initialAddressId;
        }          
        this.originalOrder = {...this._order};
        this.showSpinner = false;
    }

    handleSalesQueryDataReceived(event) {
        if (event.detail.hasError) {
            this.showSpinner = false;
            return;
        }
        if (event.detail?.queryName === 'SalesAreasQuery') {
            this.salesAreas = event.detail.data;
            this.prepareSalesAreas();
            this.checkSalesAreas();
            this.querySelectedArea(this.selectedSalesArea);
        } else if (event.detail?.queryName === 'SalesOrgQuery') {
            this.salesOrgDefaults = event.detail.data;
            this.setSalesOrgDefaults();            
            this.querySalesOffices(this.selectedSalesArea);
        } else if (event.detail?.queryName === 'SalesOfficesQuery') {
            this.offices = event.detail.data;
            this.setOffices()
            this.showSpinner = false;
        }
    }

    handleCancelClick() {
        /*
        const fields = this.template.querySelectorAll('lightning-input-field');
        let isDirty = false;
        fields.forEach((field) => {
            alert("Mirando " + field.fieldName + " y " + field.value + " y lo comparo con " + this.originalOrder[field.fieldName ]);
            isDirty = isDirty && fields.dirty;
        });
        */
        this.closeWindow(false, null);
    }

    handleOfficeChange(event) {
        const officeField = this.refs.officeField;
        if (officeField) {
            officeField.value = event.detail.value;
        }        
    }

    /* **************** Address event handlers ***************** */

    handleCollectionAddressReady(event) {
        this.shippingObject = event.detail;
    }

    handleChangeAddressClick() {
        this.showAddressesDialog = true;
    }

    handleAddressCancel() {
        this.showAddressesDialog = false;
    }

    handleAddressSelect(event) {
        this.showAddressesDialog = false;
        this.shippingObject = event.detail; 
        this.shippingObject.Locale = getCountryLocale(this.shippingObject.CountryCode);        
        this.selectedAddressId = this.shippingObject.Id;
        /*
        const cpaField = this.template.querySelector('[data-id="ContactPointAddress"]');
        if (this.collectionAddress.isContactPoint) {
            cpaField.value = this.collectionAddress.Id;
        } else {
            cpaField.value = null;
        }
        */
    }

    /* ********************** Change Handlers ********************** */

    handleDeliveryDateChange(event) {
        if (event.target.value <= this._order.EffectiveDate) {
            this.deliveryDateError = this.tr0005_014; // The delivery date must be greater than the order date
        } else {
            this.deliveryDateError = '';  
        }
    }
            
    /* *********************** Save Handlers *********************** */

    handleOKClick() {
        const submitButton = this.template.querySelector('[data-id="submitButton"]');
        if (submitButton) {
            submitButton.click();
        }
    }

    handleSubmit(event){
        event.preventDefault();     
        if (this.validate()) {
            this.isLoading = true;            
            const fields = event.detail.fields; 
            this.setAdditionalFields(fields);
            this.closeWindow(true, fields);
        } 
    }     

    //====================================================
    // Methods
    //====================================================    

    validate() {
        let ok = true;
        this.salesOfficeError = '';
        const office = this.template.querySelector("[data-id = 'office-combo']");
        ok = ok && office.checkValidity();        
        office.reportValidity();
        return ok;
    }

    setOffices() {
        this.officeOptions = [];
        for (let i = 0; i<this.offices.length; i++) {            
            const office = this.offices[i];
            const opt = {
                "label": '[' + office.SalesOffice_code__c + '] ' + office.SalesOffice_name__c ,
                "value": office.SalesOffice_code__c
            }
            this.officeOptions.push(opt);
        }
    }
    
    setAdditionalFields(fields) {
        fields.Id = this._order.Id;
        if (this.selectedAddressId && this.selectedAddressId != this._order.AccountId) {
            fields.NBK_Contact_Point_Address__c = this.selectedAddressId;
        } else {
            fields.NBK_Contact_Point_Address__c = "";
        }
    }

    setSalesOrgDefaults() {        
        this._order.CurrencyIsoCode = this.salesOrgDefaults.CurrencyIsoCode
    }

    querySelectedArea(selected) {
        const queryLib = this.template.querySelector("[data-id = 'query-lib']");
        if (queryLib) {
            const index = this.salesAreas.findIndex((salesArea) => salesArea.Id === selected);
            if (index >= 0) {
                this.showSpinner = true;
                queryLib.querySalesOrg(this.salesAreas[index].Sales_Org__c);
            }
        }
    }

    querySalesOffices(selected) {
        const queryLib = this.template.querySelector("[data-id = 'query-lib']");
        if (queryLib) {
            const index = this.salesAreas.findIndex((salesArea) => salesArea.Id === selected);
            if (index >= 0) {
                queryLib.querySalesOffices(this.salesAreas[index].Sales_Org__c, this.salesAreas[index].Distribution_Channel__c);
            }
        }
    }

    prepareSalesAreas() {
        this.selectedSalesArea = null;
        this.salesAreaOptions = [];
        for (let i = 0; i<this.salesAreas.length; i++) {            
            const salesArea = this.salesAreas[i];
            const opt = {
                "label": '[' + salesArea.Sales_Org__c + '-' + salesArea.Distribution_Channel__c + '] ' + salesArea.SalesOrgName + ' ' + salesArea.DistrChannelName,
                "value": salesArea.Id
            }
            this.salesAreaOptions.push(opt);
            if (this._order.SalesOrg__c === salesArea.Sales_Org__c && this._order.Distribution_channel__c === salesArea.Distribution_Channel__c) {
                this.selectedSalesArea = salesArea.Id;
            }
        }
        if (!this.selectedSalesArea) {
            this.selectedSalesArea = this.salesAreas[0]?.value;
        }
    }

    checkSalesAreas() {
        if (this.salesAreas.length === 0) {
            this.closeWindow(false, {message: this.labels.tr0005_015}); // The account does not have any valid sales area in SAP. Please create one before creating orders.
        }
    }

    closeWindow(success, data) {
        const resultObject = {
            success: success,
            data: data
        };
        this.close(resultObject);
    }

    async confirmCancel() {
        const result = await LightningConfirm.open({
            message: this.labels.dict_exit_message, // Exit and discard all changes?
            variant: 'headerless',
            label: this.labels.dict_confirm, 
            theme: 'warning'
            // setting theme would have no effect
        });
        //Confirm has been closed
        //result is true if OK was clicked
        //and false if cancel was clicked
    }


    //====================================================
    // Wires
    //====================================================
    @wire(getRecord, { recordId: '$recordTypeId', fields: _FIELDS })
    wiredRecord({ data, error }) {
        if (data) {
            this.recordTypeName = data.fields.Name.value;
       }
    }  
}