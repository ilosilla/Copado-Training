/**
 * **caseInvoiceCreate**
 *
 * Author: Ramón Prades  
 * Date: January 2025  
 *
 * *Description:  
 * This component manages the creation of invoice-related cases, specifically Claims and Returns, using a guided wizard.
 *
 * Due to its complexity, the wizard is divided into multiple subcomponents, each representing a distinct step in the process.  
 * Each step component must notify the parent (`caseInvoiceCreate`) whenever its readiness status changes.  
 * It does so by firing a `"stepready"` event, passing `true` or `false` as the event argument.  
 *
 * ?Translation Prefix: tr0009
 *
 * ---
 *
 * *Wizard State Variables:
 * 
 * - currentStep (Integer): The current step in the wizard.
 * - substep (Integer): The substep in step 3 (attachemtns and description)
 * - caseData: Stores information collected throughout the wizard.
 *   > caseType: "CLAIM" or "RETURN"
 *   > recordType
 *   > invoiceNumber
 *   > invoiceHeader
 *   > invoiceItems 
 *   > selectedItems
 *   > apiData (Object): Contains metadata, such as record type IDs used in the wizard.
 *
 * This object is passed to each step subcomponent, which must update it accordingly.  
 * The main component retrieves the updated object through the property "caseData," which each subcomponent must make available in its API.
 * 
 * ---
 * 
 * *API Subcomponents
 * 
 * Each subcomponent responsible for a step implements the following API:
 * - caseData: A get/set property for passing and receiving case data (see structure above).
 * - stepReady: Signals the main component that the step is ready to proceed.
 * - showSpinner: Requests the parent component to show or hide the loading spinner.
 *
 */

//import { LightningModal } from 'lightning/modal';
import { LightningElement, wire } from 'lwc';
import { IsConsoleNavigation, getFocusedTabInfo, closeTab, setTabLabel } from 'lightning/platformWorkspaceApi';
import hasCollectionsPermission from "@salesforce/customPermission/CASE_COLLECTIONS_USER";
import hasClaimsPermission from "@salesforce/customPermission/CASE_CLAIMS_USER";
//import isClaimsEditor from "@salesforce/customPermission/CASE_CLAIMS_EDITOR";
import { parseErrors } from 'c/libCommons';
import { showWarningToast } from 'c/libCommons';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

// Controller methods
import getAPIData from '@salesforce/apex/CaseClaimsController.getAPIData';
import createClaims from '@salesforce/apex/CaseClaimsController.createClaims';
import notifyNewClaims from '@salesforce/apex/CaseClaimsController.notifyNewClaims';
import saveSAPCase from '@salesforce/apex/SAPCasesController.saveSAPCase';
//import createSAPCollection from '@salesforce/apex/SAPCasesController.createSAPCollection';

import { LABELS } from './labels';

export default class CaseInvoiceCreate extends LightningElement {

    MAX_STEPS = 4;
    labels = LABELS;
    showSpinner = true;
    apiDataReady = false;
    
    currentStep;
    substep = 0;
    stepReady = false;  
    fatalErrorMessage = '';
    caseCreated = false;
    returnCaseId = null;

    @wire(IsConsoleNavigation) isConsoleNavigation;
    @wire(getAPIData) wiredAPIData({ error, data }) {
        if (data) {   
            console.info('API DATA READ' + JSON.stringify(data));
            this.setAPIData(data);
        } else if (error) {
            this.fatalError(this.labels.tr0009_020); // 'Error reading API data from the server');
        }
    }

    // Wizard data
    caseData = {
        caseType: null,
        recordType: null,
        invoiceNumber: null,
        invoiceHeader: null,
        invoiceItems: [],
        selectedItems: [],
        apiData: {}
    };

    //******************************************************
    //** Properties Getters
    //******************************************************

    get caseCreatedTitle() {
        return this.labels.caseClaimCreated;
    }

    get caseCreatedBody() {
        if (this.isClaim) {
            if (this.isClaimsEditor) {
                return this.labels.caseClaimCreatedEditor;
            }
            return this.labels.caseClaimCreatedBody;
        }
        // Return
        const url = '/' + this.returnCaseId;        
        return this.labels.caseReturnCreatedEditor.replace("{0}", url);
    }

        
    get isClaim() {
        return this.caseData.caseType === 'CLAIM';
    }

    get isReturn() {
        return this.caseData.caseType === 'RETURN';
    }

    get disablePrevious() {
        return (this.currentStep === 0);
    }

    get disableNext() {
        return (this.currentStep > 0 && !this.stepReady );
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

    get isFatalError() {
        return (this.currentStep === 99);
    }

    get showPrevious() {
        return (!this.isFatalError && this.currentStep > 1);
    }
    
    get topClass() {
        return "slds-modal slds-fade-in-open " + ( this.currentStep === 0 ? "slds-modal_small": "slds-modal_medium");
    }
    
    get showSplash() {
        return (this.currentStep === 0);
    }

    get showFooter() {
        return (this.currentStep > 0);
    }

    get nextLabel() {
        if (this.isFatalError) {
            return this.labels.dictButtonClose;
        }        
        if (this.currentStep === this.MAX_STEPS) {
            return this.labels.dictButtonFinish;
        }
        return this.labels.dictButtonNext;
    }

    get headerText() {
        if (this.isStep1) {
            return this.labels.tr0009_003; // Invoice Selection
        } else if (this.isStep2) {
            return this.labels.tr0009_005;
        } else if (this.isStep3) {
            if (this.isClaim)  {
                return this.labels.tr0009_007 + ' (' + (this.substep + 1) + '/' + this.caseData.selectedItems.length + ')';
            } 
            return this.labels.tr0009_007;
        }
        return this.labels.tr0009_009;
    }

    //**************************************************
    //** Methods
    //**************************************************

    getCaseRecordType() {
        if (this.isClaim) {
            return this.claimRecordType;
        }
        return this.returnsRecordType;
    }

    setAPIData(data) {           
        this.caseData.apiData = data;
        /*{
            claimRecordType:  data.claimRecordType,
            returnsRecordType:  data.returnsRecordType,
            fileUploadURL:  data.fileUploadURL,
            apiKey:  data.apiKey,
            unitsMap: data.unitsMap,
            policyDays
        } 
            */             
        this.caseData.recordType = (this.isClaim ? this.caseData.apiData.claimRecordType : this.caseData.apiData.returnsRecordType);
        console.info('==> Assigned Record Type is ' + this.caseData.recordType);
        this.apiDataReady = true;
        this.showSpinner = false;
    }

    connectedCallback() {
        if (hasClaimsPermission && hasCollectionsPermission) {
            this.currentStep = 0;    
        } else if (hasClaimsPermission) {
            this.currentStep = 1;
            this.caseData.caseType = 'CLAIM'
        } else if (hasCollectionsPermission) {
             this.caseData.caseType = 'RETURN'
        } else {
           this.fatalError(this.labels.tr0009_037) 
        }
        this.setTabLabel();        
    }

    getCaseDataFromStep() {
        const step = this.template.querySelector('c-case-invoice-create-step' + this.currentStep);
        if (step) {            
            this.caseData = step.caseData;
        }
    }

    fatalError(message) {
        if (Array.isArray(message)) {
            this.fatalErrorMessage = message[0];
        } else {
            this.fatalErrorMessage = message;  
        }
        this.showSpinner = false;
        this.currentStep = 99;
    }

    async closeTab() {
        if (!this.isConsoleNavigation) {
            return;
        }
        const { tabId } = await getFocusedTabInfo();
        await closeTab(tabId);
    }

    async setTabLabel() {
        if (!this.isConsoleNavigation) {
            return;
        }
        const { tabId } = await getFocusedTabInfo();
        setTabLabel(tabId, this.labels.tr0009_021); // New SAP Invoice Case
    }



    //=============================================
    // EVENT HANDLERS
    //=============================================

    handleNext() {
        if (this.isFatalError) {
            this.closeTab();            
        }
        if (this.isClaim && this.currentStep === 3 && this.substep < (this.caseData.selectedItems.length - 1)) {
            this.substep++;
            return;
        } 

        if (this.currentStep < this.MAX_STEPS) {
            this.getCaseDataFromStep();
            if (this.currentStep === 2) {
                this.substep = 0;
            } 
            this.currentStep++;
        } else {
            if (this.isClaim) {
                this.createClaims();
            } else if  (this.isReturn) {
                this.createReturnCase();
            }                           
        }
    }

    handlePrevious() {
        if (this.currentStep > 0) {            
            if (this.isClaim && this.currentStep === 3 && this.substep > 0) {
                this.substep--;
            } else {
                this.getCaseDataFromStep();
                this.currentStep--;
            }
        }
    }

    handleCancel() {
        this.closeTab();
    }

    handleStart(event) {
        this.caseData.caseType = event.detail;
        this.caseData.recordType = (this.isClaim ? this.caseData.apiData.claimRecordType : this.caseData.apiData.returnsRecordType);
        console.info('==> Assigned Record Type is ' + this.caseData.recordType);
        this.currentStep = 1;
    }

    handleStepReady(event) {
        this.stepReady = event.detail;                
    }

    handleSpinner(event) {
        this.showSpinner = event.detail;
    }

    //**********************************
    //** Server Methods
    //**********************************

    //** Claims Creation Methods
    
    async createClaims() {
        this.showSpinner = true;
        const claims = this.buildClaimArguments();
        const caseIds = [];
        createClaims({ claims: claims.cases })
        .then(async (result) => {
            console.info("==> createClaims has returned: " + JSON.stringify(result));
            console.info('==> Uploading files to ' + this.caseData.apiData.fileUploadURL);
            for (let i = 0; i < result.length; i++) {
                const newCase = result[i];
                caseIds.push(newCase.Id);
                const key = Number(newCase.SAPInvoice__c) + '-' + Number(newCase.SAPInvoiceLine__c);
                const files = claims.filesMap.get(key);
                console.info(`Case ${newCase.Id} has ${files?.length} attached`);
                if (files !== null && files !== undefined) {                
                    for (let j = 0; j < files.length; j++) {
                        await this.uploadUsingAPI(newCase.Id, files[j]);
                    }
                }
            }                
            notifyNewClaims({ ids: caseIds });
            this.showSpinner = false;
            this.newCase = result;
            this.caseCreated = true;
            })
        .catch((error) => {
            this.showSpinner = false;
            console.error('--> Error creating claim: ' + error);
            console.error('--> ' + JSON.stringify(error));
            this.fatalError(parseErrors(error));            
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
            const response = await fetch(this.caseData.apiData.fileUploadURL, {
                method: "POST",
                body: JSON.stringify(body),
                headers: {                    
                    "Content-type": "application/json",
                    "APIKey": this.caseData.apiData.apiKey
                },
                redirect: "follow"
            });
        } catch(error) {
            showWarningToast(this.labels.tr0009_014, true);
            console.error('==> ERROR UPLOADING FILES' + error);
            console.error('==> ERROR UPLOADING FILES' + JSON.stringify(error));
        }
        
        /*
        .then(response => {
            if (response.ok) {
            }
        });
        */
    }

    buildClaimArguments() {
        const cases = [];
        const header = this.caseData.invoiceHeader;
        const filesMap = new Map();        
        for (const index of this.caseData.selectedItems) {
            const item = this.caseData.invoiceItems[index];
            const claim = {};
            claim.Invoice = header.Ordernum__c;
            claim.Line = item.Orderlin__c;
            claim.AccountId = header.Account__c;
            claim.AccountName = header.accountName;    
            claim.ProductId = item.productId;
            claim.ProductCode = item.Sku__c;
            claim.ProductName = item.Name__c;
            claim.Quantity = item.defective;
            claim.SalesUnit = item.Vrkme__c;
            claim.Problem = item.problem;
            claim.Description = item.problemDescription;
            cases.push(claim);
            const key = Number(claim.Invoice) + '-' + Number(claim.Line);
            filesMap.set(key, item.filesData);            
        }
        return {
            cases: cases,
            filesMap: filesMap
        }
    }

    //** Returns Creation Methods

     createReturnCase() {
        // some default values
        this.showSpinner = true;
        const caseObject = this.buildReturnCase();
        saveSAPCase({ sapCase: caseObject.case, strItems: JSON.stringify(caseObject.lines)})
            .then(async (result) => {
                this.returnCaseId = result.Id;
                this.showSpinner = false;
                this.caseCreated = true;
                console.info('==> Returns Case created ' + this.returnCaseId);
                notifyRecordUpdateAvailable([{recordId: this.returnCaseId}]);
                console.info(`The return case has ${caseObject.files?.length} attached`);
                if (caseObject.files !== null && caseObject.files !== undefined) {                
                    for (let j = 0; j < caseObject.files.length; j++) {
                       await this.uploadUsingAPI(this.returnCaseId, caseObject.files[j]);
                    }
                }
            })
            .catch((error) => {
                this.showSpinner = false;
                console.error('--> Error creating claim: ' + error);
                console.error('--> ' + JSON.stringify(error));
                this.fatalError(parseErrors(error));                
            });            
    }

    buildReturnCase() {
        const lines = [];
        const header = this.caseData.invoiceHeader; 
        const returnHeader = {};
        for (const index of this.caseData.selectedItems) {
            const item = this.caseData.invoiceItems[index];
            const returnLine = {};
            returnLine.lineNo = item.Orderlin__c;
            returnLine.product2Id = item.ProductId;
            returnLine.productCode = item.Sku__c;
            returnLine.productName = item.Name__c;            
            returnLine.collected = item.defective;
            returnLine.unit = item.Vrkme__c;
            lines.push(returnLine);
            if (index === 0) {
                returnHeader.description = item.problemDescription;
                returnHeader.filesData = item.filesData;
                returnHeader.problem = item.problem;
            }
        }
        const returnCase = {};
        returnCase.IsCollection__c = true;
        returnCase.Subject = (this.labels.tr0009_018.replace("{0}", header.accountName).replace("{1}", header.Ordernum__c) ?? this.labels.tr0009_022); // Customer Return Request
        returnCase.AccountId = header.Account__c;
        returnCase.Description = returnHeader.description;
        returnCase.Problem = returnHeader.problem;
        returnCase.RecordTypeId = this.caseData.recordType;
        returnCase.SAPInvoice__c = header.Ordernum__c;
        returnCase.CreditRequired__c = true;
        returnCase.Reason = 'E08_1'; // Surplus

        return {
            case: returnCase,
            lines: lines,
            files: returnHeader.filesData
        }
    }

}