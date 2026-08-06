/**
 * claimAlertBox
 * 
 * Display box showing the claim progress.
 * Includes a warning if the claim has been stalled longer than allowed by our service terms (2 days).
 *
 * Ramón, Nov 2024
 * 
 * Registered translation prefiox: tr0001
 * 
 */
import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import CASE_STATUS_FIELD from "@salesforce/schema/Case.Status";
import CASE_CREATED_DATE_FIELD from "@salesforce/schema/Case.CreatedDate";
import CASE_CLOSED_DATE_FIELD from "@salesforce/schema/Case.ClosedDate";
import CASE_STATUS_TIMESTAMP_FIELD from "@salesforce/schema/Case.StatusTimestamp__c";
import CASE_FACTOR_INQUIRY_DATE_FIELD from "@salesforce/schema/Case.FactoryInquiryDate__c";
import CASE_FACTOR_INQUIRY_RESPONSE_FIELD from "@salesforce/schema/Case.FactoryInquiryResponse__c";

const FIELDS = [CASE_STATUS_FIELD, CASE_CREATED_DATE_FIELD, CASE_STATUS_TIMESTAMP_FIELD, CASE_FACTOR_INQUIRY_DATE_FIELD, CASE_FACTOR_INQUIRY_RESPONSE_FIELD, CASE_CLOSED_DATE_FIELD];
const STATUS_CONSIDERATION = 'consideration';
const STATUS_PROPOSAL = 'proposal';
const STATUS_AGREEMENT = 'agreement';
const STATUS_EXECUTION = 'execution';
const STATUS_CLOSED = 'closed';
const STATUS_REJECTED = 'rejected';
const QOS_DAYS = 2;         // Quality Of Service
const BASE_HEADER_CLASS = 'slds-page-header slds-has-flexi-truncate slds-var-p-horizontal_small slds-var-p-top_small';

import tr0001_001 from "@salesforce/label/c.tr0001_001";
import tr0001_002 from "@salesforce/label/c.tr0001_002";
import tr0001_003 from "@salesforce/label/c.tr0001_003";
import tr0001_004 from "@salesforce/label/c.tr0001_004";
import tr0001_005 from "@salesforce/label/c.tr0001_005";
import tr0001_006 from "@salesforce/label/c.tr0001_006";
import tr0001_007 from "@salesforce/label/c.tr0001_007";
import tr0001_008 from "@salesforce/label/c.tr0001_008";
import tr0001_009 from "@salesforce/label/c.tr0001_009";
import tr0001_010 from "@salesforce/label/c.tr0001_010";
import tr0001_011 from "@salesforce/label/c.tr0001_011";
import tr0001_012 from "@salesforce/label/c.tr0001_012";
import tr0001_013 from "@salesforce/label/c.tr0001_013";
import tr0001_014 from "@salesforce/label/c.tr0001_014";
import tr0001_015 from "@salesforce/label/c.tr0001_015";
import tr0001_016 from "@salesforce/label/c.tr0001_016";
import tr0001_017 from "@salesforce/label/c.tr0001_017";
import tr0001_018 from "@salesforce/label/c.tr0001_018";
import tr0001_019 from "@salesforce/label/c.tr0001_019";
import tr0001_020 from "@salesforce/label/c.tr0001_020";
import tr0001_021 from "@salesforce/label/c.tr0001_021";
import tr0001_022 from "@salesforce/label/c.tr0001_022";
import tr0001_023 from "@salesforce/label/c.tr0001_023";
import tr0001_024 from "@salesforce/label/c.tr0001_024";
import tr0001_025 from "@salesforce/label/c.tr0001_025";
import tr0001_026 from "@salesforce/label/c.tr0001_026";
import tr0001_027 from "@salesforce/label/c.tr0001_027";
import tr0001_028 from "@salesforce/label/c.tr0001_028";
import tr0001_029 from "@salesforce/label/c.tr0001_029";
import tr0001_030 from "@salesforce/label/c.tr0001_030";
import tr0001_031 from "@salesforce/label/c.tr0001_031";
import tr0001_032 from "@salesforce/label/c.tr0001_032";
import tr0001_033 from "@salesforce/label/c.tr0001_033";
import tr0001_034 from "@salesforce/label/c.tr0001_034";
import tr0001_035 from "@salesforce/label/c.tr0001_035";
import tr0001_036 from "@salesforce/label/c.tr0001_036";
import tr0001_037 from "@salesforce/label/c.tr0001_037";
import tr0001_038 from "@salesforce/label/c.tr0001_038";
import tr0001_039 from "@salesforce/label/c.tr0001_039";
import tr0001_040 from "@salesforce/label/c.tr0001_040";
import dict_today from "@salesforce/label/c.dict_today";
import dict_yesterday from "@salesforce/label/c.dict_yesterday";
import dict_unknown_error from "@salesforce/label/c.dict_unknown_error";

export default class ClaimAlertBox extends LightningElement {

    label = {
        tr0001_001, tr0001_002, tr0001_003, tr0001_004, tr0001_005,
        tr0001_006, tr0001_007, tr0001_008, tr0001_009, tr0001_010,
        tr0001_011, tr0001_012, tr0001_013, tr0001_014, tr0001_015,
        tr0001_016, tr0001_017, tr0001_018, tr0001_019, tr0001_020,
        tr0001_021, tr0001_022, tr0001_023, tr0001_024, tr0001_025,
        tr0001_026, tr0001_027, tr0001_028, tr0001_029, tr0001_030,
        tr0001_031, tr0001_032, tr0001_033, tr0001_034, tr0001_035,
        tr0001_036, tr0001_037, tr0001_038, tr0001_039, tr0001_040,
        dict_today, dict_yesterday, dict_unknown_error
    };
    
    @api recordId;
    @api 
    get compact() {
        return this._compact;
    }
    set compact(value) {
        this._compact = (value.toLowerCase() === 'true');
    }

    get windowTheme() {
        return this.headerClass;
    }

    get windowTitle() {
        return this.headerText;
    }

    _compact = false;
    header;
    subtitle;
    headerClass;
    bodyText;

    isLoading = true;
    status;
    statusTimestamp;
    createdDate;
    closedDate;
    factoryDate;
    factoryResponse;
    severity = 0;       // 0 ok, 1 warning, 2 error
    factoryDays = -1;

    get baseDate() {
        const base = this.statusTimestamp ? this.statusTimestamp : this.createdDate;
        return this.toDate(new Date(base));
    }

    get deadline() {        
        let result = new Date(this.baseDate);
        result.setDate(result.getDate() + QOS_DAYS);
        const day = result.getDay();
        // Skip weekends
        if (day === 0 || day === 6) {
            result.setDate(result.getDate() + 2);  // Saturday to monday or sunday to tuesday
        }
        return this.toDate(result);
    }

    get hasBody() {
        return (!this._compact && ( this.hasSubtitle || this.hasText ));
    }

    get hasSubtitle() {
        return (this.subtitle !== null);
    }

    get hasText() {
        return (this.bodyText !== null && this.bodyText?.length > 0);
    }

    get hasFooter() {
        return (this.factoryDate && !this.factoryResponse && this.status.toLowerCase() !== STATUS_CLOSED && this.status.toLowerCase() !== STATUS_REJECTED);
    }

    get description() {
        let description = '';
        if (this.severity === 2) {
            description = this.label.tr0001_001; // Please take the necessary steps to provide a solution. Your prompt action is essential to meet our service standards and ensure customer satisfaction
        } else if (this.status?.toLowerCase() === STATUS_AGREEMENT) {
            description = this.label.tr0001_002; // Please create the necessary orders in SAP to ensure the claim solution is executed promptly.
        } else if (this.status?.toLowerCase() === STATUS_EXECUTION) {
            description = this.label.tr0001_003; // The claim is now in the execution phase. No further action is required at this time, but please ensure the proposed solution is carried out as soon as possible.
        }
        return description;
    }

    get footerClass() {
        let cl = "slds-card__footer";
        if (this._compact) {
            if (this.factoryDays <= QOS_DAYS) {
                cl += ' slds-theme_warning slds-theme_alert-texture';
            } else {
                cl += ' slds-theme_error slds-theme_alert-texture';
            }    
        }
        return cl;
    }

    get factoryClass() {
        let cl = 'slds-var-p-around_small';
        if (!this._compact) {
            if (this.factoryDays <= QOS_DAYS) {
                cl += ' slds-theme_warning slds-theme_alert-texture';
            } else {
                cl += ' slds-theme_error slds-theme_alert-texture';
            }
        }
        return cl;
    }

    get factoryText() {
        let text = '';
        if (this.factoryDate && !this.factoryResponse) {
            let days = this.factoryDays;            
            if (days === 0) {
                // Inquiry sent to the factory ${0}. Please follow up.';
                text = this.label.tr0001_004.replace('{0}', this.label.dict_today);
            } else if (days === 1) {
                // Inquiry sent to the factory ${0}. Please follow up.';
                text = this.label.tr0001_004.replace('{0}', this.label.dict_yesterday);
            } else {
                // Inquiry sent to the factory ${0} days ago. Please follow up utgently.';
                text = this.label.tr0001_005.replace('{0}', days);
            }
        } else if (this.factoryDate && this.factoryResponse) {
            let days = this.getDaysClosed();
            text = this.label.tr0001_006; // Inquiry response received from the factory
        }
        return text;
    }
    
    setComponent() {
        const daysOverdue = this.getDaysOverdue();
        this.setSeverity(daysOverdue);
        this.setContent(daysOverdue);
        this.setHeaderClass();
        this.setFactoryDays();           
    }

    setSeverity(daysOverdue) {
        this.severity = 0;
        if (daysOverdue > 1) {
            this.severity = 2;
        } else if (daysOverdue >= 0) {
            this.severity = 1;
        }
   }

    setContent(daysOverdue) {
        const isOverdue = (daysOverdue >= 1);       
        let header = '';
        let subtitle = '';
        let text = '';
        switch (this.status.toLowerCase()) {
            case (STATUS_CONSIDERATION):
                if (isOverdue) {
                    this.setOverdueContent(daysOverdue);
                    return;
                } else if (this.approvalRequested != null && this.approvalDate != null) {
                    header = this.label.tr0001_007; // Awaiting Supervisor Approval
                    subtitle = this.label.tr0001_008; // Compensation Approval Pending
                    text = this.label.tr0001_009; // The compensation proposal is under review by a supervisor. Ensure all required details are provided for swift approval.
                } else {
                    header = this.label.tr0001_010; // Claim Under Review
                    subtitle = this.label.tr0001_011; // Solution Proposal Under Preparation
                    text = this.label.tr0001_012; // The claim is being reviewed. Analyze the details and prepare a solution proposal to address the customer's needs. Please make sure the customer receives the proposal within 48 hours of the claim creation.
                }
                break
            case (STATUS_PROPOSAL):
                if (isOverdue) {
                    this.setOverdueContent(daysOverdue);
                    return;
                } 
                header = this.label.tr0001_013; // Proposal Sent
                subtitle =  this.label.tr0001_014; // Awaiting Customer Response
                text = this.label.tr0001_015; // The proposal has been sent to the customer. Monitor for their response regarding acceptance or rejection. Follow up if necessary within the next 48 hours.
                break;
            case (STATUS_AGREEMENT):
                if (isOverdue) {
                    this.setOverdueContent(daysOverdue);
                    return;
                } 
                header = this.label.tr0001_016; // Proposal Accepted
                subtitle = this.label.tr0001_017; // Preparing for Execution
                text = this.label.tr0001_018; // The customer has accepted the proposal. Create the necessary orders in SAP to proceed with the solution. Ensure this is completed within the next 48 hours.
                break;
            case (STATUS_EXECUTION):
                header = this.label.tr0001_019; // Claim in Execution: Monitor progress
                subtitle = this.label.tr0001_020; // No further action required
                text = this.label.tr0001_021; // The claim is now in the execution phase. No further action is required at this time, but please ensure the proposed solution is carried out as soon as possible.
                break;
            case (STATUS_CLOSED):
                if (this.getDaysClosed() === 0) {
                    header = this.label.tr0001_022; // Claim succesfully resolved the same day
                } else {
                    // Claim succesfully resolved in {0} days
                    header = this.label.tr0001_023.replace('{0}', this.getDaysClosed());
                }
                break;
            case (STATUS_REJECTED):
                header = this.label.tr0001_024; // Claim Rejected: No Further Action Required
                break;
            default:
                header = '';
                subtitle = '';
                text = '';        
        }
        this.header = header;
        this.subtitle = subtitle;
        this.bodyText = text;
    }

    setOverdueContent(daysOverdue) {
        let header = '';
        let subtitle = '';
        let text = '';
        switch (this.status.toLowerCase()) {
            case (STATUS_CONSIDERATION):
                if (this.approvalRequested != null && this.approvalDate != null) {
                    header = this.label.tr0001_025; // Approval Overdue
                    subtitle = this.label.tr0001_026; // Supervisor Action Required
                    text = this.label.tr0001_027; // More than 48 hours have passed. Follow up with the supervisor to expedite the approval process for the compensation.
                } else {
                    header = this.label.tr0001_028; // Claim Review Overdue
                    subtitle = this.label.tr0001_029; // Action Needed: Finalize Proposal
                    text = this.label.tr0001_030; // More than 48 hours have passed. Ensure the proposal is completed and ready for submission as soon as possible.
                }
                break;
            case (STATUS_PROPOSAL):
                header = this.label.tr0001_031; // Customer Response Overdue
                subtitle = this.label.tr0001_032; // Customer Feedback Needed
                text = this.label.tr0001_033; // More than 48 hours have passed without a response. Follow up with the customer to obtain feedback on the proposal and expedite the process.
                break;
            case (STATUS_AGREEMENT):
                header = this.label.tr0001_034; // Execution Overdue
                subtitle = this.label.tr0001_035; // Order Creation Required
                text = this.label.tr0001_036; // More than 48 hours have passed. Follow up to ensure all necessary orders have been created in SAP for the solution’s execution.
                break;
            default:
        }    
        this.header = header;
        this.subtitle = subtitle;
        this.bodyText = text;
   }

    setHeaderClass() {
        let hclass = '';
        switch (this.severity) {
            case (0):
                hclass = 'slds-theme_shade slds-theme_alert-texture';
                break;
            case (1):    
                hclass = 'slds-theme_warning slds-theme_alert-texture';
                break;
            default:
                hclass = 'slds-theme_alert-texture slds-theme_error';
        }
        this.headerClass = BASE_HEADER_CLASS + ' ' + hclass;            
    }

    getStatusText() {
        this.severity = 0;
        let text = '';
        switch (this.status?.toLowerCase()) {
            case (STATUS_CLOSED):
                break;
            case (STATUS_REJECTED):
                break;
            case (STATUS_EXECUTION):
                break;
            case (STATUS_AGREEMENT):
                // Execution deadline is {0}
                text = this.label.tr0001_037.replace('{0}', '%DEADLINE%');
                break;
            case (STATUS_PROPOSAL):
                // Please ensure the customer responds by the end of {0}
                text = this.label.tr0001_038.replace('{0}', '%DEADLINE%');
                break;
            case (STATUS_CONSIDERATION):
                // Claim resolucion proposal deadline is {0}}
                text = this.label.tr0001_039.replace('{0}', '%DEADLINE%');
                break;    
            default:
                // Unexpected status {0}
                text = this.label.tr0001_040.replace('{0}', this.status);
        }
        return text;
    }

    getDaysOverdue() {
        let days = 0;
        let today = new Date().setHours(0, 0, 0, 0);
        let dline = new Date(this.deadline).setHours(0, 0, 0, 0);
        const ms = Math.abs(today - dline);
        days = Math.ceil(ms / (1000 * 60 * 60 * 24));
        if (today < dline) {
            days = -days;
        }
        return days;
    }

    getDaysClosed() {
        let days = 0;
        const ms = Math.abs(new Date(this.closedDate).setHours(0,0,0,0) - new Date(this.createdDate).setHours(0,0,0,0));
        days = Math.ceil(ms / (1000 * 60 * 60 * 24));
        if (this.closedDate < this.createdDate) {
            days = -days;
        }
        return days;
    }

    setFactoryDays() {
        this.factoryDays = -1;
        if (this.factoryDate) {
            const today = new Date().setHours(0, 0, 0, 0);
            const fDate = new Date(this.factoryDate).setHours(0, 0, 0, 0);
            const ms = Math.abs(today - fDate);
            this.factoryDays = Math.ceil(ms / (1000 * 60 * 60 * 24));
        }
    }

    toDate(dt) {
        return new Date(dt?.getFullYear(), dt?.getMonth(), dt?.getDate());
    }

    @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
    wiredRecord({ error, data }) {        
        if (error) {
            let message = this.label.dict_unknown_error; // Unknown error
            if (Array.isArray(error.body)) {
            message = error.body.map((e) => e.message).join(", ");
            } else if (typeof error.body.message === "string") {
            message = error.body.message;
            }
            console.log('==> Error reading the case in claimAlertBox: ' + message);
        } else if (data) {
            this.status = data.fields.Status.value;
            this.statusTimestamp = data.fields.StatusTimestamp__c.value;
            this.createdDate = data.fields.CreatedDate.value;
            this.factoryDate = data.fields.FactoryInquiryDate__c.value;
            this.factoryResponse = data.fields.FactoryInquiryResponse__c.value;
            this.closedDate = data.fields.ClosedDate.value;
            this.setComponent();
        }
        this.isLoading = false;
    }


}