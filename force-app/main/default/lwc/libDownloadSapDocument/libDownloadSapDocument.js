/**
 * libDownloadSapDocument
 * 
 * Ramón, July 2023
 * 
 * Translation Prefix: tr0004 (used in libCardInvoice too)
 * 
 * Library functions to download a SAP document in PDF
 * 
 */

import { LightningElement } from 'lwc';
import downloadSAPDocumentV2 from '@salesforce/apex/SAPSalesDocumentController.downloadSAPDocumentV2';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import tr0004_002 from "@salesforce/label/c.tr0004_002";
import tr0004_003 from "@salesforce/label/c.tr0004_003";
import tr0004_004 from "@salesforce/label/c.tr0004_004";
import tr0004_005 from "@salesforce/label/c.tr0004_005";

const label = {
    tr0004_002,
    tr0004_003,
    tr0004_004,
    tr0004_005
};


export { downloadOrder, downloadInvoice };

const downloadOrder = (orderNumber, callbackFn, param) => {
    downloadDocument('O', orderNumber, callbackFn, param);
}

const downloadInvoice = (invoiceNumber, callbackFn, param) => {
    downloadDocument('I', invoiceNumber, callbackFn, param);
}

const downloadDeliveryNote = (dnoteNumber, callbackFn, param) => {
    downloadDocument('D', dnoteNumber, callbackFn, param);
}

const downloadDocument = (docType, docNumber, callbackFn, param) => {
    console.info('==> Downloading ' + docType + ', ' + docNumber);
    downloadSAPDocumentV2({ docType: docType, docNumber: docNumber })
    .then((result) => {            
        download(docNumber + ".pdf", result);
        const event = new ShowToastEvent({
            title: label.tr0004_002, // Download Complete
            message: label.tr0004_003, // The SAP document you have requested has been downloaded!
            variant: 'success',
            mode: 'dismissible'
        });
        dispatchEvent(event); 
        if (callbackFn != undefined) {
            try {   
                callbackFn(param);
            } catch(e) {}
        }
    })
    .catch((error) => {
        console.log("Error downloading document: " + JSON.stringify(error));
        const event = new ShowToastEvent({
            title:  label.tr0004_004, // Download Error
            message:  label.tr0004_005, // Error downloading the requested SAP document
            variant: 'warning',
            mode: 'dismissible'
        });
        dispatchEvent(event);
    });            
}

const download = (filename, content) => {
    const binaryString = window.atob(content);
    const binaryLen = binaryString.length;
    let bytes = new Uint8Array(binaryLen);
    for (let i = 0; i < binaryLen; i++) {
       const ascii = binaryString.charCodeAt(i);
       bytes[i] = ascii;
    }        
    const blob = new Blob([bytes], {type: "application/pdf"});
    let link = document.createElement('a');
    link.href = window.URL.createObjectURL(blob);
    link.download = filename;
    link.click();
}