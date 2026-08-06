import { LightningElement, wire, track } from 'lwc';
import currentUserId from '@salesforce/user/Id';
import UserNameFIELD from '@salesforce/schema/User.Name';
import userEmailFIELD from '@salesforce/schema/User.Email';
import userIsActiveFIELD from '@salesforce/schema/User.IsActive';
import userAliasFIELD from '@salesforce/schema/User.Alias';
import userProfileNameFIELD from '@salesforce/schema/User.Profile.Name';

import getKeyOpportunities from '@salesforce/apex/WeeklyManagementController.getKeyOpportunities';
import getUsersUnder from '@salesforce/apex/WeeklyManagementController.getUsersUnderRole';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';

import labelName from '@salesforce/label/c.dict_name';
import labelStage from '@salesforce/label/c.dict_stage';
import labeClassification from '@salesforce/label/c.dict_classification';
import labelLastActivity from '@salesforce/label/c.dict_last_activity';
import labelPhone from '@salesforce/label/c.dict_phone';
import labelMail from '@salesforce/label/c.dict_email';
import labelCreateReminder from '@salesforce/label/c.tr0012_0025';
import labelSuccess from '@salesforce/label/c.dict_success';
import labelCreated from '@salesforce/label/c.dict_created';
import labelAccountName from '@salesforce/label/c.tr0012_0022';
import labelOpportunityName from '@salesforce/label/c.tr0012_0023';

export default class WeeklyKeyOpportunities extends LightningElement {
    @track isModalOpen = false;
    @track keyOpps = [];
    @track selectedOpportunityId;
    @track ownerId = currentUserId;
    @track usersUnder = [];
    @track baseUrl = window.location.origin;

    label = {
        labelName,
        labeClassification,
        labelLastActivity,
        labelMail,
        labelPhone,
        labelCreateReminder,
        labelSuccess,
        labelCreated,
        labelAccountName,
        labelOpportunityName,
        labelStage
    };

    get inputVariables() {
        return [
            {
                name: 'opportunityId',
                type: 'String',
                value: this.selectedOpportunityId
            }
        ];
    }

    connectedCallback() {
        this.loadData();
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

    @wire(getUsersUnder, { userId: currentUserId}) 
    cuurentUnderUsers({error, data}) {
        if (data) {
            this.usersUnder = data.map(u => ({
                label: `${u.FirstName} ${u.LastName}`, // concatenar
                value: u.Id
            }));
        } else if (error) {
            this.error = error ;
        }
    }

    get userIsAdmin() {
        if (this.currentUserProfileName == 'System Administrator' || this.currentUserProfileName == 'Managers') {
            return true;
        }
        return false;
    }

    get lookingDifferentUser() {
        return this.ownerId != currentUserId;
    }

    handleChangeOwner(event) {
        if (event.target.value != null) {
            this.ownerId = event.target.value;
            this.loadData();
        } else {
            this.ownerId = currentUserId;
        }
    }

    handleSelect(event) {
        this.selectedOpportunityId = event.currentTarget.dataset.id;
        this.isLoading = true;
    }

    handleOpportunityDataLoad(event) {
        this.isLoading = false;
    }

    loadData() {
        this.isLoading = true;
        // Reemplaza my.site.com por lightning.force.com en la baseUrl
        this.baseUrl = this.baseUrl.replace(/\.my\.site\.com/, '.lightning.force.com');

        getKeyOpportunities({ userId: this.ownerId })
            .then(result => {
                this.keyOpps = result.map(keyOpps => ({
                    ...keyOpps,
                    accountLink: `${this.baseUrl}/lightning/r/Account/${keyOpps.AccountId}/view`,
                    opportunityLink: `${this.baseUrl}/lightning/r/Opportunity/${keyOpps.Id}/view`
                }));
                this.isLoading = false;
            })
            .catch(error => {
                console.error(error);
                this.isLoading = false;
            });
    }

    handleRowAction(event) {
        this.selectedOpportunityId = event.target.dataset.id;
        this.isModalOpen = true;
    }

    handleCloseModal() {
        this.isModalOpen = false;
    }

    handleSendEmail(event) {
        this.isModalOpen = true;
    }

    handleFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.handleCloseModal();
            this.showToast(this.label.labelSuccess,this.label.labelCreated, 'success');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
            })
        );
    }
}