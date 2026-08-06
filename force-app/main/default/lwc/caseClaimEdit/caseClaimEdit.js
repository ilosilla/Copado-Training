/**
 * Edit a claim (called from caseCollectionEdit lwc component)
 * Ramón, 2024
 * 
 * How to do common tasks:
 * - Save the claim and do something:
 *          this.submitCallbackMethod = this.sendFactoryEmail;
 *          this.submitRollbackMethod = null;
 *          this.commitForm();    
 * 
 */
import { LightningElement, api, wire } from 'lwc';
import { gql, graphql } from 'lightning/uiGraphQLApi';
import getInvoiceLine from '@salesforce/apex/CaseClaimsController.getInvoiceLine';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import saveSAPCase from '@salesforce/apex/SAPCasesController.saveSAPCase';
import emailClaimToFactory from '@salesforce/apex/SAPCasesController.emailClaimToFactory';
import LightningConfirm from 'lightning/confirm';
import LightningPrompt from 'lightning/prompt';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createCompensationOrder from '@salesforce/apex/SalesOrdersController.createCompensationOrder';
import hasApprovalPermission from "@salesforce/customPermission/CASEApproveClaims";
import hasEditionPermission from "@salesforce/customPermission/CASE_CLAIMS_EDITOR";
import hasOpenAIPermission from "@salesforce/customPermission/CASE_CLAIMS_OPENAI";
import requestApproval from  '@salesforce/apex/SAPCasesController.requestApproval';
//import sendSolutionToCustomer from '@salesforce/apex/CaseClaimsController.sendSolutionToCustomer';
import approveCase from  '@salesforce/apex/SAPCasesController.approveCase';
import USER_ID from "@salesforce/user/Id";
import ACCOUNT_BUSINESS_EMAIL_FIELD from "@salesforce/schema/Account.Business_Email__c";
import ACCOUNT_PERSON_EMAIL_FIELD from "@salesforce/schema/Account.PersonEmail";
const ACCOUNT_FIELDS = [ACCOUNT_BUSINESS_EMAIL_FIELD, ACCOUNT_PERSON_EMAIL_FIELD];
import PRODUCT_MARCA_FIELD from "@salesforce/schema/Product2.Marca__c";
import PRODUCT_SAP_FACTORY_FIELD from "@salesforce/schema/Product2.SAPFactory__c";
import PRODUCT_CATALOG_CATEGORY_FIELD from "@salesforce/schema/Product2.SAPItemGroup__r.CatalogCategory__c";
const PRODUCT_FIELDS = [PRODUCT_MARCA_FIELD, PRODUCT_SAP_FACTORY_FIELD, PRODUCT_CATALOG_CATEGORY_FIELD];
import ORDER_NUMBER_FIELD from "@salesforce/schema/Order.OrderNumber";
import ORDER_STATUS_FIELD from "@salesforce/schema/Order.Status";
import ORDER_SAP_ID_FIELD from "@salesforce/schema/Order.Sap_Id__c";
const COLLECTION_ORDER_FIELDS = [ORDER_NUMBER_FIELD, ORDER_SAP_ID_FIELD, ORDER_STATUS_FIELD];
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import summarizeFactoryEmails from '@salesforce/apex/CaseAIController.summarizeFactoryEmails';
import { LABELS } from './labels';
import * as LibCommons from 'c/libCommons';
import libCustomTextModal from 'c/libCustomTextModal';


const K_REPLACEMENT_TYPE = 'Z051';
const K_FREE_COLLECTION_TYPE = 'Z018_F';
//const K_COMPENSATION_TYPE = 'Z017';

export default class CaseClaimEdit extends LightningElement {

    label = LABELS;
    //----------------------------------------------------
    // Component API
    //----------------------------------------------------
    @api recordId;
    @api
        save() {
            this.handleSaveClick();
        }

    SOLUTION_REPLACE = 'ReplaceProduct';
    SOLUTION_COVER = 'CoverCosts';
    SOLUTION_COMPENSATE = 'Compensate';

    STATUS_CONSIDERATION = 'Consideration';
    STATUS_PROPOSAL = 'Proposal';
    STATUS_AGREEMENT = 'Agreement';
    STATUS_EXECUTION = 'Execution';
    STATUS_REJECTED = 'Rejected';
    STATUS_CLOSED = 'Closed';
    K_CLOSED_STATUSES = 'CLOSED;REJECTED';
    K_SAP_STATUS='AGREEMENT;EXECUTION;CLOSED;'

    isLoading = true;
    lblTabDetails = 'Details';
    lblTabProducts = 'Products';
    steps = [];
    currentStatus;
    statusBarError
    queryName;
    accountId = null;
    invoiceNumber = null;
    invoiceLine = null;
    invoiceHeader = {};
    invoiceItem = {};
    caseNumber;
    daysOpened = 0;
    dateCreated;   
    compensationAmount = 0;
    orderStatus = null;
    orderId = null;
    orderData = null;
    compensationOrderId = null;
    collectionOrderId = null;
    currentOrderId = null;
    productId;

    factoryContact;
    supplyReplacementFlag = false;
    
    supplyInstallationFlag = false;
    arrangeCollectionFlag = false;
    recommendedCure = null;

    // marcasMap;
    productTypesMap;
    symptomsMap;
    detailsMap;
    causesMap;
    solutionsMap;

    errorTheme;
    errorObject;

    solutionEmail;
 
    // Server accesss methods
    submitServerMethod;     // Server Method to call when submitting the form
    submitCallbackMethod;   // Method to call AFTER server success
    submitRollbackMethod;   // Method to call AFTER server error    
    
    isReasonDisabled = true;
    showOrderDialog = false;

    orderItems = [];
    itemQuantity;
    itemUnit;
    recordLoaded = false;
    tab2Loaded = false;
    originalInquiryDate;

    approvalRequested = null;
    approvedBy;
    approverName;
    approvalDate;
    approved = false;

    productCatalogCategoryDone = false;
    lastFactoryResponse = null;
    
    /*get historyTitle() {
        return 'Solutions History (' + this.historyLines.length + ')';
    }

    get hasHistory() {
        return this.historyLines.length > 0;
    }*/

    @wire (getRecord, { recordId: '$accountId', fields: ACCOUNT_FIELDS}) accountData;
    @wire (getRecord, { recordId: '$productId', fields: PRODUCT_FIELDS}) productData;
    @wire (getRecord, { recordId: '$collectionOrderId', fields: COLLECTION_ORDER_FIELDS}) collectionOrderData;

    get collectionOrderStatus() {
        return getFieldValue(this.collectionOrderData?.data, ORDER_STATUS_FIELD);
    }

    get productMake() {
        return getFieldValue(this.productData?.data, PRODUCT_SAP_FACTORY_FIELD);
    }

    get productCatalogCategory() {
        return getFieldValue(this.productData?.data, PRODUCT_CATALOG_CATEGORY_FIELD);
    }

    get makeName() {
        let name = 'UNDEFINED';
        switch(this.productMake) {
            case '000':
                name = this.label.dictOtherMake.toUpperCase();
                break;
            case '001':
                name = "L'ANTIC COLONIAL";
                break;
            case '002':
                name = 'PORCELANOSA';
                break;
            case '003':
                name = 'VENIS';
                break;
            case '004':
                name = 'URBATEK';
                break;
            case '006':
                name = 'NOKEN';
                break;
            case '007':
                name = 'BUTECH';
                break;
            case '008':
                name = 'KRION';
                break;
            case '009':
                name = 'GAMA DECOR';
                break;
            case '040':
                name = 'XLIGHT';
                break;
            case '041':
                name = 'XTONE';
                break;                                                                        
            default:
                name = this.label.dictUndefined.toUpperCase();
                break;
        }
        return name;
    }

    get customerEmail() {
        let email = null;
        if (this.accountData != null) {
            email = getFieldValue(this.accountData.data, ACCOUNT_BUSINESS_EMAIL_FIELD);
            if (email == null) {
                email = getFieldValue(this.accountData.data, ACCOUNT_PERSON_EMAIL_FIELD);
            }            
        }
        return email;
    }

    get approvalRequestedWarning() {
        let text = '';
        if (this.approvalRequested !== null && this.approvalRequested !== undefined) {
            text = this.label.caseApprovalRequested.replace('{0}', new Date(this.approvalRequested)?.toLocaleDateString());
        }
        return text;
    }

    get proposalApprovedWarning() {
        let text = '';
        if (this.approved) {
            text = this.label.caseProposalApprovedBy.replace('{0}', this.approverName).replace('{1}',  new Date(this.approvalDate).toLocaleDateString());
        }
        return text;
    }

    get isApprovalNeeded() {
        return (this.currentStatus === this.STATUS_CONSIDERATION && !this.approved && this.compensationAmount > 0);
    }

    get isApprover() {
        return (hasApprovalPermission);
    }

    get isProposalEnabled() {
        return (this.proposalReady && (!this.isApprovalNeeded || this.approved));
    }

    get isCollectionOrderActivated() {
        return (this.collectionOrderStatus?.toLowerCase() === 'activated');
    }

    get isOrderActivated() {
        return (this.orderStatus?.toLowerCase() === 'activated');
    }

    get mainTitle() {
        return this.label.claimEditTitle.replace('{0}', this.caseNumber);
    }

    get yesNoOptions() {
        return [
            { label: this.label.dictYes, value: 'yes' },
            { label: this.label.dictNo, value: 'no' },
        ];
    }

    get isSolutionVisible() {
        return (this.recommendedCure?.length > 0) ?? false;
    }

    get proposalSent() {
        return (this.currentStatus !== this.STATUS_CONSIDERATION);
    }

    get isApprovalRequired() {
        return (this.supplyInstallationFlag || this.compensationFlag);
    }

    get isConsideration() {
        return this.currentStatus === this.STATUS_CONSIDERATION;
    }

    get isApproved() {
        return this.currentStatus === this.STATUS_APPROVED;
    }

    get isAgreement() {
        return this.currentStatus === this.STATUS_AGREEMENT;
    }

    get isExecution() {
        return this.currentStatus === this.STATUS_EXECUTION;
    }

    get isClosed() {
        return this.currentStatus === this.STATUS_CLOSED;
    }

    get isOpen() {
        return !this.isClosed && !this.isRejected;
    }

    get isProposal() {
        return this.currentStatus === this.STATUS_PROPOSAL;
    }

    get isRejected() {
        return this.currentStatus === this.STATUS_REJECTED;
    }

    get isClaimInSAP() {
        return this.K_SAP_STATUS.includes(this.currentStatus?.toUpperCase());
    }

    get rejectedClass() {
        let className = 'slds-var-p-horizontal_x-small slds-col slds-size_2-of-2';
        if (!this.isRejected) {
            className += ' slds-hide';
        }
        return className;
    }

    get ageText() {
        let result = '';
        if (this.isClosed) {
            result = this.label.caseClaimClosed; // Claim closed!
        } else if (this.isRejected) {
            result = this.label.caseClaimRejected; // Claim rejected!
        } else if (this.daysOpened === 0) {
            result = this.label.caseClaimCreatedToday; // Claim registered today
        } else if (this.daysOpened === 1) {
            result = this.label.caseClaimCreatedYesterday; // Claim registered yesterday
        } else if (this.daysOpened <= 31) {
            result = this.label.caseClaimCreatedDays.replace('{0}', this.daysOpened);
        } else {
            const tdy = new Date();
            const years = tdy.getFullYear() - this.dateCreated?.getFullYear();   
            const months = tdy.getMonth() - this.dateCreated?.getMonth() + 12 * years;
            if (months === 1) {
                result = this.label.caseClaimLastMonth; // Claim created last month
            } else if (months <= 11) {
                result = this.label.caseClaimCreatedMonths.replace('{0}', months);
            } else if (years === 1) { 
                result = this.label.caseClaimLastYear; // Claim created last year';
            } else {          
                result = this.label.caseClaimCreatedYears.replace('{0}', years);
            }
            
        }
        return result;
    }

    get ageClass() { 
        const baseClass = 'slds-card slds-var-p-around_small';
        let className = '';
        if (this.K_CLOSED_STATUSES.includes(this.currentStatus?.toUpperCase())) {
            className = baseClass + ' slds-theme_info';
        } else if (this.daysOpened <= 7) {
            className = baseClass + ' slds-theme_success ';
        } else if (this.daysOpened <= 14) {
            className =  baseClass + ' slds-theme_warning';
        } else {
            className = baseClass + ' slds-theme_error';
        }
        return className;
    }

    get proposalSentDisabled() {
        return !this.proposalReady;
    }

    get proposalReady() {
        return (this.recommendedCure != null && (this.supplyReplacementFlag || this.supplyInstallationFlag || this.compensationFlag || this.arrangeCollectionFlag));    
    }

    get factoryContactNotSelected() {
        return (!this.factoryContact);
    }

    get supplyReplacementDisabled() {
        return !(this.supplyReplacementFlag && (this.isAgreement || this.isExecution || this.isClosed));
    }

    get arrangeCollectionDisabled() {
        return !(this.arrangeCollectionFlag && (this.isAgreement || this.isExecution || this.isClosed));
    }


    get compensationFlag() {
        return (this.compensationAmount > 0);
    } 

    get compensationDisabled() {
        return (!(this.compensationFlag && this.isAgreement) || this.compensationOrderId);
    }

    get collectionButtonLabel() {             
        if (this.collectionOrderId) {
            if (this.isCollectionOrderActivated) {
                return this.label.dictButtonViewOrder;
            } else {
                return this.label.dictButtonEditOrder;
            }
        } else {
            return this.label.dictButtonCreateOrder;
        }
    }

    get replacementButtonLabel() {             
        if (this.orderId) {
            if (this.isOrderActivated) {
                return this.label.dictButtonViewOrder;
            } else {
                return this.label.dictButtonEditOrder;
            }
        } else {
            return this.label.dictButtonCreateOrder;
        }
    }

    get hasFactoryDate() {
        return (this.factoryDate);
    }

    get factoryDate() {
        return this.template.querySelector('[data-id = "FactoryInquiryDate__c"]')?.value;
    }

    get factorySectionTitle() {
        let title = this.label.claimInquirySection     
        if (this.factoryDate) {
            const dt = new Date(Date.parse(this.factoryDate));
            title += ' (' + this.label.dictSentOn .replace('{0}', dt?.toLocaleDateString()) + ')';
        } else if (this.factoryContact) {
            title += ` (${this.label.dictNotSentYet})`;
        }
        return title;
    }

    get factoryReponseNotReceived() {
        return ((this.lastFactoryResponse?.length) === 0 ?? false);
    }

    get hasOpenAIPermission() {
        return hasOpenAIPermission;
    }

    connectedCallback() {
        if (!hasEditionPermission){
            this.dispatchEvent(new CustomEvent('close', {}));    
            this.showToast('error', this.label.caseClaimCantEdit); // You do not have the required permission to edit claims. Please contact your administrator if you believe this is an error.
        } 
    }

    setReportedMakeProblem() {
        const make = this.getDataIdControl('SAPMake__c')?.value;
        const problem = this.getDataIdControl('Problem__c')?.value;
        let control = this.getDataIdControl('ReportedMakeProblem__c');       
        if (control !== null && control !== undefined) {
            if (make !== null && problem !== null) {      
                control.value = make + '-' + problem;
            } else {
                control.value = null;
            }
        }
    }

    setReportedTypeProblem() {        
        const make = this.getDataIdControl('SAPMake__c')?.value;
        const problem = this.getDataIdControl('Problem__c')?.value;
        const ptype = this.getDataIdControl('ProductType__c')?.value;
        let control = this.getDataIdControl('ReportedTypeProblem__c'); 
        if (control !== null && control !== undefined) { 
            if (make !== null && problem !== null && !LibCommons.isBlank(ptype)) {                 
                control.value = make + '-' + ptype + '-' + problem;
            } else {
                control.value = null;
            }
        }
    }

    setProductTypeValue(value) {
        let control = this.getDataIdControl('ProductType__c'); 
        if (control !== null && control !== undefined) {                         
            control.value = value;
            this.setReportedTypeProblem();
        }        
    }

    isBlank(value) {
        return (value === null || value === undefined || value.trim() === '');
    }

    //=======================================================================================================

    /*
    handleSiteVisitChange(event) {
        this.siteVisitSelected = event.target.checked;
    }
    
    handleFactoryChange(event) {
        this.factorySelected = event.target.checked;
    }
    */


    handleRequestApprovalClick() {
        this.confirmRequestApproval();
    }

    async confirmRequestApproval() {
        let text = this.label.caseClaimApprovalConfirm; // The case will be saved and an email will be sent to a supervisor requesting approval for the proposed solution. Do you want to proceed?
        const result = await LightningConfirm.open({
            message: text,
            variant: 'header',
            label: this.label.dictRequestApproval,
            theme: 'Warning'
        });
        if (result) {
            this.submitServerMethod = this.saveCase;
            this.submitCallbackMethod = this.requestApproval;
            this.submitRollbackMethod = null;
            this.commitForm();
        }
    }

    handleApproveClick() {
        this.confirmApproval();
    }

    async confirmApproval() {
        let text = this.label.caseClaimApproveConfirm; // The case will be saved and the proposed solution will be approved and ready to be sent to the customer. Would you like to proceed?
        const result = await LightningConfirm.open({
            message: text,
            variant: 'header',
            label: this.label.caseClaimSolutionApproval, // Solution Approval
            theme: 'Warning'
        });
        if (result) {
            this.submitServerMethod = this.saveCase;
            this.submitCallbackMethod = this.approveClaim;
            this.submitRollbackMethod = null;
            this.commitForm();
        }
    }

    handleRecordLoad(event) {
        if (this.recordId) { 
            const caseFields = event.detail.records[this.recordId].fields;              
            // Some fields aren't included in the first batch of fields received - we read them here
            this.orderStatus = caseFields.OrderStatus__c?.value ?? null;
            this.approvalRequested = caseFields.ApprovalRequested__c?.value;
            this.approvedBy = caseFields.ApprovedBy__c?.value;
            this.approverName = caseFields.ApprovedBy__r?.displayValue;
            this.approvalDate = caseFields.ApprovalDate__c?.value;
            this.approved = caseFields.Approved__c?.value;
            this.productId = caseFields.ProductId?.value;  
            if (!this.recordLoaded) {
                try {
                    if (caseFields.SAPInvoice__c) {
                        this.currentStatus = caseFields.Status.value;      
                        this.buildStatusPath(event.detail.picklistValues.Status);      
                        this.queryName = 'InvoiceQuery';
                        this.accountId = caseFields.AccountId?.value;
                        this.caseNumber = caseFields.CaseNumber?.value;
                        this.invoiceNumber = caseFields.SAPInvoice__c?.value;
                        this.invoiceLine = caseFields.SAPInvoiceLine__c?.value;
                        this.recommendedCure = caseFields.RecommendedCure__c?.value;
                        this.dateCreated = new Date(Date.parse(caseFields.CreatedDate?.value));
                        this.compensationAmount = Number(caseFields.Compensation__c?.value ?? 0);
                        const tdy = new Date();
                        let difference = tdy.getTime() - this.dateCreated.getTime();                    
                        this.daysOpened = Math.round(difference / (1000 * 3600 * 24));
                        this.isLoading = false;  
                        this.setSolutionFlags(caseFields);
                        this.fillComboMaps(event.detail.picklistValues);                                         
                        this.orderId = (caseFields.OrderId__c?.value ?? null);                 
                        this.compensationOrderId = (caseFields.CompensationOrderId__c?.value ?? null);      
                        this.collectionOrderId = (caseFields.CollectionOrderId__c?.value ?? null);
                        this.lastFactoryResponse = (caseFields.FactoryInquiryResponse__c?.value ?? null);                        
                        this.recordLoaded = true;
                        this.setReportedMakeProblem();
                        this.setReportedTypeProblem();
                    }
                } catch(e) {
                    alert("Error: " + e);
                    console.error('Error received in handleRecordLoad: ' + e);
                }
            }
            if (!this.tab2Loaded) {
                const caseFields = event.detail.records[this.recordId].fields; 
                if (caseFields.FactoryInquiryContact__c) {
                    this.factoryContact = caseFields.FactoryInquiryContact__c?.value;
                    this.tab2Loaded = true;
                }                
            }
            if (!this.productCatalogCategoryDone && this.productCatalogCategory) {
                const pt = caseFields.ProductType__c?.value;
                if (pt === null) {
                    this.setProductTypeValue(this.productCatalogCategory);                    
                }
                this.productCatalogCategoryDone = true;
            }
    
        }
    }

    handleRecommendedCureChange(event) {
        this.recommendedCure = event.detail.value;
    }

    handleReplacementChange(event) {
        this.supplyReplacementFlag = event.target.checked;
        const input = this.template.querySelector('[data-id="ReplacementOrderClass__c"]');
        if (this.supplyReplacementFlag && input?.value === null) {
            input.value = 'REPLACE_FULL';
        }
    }

    handleCollectionChange(event) {
        this.arrangeCollectionFlag = event.target.checked;
    }


    handleInstallationChange(event) {  
        this.supplyInstallationFlag = event.target.checked;        
    }

    /*
    handleSettlementChange(event) { 
        this.compensationAmount = Number(event.target.value);
    }
    */

    handleFocusOut(event) { 
        this.compensationAmount = Number(event.target.value);  
    }

    handleStatusPathClick(event) {
        const newStatus = event.target.value;
        if (newStatus !== this.currentStatus) {
            this.changeStatusTo(newStatus);
        }
    }
        
    handleSaveClick() {
        this.submitServerMethod = this.saveCase;
        this.submitCallbackMethod = this.closeForm;
        this.submitRollbackMethod = null;
        this.commitForm();
    }

    handleSubmit(event){
        if (this.submitServerMethod != null) {
            this.isLoading = true;
            event.preventDefault();       // stop the form from submitting
            const fields = event.detail.fields; 
            this.setAdditionalFields(fields);
            this.submitServerMethod(fields);
        }
    }     

    handleProposalSentClick() {
        this.confirmProposalSent();
    }

    /*
    handleEmailCustomerClick() {
        this.confirmCustomerEmail();
    }
    */


    handleProposalAcceptedClick() {
        this.confirmAgreementStatus();
    }

    handleProposalRejectedClick() {
        this.confirmConsiderationStatus();
    }

    handleEditReasonClick() {
        this.isReasonDisabled = false;
    }

    handleReopenClick() {
        this.confirmReopenClaim();
    }

    handleCreateSupplyClick() {
        if (!this.orderId) {
            this.createReplacementOrder();
        } else {
            this.editReplacementOrder();
        }
    }

    handleCreateCollectionClick() {
        if (!this.collectionOrderId) {
            this.createCollectionOrder();
        } else {
            this.editCollectionOrder();
        }
    }

    handleCreateCompensationClick() {
        if (!this.compensationOrderId) {
            this.launchCompensation();
        } 
    }

    handleOrderCancel(event) {
        this.showOrderDialog = false;
    }

    handleOrderClose(event) {
        let notice = '';
        this.showOrderDialog = false;
        let isNew = false;
        if (event.detail?.success) {            
            if (event.detail.order.Type === K_FREE_COLLECTION_TYPE) {
                isNew = (this.colectionOrderId === null);
                notice = this.label.claimLabel016;
                this.collectionOrderId = event.detail.order.Id;                
            } else {
                isNew = (this.orderId === null);
                notice = this.label.claimLabel015;
                this.orderId = event.detail.order.Id;
            }
            notifyRecordUpdateAvailable([{recordId: this.recordId}, {recordId: event.detail.order.Id}]);
            //this.getReplacementOrderStatus();
            if (isNew) {
                this.showToast('success',notice);
            } 
        }
    }

    handleOrderDelete(event) {
        let notice = '';
        this.showOrderDialog = false;
        if (event.detail?.success) {            
            if (this.orderId === event.detail?.orderId) {
                this.orderId = null;                
                notice = this.label.claimLabel021;
            } else if (this.collectionOrderId === event.detail?.orderId) {
                this.collectionOrderId = null;
                notice = this.label.claimLabel022;
            }
        }
        notifyRecordUpdateAvailable([{recordId: this.recordId}, {recordId: event.detail.orderId}]);
        //this.getReplacementOrderStatus();
        if (notice?.length > 0) {
            this.showToast('success', notice);
        } 
    }


    /*
    handleOrderDataReceived(event) {
        const received = event.detail;        
        if (received.success) {
            if (received.data.Id === this.orderId) {
                this.orderStatus = received.data.Status;
            }
        }
    }
    */

    handleSendFactoryEmail(event) {
        this.confirmFactoryEmail();
    }

    handleFactoryContactChanged(event) {
        this.factoryContact = event.target.value;
    }

    handleAISummaryClick() {
        const comp = this.refs.aiSummary;
        comp.invoke();
    }

    //=======================================================================================================
    /*
    confirmCustomerEmail() {
        LightningPrompt.open({
            message: "The proposed solution will be sent to the customer's email shown below. Be aware that once sent, the proposal will be blocked, and no further changes will be allowed.",
            theme: "warning",
            label: 'Customer Notification', // this is the header text
            defaultValue: this.customerEmail
        }).then((result) => {
            if (result === null || result.length == 0) {
                this.showToast('error', 'Wrong email');                
            } else {
                this.solutionEmail = result;
                this.submitServerMethod = this.saveCase;
                this.submitCallbackMethod = this.sendSolution;
                this.submitRollbackMethod = null;
                this.commitForm();
            }
        });
    }
    */

    /*getReplacementOrderStatus() {
        if (this.orderId) {
            const helper = this.refs.LibOrderHelper;
            if (helper) {
                helper.querySAPStatus(this.orderId);
            }
        }
    }*/

    async confirmFactoryEmail() {
        this.resetErrors();
        const fc = this.refs.factoryComments;
        if (!fc?.value) {
            this.errorObject = this.label.caseCommentRequired; // Please enter a text in "Factory Inquiry Comments" before sending the email;
            this.errorTheme = 'error';
            return;
        }
        let text = this.label.caseClaimFactoryConfirm; // The claim will be saved and a summary email will be sent to the selected factory contact. Would you like to continue?;
        const factoryDate = this.template.querySelector('[data-id = "FactoryInquiryDate__c"]')?.value;
        if (factoryDate) {
            text = this.label.caseClaimFactoryWarning; // "You have already sent an inquiry to the factory, but you can resend it. If you proceed, the claim will be saved and a summary email will be sent to the designated factory contact. Would you like to continue?
        }
        const result = await LightningConfirm.open({
            message: text,
            variant: 'header',
            label: this.label.claimInquirySection,
            theme: 'Warning'
        });
        if (result) {     
            this.submitServerMethod = this.sendClaimToFactory;
            this.submitCallbackMethod = this.factoryEmailSent;
            this.submitRollbackMethod = null;
            this.commitForm();
    
        }
    }

    changeStatusTo(newStatus) {
        if (newStatus === this.STATUS_CONSIDERATION) {
            this.confirmConsiderationStatus();
        } else if (newStatus === this.STATUS_PROPOSAL) {
            this.confirmProposalSent();            
        } else if (newStatus === this.STATUS_REJECTED) {
            this.confirmRejectedStatus();
        } else if (newStatus === this.STATUS_AGREEMENT) {
            this.confirmAgreementStatus();
        } else if (newStatus === this.STATUS_EXECUTION) {
            this.setExecutionStatus();
        } else if (newStatus === this.STATUS_CLOSED) {
            this.confirmClosedStatus();
        }
    }

    handleExecutionClick() {
        this.changeStatusTo(this.STATUS_EXECUTION);
    }

    handleCloseClick() {
        this.changeStatusTo(this.STATUS_CLOSED);
    }

    confirmRejectedStatus() {   
        LightningPrompt.open({
            label: this.label.caseClaimRejected, // Claim Rejected!
            theme : 'warning',
            message: this.label.claimEnterReason // Please enter the reason why the claim has been rejected
        }).then((reason) => {
            if (reason) {
                this.setRejectedStatus(reason);                
            } else {
                this.setPathStatus(this.currentStatus);
                this.showToast('warning', this.label.errorReasonMissing); // Status not updated (no rejection reason given!
            }
        });
    }

    setRejectedStatus(reason) {
        this.currentStatus = this.STATUS_REJECTED;
        const input = this.template.querySelector('[data-id="RejectionReason"]');
        if (input) {
            input.value = reason;
        }
        this.submitServerMethod = this.saveCase;
        this.submitCallbackMethod = this.closeForm;
        this.submitRollbackMethod = null;
        this.commitForm();
    }

    commitForm() {
        const submitButton = this.template.querySelector('[data-id="submitButton"]');
        if(submitButton) {
            if (this.checkFieldsValidity()) {
                submitButton.click();
            } 
        }
    }

    async confirmClosedStatus() {    
        this.resetErrors();
        let text = this.label.claimResolvedConfirm; // Please confirm that the claim has been resolved and that the case can be closed.
        const confirmation = await LightningConfirm.open({
            message: text,
            variant: 'header',
            label: this.label.dictConfirmClosing, 
            theme: 'Warning'
        });
        if (confirmation) {                     
            this.setClosedStatus();
        }
    }


    async confirmAgreementStatus() {    
        this.resetErrors();
        if (this.proposalReady) {            
            let text = this.label.claimConfirmAgreement; // "Please confirm the solution's acceptance and customer agreement. The claim will advance to the AGREEMENT phase for solution implementation.";
            const confirmation = await LightningConfirm.open({
                message: text,
                variant: 'header',
                label: this.label.dictConfirmAgreement,
                theme: 'Warning'
            });
            if (confirmation) {                     
                this.setAgreementStatus();
            }
        } else {
            this.setPathStatus(this.currentStatus);
            this.errorObject = this.label.claimLabel001, //'Please select the proposed solution first';
            this.errorTheme = 'warning';            
        }
    }

    setExecutionStatus() {
        this.currentStatus = this.STATUS_EXECUTION;
        this.submitServerMethod = this.saveCase;
        this.submitCallbackMethod = null;
        this.submitRollbackMethod = null;
        this.commitForm();
    }

    setClosedStatus() {
        this.currentStatus = this.STATUS_CLOSED;
        this.submitServerMethod = this.saveCase;
        this.submitCallbackMethod = null;
        this.submitRollbackMethod = null;
        this.commitForm();
    }

    setAgreementStatus() {
        this.currentStatus = this.STATUS_AGREEMENT;
        this.submitServerMethod = this.saveCase;
        this.submitCallbackMethod = null;
        this.submitRollbackMethod = null;
        this.commitForm();
    }

    setPathStatus(sts) {
        const statusComponent = this.refs.progressIndicator;
        if (statusComponent) {
            statusComponent.currentStep = sts;
        }
    }

    async confirmConsiderationStatus() {
        const result = await LightningConfirm.open({
            message: this.label.claimLabel002, // The claim will be taken back to the CONSIDERATION phase. Do you want to continue?,
            theme: "warning",
            label: this.label.claimProposalRejected // 'Proposal Rejected' 
        });
        if (result)  {
            this.setConsiderationStatus();            
        }
    }

    async confirmReopenClaim() {
        const result = await LightningConfirm.open({
            message: this.label.claimLabel003, // 'Do you want to reopen the claim and take it back to the CONSIDERATION phase?',
            theme: "warning",
            label: this.label.claimReopen // 'Reopen Claim' 
        });
        if (result) {
            this.setConsiderationStatus();
        }
    }

    setConsiderationStatus() {
        this.currentStatus = this.STATUS_CONSIDERATION;
        this.submitServerMethod = this.saveCase;
        this.submitCallbackMethod = null;
        this.submitRollbackMethod = null;
        this.commitForm();
    }


    async confirmProposalSent() {
        if (!this.proposalReady) {
            this.errorObject = this.label.claimLabel004; // 'Please qualify the problem before changing the claim status';
            this.errorTheme = 'warning';
            this.setPathStatus(this.currentStatus);
        } else {
            let text = this.label.claimLabel005; // "Please confirm that the proposal has been sent to the customer. Be aware that the proposed solution will be blocked and no further changes will be allowed.";
            const confirmation = await LightningConfirm.open({
                message: text,
                variant: 'header',
                label: this.label.claimLabel006, // 'Proposal Sent',
                theme: 'Warning'
            });
            if (confirmation) {     
                this.setProposalSent();
            } else {
                this.setPathStatus(this.currentStatus);
            }
        }
    }

    setProposalSent() {
        this.currentStatus = this.STATUS_PROPOSAL;
        this.submitServerMethod = this.saveCase;
        this.submitCallbackMethod = null;
        this.submitRollbackMethod = this.rollbackProposalSent;
        this.commitForm();
    }

    setAdditionalFields(fields) {
        fields.Id = this.recordId;        
        fields.Status = this.currentStatus;
        fields.SupplyReplacement__c = this.supplyReplacementFlag;
        fields.SupplyInstallation__c = this.supplyInstallationFlag;
        fields.ArrangeCollection__c = this.arrangeCollectionFlag;
        if (!fields.ReplacementOrderClass__c && this.defaultReplacementOrderClass) {
            fields.ReplacementOrderClass__c = this.defaultReplacementOrderClass;
        }
        if (this.currentStatus === this.STATUS_REJECTED && !fields.RejectionReason__c) {
            // As it is readonly, it is not included by default
            const input = this.template.querySelector('[data-id="RejectionReason"');
            fields.RejectionReason__c = input.value;
        }
    }

    setSolutionFlags(fields) {
        this.supplyReplacementFlag = fields.SupplyReplacement__c?.value ?? false;
        this.supplyInstallationFlag = fields.SupplyInstallation__c?.value ?? false;
        this.arrangeCollectionFlag = fields.ArrangeCollection__c?.value ?? false;
    }

    /**
     * Checks all required fields have a value
     */
    checkFieldsValidity() {
        const allValid = [...this.template.querySelectorAll('lightning-input-field')].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            const fieldOK = (!inputCmp.required || (inputCmp.value != null));
            return validSoFar && fieldOK;
        }, true);
        return allValid;
    }

    //---------------------------------------------------------------------
    // Server Access Methods
    //---------------------------------------------------------------------

    async requestApproval() {    
        try {
            this.isLoading = true;
            const data = await requestApproval({caseId: this.recordId});
            this.approvalRequested = data;
            notifyRecordUpdateAvailable([{recordId: this.recordId}]);
            this.showToast('success', this.label.claimApprovalRequested);
        } catch(ex) {  
            console.error('---> [caseCLaimEdit.js] createCompensationOrder Error');
            console.error(JSON.stringify(ex));
            this.errorObject = ex;
            this.errorTheme = 'error';
            //this.processServerErrors(error);
        } finally {
            this.isLoading = false;
        }
    }

    async approveClaim() {    
        try {
            this.isLoading = true;
            await approveCase({caseId: this.recordId});
            this.approved = true;
            this.approvalDate = new Date();
            this.approvedBy = USER_ID;
            notifyRecordUpdateAvailable([{recordId: this.recordId}]);
            this.showToast('success', 'Claim approved!');
        } catch(ex) {  
            console.error('---> createCompensationOrder Error');
            console.error(JSON.stringify(ex));
            this.errorObject = ex;
            this.errorTheme = 'error';
            //this.processServerErrors(error);
        } finally {
            this.isLoading = false;
        }
    }

    saveCase(fields) {    
        // some default values
        this.isLoading = true;
        this.resetErrors();  
        saveSAPCase({ sapCase: fields })
            .then((result) => {
                this.afterSave();
            })
            .catch((error) => {
                this.processServerErrors(error);
            });            
    }

    sendClaimToFactory(fields) {        
        // some default values
        this.isLoading = true;
        this.resetErrors();        
        emailClaimToFactory({sapCase: fields})
        .then((result) => {
            this.afterSave();
        })
        .catch((error) => {
            this.processServerErrors(error);
        });            
    }

    processServerErrors(error) {
        console.error('--> error in caseClaimEdit.processServerError ' + JSON.stringify(error));
        if (this.submitRollbackMethod != null) {
            this.submitRollbackMethod();
        }
        this.showToast('info', this.label.claimLabel007); //  'Errors received - See the form for details');
        this.isLoading = false;
        this.errorTheme = 'error';
        this.errorObject = error;
    }

    afterSave() {
        notifyRecordUpdateAvailable([{recordId: this.recordId}]);
        if (this.submitCallbackMethod != null) {
            this.submitCallbackMethod();
        } else {
            this.showToast('info', this.label.claimLabel008); // 'Claim saved!');
        }
        this.isLoading = false;
    }

    factoryEmailSent() {
        this.showToast('info', this.label.claimLabel009); //  'Factory inquiry sent!');
    }

    closeForm() {        
        this.dispatchEvent(new CustomEvent('close', {}));    
    }

    rollbackProposalSent() {
        this.currentStatus = this.STATUS_CONSIDERATION;
    }

    buildStatusPath(picklistValues) {
        if (this.steps.length == 0 && picklistValues) {
            // this.currentStatus = this.getStatusValue();
            this.steps = [];
            for (let i = 0; i < picklistValues.values.length; i++) {
                var step = {};
                step.label = picklistValues.values[i].label;
                step.value = picklistValues.values[i].value;
                this.steps.push(step);
            }
        }
    }

    resetErrors() {
        this.errorObject = null;
    }

    showToast(theme, message) {
        let title = 'Info';
        let variant = 'info';
        let mode = 'dismissible';
    
        if (theme === 'warning') {
            title  = 'Warning';
            variant = 'warning';
        } else if (theme === 'error') {
            title  = 'error';
            variant = 'error';
        }

        
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,       // Default is info!
            mode: mode              // Default is dismissible
        });
        this.dispatchEvent(event);
    }

    async editReplacementOrder() {        
        this.orderItems = [];
        this.currentOrderId = this.orderId;
        this.showOrderDialog = true;       
    }

    async editCollectionOrder() {        
        this.orderItems = [];
        this.currentOrderId = this.collectionOrderId;
        this.showOrderDialog = true;       
    }

    async createReplacementOrder() {
        this.currentOrderId = null;
        this.orderData = this.getBlankOrderWithDefaults(K_REPLACEMENT_TYPE)
        this.getBlankOrderItems();
        //this.showOrderDialog = true;        
    }

    async createCollectionOrder() {
        this.currentOrderId = null;
        this.orderData = this.getBlankOrderWithDefaults(K_FREE_COLLECTION_TYPE)
        this.getBlankOrderItems();
        //this.showOrderDialog = true;        
    }

    getBlankOrderWithDefaults(orderType) {
        const blankOrder = {};
        blankOrder.Type = orderType;
        //blankOrder.EffectiveDate = new Date().toJSON();
        blankOrder.AccountId = this.accountId;
        blankOrder.BillTo__c = this.accountId;
        blankOrder.SalesOrg__c = this.invoiceHeader.SalesOrg;
        blankOrder.Distribution_channel__c = this.invoiceHeader.DistChannel;
        blankOrder.SalesOffice__c = this.invoiceHeader.SalesOffice;
        blankOrder.CurrencyIsoCode = this.invoiceHeader.Currency;
        blankOrder.NB2B_Delivery_Method__c = '3';
        blankOrder.PoNumber = this.label.claimLabel014.replace('{0}',this.caseNumber); // 'Ref. ' + this.invoiceNumber + '/' + this.invoiceLine;
        blankOrder.ReferredInvoice__c = this.invoiceNumber;
        return blankOrder;
    }

    async launchCompensation() {
        if (this.compensationAmount <= 0) {
            this.showToast('error', 'Please enter a compensation amount');
            return;
        }
        if (await this.confirmCreateCompensation()) {
            this.submitServerMethod = this.saveCase;
            this.submitCallbackMethod = this.createCompensationMethod;
            this.submitRollbackMethod = null;
            this.commitForm();
        }
    }

    async createCompensationMethod() {    
        try {
            this.isLoading = true;
            const data = await createCompensationOrder({caseId: this.recordId});
            this.compensationOrderId = data;
            notifyRecordUpdateAvailable([{recordId: this.recordId}, {recordId: this.compensationOrderId}]);
            this.showToast('success', this.label.claimLabel010); //  'Compensation order created!');
        } catch(ex) {  
            console.error('---> [caseCLaimEdit.js] createCompensationOrder Error');
            console.error(JSON.stringify(ex));
            this.errorObject = ex;
            this.errorTheme = 'error';
            //this.processServerErrors(error);
        } finally {
            this.isLoading = false;
        }
    }
    
    async confirmCreateCompensation() {
        let text = this.label.claimLabel011; // The claim will be saved and a compensation order for the amount you entered will then be automatically created and sent to SAP. Do you want to continue?
        const confirmation = await LightningConfirm.open({
            message: text,
            variant: 'header',
            label: this.label.claimLabel012, // Compensation Order
            theme: 'Warning'
        });
        return confirmation;
    }

    async getBlankOrderItems() {
        let productId = this.refs.ProductId.value;
        const lib = this.refs.LibProductQuery;
        console.info('==> Ready to call queryProductById with productId ' + productId);
        lib.queryProductById(productId);
    }

    handleProductQuery(event) {
        console.info('==> HandleProductQuery: ' + JSON.stringify(event.detail));
        let quantity = this.refs.Quantity__c?.value;
        let unit = this.refs.Unit__c?.value;
        const item = {};
        item.Product2Id = event.detail.data.Id;
        item.ProductName__c = event.detail.data.Name;
        item.ProductCode__c = event.detail.data.ProductCode;
        item.StockKeepingUnit__c = event.detail.data.StockKeepingUnit;
        item.Quantity = quantity;
        item.SalesUnit__c = unit;
        item.UnitPriceUnitCode__c = item.SalesUnit__c;
        item.ListPriceUnitCode__c = item.SalesUnit__c;
        item.ReferredLine__c = this.invoiceLine;
        this.orderItems = [];
        this.orderItems.push(item);
        this.showOrderDialog = true;
    }


    async showFactorySummary() {    
        try {
            this.isLoading = true;
            const data = await summarizeFactoryEmails({caseId: this.recordId});
            /*
            const data = '<div class="slds-var-m-top_small slds-var-p-around_medium"><p><strong>Email Summary &#124; From:</strong> Ramon Prades &#124; <strong>Date:</strong> 27/02/2025 11:49</p><p>A customer claim has been received regarding product FERROKER ALUMINIO 44X66(A) with case number 00001450. The customer reports water leakage through joints of the material and suggests a need for improved insulation. Claim details are attached for review.</p></div>' +
                '<div class="slds-var-m-top_small slds-var-p-around_medium slds-theme_shade"><p><strong>Email Summary &#124; From:</strong> rprades@porcelanosagrupo.com &#124; <strong>Date:</strong> 27/02/2025 12:47</p><p>The response indicates that the issue of water leakage is new to the sender. It is suggested that the customer check for faulty pipes in the wall where the product is installed. Additionally, the use of waterproofing product RAPIDFIX (code 133566) is recommended to mitigate damage.</p></div></div>' +
                '<div class="slds-var-m-top_small slds-var-p-around_medium slds-border_top slds-border_bottom"><p><strong>Conversation Status</strong></p><p>The conversation is open. Ramon Prades needs to check with the customer regarding the condition of the wall and consider the application of RAPIDFIX.</p></div>';
            */
            //This summary was generated by AI and is experimental. If you notice any inaccuracies, please contact support and share your feedback to help us improve the service.
            let html = '<div class="slds-theme_warning slds-var-p-around_medium slds-text-align_center">' + this.label.claimLabel018 + '</div>' + data;

            console.log("==> " + html);
            html = html.replaceAll('ai-section even', 'ai-section slds-theme_shade')
                        .replaceAll('ai-section', 'slds-var-m-top_x-small slds-var-p-around_medium')
                        .replace('conversation-status', 'slds-var-m-top_small slds-box slds-theme_shade slds-theme_alert-texture');
                        //.replace('conversation-status', 'slds-var-m-top_medium slds-var-p-around_medium slds-border_top slds-border_bottom');
            this.isLoading = false;
            await libCustomTextModal.open({
                size: 'large', // small, medium, large, full
                label: this.label.claimLabel017, // 'Factory Email AI Summary'
                bodyHtml: html
            });
        } catch(ex) {  
            this.isLoading = false;
            console.error('---> [caseCLaimEdit.js] showFactorySummary Error');
            console.error(JSON.stringify(ex));
            this.errorObject = ex;
            this.errorTheme = 'error';
        } 
    }

    //========================================================================================================
    @wire(getInvoiceLine, { invoiceNumber: "$invoiceNumber", invoiceLine: "$invoiceLine" }) 
        invoiceLinesMethod({error, data}) {
            this.invoiceLines = [];
            if (data) {
                this.invoiceItem = { ...data };
            } 
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
                                    Distchannel__c { value }
                                    SALESOFFIC__c { value }
                                    Dnet__c { value }     
                                    Dtax__c { value }
                                    Dtotal__c { value }
                                    Dcurr__c { value }
                                    BillTo__c { value }                          
                                    Account__c { value }     
                                    Account__r { Name { value }  }     
                                    Sfopportunity__c { value }
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
                if (data !== undefined) {
                    if (data.uiapi.query.Facturas_cabeceraSet__x !== undefined) {    
                            const results = data.uiapi.query.Facturas_cabeceraSet__x.edges.map((edge) => ({
                            Number: edge.node.Ordernum__c.value,
                            Date: edge.node.Orderdate__c?.value,
                            SalesOrg: edge.node.Salesorg__c.value,
                            DistChannel: edge.node.Distchannel__c.value,
                            SalesOffice: edge.node.SALESOFFIC__c.value,
                            Net: edge.node.Dnet__c.value,
                            Tax: edge.node.Dtax__c.value,
                            Total: edge.node.Dtotal__c.value,
                            Currency: edge.node.Dcurr__c.value,
                            AccountId: edge.node.Account__c.value,
                            AccountSAPCode: edge.node.BillTo__c.value,
                            AccountName: edge.node.Account__r?.Name.value,  
                            Opportunity: edge.node.Sfopportunity__c.value                          
                        }));
                        if (results.length > 0) {
                            this.invoiceHeader = results[0];
                            const dateOnly = new Date(this.invoiceHeader?.Date);
                            //this.invoiceHeader.Date = dateOnly;
                            this.salesOrg = this.invoiceHeader.SalesOrg;
                            //this.queryName = 'AuditTrailQuery';
                        } else if (this.invoiceNumber?.length > 0) {
                            return;
                        } 
                    } else if (data.uiapi.query.Sales_Org__c !== undefined) {
                        const results = data.uiapi.query.Sales_Org__c.edges.map(edge => edge.node);
                        this.salesOrgName = this.salesOrg + ' -> ' + results[0].Name.value;
                    } /*else if (data.uiapi.query.ObjectAuditTrail__c !== undefined) {
                        this.historyLines = data.uiapi.query.ObjectAuditTrail__c.edges.map((edge) => ({
                            userName: edge.node.CreatedBy.Name.value,
                            createdDate: edge.node.CreatedDate.value,
                            supplyReplacement: (edge.node.Value01__c.value === 'true'?"Yes":"No"),
                            supplyInstallation: parseFloat(edge.node.Value02__c.value),
                            settlementAmount: (parseFloat(edge.node.Value03__c.value) ?? 0)
                        }));                        
                    }*/
                } 
            } 
            if (errors) {
                console.error("> [caseCLaimEdit.js] GRAPH-QL Errors " + JSON.stringify(errors));
            }
            this.errors = errors;
        }

    get queryVariables() {
        return {     
            queryName: this.queryName, 
            invoiceNumber: this.invoiceNumber,      
            salesOrg: this.salesOrg,
            caseId: this.recordId
        };
    }

    handleProblemChange(event) {   
        this.setReportedMakeProblem();     
    }

    handleMakeProblemChange(event) {
        this.setComboOptions(this.productTypesMap, event.detail.value, 'ProductType__c');
        this.setReportedTypeProblem();
    }
    
    handleTypeProblemChange(event) {
        this.setComboOptions(this.symptomsMap, event.detail.value, 'Symptoms__c');
    }

    handleProductTypeChange(event) {
        this.setReportedTypeProblem();
    }

    handleSymptomChange(event) {
        this.setComboOptions(this.detailsMap, event.detail.value, 'SymptomsDetails__c');
    }

    handleDetailChange(event) {
        this.setComboOptions(this.causesMap, event.detail.value, 'LikelyCause__c');
    }

    handleCauseChange(event) {
        this.setComboOptions(this.solutionsMap, event.detail.value, 'RecommendedCure__c');
    }

    handleOrderError(event) {
        this.showOrderDialog = false;
        this.showToast("error", event.detail);
    }

    setComboOptions(comboMap, value, dependentId) {
        const options = comboMap[value]; 
        if (options?.length === 1) {
            const control = this.getDataIdControl(dependentId); 
            if (control!== null && control !== undefined) {
                control.value = options[0];
                if (dependentId.toLowerCase() === 'recommendedcure__c') {
                    this.showToast('success', 'Solution selected!');
                }
            } else {
                console.error('Control ' + dependentId + ' not found in setComboOptions');
            }
        } 
    }

    fillComboMaps(data) {   
        if (this.productTypesMap === undefined || this.productTypesMap == null) { 
            this.productTypesMap = this.getComboMap(data.ProductType__c);
            this.symptomsMap = this.getComboMap(data.Symptoms__c);
            this.detailsMap = this.getComboMap(data.SymptomsDetails__c);
            this.causesMap = this.getComboMap(data.LikelyCause__c);
            this.solutionsMap = this.getComboMap(data.RecommendedCure__c);
        }
    }

    getComboMap(data) {
        let comboMap = {};
        let keysMap = {};
        Object.getOwnPropertyNames(data.controllerValues).forEach((property) => {
            const key = data.controllerValues[property];
            keysMap[key] = property;
            comboMap[property] = [];
        });        

        data.values.forEach((item) => {
            const validFor = item.validFor;
            validFor.forEach((controllingValue) => {
                const lbl = keysMap[controllingValue];                    
                let list = comboMap[lbl];
                list.push(item.value);
            })
        });
        return comboMap;
    } // getCombosMap

    getDataIdControl(dataId) {
        return this.template.querySelector('[data-id = "' + dataId + '"]');
    }

}