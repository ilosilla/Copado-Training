import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { convertToUKUnits, convertFromPieces } from 'c/libUnitConversions';
import USER_COUNTRY_FIELD from '@salesforce/schema/User.CountryCode';
import USER_EXECUTION_CONTEXT_FIELD from '@salesforce/schema/User.Execution_Context__c';
import userId from '@salesforce/user/Id';
import { LABELS } from './labels';

export default class CaseCollectionItem extends LightningElement {

    labels = LABELS;

    ////////////////////////// API ///////////////////////////

    @api invoice;
    @api readOnly = false;
    @api index;
    @api numItems;
    @api showDialog;

    @api
        get item() {return this.currentItem;}
        set item(value) {
            console.log("==> Item setter with: " + value + ' and showDialog is ' + this.showDialog);
            if (value != null && value != undefined) {
                this.configureDialog(value);
            } else {
                this.currentItem = {};
            }
        }

    /////////////////////// VARIABLES //////////////////////

    get disablePreviousButton() {
        return (this.index == 0);
    }

    get disableNextButton() {
        return (this.index >= (this.numItems - 1));
    }
    get useInvoiceUnits() {
        return (this.selectedUnit == 'INV' );
    }

    get disableConversions() {
        return (!this.currentItem.pcsxbox > 0);
    }

    get isNotOK() {
        return (!this.currentItem.lineOK || this.readOnly);
    }

    productString;
    currentItem;
    displayUnits;
    selectedUnit;
    lastSelectedUnit;
    debugItem;
    data;
    userCountry='';
    userContext='';
    error;
    contador = 0;

    /////////////////////// LIFECYCLE HOOKS /////////////////////

    connectedCallback() {
        this.prepareDisplayUnits();
    }

    ////////////////////// DATA BINDING ///////////////////////////////
    @wire(getRecord, { recordId: userId, fields: [USER_COUNTRY_FIELD, USER_EXECUTION_CONTEXT_FIELD] }) userRecord({data, error}) {
        if (data) {
            this.userCountry = getFieldValue(data, USER_COUNTRY_FIELD);
            this.userContext = getFieldValue(data, USER_EXECUTION_CONTEXT_FIELD);
            this.setDefaultUnit();
        }
    };

    ////////////////////// EVENT HANDLERS /////////////////////////////

    handleDisplayUnitChange(event) {
        this.selectedUnit = event.target.value;
        this.lastSelectedUnit = this.selectedUnit;
    }

    handleCancelClick(event) {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    handleOKClick(event) {
        if (this.validateDialog()) {
            this.dispatchEvent(new CustomEvent('continue', {detail: this.currentItem}));
        }
    }

    handlePreviousClick(event) {
        if (this.validateDialog()) {
            this.dispatchEvent(new CustomEvent('previous', {detail: this.currentItem}));
        }
    }

    handleNextClick(event) {
        if (this.validateDialog()) {
            this.dispatchEvent(new CustomEvent('next', {detail: this.currentItem}));
        }
    }


    handleQuantityChange(event) {    
        if (this.fieldHasChanged(event.target)) {
            this.resetErrors();
            const fieldName = JSON.stringify(event.target.dataset.id);
            if (fieldName.includes('Units')) {
                this.validateInvoiceInputs();
            } else {
                this.validateUKInputs();
            }            
        }
    } // handleQuantityChange

    
    ////////////////////// METHODS ///////p/////////////////////

    fieldHasChanged(field) {
        let changed = false;
        if (field.dataset.id == 'colUnits') {
            changed = (field.value != this.currentItem.collected);
        }  else if (field.dataset.id == 'colBoxes') {
            changed = (field.value != this.currentItem.colBoxes);
        } else if (field.dataset.id == 'colPieces') {
            changed = (field.value != this.currentItem.colPieces);
        }
        return changed;
    }

    validateDialog() {
        let ok = true;
        const message = 'The quantity you are attempting to collect exceeds the quantity invoiced. Please review and adjust accordingly.';
        if (this.currentItem.collected > this.currentItem.invoiced) {
            ok = false;
            this.error = message;
        }
        return ok;
    } // validateDialog

    resetErrors() {
        this.error = '';
    }


    configureDialog(value) {
        this.currentItem = Object.assign({},value);
        this.productString = '(' + this.currentItem.productCode + ') ' + this.currentItem.productName;
        if (this.disableConversions) {
            this.selectedUnit = 'INV';
        } else if (this.lastSelectedUnit) {
            this.selectedUnit = this.lastSelectedUnit;    
        }
    }

    prepareDisplayUnits() {
        this.displayUnits = [
            { label: this.labels.dict_invoice_units, value: 'INV' },
            { label: this.labels.dict_boxes_and_pieces, value: 'UKU' },
        ];
        //this.selectedUnit = 'INV';
    }

    validateNumber(field) {
        let ok = true;
        if (isNaN(field.value)) {
            field.setCustomValidity('Please enter a valid number');   
            ok = false;
        } else {                        
            field.setCustomValidity('');   
        }
        field.reportValidity();
        return ok;
    }

    validateInvoiceInputs() {
        let collectedField = this.template.querySelector('[data-id = "colUnits"]');
        if (!this.validateNumber(collectedField)) {
            return;         
        }
        let quantity = parseFloat(collectedField.value);        

        if (this.currentItem.unit != 'MT2') {
            quantity = Math.ceil(quantity);        
        }
        collectedField.value = quantity;        
        let result = convertToUKUnits(quantity, this.currentItem.unit, this.currentItem.pcsxbox, this.currentItem.mt2xbox);
        this.currentItem.collected = quantity;
        this.currentItem.colBoxes = result.boxes;
        this.currentItem.colPieces = result.pieces;
   }

    validateUKInputs() {
        let boxesField = this.template.querySelector('[data-id = "colBoxes"]');
        if (!this.validateNumber(boxesField)) {
            return;         
        }

        var piecesField = this.template.querySelector('[data-id = "colPieces"]');
        if (!this.validateNumber(piecesField)) {
            return;         
        }

        const boxes = Math.round(Number(boxesField.value));
        const pieces = Math.round(Number(piecesField.value));

        let totPieces = boxes * this.currentItem.pcsxbox + pieces; 
        this.currentItem.collected = convertFromPieces(totPieces, this.currentItem.unit, this.currentItem.pcsxbox, this.currentItem.mt2xbox);
        this.currentItem.colBoxes = Math.trunc(totPieces / this.currentItem.pcsxbox);
        this.currentItem.colPieces = totPieces % this.currentItem.pcsxbox;
        boxesField.value = this.currentItem.colBoxes;
        piecesField.value = this.currentItem.colPieces;
    }

    setDefaultUnit() {
        if (this.userContext == 'GB') { 
            this.selectedUnit = 'UKU';
        } else {
            this.selectedUnit = 'INV';
        }
        this.lastSelectedUnit = this.selectedUnit;
    }

}