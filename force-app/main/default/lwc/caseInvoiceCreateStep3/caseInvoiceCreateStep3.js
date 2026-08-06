/**
 * **caseInvoiceCreateStep3**
 *
 * Author: Ramón Prades  
 * Date: January 2025  
 *
 * *Description:  
 *
 * This subcomponent implements the third step of the invoice-related case creation wizard.  
 * It allows the user to entert a description of the problem and to attach any files that help identify the issue.
 * 
 * This step is repeated as many times as the number of prodcuts selected in step 2.
 *
 * Once an invoice number is selected, this step updates the caseData object accordingly  
 * and notifies the parent component (caseInvoiceCreate) that it is ready by firing a "stepready" event.
 *
 * ?Translation Prefix: tr0009
 *
 * ---
 *
 * This subcomponent updates the caseData object with the selected invoice number and with the invoice header and items.  
 * The parent component retrieves this data using the "caseData" property.
 */
import { LightningElement, api } from 'lwc';
import { LABELS } from './labels';

export default class CaseInvoiceCreateStep3 extends LightningElement {

    //****************************************
    //** API
    //****************************************

    @api 
    get substep() {
        return this._substep;
    }
    set substep(value) {        
        this._substep = value;
        this.refreshProblemDescription();
        this.checkStepReady();
    }

    @api 
    get caseData() {        
        return this._caseData;
    }
    set caseData(value) {   
        this._caseData = JSON.parse(JSON.stringify(value));        
        /*this._caseData.invoiceItems = [];
        for (const item of value.invoiceItems) {
            this._caseData.invoiceItems.push({...item});
        }*/
   }       

    //****************************************
    //** Variables and getters
    //****************************************

    _caseData;
    _substep;
    labels = LABELS;

    get areFilesRequired() {
        return (this.isClaim && (this._caseData?.settings?.CLAIM_FilesRequired__c ?? false));
    }

    get descriptionPrompt() {
        return this._caseData?.caseType === 'CLAIM' ? this.labels.caseProblemDescriptionPrompt : this.labels.tr0009_017;
    }

    get defectiveString() {        
        return this.currentItem.defective + ' ' + this.currentItem.salesUnitName;
    }

    get currentItem() {
        const index = this._caseData.selectedItems[this._substep];    
        return this._caseData.invoiceItems[index];    
    }

    get isClaim() {
        return (this._caseData.caseType === 'CLAIM');
    }

    //****************************************
    //** Methods
    //****************************************

    refreshProblemDescription() {        
        const field = this.template.querySelector('[data-id="problem-description"]');
        if (field) {
            field.value = this.currentItem.problemDescription;
        }
    }

    checkStepReady() {
        let descriptionReady = (!this.isClaim || (this.currentItem.problemDescription ?? "").length > 0);
        let filesReady = (!this.areFilesRequired || this.getNumAttachments() > 0);
        this.fireStepReady(descriptionReady && filesReady);
    }

    getNumAttachments() {
        return this.currentItem.filesToUpload.length;
    }

    //****************************************
    //** Event Handlers
    //****************************************

    fireStepReady(value) {
        this.dispatchEvent(new CustomEvent('stepready', {detail: value}));
    }   

    handleDescriptionChange(event) {
        this.currentItem.problemDescription = event.detail.value;
        this.checkStepReady();
    }

    handleFilesChange(event) {      
        let items = [...this.currentItem.filesToUpload];  
        for (let i=0; i< event.target.files.length; i++){
            let file = event.target.files[i];
            const found = items.find((element) => element.name === file.name);
            if (found !== undefined) {                
                continue;   // This file was already in the list!
            }
            const pills = this.template.querySelector('[data-id="pills-container"]');
            let reader = new FileReader();
            reader.onload = (() => {
                let fileContents = reader.result.split(',')[1];
                this.currentItem.filesData.push({'fileName':file.name, 'fileContent':fileContents});                
                let pill = {};
                pill.type = 'icon';
                pill.label = file.name;
                pill.name = file.name;
                pill.iconName = 'standard:file';
                pill.alternativeText = 'File';
                this.currentItem.filesToUpload.push(pill);                
                if (pills) {
                    pills.items = this.currentItem.filesToUpload;
                }
                this.checkStepReady();
            });            
            reader.readAsDataURL(file);            
        }
    }

    handleItemRemove(event) {
        //const name = event.detail.item.name;
        const index = event.detail.index;
        this.currentItem.filesToUpload.splice(index, 1);
        this.currentItem.filesData.splice(index, 1);                
        this.checkStepReady();
        const pills = this.template.querySelector('[data-id="pills-container"]');
        if (pills) {
            pills.items = this.currentItem.filesToUpload;
        }
    }



}