/**
 * **caseInvoiceCreateStep3**
 *
 * Author: Ramón Prades  
 * Date: January 2025  
 *
 * *Description:  
 *
 * This subcomponent implements the fourth step of the invoice-related case creation wizard.  
 * It allows the user to review the products selected and the problem descriptions and submit the case.
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

export default class CaseInvoiceCreateStep4 extends LightningElement {

    
    @api caseData;

    get isClaim() {
        return (this.caseData.caseType === 'CLAIM');
    }

    get isReturn() {
        return (this.caseData.caseType === 'RETURN');
    }

    labels = LABELS;
    selectedLines = [];
    returnsHeader = {};

    connectedCallback() {
        let position = 0;
        for (const index of this.caseData.selectedItems) {
            const item = {...this.caseData.invoiceItems[index]};
            const l = item.filesToUpload.length;
            item.position = ++position;
            item.attachmentsText = (l === 0 ? this.labels.dictNoAttached : this.labels.dictNumberAttached.replace('{0}', l));
            this.selectedLines.push(item);        
        }
        // If return, the description and the attachment are stored in the first item although they apply to the full collection
        if (this.isReturn) {
            this.returnsHeader.description = this.selectedLines[0].problemDescription; 
            this.returnsHeader.attachmentsText =  this.selectedLines[0].attachmentsText; 
        }

    }

}