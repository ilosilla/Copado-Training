/**
 * **caseInvoiceCreateStep2**
 *
 * Author: Ramón Prades  
 * Date: January 2025  
 *
 * Description:  
 * This subcomponent represents the second step of the invoice-related case creation wizard.  
 * It allows the user to select the products from the previously chosen invoice that will be included in the case.  
 * Additionally, the user specifies the quantity of each selected product and provides an initial description of the issue.  
 *
 * Once the selections are made, this step updates the caseData object with the relevant details  
 * and notifies the parent component (caseInvoiceCreate) that it is ready by firing a "stepready" event.
 *
 * ?Translation Prefix: tr0009
 *
 * ---
 *
 * Step State Variables:
 *
 *
 * This subcomponent updates the caseData object with the selected products, their quantities,  
 * and the initial issue description. 
 * The parent component retrieves this data using the "caseData" property.
 */

import { LightningElement, wire, api } from 'lwc';
import { LABELS } from './labels';
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import CASE_PROBLEM_FIELD from "@salesforce/schema/Case.Problem__c";

export default class CaseInvoiceCreateStep2 extends LightningElement {

    _caseData = {};
    labels = LABELS;
    invoiceLines = [];
    defectOptions = [];
    componentLoading = true;

    //****************************************
    //** API
    //****************************************

    @api 
    get caseData() {
        this._caseData.invoiceItems = [...this.invoiceLines];        
        this._caseData.selectedItems = [];
        for (let i = 0; i < this._caseData.invoiceItems.length; i++) {
            if (this.isPositiveNumber(this._caseData.invoiceItems[i].defective)) {
                this._caseData.selectedItems.push(i);
            }
        }
        return this._caseData;
    }
    set caseData(value) {   
        this._caseData = {...value};
        this.setLines();
    }    

    get isClaim() {
        return this._caseData.caseType === 'CLAIM';
    }

    get introText() {
        return (this.isClaim ? this.labels.caseSelectProducts : this.labels.tr0009_006);
    }

    //****************************************
    //** Event Handlers
    //****************************************
    handleProblemChange(event) {
        const v = event.target.value;
        const index = event.target.dataset.index;
        this.invoiceLines[index].problem = v;
        this.invoiceLines[index].problemLabel = this.searchProblemLabel(v);

        this.invoiceLines[index].disabled = (v === '');
        const inputElement = this.template.querySelector("[data-id='"+ this.invoiceLines[index].inputId +"']");
        if (inputElement) {
            inputElement.disabled = this.invoiceLines[index].disabled;
            if (inputElement.disabled) {
                inputElement.value = 0;
                this.invoiceLines[index].defective = 0;
            }
        } 
        this.checkSelectedItems();
    }

    handleQuantityChange(event) {
        const error = !event.target.checkValidity();
        const v = event.target.value;
        const index = event.target.dataset.index;
        this.invoiceLines[index].defective = v;        
        this.invoiceLines[index].error = error;
        event.target.reportValidity();
        if (error) {
            this.fireStepReady(false);
        } else {
            this.checkSelectedItems();
        }
    }

    //****************************************
    //** Event Dispatchers
    //****************************************
    fireStepReady(value) {
        this.dispatchEvent(new CustomEvent('stepready', {detail: value}));
    }   

    //****************************************
    //*** Methods
    //****************************************


    searchProblemLabel(value) {
        let i = 0;
        while (i<this.defectOptions.length) {
            if (this.defectOptions[i].value === value) {
                return this.defectOptions[i].label;
            }
            i++;
        }
        return '';
    }

    /**
     * Adds the following fields to the invocie lines:
     * - index: the line number
     * - className: used to alternate the background color of the line
     * - defective: the quantity of defective products
     * - problem: the problem description
     * - disabled: used to disable the input field when the problem is not defined
     * - inputId: used to identify the quantity input field (for binding with the search results)
     * - isInvalid: the product does not exist in salesforce, so it han't be handled here
     */
    setLines() {        
        this.invoiceLines = [];
        for (let i = 0; i < this._caseData.invoiceItems.length; i++) {
            const line = {...this._caseData.invoiceItems[i]};
            if (!Object.hasOwn(line, "index")) {
                line.index = i;
                line.className = (i % 2  === 0) ? "slds-var-p-horizontal_small table-row-even" : "slds-var-p-horizontal_small table-row-odd";
                line.defective = '';
                line.problem = '';
                line.problemLabel = '';
                line.disabled = true;
                line.error = false;
                line.inputId = 'input-' + line.index;  
                line.problemDescription = null;
                line.filesToUpload = [];
                line.filesData = [];
                line.salesUnitName = this._caseData?.apiData.unitsMap[line.Vrkme__c];
                if (line.salesUnitName === null || line.salesUnitName === undefined) {
                    line.salesUnitName = line.Vrkme__c;
                }
                line.isInvalid = (line.productId === null || line.productId === undefined);
            }
            this.invoiceLines.push(line);
        }  
        this.checkSelectedItems();      
    }

    isPositiveNumber(value) {
        const num = Number(value);
        return !isNaN(num) && num > 0;
    }

    checkSelectedItems() {        
        let hasItems = false;
        let hasErrors = false;
        for (let i = 0;  i < this.invoiceLines.length; i++) {
            const iline = this.invoiceLines[i];
            if (iline.problem !== '' && this.isPositiveNumber(iline.defective)) {
                hasItems = true;
                hasErrors = hasErrors || iline.error;
            }
        }        
        this.fireStepReady(hasItems && !hasErrors);
    }

    //************************************* 
    // * Wired Data
    //*************************************

    @wire(getPicklistValues, { recordTypeId: "$_caseData.recordType", fieldApiName: CASE_PROBLEM_FIELD })
        picklistResults({ error, data }) {
            if (data) {
                this.componentLoading = false;
                this.defectOptions = [];
                this.defectOptions.push({label: '--' + this.labels.dictNone + '--', value: ''});
                this.defectOptions.push(...data.values);
            } else if (error) {
                console.error('===========================================');
                console.error('Error reading Problem picklist values');
                console.error(error);
                console.error('===========================================');
            }
        }

}