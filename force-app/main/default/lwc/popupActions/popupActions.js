import { LightningElement, api, track, wire } from 'lwc';

import getCurrentUserData from '@salesforce/apex/PopupActionsService.currentUserData';
import getNoManagedAccounts from '@salesforce/apex/PopupActionsService.getNoManagedAccounts';
import updateUserPopupTime from '@salesforce/apex/UserAdditionalInfo.setLastPopupTime';
import getAllUserAdditionalInfo from '@salesforce/apex/UserAdditionalInfo.getAllInfo';
import getAccountDvsData from '@salesforce/apex/DvsService.accountDvsData';

import dataValidationLabel from '@salesforce/label/c.dvs_data_Validation';
import dataValidationSubtitleLabel from '@salesforce/label/c.dvs_validate_account';
import needsValidationLabel from '@salesforce/label/c.dvs_needs_validation';
import validatedLabel from '@salesforce/label/c.dvs_validated';
import nameLabel from '@salesforce/label/c.dict_name';
import seeAllLabel from '@salesforce/label/c.dict_see_all';

// LIST OF ACTIONS
const actionDvsUnmanaged = 'DVSUNMANAGED';

const columnsDvsUnmanaged = [
    {  
        label: "Nom",  
        fieldName: "recordLink",  
        type: "url", 
        fixedWidth: 400,
        typeAttributes: { label: { fieldName: "Name" }, tooltip:"Name", target: "_blank" }  
    }, 
    { label: 'Status', fieldName: 'managed', type: 'Boolean', cellAttributes: { alignment: 'center' } }
];

export default class PopupActions extends LightningElement {
    @api recordId;
    columnsDvsUnmanaged = columnsDvsUnmanaged;

    @api minutes = 0;
    @api actions;
    @api disableClose = false;

    @track actionsToStart = [];
    @track showPopup = false;
    @track usrAdditionalInfo;
    @track showComponentDvsUnmanaged = false;
    @track titlePopup;
    @track subtitlePopup;
    @track showModal = false;
    @track managedDvs = false;

    label = {
        dataValidationLabel,
        dataValidationSubtitleLabel,
        needsValidationLabel,
        validatedLabel,
        nameLabel,
        seeAllLabel
    };


    connectedCallback() {
        if (this.actions != null) {
            this.actionsToStart = this.actions.split(';');
        }
    }

    get hasDvsUnmanaged() {
        return this.actionsToStart.includes(actionDvsUnmanaged);
    }

    get canBeClosed() {
        return this.disableClose == false;
    }

    get notEmptyAccountList() {
        return this.noManagedAccounts.length > 0
    }

    get showList() {        
        return this.managedDvs == true && this.showPopup == true && this.showModal == true;
    }

    @wire(getAccountDvsData, { recordId: '$recordId'})
    wiredAccount({error, data}) {
        if (data) {
            this.accountdDvsData = data;
            if (this.accountdDvsData.BillingCountryCode == undefined) {
                this.managedDvs = true;
            }
            if (this.accountdDvsData.DVSAction__c != undefined && this.accountdDvsData.DVSAction__c != null) {
                this.managedDvs = true;
            }
        }
    }

    @wire(getCurrentUserData, { recordId: '$recordId'})
    wiredCurrentUser({error, data}) {
        if (data) {
            this.currentUserData = data;

            if (this.hasDvsUnmanaged) {
                this.getAdditionalUserInfo();
            }
        }
    }

    getAdditionalUserInfo() {
        getAllUserAdditionalInfo({ userId : this.currentUserData.Id })
        .then((response) => {
            this.usrAdditionalInfo = response;
            this.setDvsUnmanagedData();
            this.setPopup();
        }).catch( (error) => {
            console.log(error);
            //console.info("error: " + error.body.message);
        });
    }

    setPopup() {
        if (this.usrAdditionalInfo != undefined) {
            console.log('MINUTES')
            console.log(this.minutes)
            if (this.minutes > 0) {
                if (this.usrAdditionalInfo.lastPopupTime != null) {
                    var dateSF = new Date(this.usrAdditionalInfo.lastPopupTime.Value1__c);
                    var dateSFAfter = new Date(this.usrAdditionalInfo.lastPopupTime.Value1__c);
                    dateSFAfter = dateSFAfter.setMinutes(dateSFAfter.getMinutes() + this.minutes);
                    var SystemNow = (new Date()).getTime();
    
                    if (dateSFAfter < SystemNow) {
                        if (this.currentUserData.Id) {
                            this.onUpdatePopupTime(this.currentUserData.Id);
                        }
                        this.showPopup = true;
                    }
                } else {
                    if (this.currentUserData.Id) {
                        this.onUpdatePopupTime(this.currentUserData.Id);
                    }
                    this.showPopup = true;
                }
            } else {
                this.showPopup = true;
            }
        }
        if (this.minutes == 0 || this.minutes == '') {
            this.showPopup = true;
        }
    }

    setDvsUnmanagedData() {
        var aux = this;
        var numberToManage = 2;
        console.log('MANAGED')
        console.log(aux.usrAdditionalInfo.dvsAccountsManaged.length)
        var AccountsManagedNumber = aux.usrAdditionalInfo.dvsAccountsManaged.length;
        var accountsLeft = numberToManage - AccountsManagedNumber;
        console.log('LEFT')
        console.log(accountsLeft)
        this.titlePopup = this.label.dataValidationLabel;
        this.subtitlePopup = this.label.dataValidationSubtitleLabel;
        if (accountsLeft > 0) {
            getNoManagedAccounts({ numOfRecords: accountsLeft, userData : "$usrAdditionalInfo"})
            .then( (response) => {
                var tempAccList = []; 
                if (response.length > 0) {
                    var left = accountsLeft;
                    response.forEach(function(item, index, array) {
                        if (left > 0) {
                            let tempRecord = Object.assign({}, item); //cloning object  
                            tempRecord.recordLink = "/" + tempRecord.Id;    
                            tempRecord.managed = aux.label.needsValidationLabel;
                            tempAccList.push(tempRecord);
                            left--;
                        }
                        
                    });

                    if (aux.usrAdditionalInfo.dvsAccountsManaged != undefined ) {
                        aux.usrAdditionalInfo.dvsAccountsManaged.forEach(function(item) {
                            let tempRecord = Object.assign({}, item); //cloning object  
                            tempRecord.managed = aux.label.validatedLabel;
                            tempRecord.recordLink = "/" + tempRecord.Id; 
                            tempAccList.push(tempRecord);
                        });
                    }

                    this.noManagedAccounts = tempAccList;
                    this.showComponentDvsUnmanaged = true;
                    if (this.showPopup) {
                        this.showModal = true;
                    }
                }
            })
            .catch( (error) => {
                console.log(error);
                console.info("error: " + error.body.message);
            });
        }
    }

    // Checks if the popup has to appear because the minutes has passed since the last time
    onUpdatePopupTime(userId) {
        this.hasResult = false;
        this.waitingForResult = true;
        updateUserPopupTime({userId: userId })
        .then( (response) => {
            console.log('ACTUALIZADO LA FECHA DE OUOUOP')
        })
        .catch( (error) => {
            console.log(error);
            console.info("error: " + error.body.message);
        });
    }

    closeModal() {
        this.showComponentDvsUnmanaged = false;
        this.showPopup = false;
        this.showModal = false;
    }
}