import { LightningElement, wire,track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';

import getData from '@salesforce/apex/KeyAccountManagementController.getData';
import removeAsKey from '@salesforce/apex/KeyAccountManagementController.removeAsKey';
import translateComment from '@salesforce/apex/WeeklyManagementController.translate';
import addCCEmail from '@salesforce/apex/KeyAccountManagementController.addCCEmailToComment';
import addCCUser from '@salesforce/apex/KeyAccountManagementController.addCCUserToComment';
import removeCCEmail from '@salesforce/apex/KeyAccountManagementController.removeCCEmailToComment';
import removeToEmail from '@salesforce/apex/KeyAccountManagementController.removeToEmailToComment';
import sendMainCommentOpps from '@salesforce/apex/WeeklyManagementEmails.sendMainCommentKeyOpportunityComments';

export default class KeyAccountManagement extends LightningElement {
    _accountId;
    @api 
    get accountId() {
        return this._accountId;
    }
    set accountId(value) {
        if (this._accountId !== value) {
            this._accountId = value;
            // Aquí puedes recargar datos
            if (value) {
                this.loadData();
            }
        }
    }
    @api sendCommentsList = [];
    @api titleIndex = '';

    baseUrl = window.location.origin;
    @track selectedOpportunityId = null;
    @track isLoading = true;
    @track isLoadingForm = false;
    @track accountData = null
    @track comments = []
    @track oppComments = []
    @track teamMembers = []
    @track opportunities = []
    @track tasks = []
    @track contacts = []
    @track events = []
    @track activities = []
    @track accountInfo = null;
    @track selectedComment = null;
    @track mainOppComment = '';
    @track isTranslating = false;
    @track emailCC = [];
    @track needsSave = false;
    @track rightPanelExpanded = false;
    @track isModalChangeOwnerOpen = false;
    @track isModalChangeOwnerOpportunityOpen = false;
    @track isModalNewMemberOpen = false;
    @track isModalChangeAccountOpen = false;
    @track isOppCommentsModalOpen = false;

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
        this.loadData();
    }

    get inputVariablesChangeOwner() {
        return [
            {
                name: 'accountId',
                type: 'String',
                value: this.accountId
            }
        ];
    }

    get inputVariablesChangeOwnerOpportunity() {
        return [
            {
                name: 'opportunityId',
                type: 'String',
                value: this.selectedOpportunityId
            }
        ];
    }

    get locked() {
        if (this.isLastCommentNotSelected || (this.isLastCommentSelected && this.selectedComment.SentAnswer__c != '' && this.selectedComment.SentAnswer__c != null)) {
            return true;
        }
        return false;
    }

    get mainCommentHasNoValue() {
        if (this.mainOppComment != null && this.mainOppComment != '') {
            return false;
        }
        return true;
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

    get emailCCList() {
        return this.selectedComment.Value3__c.split(';')
    }

    get numberContactsLabel() {
        return `Contacts (${this.contacts.length})`;
    }

    get hasContacts() {
        return this.contacts && this.contacts.length > 0;
    }

    get emailToList() {
        if (this.selectedComment.Value4__c == null || this.selectedComment.Value4__c == '') {
            return [];
        }
        return this.selectedComment.Value4__c.split(';')
    }

    get styleNeedsSave() {
        if (this.needsSave == false) {
            return 'slds-hidden';
        }
        return '';
    }

    get numberActivitiesLabel() {
        return `Activities (${this.activities.length})`;
    }

    get numberKeyOpportunitiesLabel() {
        return 'Key Opportunities (' + this.opportunities.filter(opp => opp.keyOpp).length + ')';
    }

    get numberOpportunitiesLabel() {
        return 'Opportunities (' + this.opportunities.length + ')';
    }

    get keyOppsWithNoAnswer() {
        return this.opportunities.filter(opp => opp.keyOpp && (opp.answer == null || opp.answer == ''));
    }

    get keyOppscanSendEmail() {
        return this.opportunities.filter(opp => opp.keyOpp && (opp.answer == null || opp.answer == '')).length > 0;
    }

    async loadData() {
        this.isLoading = true;
                
        try {
            const data = await getData({ accountId: this.accountId });
            
            this.accountInfo = {
                ...data.accountData,
                accountLink: `${this.baseUrl}/lightning/r/Account/${data.accountData.Id}/view`
            };

            this.oppComments = [...data.opportunityComments]
            this.tasks = [...data.tasks]
            this.events = [...data.events]
            this.buildActivities();
            this.contacts = [...data.contacts]
            const latestOppCommentsMap = {};

            this.oppComments.forEach(comment => {
                const oppId = comment.Opportunity__r.Id;

                if (
                    !latestOppCommentsMap[oppId] ||
                    new Date(comment.WeeklyCompleted__c) > new Date(latestOppCommentsMap[oppId].WeeklyCompleted__c)
                ) {
                    latestOppCommentsMap[oppId] = comment;
                }
            });

            this.comments = [...data.comments]
            .map(comm => ({
                ...comm,
                shortValue: comm.Value__c ? (comm.Value__c.length > 60 ? comm.Value__c.substring(0, 60) + '…' : comm.Value__c) : '',
                Value2__c: comm.Value2__c || '',
                shortValue2: comm.Value2__c ? (comm.Value2__c.length > 60 ? comm.Value2__c.substring(0, 60) + '…' : comm.Value2__c) : '',
                sendEmail: false,
                translatedComment: '',
                selected : false
            }));
            this.comments[0].selected = true;
            this.teamMembers = [...data.teamMembers]
            this.opportunities = [...data.opportunities]
            .map(opp => ({
                ...opp,
                keyOpp: opp.LeadSource == 'Porsamarket' && opp.StageName != 'Closed Won' ? true : false,
                opportunityLink: `${this.baseUrl}/lightning/r/Opportunity/${opp.Id}/view`,
                comment: latestOppCommentsMap[opp.Id]?.Value__c || '',
                answer: latestOppCommentsMap[opp.Id]?.SentAnswer__c || null
            }));
            this.selectedComment = this.comments.length > 0 ? this.comments[0] : null;
            this.selectedComment.sendEmail = this.sendCommentsList.includes(this.selectedComment.Id) ? true : false;
        } catch (error) {
            this.showToast('Error', error.body?.message || error.message, 'error');
        } finally {
            this.isLoading = false;
            this.isLoadingForm = false;
        }
    }

    buildActivities() {
        const merged = [];

        // Tasks
        this.tasks.forEach(task => {
            merged.push({
                id: task.Id,
                type: 'Task',
                icon: 'utility:task',
                subject: task.Subject,
                date: task.ActivityDate
                    ? new Date(task.ActivityDate)
                    : null,
                ownerName: task.Owner?.Name,
                link: `/lightning/r/Task/${task.Id}/view`
            });
        });

        // Events
        this.events.forEach(event => {
            merged.push({
                id: event.Id,
                type: 'Event',
                icon: 'utility:event',
                subject: event.Subject,
                date: event.StartDateTime
                    ? new Date(event.StartDateTime)
                    : null,
                ownerName: event.Owner?.Name,
                link: `/lightning/r/Event/${event.Id}/view`
            });
        });

        // Ordenar: más nuevo → más antiguo
        merged.sort((a, b) => {
            if (!a.date) return 1;
            if (!b.date) return -1;
            return b.date - a.date;
        });

        this.activities = merged;
    }

    async handleRemoveAsKey(event) {
        var accountId = event.target.dataset.id;

        const result = await LightningConfirm.open({
            message: 'Do you want to remove as Key Account? It won\'t show again on the list',
            theme: 'warning'
            // setting theme would have no effect
        });
        if (result == true) {
            this.isLoading = true;
            removeAsKey({ accountId: accountId })
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

    async handleSendOppComments() {
        const result = await LightningConfirm.open({
            message: 'Do you want to send the comments to the not already answered Key Opportunity comments? (' + this.keyOppsWithNoAnswer.length + ' Opportunities)',
            theme: 'warning'
            // setting theme would have no effect
        });
        if (result == true) {
            this.isLoading = true;
            sendMainCommentOpps({ comment: this.mainOppComment, accountId: this.accountId })
            .then(result => {
                this.isLoading = false;
                this.handleCloseModal();
                this.loadData();
                this.dispatchEvent(new CustomEvent('refreshnoclose'));
            })
            .catch(error => {
                console.error(error);
                this.isLoading = false;
            });
        }
    }

    handleChangeMainComment(event) {
        this.mainOppComment = event.target.value;
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
        this.isLoading = false;
    }

    handleUpdateOwner() {
        this.isModalChangeOwnerOpen = true;
    }

    async handleRemoveAsKeyOpportunity(event) {
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
                this.handleCloseModal();
                this.loadData();
                this.dispatchEvent(new CustomEvent('refreshnoclose'));
            })
            .catch(error => {
                console.error(error);
                this.isLoading = false;
            });
        }
    }
    

    handleUpdateOwnerOpportunity(event) {
        this.selectedOpportunityId = event.target.dataset.id;
        this.isModalChangeOwnerOpportunityOpen = true;
    }

    handleManageOpportunityHistoric(event) {
        const opportunityId = event.target.dataset.id;

        // Filtrar comentarios de la oportunidad
        this.selectedOpportunityComments = this.oppComments
            .filter(c => c.Opportunity__r?.Id === opportunityId)
            .sort((a, b) => {
                const dateA = a.WeeklyCompleted__c ? new Date(a.WeeklyCompleted__c) : new Date(0);
                const dateB = b.WeeklyCompleted__c ? new Date(b.WeeklyCompleted__c) : new Date(0);
                return dateB - dateA; // más reciente primero
            })
            .map(c => ({
                ...c,
                shortValue: c.Value__c?.length > 80 
                    ? c.Value__c.substring(0, 80) + '…' 
                    : c.Value__c,
                shortAnswer: c.Value2__c?.length > 80 
                    ? c.Value2__c.substring(0, 80) + '…' 
                    : c.Value2__c
            }));

        this.selectedOpportunityId = opportunityId;
        this.selectedOpportunityName =
            this.opportunities.find(o => o.Id === opportunityId)?.Name || '';

        this.isOppCommentsModalOpen = true;
    }

    handleUpdateAccountOpportunity() {
        this.selectedOpportunityId = event.target.dataset.id;
        this.isModalChangeAccountOpen = true;
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

    handleFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.handleCloseModal();
            this.loadData();
            this.dispatchEvent(new CustomEvent('refresh'));
        }
    }

    handleFlowStatusChangeOpportunity(event) {
        if (event.detail.status === 'FINISHED') {
            this.handleCloseModal();
            this.loadData();
            this.dispatchEvent(new CustomEvent('refreshnoclose'));
        }
    }

    handleNewMember() {
        this.isModalNewMemberOpen = true;
    }

    handleCloseModal() {
        this.isModalChangeOwnerOpen = false;
        this.isModalChangeOwnerOpportunityOpen = false;
        this.isModalChangeAccountOpen = false;
        this.isModalNewMemberOpen = false;
        this.isOppCommentsModalOpen = false;
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