// @Task: Internacionalizar con etiquetas (Ramón 5 Sept 2022)
import { LightningElement, wire, track} from 'lwc';
import readInitialValues from '@salesforce/apex/CaseInvoiceSearchController.readInitialValues';
import readInvoiceData from '@salesforce/apex/CaseInvoiceSearchController.readInvoiceData';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import CASETYPE_FIELD from '@salesforce/schema/Case.Type';

// import Dtotal__c from '@salesforce/schema/Facturas_cabeceraSet__x.Dtotal__c';

export default class caseInvoiceSearch extends LightningElement {
    isLoading = false;
    showSpinner = true;
    invoiceDTO;
    invoiceNumber; //= '6215100036';
    invoiceDate;
    amountString;
    customer;
    error;
    recordTypeId;
    caseType;
    picklistValues = null;
    disableContinue = true;
    @track salesRep = '';
    @track salesOrg = '';
    @track salesOffice = '';
    @track numItems;
    @track collectionDays;
    @track daysWarning = false;
    debugText;

    constructor() {
        super();
        if (window.location.hostname.includes('porcelanosa--rpr')) {
            this.invoiceNumber = 6215100036;
        }            

    }
    
    handleInvoiceSearch(){        
        this.clearInvoiceData();
        var inputCmp = this.template.querySelector('[data-id="invoiceNumber"]');
        inputCmp.setCustomValidity('');
        inputCmp.reportValidity();
        if (!inputCmp.validity.valid) {
            inputCmp.reportValidity();
            return;
        } 
        this.isLoading = true; 
        this.disableContinue = true;
        var sapInvoice = this.template.querySelector('lightning-input[data-name="sapInvoice"]').value;     
        console.log('==> Searching invoice ' + sapInvoice);   
        readInvoiceData({ invoiceNumber: sapInvoice })
            .then((result) => {
                console.log('==> SAP result is OK');
                console.log('==> Result is ' + JSON.stringify(result));
                this.invoiceDTO = result;
                this.invoiceNumber = this.invoiceDTO.invoiceHeader.docNumber; 
                this.invoiceDate = this.invoiceDTO.invoiceHeader.docDate;
                if (!this.invoiceDTO.accountName) {
                    this.invoiceDTO.accountName = 'Customer not found in Salesforce';
                }
                console.log('==> Checkpoint 1');
                if (!this.invoiceDTO.repName) {
                    this.invoiceDTO.repName = 'Sales Rep not found in Salesforce';
                }
                this.salesRep = '[' + this.invoiceDTO.invoiceHeader.SAPRep1 + '] ' + this.invoiceDTO.repName;                 
                this.customer = '[' + this.invoiceDTO.invoiceHeader.SAPCustomer + '] ' + this.invoiceDTO.accountName;
                this.salesOrg = '[' + this.invoiceDTO.invoiceHeader.salesOrg + '] ' + this.invoiceDTO.salesOrgName;
                console.log('==> Checkpoint 2');
                this.salesOffice = '[' + this.invoiceDTO.invoiceHeader.salesOffice + '] ' + this.invoiceDTO.salesOfficeName;
                this.amountString = this.invoiceDTO.formattedAmount;
                this.collectionDays = this.invoiceDTO.collectionDays;
                console.log('==> Checkpoint 3');
                this.daysWarning = this.invoiceDTO.daysWarning;
                this.numItems = this.invoiceDTO.numItems; 
                this.isLoading = false;
                this.disableContinue = false;
                console.log('==> Checkpoint 4');
            })
        .catch((error) => {
            console.log('==> SAP result is ERROR');
            console.log('==> Error returned is: ' +  JSON.stringify(error));
            this.isLoading = false
            this.error = error;
            var inputCmp = this.template.querySelector('[data-id="invoiceNumber"]');
            inputCmp.setCustomValidity(this.error.body.message);
            inputCmp.reportValidity();
            this.invoiceDTO = undefined;
        });
    }

    // ===================================================
    // EVENT HANDLERS
    // ===================================================

    handleInvoiceChange(event) {
        var textvalue = event.detail.value;
        var inputCmp = this.template.querySelector('[data-id="invoiceNumber"]');
        inputCmp.setCustomValidity('');
        inputCmp.reportValidity();
        // Use this to reset the validity attribute
    }

    handleEnter(event){
        if(event.keyCode === 13){
          this.handleInvoiceSearch();
        }
    }

    handleCancel() {
         // Fire the custom event
         this.dispatchEvent(new CustomEvent('cancel', {}));    
    }

    handleContinue() {
        var dto = {};
        dto.invoiceNumber = this.invoiceNumber;
        dto.invoiceData = this.invoiceDTO;
        const continueEvent = new CustomEvent("continue", {
            detail: dto 
          });
        this.dispatchEvent(continueEvent);
    }
    // ===================================================
    // PRIVATE METHODS
    // ===================================================

    clearInvoiceData() {
        this.invoiceNumber = '';
        this.invoiceDate = '';
        this.salesRep = '';
        this.customer = '';
        this.salesOrg = '';
        this.salesOffice = '';
        this.amountString = '';
        this.numItems = '';
        this.daysWarning = false;
    } 


}