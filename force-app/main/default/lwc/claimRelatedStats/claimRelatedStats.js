/**
 * claimRelatedStats
 * Ramón Nov 2024
 * 
 * Component to display some stats in relation with a  claim
 * 
 * Translation prefix: tr0003
 * 
 */
import { LightningElement, api, wire } from 'lwc';
import getClaimStats from '@salesforce/apex/ClaimRelatedStatsController.getClaimStats';

const ICON_OK = "utility:check";
const ICON_FLAG = "utility:priority";

import tr0003_001 from "@salesforce/label/c.tr0003_001";
import tr0003_002 from "@salesforce/label/c.tr0003_002";
import tr0003_003 from "@salesforce/label/c.tr0003_003";
import tr0003_004 from "@salesforce/label/c.tr0003_004";
import tr0003_005 from "@salesforce/label/c.tr0003_005";
import tr0003_006 from "@salesforce/label/c.tr0003_006";
import tr0003_007 from "@salesforce/label/c.tr0003_007";

export default class ClaimRelatedStats extends LightningElement {    
    
    label = {
        tr0003_001, tr0003_002, tr0003_003, tr0003_004,
        tr0003_005, tr0003_006, tr0003_007
    };

    @api recordId;

    isLoading = true;
    resultDTO = null;

    get invoiceClaimsIcon() {
        let icon = '';            
        if (this.resultDTO?.invoiceClaims>=0) {
            if (this.resultDTO.invoiceClaims === 0) {
                icon = ICON_OK;
            } else {
                icon = ICON_FLAG;
            }
        } 
        return icon;   
    }

    get invoiceClaimsText() {
        let text = '';
        if (this.resultDTO?.invoiceClaims>=0) {
            if (this.resultDTO.invoiceClaims === 0) {
                text = this.label.tr0003_002; //No claims for this invoice
            } else {
                text = this.label.tr0003_003.replace('{0}', this.resultDTO.invoiceClaims); //Invoice line claimed {0} times
            }
        }
        return text;   
    }


    get productClaimsIcon() {
        let icon = '';
        if (this.resultDTO?.productClaims>=0) {
            if (this.resultDTO.productClaims === 0) {
                icon = ICON_OK
            } else {
                icon = ICON_FLAG
            }
        }
        return icon;   
    }

    get productClaimsText() {
        let text = '';
        if (this.resultDTO?.productClaims>=0) {
            if (this.resultDTO.productClaims === 0) {
                text = this.label.tr0003_004; // No claims for this product 
            } else {
                text = this.label.tr0003_005.replace('{0}', this.resultDTO.productClaims); // Product claimed {0} times
            }
        }
        return text;   
    }

    get accountClaimsIcon() {
        let icon = '';
        if (this.resultDTO?.accountClaims>=0) {
            if (this.resultDTO.accountClaims === 0) {
                icon = ICON_OK
            } else {
                icon = ICON_FLAG
            }
        }
        return icon;   
    }

    get accountClaimsText() {
        let text = '';
        if (this.resultDTO?.accountClaims>=0) {
            if (this.resultDTO.accountClaims === 0) {
                text = this.label.tr0003_006; // No claims from this customer
            } else {
                text = this.label.tr0003_007.replace('{0}', this.resultDTO.accountClaims); // Customer claimed {0} times
            }
        }
        return text;   
    }

    
    @wire(getClaimStats, { claimId: "$recordId" })             
        getClaimStats({error, data}) {
            if (data) {                              
                this.isLoading = false;
                this.resultDTO = data;
            } 
            if (error) {
                this.isLoading = false;
                console.log('Error reading claim stats ' + JSON.stringify(error));
            }
        };                
}