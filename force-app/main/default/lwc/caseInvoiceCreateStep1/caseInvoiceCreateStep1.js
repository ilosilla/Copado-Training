/**
 * **caseInvoiceCreateStep1**
 *
 * Author: Ramón Prades  
 * Date: January 2025  
 *
 * Description:  
 * This subcomponent represents the first step of the invoice-related case creation wizard.  
 * It allows the user to select an invoice number, which will be used in subsequent steps to process the case.  
 *
 * Once an invoice number is selected, this step updates the caseData object accordingly  
 * and notifies the parent component (caseInvoiceCreate) that it is ready by firing a "stepready" event.
 *
 * ?Translation Prefix: tr0009
 * ---
 *
 * This subcomponent updates the caseData object with the selected invoice number and with the invoice header and items.  
 * The parent component retrieves this data using the "caseData" property.
 */

import { LightningElement, api } from 'lwc';
import SapInvoiceSearch from 'c/sapInvoiceSearch';
import apexReadInvoiceWithDetails from '@salesforce/apex/SAPDocumentsQueryController.readInvoiceWithDetails';
import { LABELS } from './labels';

export default class CaseInvoiceCreateStep1 extends LightningElement {

    @api 
    get caseData() {
        return this._caseData;
    }
    set caseData(value) {   
        this._caseData = {...value};
        this.invoiceOK = this._caseData?.invoiceHeader ?? false;
        this.originalInvoice = (this._caseData.invoiceNumber ?? "0");   
        if (this.invoiceOK) {
            this.dispatchEvent(new CustomEvent('stepready', {detail: (this.invoiceOK)}));                 
        }     
    }   
    
    originalInvoice;
    _caseData = {};
    labels = LABELS;
    invoiceOK = false; 
    accessDenied = false;
    isInvalidInvoice = false;
    invalidErrorMessage = '';
    hasWarning = false;
    warningMessage = '';
    policyWarning = false;
    errorObject = {};
    
    get invoiceNumber() {
        return this._caseData?.invoiceNumber;//  ?? "6215100037";  // "6215150072";
    }
    get accountString() {
        return '[' + this._caseData.invoiceHeader.BillTo__c + '] ' +  this._caseData.invoiceHeader.accountName;
    }

    get salesOrgString() {
        return '[' + this._caseData.invoiceHeader.Salesorg__c + '] ' +  this._caseData.invoiceHeader.salesOrgName;
    }

    get errorMessage() {
        return this.errorObject?.message;
    }

    get numberOfLines() {
        return (this._caseData?.invoiceItems?.length ?? 0);
    }

    get isClaim() {
        return this._caseData.caseType === 'CLAIM';
    }

    get isReturn() {
        return this._caseData.caseType === 'RETURN';
    }

    get returnsPolicyMessage() {
        return this.labels.tr0009_016.replace('{0}', (this._caseData.settings?.COL_PolicyDays__c ?? 28));
    }


    //============================================================
    // EVENT HANDLERS
    //============================================================

    async handleSearch() {
        this.accessDenied = false;
        const result = await SapInvoiceSearch.open({
            label: 'Search invoices',
            size: 'full',
            content: 'Passed into content api',
        });
        if (result !== undefined) {
            const control = this.template.querySelector('[data-id="invoiceNumber"]');
            if (control) {
                control.value = result;
            }
        }
    }

    setCaseData(invoiceData) {
        this._caseData.invoiceNumber = invoiceData.sapInvoice.Ordernum__c;
        this._caseData.invoiceHeader = {...invoiceData.sapInvoice};                
        this._caseData.invoiceHeader.accountName = invoiceData.accountName;        
        this._caseData.invoiceHeader.salesOrgName = invoiceData.salesOrgName;  
        this._caseData.settings = invoiceData.settings;                  
        if (this.isReturn) {
            const policyDays = (this._caseData.settings?.COL_PolicyDays__c ?? 28 );
            const today = new Date(); // Current date
            const pastDate = new Date(this._caseData.invoiceHeader.Orderdate__c);
            const daysPassed = Math.floor((today - pastDate) / (1000 * 60 * 60 * 24));
            console.info(`The selected invoice is ${daysPassed} days old`);
            this._caseData.invoiceHeader.policyWarning = (daysPassed > policyDays);
        }
        const anotherInvoice = true; // (this.caseData.invoiceHeader.Ordernum__c !== this.originalInvoice);
        if (anotherInvoice || this._caseData.invoiceItems?.length === 0) {
            this._caseData.invoiceItems = JSON.parse(JSON.stringify(invoiceData.sapItems));
        }
    }

    async handleInvoiceOK() {
        this.accessDenied = false;
        this.isInvalidInvoice = false;
        this.invalidErrorMessage = '';
        this.hasWarning = false;
        this.warningMessage = false;
        const control = this.template.querySelector('[data-id="invoiceNumber"]');
        control.setCustomValidity('');
        control.reportValidity();
        if (control?.checkValidity()) {            
            control.setCustomValidity('');
            try {
                this.showSpinner(true);
                const invoiceData = await apexReadInvoiceWithDetails({invoiceNumber: control.value});                
                console.info('Invoice read ' + JSON.stringify(invoiceData));
                this.setCaseData(invoiceData);
                this.invoiceOK = true;    
                console.log('=======> OK!!!');
                const header = this._caseData.invoiceHeader;                  

                // ☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️
                /*
                if (header.Account__c === undefined || header.Account__c === null) {
                    header.Account__c = '0012z00000C55LwAAJ';                    
                }
                */
                // ☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️☠️

                if (header.Account__c === undefined || header.Account__c === null) {
                    this.isInvalidInvoice = true;
                    this.invalidErrorMessage = this.labels.tr0009_013;                
                } else if (!invoiceData.readyForCase) {
                    this.isInvalidInvoice = true;
                    this.invalidErrorMessage = this.labels.tr0009_038;                  
                } else {
                    this.setItemData(invoiceData.productMap);
                }
            } catch(exception) {
                console.error('==> Error reading the invoice number: ' + exception);
                console.error('==>  ' + JSON.stringify(exception));
                this.invoiceOK = false;
                this.errorObject = this.parseException(exception);
                if (this.errorObject?.exception === 'SecurityException') {
                    this.accessDenied = true;
                } else {
                    control.setCustomValidity(this.labels.dict_error_invoice);
                }
            } finally {
                this.dispatchEvent(new CustomEvent('stepready', {detail: (this.invoiceOK && !this.isInvalidInvoice)}));                 
            }
            control.reportValidity();
            this.showSpinner(false);
        }

    }

    setItemData(productMap) {
        for (const item of this._caseData.invoiceItems) {
            const product = productMap[item.Sku__c];
            item.productId = product?.Id;
            if (item.productId === null || item.productId === undefined) {
                this.hasWarning = true;
                this.warningMessage = this.labels.tr0009_014.replace('{0}', item.Sku__c);
            } else if (item.Vrkme__c === 'PAL') {
                item.Vrkme__c = 'CJ';
                item.Quantity__c *= product.BoxXPal__c;
            }
        }             
    }

    showSpinner(value) {
        this.dispatchEvent(new CustomEvent('showspinner', {detail: value}));                 
    }

    parseException(ex) {
        const err = {};        
        if (ex?.body !== null) {
            err.exception = ex.body?.exceptionType;
            err.message = ex.body?.message;
            err.severity = 'E';
        } else if (typeof ex === 'string') {
            err.exception = null;
            err.message = ex;
            err.severity = 'E';
        } else {
            err = null;
        }        
        return err;
    }

    isMySandbox() {
        let name = null;
        const hostname = window.location.hostname;
         if (hostname.includes('--')) {;    
            const parts = hostname.split('--')[1].split('.');
            name = parts[0]; // Get the first part after the `--`
         }
         return (name === 'rpr');
    }
    

}