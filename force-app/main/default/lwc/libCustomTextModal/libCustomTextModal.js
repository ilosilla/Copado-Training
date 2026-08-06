import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class libCustomTextModal extends LightningModal {
    @api bodyHtml;

    get modalClass() {
       return '';
    }
    
    closeModal() {
        this.close();
    }
}