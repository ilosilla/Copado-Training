import { LightningElement, wire,track, api } from 'lwc';
import {
    registerRefreshContainer,
    unregisterRefreshContainer,
    REFRESH_ERROR,
    REFRESH_COMPLETE,
    REFRESH_COMPLETE_WITH_ERRORS,
  } from "lightning/refresh";

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';

import getData from '@salesforce/apex/KeyOpportunityManagementController.getData';
import removeAsKey from '@salesforce/apex/KeyOpportunityManagementController.removeAsKey';
import translateComment from '@salesforce/apex/WeeklyManagementController.translate';
import addCCEmail from '@salesforce/apex/KeyOpportunityManagementController.addCCEmailToComment';
import addCCUser from '@salesforce/apex/KeyOpportunityManagementController.addCCUserToComment';
import removeCCEmail from '@salesforce/apex/KeyOpportunityManagementController.removeCCEmailToComment';
import removeToEmail from '@salesforce/apex/KeyOpportunityManagementController.removeToEmailToComment';
import setSpecialProduct from '@salesforce/apex/KeyOpportunityManagementController.addSpecialProduct';

export default class KeyOpportunityManagement extends LightningElement {
    refreshContainerID
    _opportunityId;
    @api 
    get opportunityId() {
        return this._opportunityId;
    }
    set opportunityId(value) {
        if (this._opportunityId !== value) {
            this._opportunityId = value;
            console.log('OpportunityId changed:', value);

            // Aquí puedes recargar datos
            if (value) {
                this.loadData();
            }
        }
    }
    @api sendCommentsList = [];
    @api removeKeysList = [];

    baseUrl = window.location.origin;
    @track isLoading = true;
    @track isLoadingForm = false;
    @track opportunityData = null;
    @track comments = []
    @track teamMembers = []
    @track opportunityInfo = null;
    @track selectedComment = null;
    @track isTranslating = false;
    @track needsSave = false;
    @track rightPanelExpanded = false;
    @track isModalOpen = false;
    @track isModalChangeOwnerOpen = false;
    @track isCommentPanelOpen = false;
    @track isModalNewMemberOpen = false;
    @track showOppForm = false

    filterUsers = {
        criteria: [
            {
                fieldPath: 'IsActive',
                operator: 'eq',
                value: true,
            },
            {
                fieldPath: 'Profile.Name',
                operator: 'eq',
                value: 'Standard Trade',
            },
            {
                fieldPath: 'Profile.Name',
                operator: 'eq',
                value: 'Managers',
            },
            {
                fieldPath: 'Profile.Name',
                operator: 'eq',
                value: 'Standard After Sales',
            },
        ],
        filterLogic: '1 AND (2 OR 3 OR 4)',
    };

    displayInfoUsers = {
        primaryField: 'Name',
        additionalFields: ['Email','UserRole.Name'],
    };

    connectedCallback() {
        this.refreshContainerID = registerRefreshContainer(this, this.refreshContainer);
        this.loadData();
    }

    disconnectedCallback() {
        unregisterRefreshContainer(this.refreshContainerID);
      }

    refreshContainer(refreshPromise) {
    return refreshPromise.then((status) => {
        if (status === REFRESH_COMPLETE) {
        console.log("Done!");
        } else if (status === REFRESH_COMPLETE_WITH_ERRORS) {
        console.warn("Done, with issues refreshing some components");
        } else if (status === REFRESH_ERROR) {
        console.error("Major error with refresh.");
        }
    });
    }

    get inputVariables() {
        return [
            {
                name: 'opportunityId',
                type: 'String',
                value: this.opportunityId
            }
        ];
    }

    get inputVariablesChangeOwner() {
        return [
            {
                name: 'opportunityId',
                type: 'String',
                value: this.opportunityId
            }
        ];
    }


    get locked() {
        if (this.isLastCommentNotSelected || (this.isLastCommentSelected && this.selectedComment.SentAnswer__c != '' && this.selectedComment.SentAnswer__c != null)) {
            return true;
        }
        return false;
    }

    get isLastCommentSelected() {
        if (this.selectedComment != null && this.selectedComment.Id == this.comments[0].Id) {
            return true;
        }
        return false;
    }

    get isLastCommentNotSelected() {
        return !this.isLastCommentSelected;
    }

    get rightPanelClass() {
        return 'slds-panel slds-size_medium slds-panel_docked slds-panel_docked-right' + ( this.rightPanelExpanded == true ? ' slds-is-open' : '')
    }

    get styleNeedsSave() {
        if (this.needsSave == false) {
            return 'slds-hidden';
        }
        return '';
    }

    get emailCCList() {
        return this.selectedComment.Value3__c.split(';')
    }

    get emailToList() {
        if (this.selectedComment.Value4__c == null || this.selectedComment.Value4__c == '') {
            return [];
        }
        return this.selectedComment.Value4__c.split(';')
    }

    async loadData() {
        this.isLoading = true;
        this.showOppForm = false;
                
        try {
            const data = await getData({ opportunityId: this.opportunityId });
            
            this.opportunityInfo = {
                ...data.opportunityData,
                opportunityLink: `${this.baseUrl}/lightning/r/Opportunity/${data.opportunityData.Id}/view`,
                accountLink: `${this.baseUrl}/lightning/r/Account/${data.opportunityData.AccountId}/view`
            };

            this.comments = [...data.comments]
            .map(comm => ({
                ...comm,
                shortValue: comm.Value__c ? (comm.Value__c.length > 60 ? comm.Value__c.substring(0, 60) + '…' : comm.Value__c) : '',
                Value2__c: comm.Value2__c || '',
                shortValue2: comm.Value2__c ? (comm.Value2__c.length > 60 ? comm.Value2__c.substring(0, 60) + '…' : comm.Value2__c) : '',
                sendEmail: false,
                removeKey: false,
                translatedComment: '',
                selected : false
            }));
            this.comments[0].selected = true;
            this.teamMembers = [...data.teamMembers]
            this.selectedComment = this.comments.length > 0 ? this.comments[0] : null;
            this.selectedComment.sendEmail = this.sendCommentsList.includes(this.selectedComment.Id) ? true : false;
            this.selectedComment.removeKey = this.removeKeysList.includes(this.selectedComment.Id) ? true : false;
        } catch (error) {
            this.showToast('Error', error.body?.message || error.message, 'error');
        } finally {
            this.isLoading = false;
            this.showOppForm = true;
            this.isLoadingForm = false;
        }
    }

    async handleRemoveAsKey(event) {
        var opportunityId = event.target.dataset.id;

        const result = await LightningConfirm.open({
            message: 'Do you want to remove as Key Opportunity? It won\'t show again on the list',
            theme: 'warning'
            // setting theme would have no effect
        });
        if (result == true) {
            this.isLoading = true;
            removeAsKey({ opportunityId: opportunityId })
            .then(result => {
                this.isLoading = false;
                this.selectedAction = null;
                this.dispatchEvent(new CustomEvent('removedaskey'));
            })
            .catch(error => {
                console.error(error);
                this.isLoading = false;
            });
        }
    }

    async handleSetOffsite(event) {
        this.setOppSpecialProduct(event, 'OFFSITE');
    }

    async handleSetKitchen(event) {
        this.setOppSpecialProduct(event, 'KITCHEN');
    }

    async setOppSpecialProduct(event, product) {
        this.isLoading = true;
        setSpecialProduct({ commentId: this.selectedComment.Id, product: product })
        .then(result => {
            this.loadData();
            this.showToast('Success', 'Product set', 'success');
        })
        .catch(error => {
            console.error(error);
            this.isLoading = false;
        });
    }

    addUserToEmailCCList(event) {
        var selection = event.detail.recordId;
        if (selection != null) {
            this.handleAddCCUser(event,selection);
        }
        this.refs.recordPickerRef.clearSelection();
    }

    handleLoadForm() {
        this.isLoadingForm = false;
        this.showOppForm = true;
        this.isLoading = false;
    }

    openCommentPanel() {
        this.isCommentPanelOpen = true;
    }
    
    closeCommentPanel() {
        this.isCommentPanelOpen = false;
    }

    handleUpdateAccount() {
        this.isModalOpen = true;
    }

    handleUpdateOwner() {
        this.isModalChangeOwnerOpen = true;
    }

    handleNewMember() {
        this.isModalNewMemberOpen = true;
    }

    handleCloseModal() {
        this.isModalOpen = false;
        this.isModalChangeOwnerOpen = false;
        this.isModalNewMemberOpen = false;
    }

    handleFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.loadData();
            this.handleCloseModal();
            this.dispatchEvent(new CustomEvent('refresh'));
        }
    }

    handleNext() {
        var aux = this;
        this.dispatchEvent(new CustomEvent('next', {
            detail: {
                recordId: aux.selectedComment.Id
            }}));
    }

    handlePrevious() {
        var aux = this;
        this.dispatchEvent(new CustomEvent('previous', {
            detail: {
                recordId: aux.selectedComment.Id
            }}));
    }

    handleCommentChanged(event) {
        this.selectedComment.Value2__c = event.target.value;
        this.needsSave = true;
        var aux = this;

        this.dispatchEvent(new CustomEvent('commentchanged', {
            detail: {
                comment: aux.selectedComment.Value2__c,
                commentId: aux.selectedComment.Id
            }
        }));
    }

    handleCommentSelected(event) {
        const commentId = event.target.dataset.id;

        // Recorremos todos los comentarios y reseteamos selected
        this.comments = this.comments.map(comment => ({
            ...comment,
            selected: comment.Id === commentId // true solo para el seleccionado
        }));

        const selected = this.comments.find(comment => comment.Id === commentId);

        if (selected) {
            this.selectedComment = { ...selected }; // hacemos copia para que sea reactivo
            this.rightPanelExpanded = true
            this.isCommentPanelOpen = true;
        }
    }

    handleSendEmailChanged(event) {
        this.selectedComment.sendEmail = event.target.checked;
        this.needsSave = true;
        var aux = this;

        this.dispatchEvent(new CustomEvent('sendchanged', {
            detail: {
                checked: aux.selectedComment.sendEmail,
                commentId: aux.selectedComment.Id
            }
        }));
    }

    handleRemoveKeyChanged(event) {
        this.selectedComment.removeKey = event.target.checked;
        this.needsSave = true;
        var aux = this;

        this.dispatchEvent(new CustomEvent('removekeychanged', {
            detail: {
                checked: aux.selectedComment.removeKey,
                commentId: aux.selectedComment.Id
            }
        }));
    }

    async handleAddCCUser(event, userId) {  
        try {
            const data = await addCCUser({ commentId: this.selectedComment.Id, userId: userId });
            this.selectedComment.Value3__c = data;
        } catch (error) {
            this.showToast('Error', error.body?.message || error.message, 'error');
        } finally {
        }
    }

    async handleAddEmail(event) {
               
        try {
            const data = await addCCEmail({ commentId: this.selectedComment.Id, email: event.target.dataset.email });
            this.selectedComment.Value3__c = data;
            this.showToast('Success', 'Email added', 'success');
        } catch (error) {
            this.showToast('Error', error.body?.message || error.message, 'error');
        } finally {
        }
    }

    async handleRemoveEmail(event) {
        try {
            const data = await removeCCEmail({ commentId: this.selectedComment.Id, email: event.target.dataset.email });
            this.selectedComment.Value3__c = data;
        } catch (error) {
            this.showToast('Error', error.body?.message || error.message, 'error');
        } finally {
        }
    }

    async handleRemoveToEmail(event) {
        try {
            const data = await removeToEmail({ commentId: this.selectedComment.Id, email: event.target.dataset.email });
            this.selectedComment.Value4__c = data;
        } catch (error) {
            this.showToast('Error', error.body?.message || error.message, 'error');
        } finally {
        }
    }

    // --- Utilidades ---
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    async handleTranslateClick(event) {
            if (!this.selectedComment || !this.selectedComment.Value2__c) return;
    
            this.isTranslating = true;
    
            try {
                // Llamada a Apex para traducir
                const translatedText = await translateComment({ 
                    text: this.selectedComment.Value2__c, 
                    targetLang: 'french' // o el idioma que necesites
                });
                this.selectedComment.translatedComment = translatedText;
                this.selectedComment.Value2__c = translatedText;
                this.dispatchEvent(new CustomEvent('commentchanged', {
                    detail: {
                        comment: this.selectedComment.Value2__c,
                        commentId: this.selectedComment.Id
                    }
                }));
            } catch (error) {
                console.error('Translation error', error);
            } finally {
                this.isTranslating = false;
            }
        }

}