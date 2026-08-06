import { LightningElement, api, track, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import { NavigationMixin } from "lightning/navigation";

import getAccountDvsData from '@salesforce/apex/DvsService.accountDvsData';
import getDvsEnabled from '@salesforce/apex/DvsService.isDvsEnabled';
import getIsAccounting from '@salesforce/apex/DvsService.isAccounting';

export default class DvsAutoLaunch extends NavigationMixin(LightningModal) {
    @api recordId;

    @track accountdDvsData = {};
    @track showComponent = false;
    @track dvsEnabled = false;
    @track isAccounting = false;

    @wire(getAccountDvsData, { recordId: '$recordId'})
    wiredAccount({error, data}) {
        if (data) {
            this.accountdDvsData = data;
            if (this.accountdDvsData.DVSAction__c == null) {
                this.showComponent = true;
            }
        }
    }

    @wire(getIsAccounting, { recordId: '$recordId'})
    wiredIsAccounting({error, data}) {
        if (data) {
            this.isAccounting = data;
        }
    }

    @wire(getDvsEnabled, { recordId: '$recordId'})
    wiredDvsEnabled({error, data}) {
        if (data) {
            this.dvsEnabled = data;
        }
    }

    get showData() {
        return this.showComponent && this.dvsEnabled && (this.isAccounting == false);
    }

    closeModal() {
        this.showComponent = false;
    }
}