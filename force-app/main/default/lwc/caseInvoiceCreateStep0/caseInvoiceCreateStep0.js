/**
 * caseInvoiceCreate - Step 0
 * 
 * Ramón Prades
 * January 2025
 * 
 * First step of the wizard to select between claims and colelctions.
 * 
 * As this is a relatively complex component, it has been divided into several subcomponents, each representing a step of the wizard.
 * 
 * Translation prefix tr0009
 * 
 */
import { LightningElement, api } from 'lwc';
//import { LABELS } from './labels';


export default class CaseInvoiceCreate extends LightningElement {

    //labels = LABELS;

    defaultCaseType = 'CLAIM';
    selectedCaseType = 'CLAIM';

    @api 
    get caseType() {
        return  this.selectedCaseType;
    }

    set caseType(value) {
        if (value === null) {
            value = this.defaultCaseType;
        }
        this.selectedCaseType = value;
    }
    
    get caseOptions() {
        return [
            { value: 'CLAIM', label: 'Create a Claim (use this option to report an issue with a product)' },
            { value: 'RETURN', label: 'Create a Return (choose this option to return a product)' },
        ];
    }

    //=============================================
    // EVENT HANDLERS
    //=============================================

    handleCaseTypeChanged(event) {  
        this.selectedCaseType = event.detail.value;
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent("cancel"));
    }

    handleStart() {
        this.dispatchEvent(new CustomEvent("start", { detail: this.selectedCaseType }) );

    }

}