import { LightningElement, api, wire } from 'lwc';
import downloadSelectedRecords from '@salesforce/apex/ReportsHelper.downloadWeeklyReport';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class downloadWeeklyReportLWC extends LightningElement {
    @api recordId;


    @wire(downloadSelectedRecords, { wreportId: '$recordId'})
    wiredAccountData({error, data}) {
        if (data) {
            const byteArray = this.base64ToUint8Array(data['data']);
            const mimeType = this.getMimeTypeFromExtension(data['filename']);
            const blob = new Blob([byteArray], { type: mimeType });

            const link = document.createElement('a');
            link.href = URL.createObjectURL(blob);
            link.download = data['filename'];
            document.body.appendChild(link);
            link.click();

            this.dispatchEvent(new CloseActionScreenEvent());
        } else if (error) {
            console.log('(error---> ' + JSON.stringify(error));
            }
    }

    base64ToUint8Array(base64) {
        const binaryString = window.atob(base64);
        const len = binaryString.length;
        const bytes = new Uint8Array(len);
        for (let i = 0; i < len; i++) {
            bytes[i] = binaryString.charCodeAt(i);
        }
        return bytes;
    }
    
    getMimeTypeFromExtension(filename) {
        const extension = filename.split('.').pop().toLowerCase();
        const mimeTypes = {
            pdf: 'application/pdf',
            xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            csv: 'text/csv',
            txt: 'text/plain',
            doc: 'application/msword',
            docx: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            json: 'application/json',
            zip: 'application/zip',
            png: 'image/png',
            jpg: 'image/jpeg',
            jpeg: 'image/jpeg'
        };
        return mimeTypes[extension] || 'application/octet-stream';
    }
}