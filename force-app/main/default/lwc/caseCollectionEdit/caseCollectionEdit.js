import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import CASE_IS_CLAIM_FIELD from '@salesforce/schema/Case.IsClaim__c';
import CASE_IS_COLLECTION_FIELD from '@salesforce/schema/Case.IsCollection__c';
import { getFocusedTabInfo, closeTab } from 'lightning/platformWorkspaceApi';

//import REVENUE_FIELD from "@salesforce/schema/Account.AnnualRevenue";

const FIELDS = ["Case.Subject", "Case.isCollection__c"];

// Labels
import save from '@salesforce/label/c.dict_save';
import cancel from '@salesforce/label/c.dict_button_cancel';
import saveAndNew from '@salesforce/label/c.dict_saveAndNew';

export default class CaseCollectionEdit extends LightningElement {

    invoiceNumber;
    invoiceData;
    showModal = true;

    // ===================================================
    // COMPONENT API
    // ===================================================
    @api recordId;
    @wire(getRecord, { recordId: "$recordId", fields: [CASE_IS_CLAIM_FIELD, CASE_IS_COLLECTION_FIELD] })
        wiredCase({ error, data }) {
            if (data) {
                this.isClaim = getFieldValue(data, CASE_IS_CLAIM_FIELD);
                this.isCollection = getFieldValue(data, CASE_IS_COLLECTION_FIELD);
                this.setCaseFlags();
            } else if (error) {
                console.log("Error received while reading the case classification fields: " + error);
                console.log("The error is " + JSON.stringify(error));
            }
        }

    dataLoaded = false;
    isClaim = false;
    isCollection = false;
    showInvoiceWindow = false; 
    showCaseWindow = false;

    // Button labels
    label = {
        save,
        saveAndNew,
        cancel
    }

    get isLoading() {
        return !this.dataLoaded;
    }

    // ===================================================
    // LIFECYCLE HOOKS
    // ===================================================
    connectedCallback() {
        // Initial state
        if (this.recordId == null) {
            this.isCollection = true;   // 
            this.showInvoiceWindow = true;
            this.showCaseWindow = false;
        // } else {
        //     this.showInvoiceWindow = false;
        //    this.showCaseWindow = true;
        }
    }
    
    // ===================================================
    // EVENT HANDLERS
    // ===================================================
    handleContinue(event) {
        var dto = event.detail;
        this.invoiceNumber = dto.invoiceNumber;
        this.invoiceData = dto.invoiceData;
        this.showInvoiceWindow = false;
        this.showCaseWindow = true;
    }

   async handleCloseTab() {
        try {
            const loc = window.location?.search;  
            const qs = loc?.toUpperCase();
            if (qs?.includes('=LIST_VIEW_ROW')) {
                const tabInfo = await getFocusedTabInfo();
                if (tabInfo && tabInfo.tabId) {
                    await closeTab(tabInfo.tabId);
                    console.log('======> Pestaña cerrada con éxito');
                }
            }
        } catch (error) {
            console.error('Error al cerrar la pestaña:', error);
        }
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('close', {}));        
        this.handleCloseTab();
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleSaveClick() {
        let component = this.template.querySelector('[data-id="case-form"]');
        if (component) {
            component.save();
        }
    }

    setCaseFlags() {
        if (this.isCollection) {
            this.showInvoiceWindow = false;
            this.showCaseWindow = true;         
        }
    }

}