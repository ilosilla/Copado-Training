import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';

import currentUserId from '@salesforce/user/Id';
import UserNameFIELD from '@salesforce/schema/User.Name';
import userEmailFIELD from '@salesforce/schema/User.Email';
import userIsActiveFIELD from '@salesforce/schema/User.IsActive';
import userAliasFIELD from '@salesforce/schema/User.Alias';
import userProfileNameFIELD from '@salesforce/schema/User.Profile.Name';

import getBTrips from '@salesforce/apex/BusinessTripController.getBusinessTrips';

export default class BTripsMainList extends LightningElement {
    @track bTrips = [];
    @track bTripSelected = null;
    @track isModalOpenCreate = false;
    @track isLoading = false;

    @track currentUserName;
    @track currentUserProfileName;
    @track currentUserEmail;
    @track currentIsActive;
    @track currentUserAlias;

    get tripSelected() {
        return this.bTripSelected != null;
    }

    @wire(getRecord, { recordId: currentUserId, fields: [UserNameFIELD, userEmailFIELD, userIsActiveFIELD, userAliasFIELD, userProfileNameFIELD ]}) 
    currentUserInfo({error, data}) {
        if (data) {
            this.currentUserName = data.fields.Name.value;
            this.currentUserEmail = data.fields.Email.value;
            this.currentIsActive = data.fields.IsActive.value;
            this.currentUserAlias = data.fields.Alias.value;
            this.currentUserProfileName = data.fields.Profile.value.fields.Name.value;
        } else if (error) {
            this.error = error ;
        }
    }

    @wire(getBTrips, { userId: currentUserId}) 
    cuurentUnderUsers({error, data}) {
        if (data) {
            this.bTrips = data;
        } else if (error) {
            this.error = error ;
        }
    }

    handleCloseModal() {
        this.isModalOpenCreate = false;
    }

    handleNewTrip(event) {
        this.isModalOpenCreate = true;
    }

    handleRowAction(event) {
        this.bTripSelected = event.target.dataset.id;
    }

    handleFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            const outputVariables = event.detail.outputVariables;
            const recordIdVar = outputVariables.find(o => o.name === 'newRecordId');
            if (recordIdVar) {
                this.bTripSelected = recordIdVar.value;
                console.log('Registro creado con Id:', this.bTripSelected);
                // Aquí puedes hacer algo más, como navegar al registro
            }
            this.isModalOpenCreate = false;
        }
    }

}