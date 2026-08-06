import { LightningElement, wire } from 'lwc';
import getInvoiceLines from '@salesforce/apex/CaseClaimsController.getInvoiceLines';
import createClaimsFromString from '@salesforce/apex/CaseClaimsController.createClaimsFromString';
import notifyNewClaims from '@salesforce/apex/CaseClaimsController.notifyNewClaims';
import getAPIData from '@salesforce/apex/CaseClaimsController.getAPIData';
import hasClaimsPermission from "@salesforce/customPermission/CASE_CLAIMS_USER";
import { gql, graphql } from 'lightning/uiGraphQLApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import USER_ID from '@salesforce/user/Id';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import CASE_PROBLEM_FIELD from "@salesforce/schema/Case.Problem__c";
import { LABELS } from './labels';

const ICON_CURRENT = 'utility:forward';
const ICON_DONE = 'utility:check';
const ICON_PENDING = 'utility:choice';

import USER_SALES_ORGS_FIELD from "@salesforce/schema/User.Sales_Org__c";
import USER_CHANNEL_FIELD from "@salesforce/schema/User.Distribution_channel__c";
const USER_FIELDS = [USER_SALES_ORGS_FIELD, USER_CHANNEL_FIELD];

export default class InvoiceSelectionWindow extends LightningElement {

    labels = LABELS;

    formData={invoiceNumber:null, selectedLines:[]};   
    selectedIndex = -1; 
    invoiceNumber = null;
    invoiceData;    
    salesOrg;
    salesOrgName;
    queryName='';
    currentStep = 1;
    numberOfSelectedLines = 0;
    invoiceLines = [];
    caseCreated = false;
    newCase;
    errorObject;
    showSpinner = false;
    userId = USER_ID;
    error99;
    defectOptions;

    get uploadedFiles() {
        return this.currentItem?.filesToUpload;
    }

    get userSalesOrgs() {
        return getFieldValue(this.userRecord.data, USER_SALES_ORGS_FIELD);
    }

    get claimRecordType() {
        return this.apiData?.data?.claimRecordType;
    }

    get fileUploadURL() {
        return this.apiData?.data?.fileUploadURL;
    }

    get apiKey() {
        return this.apiData?.data?.apiKey;
    }

    get selectedLines() {
        return this.formData?.selectedLines;
    }

    get currentItem() {
        let ci = null;
        if (this.formData?.selectedLines?.length > 0 && this.selectedIndex >= 0 ) {
            ci = this.formData.selectedLines[this.selectedIndex];
        }
        return ci;
    }

    get headerText() {
        if (this.isStep99) {
            return this.labels.dictMissingAuthorisation;
        } else if (this.isStep1) {
            return this.labels.caseCreateStep1Title;
        } else if (this.isStep2) {
            return this.labels.caseCreateStep2Title;
        } else if (this.isStep3) {
            return this.labels.caseCreateStep3Title + ' (' + (this.selectedIndex + 1) + '/' + this.formData.selectedLines.length + ')';
        } else {
            return this.labels.caseCreateStep4Title;
        }
    }

    get disablePrevious() {
        return (this.isStep1 || this.isStep99);
    }

    get disableNext() {
        return (!this.invoiceOK || this.currentStep === 99 || (this.currentStep === 2 && this.numberOfSelectedLines === 0));
    }

    get nextLabel() {
        if (this.isStep4) {
            return this.labels.dictButtonFinish;
        } else {
            return this.labels.nextButtonLabel;
        }
    }

    get invoiceOK() {
        return this.invoiceData != null;
    }

    get isStep1() {
        return (this.currentStep === 1);
    }

    get isStep2() {
        return (this.currentStep === 2);
    }

    get isStep3() {
        return (this.currentStep === 3);
    } 

    get isStep4() {
        return (this.currentStep === 4);
    } 

    get isStep99() {
        return (this.currentStep === 99)
    }

    get icon1() {
        return this.getIconForStep(1);
    }

    get icon2() {
        return this.getIconForStep(2);
    }

    get icon3() {
        return this.getIconForStep(3);
    }

    get icon4() {
        return this.getIconForStep(4);
    }

    get bearerToken() {
        return  ''; //this.apiData.data.token;
    }

    get uploadURL() {
        return 'this.apiData.data.url';
    }

    // ===============================================================================

    connectedCallback() {
        if (!hasClaimsPermission) {
            this.error99 = this.labels.caseClaimsNotPermitted;
            this.currentStep = 99;           // Error state
        }
    }

    renderedCallback() {
        const invoiceField = this.template.querySelector('[data-id="invoiceNumber"]');
        if (invoiceField) {
            //invoiceField.value = '6215100036';
            invoiceField.focus();
        }
    }

    handlePrevious() {
        if (this.currentStep === 4) {
            if (this.selectedIndex >= this.formData.selectedLines.length) {
                this.selectedIndex = this.formData.selectedLines.length - 1;
                this.currentStep--;
            }
        } else if (this.currentStep === 3) {
            if (this.selectedIndex > 0) {
                this.selectedIndex--;
            } else {
                this.currentStep--;                
            }
        } else if (this.currentStep > 1) {
            this.currentStep--;            
        }
    }

    handleNext() {
        switch (this.currentStep) {
            case 1:             // Invoice selection
                if (this.invoiceOK) {
                    this.currentStep = 2;
                }
                break;
            case 2:             // Select invoice lines in claim
                if (this.numberOfSelectedLines > 0) {
                    this.setSelectedLines();
                    if (this.validateSelectedLines()) {
                        this.currentStep = 3;                    
                    }
                }
                break;
            case 3:             // Add details (per line)                
                this.selectedIndex++;
                if (this.selectedIndex >= this.formData.selectedLines.length) {
                    this.currentStep = 4;
                    this.prepareSelectedLines();
                } else {
                    this.refreshProblemDescription();
                }
                break;
            case 4:
                this.createNewClaim();
                break;
            default:
                break;
        }
    }

    handleDone() {
        this.showSpinner = false;
        if (this.currentStep === 4) {
            this.handleNext();
        }
    }

    handleSearch() {       
        this.showSpinner = true; 
        const invoiceField = this.template.querySelector('[data-id="invoiceNumber"]');
        this.queryName = 'InvoiceQuery';
        this.invoiceNumber = invoiceField?.value;
    }

    handleLineDefectChanged(event) {
        const v = event.target.value;
        const index = event.target.dataset.index;
        this.invoiceLines[index].problem = v;
        this.invoiceLines[index].disabled = (v === '');
        const inputElement = this.template.querySelector("[data-id='"+ this.invoiceLines[index].inputId +"']");
        if (inputElement) {
            inputElement.disabled = this.invoiceLines[index].disabled;
            if (inputElement.disabled) {
                inputElement.value = 0;
                this.invoiceLines[index].defective = 0;
            }
        } 
        this.countSelectedLines();
    }

    handleLineUnitsChanged(event) {
        const v = event.target.value;
        const index = event.target.dataset.index;
        this.invoiceLines[index].defective = v;
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
            });
            reader.readAsDataURL(file);            
        }
    }

    handleItemRemove(event) {
        //const name = event.detail.item.name;
        const index = event.detail.index;
        this.currentItem.filesToUpload.splice(index, 1);
        this.currentItem.filesData.splice(index, 1);        
        const pills = this.template.querySelector('[data-id="pills-container"]');
        if (pills) {
            pills.items = this.currentItem.filesToUpload;
        }
        console.log('--> (-) FilesToUpload (pills) queda así: ' + JSON.stringify(this.currentItem.filesToUpload));
        console.log('--> (-) FilesData (attachments) queda así: ');
        for (let i = 0; i < this.currentItem.filesData.length; i++) {
            console.log('--> ' + this.currentItem.filesData[i].fileName);
        }
    }

    handleDescriptionChange(event) {
        this.currentItem.ProblemDescription = event.detail.value;
    }

    handleClose(event) {
        this.isLoading = false;
        this.dispatchEvent(new CustomEvent('close', {}));   
    }

    handleCancel() {
        // Fire the custom event
        this.dispatchEvent(new CustomEvent('cancel', {}));    
    }

    showToast(title, variant, message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                variant: variant,
                message: message,
            })
        );
    }

    getIconForStep(step)  {
        if (this.currentStep < step) { 
            return ICON_PENDING; 
        } else if (this.currentStep == step) { 
            return ICON_CURRENT; 
        } else { 
            return ICON_DONE;  
        }
    }
    countSelectedLines() {
        let c = 0;
        for (let i = 0; i < this.invoiceLines.length; i++) {
            if (this.invoiceLines[i].problem !== '') {
                c++;
            }
        }
        this.numberOfSelectedLines  = c;
    }

    setSelectedLines() {
        this.formData.selectedLines = [];
        for (let i = 0; i < this.invoiceLines.length; i++) {
            if (this.invoiceLines[i].problem !== '') {
                let sline = {};
                sline.Position = i + 1;
                sline.Invoice = this.invoiceLines[i].Invoice;
                sline.Line = this.invoiceLines[i].Line;
                sline.ProductId = this.invoiceLines[i].ProductId;
                sline.ProductCode = this.invoiceLines[i].ProductCode;
                sline.ProductName = this.invoiceLines[i].ProductName;
                sline.defective = this.invoiceLines[i].defective;
                sline.SalesUnit = this.invoiceLines[i].SalesUnit;
                sline.invoiceQuantity = this.invoiceLines[i].Quantity;
                sline.QuantityString = sline.defective + ' ' + sline.SalesUnit;
                sline.problem = this.invoiceLines[i].problem;
                sline.description = this.searchProblemLabel(this.invoiceLines[i].problem);
                sline.ProblemDescription = '';
                sline.filesToUpload = [];
                sline.filesData = [];                
                this.formData.selectedLines.push(sline);
            }
        }
        this.selectedIndex = 0;
    }

    validateUserOrgs() {
        const invoiceOrg = this.invoiceData?.SalesOrg;
        if (!this.userSalesOrgs?.includes(invoiceOrg)) {
            console.log('=================================================================');
            console.log('Error validating access to the invoice sales organisation: ' + invoiceOrg);
            console.log('User has access to: ' + this.userSalesOrgs);
            console.log('=================================================================');
            this.error99 = this.labels.caseMissingOrgAuth.replace('{0}', invoiceOrg);
            this.currentStep = 99;           // Error state
        }
    }

    validateAccount() {
        if (this.invoiceData?.AccountId === null || this.invoiceData?.AccountId === undefined) {
            console.log('=================================================================');
            console.log('Error retrieving the account ID for sap code ' + this.invoiceData?.AccountSAPCode);
            console.log('=================================================================');
            this.error99 = this.labels.caseSAPCustomerNotFound.replace('{0}', this.invoiceData?.AccountSAPCode);
            this.currentStep = 99;           // Error state
        }
    }


    validateSelectedLines() {
        this.errorObject = []; 
        let isCorrect = true;
        this.formData.selectedLines.forEach((sline) => {
            if (sline.defective <= 0) {
                this.errorObject.push(`[${sline.Position}] ${this.labels.caseFaultyUnits}`);
                isCorrect = false;
            } else if (sline.defective > sline.invoiceQuantity) {
                this.errorObject.push(`[${sline.Position}] ${this.labels.caseFaultyError}`);
                isCorrect = false;
            } 
        });
        return isCorrect;
    }

    prepareSelectedLines() {
        this.formData.selectedLines.forEach((line) => {
            if (line.ProblemDescription) {
                line.ProblemDescriptionText = line.ProblemDescription;
            } else {
                line.ProblemDescriptionText = this.labels.caseNoDescription;
            }
            const l = line.filesToUpload.length;
            if (l == 0) {
                line.AttachmentsText = this.labels.dictNoAttached;
            } else {
                line.AttachmentsText = this.labels.dictNumberAttached.replace('{0}', l);
            }
        });
    }

    searchProblemLabel(value) {
        let i = 0;
        while (i<this.defectOptions.length) {
            if (this.defectOptions[i].value == value) {
                return this.defectOptions[i].label;
            }
            i++;
        }
        return '';
    }

    async createNewClaim() {
        for (let i = 0; i < this.selectedLines.length; i++) {
            for (let j = 0; j < this.selectedLines[i].filesData.length; j++) {
                console.log('--> * ' + this.selectedLines[i].filesData[j].fileName);
            }
        }

        this.showSpinner = true;
        /*
        claimData.Invoice = this.invoiceData.Number;
        claimData.AccountId = this.invoiceData.AccountId;
        claimData.AccountName = this.invoiceData.AccountName;
        claimData.Description = this.problemDescription;
        */
        const products = [];  
        const filesMap = new Map();
        for (let i = 0; i < this.selectedLines.length; i++) {
            const sline = this.selectedLines[i];
            const product = {};
            product.Invoice = sline.Invoice;
            product.Line = sline.Line;
            product.AccountId = this.invoiceData.AccountId;
            product.AccountName = this.invoiceData.AccountName;    
            product.ProductId = sline.ProductId;
            product.ProductCode = sline.ProductCode;
            product.ProductName = sline.ProductName;
            product.Quantity = sline.defective;
            product.SalesUnit = sline.SalesUnit;
            product.Problem = sline.problem;
            product.Description = sline.ProblemDescription;
            products.push(product);
            const key = product.Invoice + '-' + product.Line;
            filesMap.set(key, sline.filesData);
        }   
        console.log("--> Creating claim: " + JSON.stringify(products));
        const caseIds = [];
        createClaimsFromString({ claimsString: JSON.stringify(products) })
        .then(async (result) => {
            for (let i = 0; i < result.length; i++) {
                const newCase = result[i];
                caseIds.push(newCase.Id);
                const key = newCase.SAPInvoice__c + '-' + newCase.SAPInvoiceLine__c;
                const files = filesMap.get(key);
                for (let j = 0; j < files.length; j++) {
                    await this.uploadUsingAPI(newCase.Id, files[j]);
                }
            }            
            notifyNewClaims({ ids: caseIds });
            this.showSpinner = false;
            this.newCase = result;
            this.caseCreated = true;

         })
        .catch((error) => {
            this.showSpinner = false;
            console.log('--> Error creating claim: ' + error);
            console.log('--> ' + JSON.stringify(error));
            this.errorObject = error;
        });            

    }

    async uploadUsingAPI(caseId, fileDTO) {
        const fileString = fileDTO.fileContent;
        const fileName = fileDTO.fileName;        

        const body = {};
        body.Title = fileName;
        body.PathOnClient = fileName;
        body.VersionData = fileString;
        body.FirstPublishLocationId = caseId;
        
        try {
            const response = await fetch(this.fileUploadURL, {
                method: "POST",
                body: JSON.stringify(body),
                headers: {                    
                    "Content-type": "application/json",
                    "APIKey": this.apiKey
                },
                redirect: "follow"
            });
            //"Content-Security-Policy": "connect-src 'self' 'porcelanosa-api-des.test.apimanagement.eu20.hana.ondemand.com'",
            console.log("La response es " + response);
            console.log("La response (O) es " + JSON.stringify(response));        
        } catch(error) {
            console.error('==> ERROR ' + error);
        }
        
        /*
        .then(response => {
            if (response.ok) {
            }
        });
        */
    }

    refreshProblemDescription() {        
        const field = this.template.querySelector('[data-id="problem-description"]');
        if (field) {
            field.value = this.currentItem.problemDescription;
        }
    }


    // ===============================================================================
    //  WIRED QUERIES
    // ================================================================================*/


    @wire(getPicklistValues, { recordTypeId: "$claimRecordType", fieldApiName: CASE_PROBLEM_FIELD })
    picklistResults({ error, data }) {
      if (data) {
        //this.setProblemOptions(data.values);
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

    @wire(getRecord, { recordId: '$userId', fields: USER_FIELDS })
    userRecord;

    @wire(getAPIData) apiData;  

    @wire(getInvoiceLines, { invoiceNumber: "$invoiceNumber" }) 
        invoiceLinesMethod({error, data}) {
            this.invoiceLines = [];
            if (data) {
                for (let i = 0; i < data.length; i++) {
                    let line = { ...data[i] };
                    line.index = i;
                    line.className = (i % 2  == 0) ? "slds-var-p-horizontal_small table-row-even" : "slds-var-p-horizontal_small table-row-odd";
                    line.defective = '';
                    line.problem = '';
                    line.disabled = true;
                    line.inputId = 'input-' + line.index;
                    this.invoiceLines.push(line);                    
                }                
            }  else if (error)  {
                console.log('Error on getInvoiceLines ' + error);
                console.log('Error on getInvoiceLines (JSON)' + JSON.stringify(error));
                this.showToast('Error!', 'error', 'Error reading the invoice lines');
            }
            this.numberOfSelectedLines = 0;        
        };

    @wire(graphql, {
        query: gql`
            query InvoiceQuery($invoiceNumber: String) {
                uiapi {
                    query {
                        Facturas_cabeceraSet__x(where: { Ordernum__c: { eq: $invoiceNumber } }) { 
                            edges {
                                node {
                                    Ordernum__c { value }
                                    Orderdate__c { value, displayValue }
                                    Salesorg__c { value }
                                    Dnet__c { value }     
                                    Dtax__c { value }
                                    Dtotal__c { value }
                                    Dcurr__c { value }
                                    BillTo__c { value }                          
                                    Account__c { value }     
                                    Account__r { Name { value }  }     
                                }
                            }
                        }
                    }
                }
            },
            query SalesOrgQuery($salesOrg: String) {
                uiapi {
                    query {
                        Sales_Org__c(where: { SalesOrg__c: { eq: $salesOrg }})
                        {
                            edges {
                                node {
                                    Name { value }
                                }
                            }
                        }
                    }
                }
            } 
            `,
            variables: '$queryVariables',
            operationName: '$queryName'
        }) graphqlQueryResult({ data, errors }) {
            //(where: { Ordernum__c: { eq: $invoiceNumber } }) {
            if (data) {
                this.showSpinner = false;
                if (data !== undefined) {
                    if (data.uiapi.query.Facturas_cabeceraSet__x !== undefined) {    
                        const results = data.uiapi.query.Facturas_cabeceraSet__x.edges.map((edge) => ({
                            Number: edge.node.Ordernum__c.value,
                            Date: edge.node.Orderdate__c.value,
                            SalesOrg: edge.node.Salesorg__c.value,
                            Net: edge.node.Dnet__c.value,
                            Tax: edge.node.Dtax__c.value,
                            Total: edge.node.Dtotal__c.value,
                            Currency: edge.node.Dcurr__c.value,
                            AccountId: edge.node.Account__c.value,
                            AccountSAPCode: edge.node.BillTo__c.value,
                            AccountName: edge.node.Account__r?.Name.value,
                        }));                        
                        if (results.length > 0) {
                            this.invoiceData = results[0];
                            this.formData.invoiceNumber =  this.invoiceNumber;
                            this.salesOrg = this.invoiceData.SalesOrg;
                            this.queryName = 'SalesOrgQuery';
                            this.validateUserOrgs();
                            this.validateAccount();
                        } else if (this.invoiceNumber?.length > 0) {
                            alert("Invoice does not exist");
                            return;
                        } 
                    } else if (data.uiapi.query.Sales_Org__c!== undefined) {                        
                        const results = data.uiapi.query.Sales_Org__c.edges.map(edge => edge.node);
                        if (results.length > 0) {
                            this.salesOrgName = this.salesOrg + ' - ' + results[0].Name?.value;
                        } else {
                            this.error99 = this.labels.caseOrgNotFound?.replace('{0}', this.salesOrg);
                            this.currentStep = 99;           // Error state
                        }
                    }
                } else {
                    alert("Me llega un data a undefined");
                }
            } 
            if (errors) {
                console.log("> GRAPH-QL Errors " + JSON.stringify(errors));
            }
            //this.errors = errors;
        }
    
    get queryVariables() {
        return {      
            invoiceNumber: this.invoiceNumber,      
            salesOrg: this.salesOrg
        };
    }


}