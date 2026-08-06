import { LightningElement, wire,track } from 'lwc';
import LightningConfirm from 'lightning/confirm';
import currentUserId from '@salesforce/user/Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';

import getKeyAccountComments from '@salesforce/apex/KeyAccountManagementController.getLastKeyAccountsComments';
import saveComments from '@salesforce/apex/WeeklyManagementController.saveKeyAccountCommentAnswers';
import sendKeyAccountCommentAnswers from '@salesforce/apex/WeeklyManagementEmails.sendKeyAccountCommentAnswers';
import getKeyOpportunityComments from '@salesforce/apex/KeyOpportunityManagementController.getLastKeyOpportunitiesComments';

// Campos de usuario
import UserNameFIELD from '@salesforce/schema/User.Name';
import userEmailFIELD from '@salesforce/schema/User.Email';
import userIsActiveFIELD from '@salesforce/schema/User.IsActive';
import userAliasFIELD from '@salesforce/schema/User.Alias';
import userProfileNameFIELD from '@salesforce/schema/User.Profile.Name';

// Etiquetas
import labelSelectUser from '@salesforce/label/c.tr0012_0001';
import labelSelectorWeek from '@salesforce/label/c.tr0012_0002';
import labelSendReportStage from '@salesforce/label/c.tr0012_0003';
import labelCompletedStage from '@salesforce/label/c.dict_completed';
import labelTasksCompletedStage from '@salesforce/label/c.tr0012_0004';
import labelEventManagement from '@salesforce/label/c.tr0012_0005';
import labelEventManagementInfo from '@salesforce/label/c.tr0012_0006';
import labelKeyAccountComments from '@salesforce/label/c.tr0012_0007';
import labelKeyAccountCommentsInfo from '@salesforce/label/c.tr0012_0008';
import labelKeyOppComments from '@salesforce/label/c.tr0012_0009';
import labelKeyOppCommentsInfo from '@salesforce/label/c.tr0012_0010';
import labelSendReport from '@salesforce/label/c.tr0012_0011';
import labelReportAlreadySent from '@salesforce/label/c.tr0012_0012';
import labelReportAlreadySentBody from '@salesforce/label/c.tr0012_0013';
import labelSend from '@salesforce/label/c.Send';
import labelSuccess from '@salesforce/label/c.dict_success';
import labelReportSentSuccess from '@salesforce/label/c.tr0012_0014';
import labelReportFridays from '@salesforce/label/c.tr0012_0015';
import labelWeeklyCommentInfo from '@salesforce/label/c.tr0012_0016';
import labelWeeklyReport from '@salesforce/label/c.tr0012_0017';
import labelDownloadReport from '@salesforce/label/c.tr0012_0024';
import labelUpdated from '@salesforce/label/c.dict_updated';
import labelHelpComments from '@salesforce/label/c.tr0012_0027';
import labelNewEvent from '@salesforce/label/c.tr0012_0028';
import labelNewEventMessage from '@salesforce/label/c.tr0012_0029';
import labelName from '@salesforce/label/c.dict_name';
import labelSalesMaturity from '@salesforce/label/c.tr0012_0020';

export default class WeeklyCommentsLWC extends LightningElement {
    @track selectedIds = [];
    @track removeIds = [];
    @track keyOpportunityComments = [];
    @track commentValues = {};
    @track baseUrl = window.location.origin;
    @track saveDelay;
    @track keyAccountComments = [];
    @track keyAccountCommentsFiltered = [];
    @track isLoading = false;
    @track isReady = false;
    @track ownerId = currentUserId;
    @track currentUserName;
    @track currentUserProfileName;
    @track currentUserEmail;
    @track currentIsActive;
    @track currentUserAlias;
    @track isTranslating = false;
    @track indexSelected = 0;
    // Para el combobox
    @track accountOptions = []; // { label, value }
    @track selectedAccountId = null;
    @track selectedSalesOrg = null;
    @track selectedOwnerId = null;
    @track loadingRecord = false;
    @track isModalOpen = false;
    @track isModalSendOpen = false;
    @track selectedAccountChecked = false;
    @track filteredAnswered = null;
    @track filteredKeyOpps = null;

    @track sortField = null;
    @track sortDirection = 'asc';

    salesCodeOptions = [
        { label: 'All Orgs', value: null },
        { label: 'FR - Xtone FR', value: '225' },
        { label: 'FR - Azurceramique', value: '226' },
        { label: 'FR - Lorceram', value: '227' },
        { label: 'FR - Euroceramique', value: '228' },
        { label: 'FR - Paris IDF', value: '229' },
        { label: 'FR - Socamed', value: '230' },
        { label: 'FR - Ouest', value: '231' },
        { label: 'FR - Sud-Ouest', value: '232' },
        
        { label: 'UK - South East', value: '502' },
        { label: 'UK - Xtone UK', value: '511' },
        { label: 'UK - Nort West', value: '514' },
        { label: 'UK - Midlands', value: '515' },
        { label: 'UK - Scotland', value: '516' },
        { label: 'UK - Western', value: '517' },
        { label: 'UK - Yorkshire', value: '518' },

        { label: 'US - Florida', value: '602' },
        { label: 'US - Los Angeles', value: '603' },
        { label: 'US - San Francisco', value: '604' },
        { label: 'US - New York', value: '605' },
        { label: 'US - Maryland', value: '606' },
        { label: 'US - Texas', value: '608' },
        { label: 'US - Canada', value: '650' },
        { label: 'US - XTone US', value: '615' },
        
        { label: 'AU - Australia', value: '850' }
    ];

    answerFilterOptions = [
        { label: 'Show All - Answered', value: null },
        { label: 'Show Not Sent', value: '0' },
        { label: 'Show Sent', value: '1' },
        { label: 'Show Marked to send', value: '2' }
    ]

    keyOppsFilterOptions = [
        { label: 'Show All - Key Opps', value: null },
        { label: 'With Key Opportunities', value: 'with' },
        { label: 'Without Key Opportunities', value: 'without' }
    ]

    currentUser = {};

    label = {
        labelSelectUser,
        labelSelectorWeek,
        labelSendReportStage,
        labelCompletedStage,
        labelTasksCompletedStage,
        labelEventManagement,
        labelEventManagementInfo,
        labelKeyAccountComments,
        labelKeyAccountCommentsInfo,
        labelKeyOppComments,
        labelKeyOppCommentsInfo,
        labelSendReport,
        labelReportAlreadySent,
        labelReportAlreadySentBody,
        labelSend,
        labelSuccess,
        labelReportSentSuccess,
        labelReportFridays,
        labelWeeklyCommentInfo,
        labelWeeklyReport,
        labelDownloadReport,
        labelUpdated,
        labelHelpComments,
        labelNewEvent,
        labelNewEventMessage,
        labelName,
        labelSalesMaturity
    };

    connectedCallback() {
        this.loadData();
    }

    get numberOfComments() {
        return this.keyAccountCommentsFiltered.length;
    }

    // --- Getters simplificados ---
    get hasKeyAccountComments() {
        return this.keyAccountComments.length > 0;
    }

    get userIsAdmin() {
        return ['System Administrator', 'Managers'].includes(this.currentUser.profileName);
    }

    get ownerList() {
        if (!this.keyAccountComments || this.keyAccountComments.length === 0) {
            return [];
        }
     
        const ownersMap = new Map();
        this.keyAccountComments.forEach(comment => {
            ownersMap.set(comment?.Account__r?.OwnerId, {
                value: comment.Account__r.OwnerId,
                label: comment.Account__r.Owner.Name
            });
        });
    
        // List sorted alphabetically
        const sortedOwners = Array.from(ownersMap.values()).sort(
            (a, b) => a.label.localeCompare(b.label)
        );

        // Add "All Users" at the beginning
        return [
            { label: 'All Users', value: null },
            ...sortedOwners
        ];

    }

    get titleIndex() {
        return `( ${this.indexSelected} / ${this.keyAccountCommentsFiltered.length} )`;
    }

    get commentsToSend() {
        return this.keyAccountComments
            .filter(c => c.sendEmail === true)
            .map(c => ({
                id: c.Id,
                accountId: c.Account__r?.Id,
                accountName: c.Account__r?.Name,
                ownerId: c.Account__r?.Owner?.Id,
                ownerName: c.Account__r?.Owner?.Name,
                ownerEmail: c.Account__r?.Owner?.Email,
                comment: c.Value__c || '',           // Comentario original
                answer: c.Value2__c || '',              // Contestación / respuesta
                removeAsKey: c.removeKey
            }));
    }

    get accountNameSortIcon() {
        if (this.sortField !== 'AccountName') return 'utility:sort';
        return this.sortDirection === 'asc' ? 'utility:arrowup' : 'utility:arrowdown';
    }
    
    get weeklyCompletedSortIcon() {
        if (this.sortField !== 'WeeklyCompleted') return 'utility:sort';
        return this.sortDirection === 'asc' ? 'utility:arrowup' : 'utility:arrowdown';
    }

    // --- Wire de usuario actual ---
    @wire(getRecord, { recordId: currentUserId, fields: [UserNameFIELD, userEmailFIELD, userIsActiveFIELD, userAliasFIELD, userProfileNameFIELD] })
    currentUserInfo({ error, data }) {
        if (data) {
            this.currentUser = {
                name: data.fields.Name.value,
                email: data.fields.Email.value,
                isActive: data.fields.IsActive.value,
                alias: data.fields.Alias.value,
                profileName: data.fields.Profile.value.fields.Name.value
            };
        } else if (error) {
            this.showToast('Error', error.body.message, 'error');
        }
    }

    handleSendEmailsButton() {
        this.isModalSendOpen = true;
    }

    handleRefresh() {
        this.handleCloseModal();
        this.loadData()
    }

    handleRefreshNoClose() {
        this.loadData()
    }

    handleNext() {
        this.handleCloseModal();
        const aux = this;

        const currentIdx = this.keyAccountCommentsFiltered.findIndex(
            c => c.Account__r.Id === aux.selectedAccountId
        );

        // Calculamos el siguiente índice, con wrap-around
        const nextIdx = (currentIdx + 1) % this.keyAccountCommentsFiltered.length;
        this.indexSelected = nextIdx + 1;
        this.selectedAccountId = this.keyAccountCommentsFiltered[nextIdx].Account__r.Id;
        this.isModalOpen = true;
    }

    handlePrevious() {
        this.handleCloseModal();

        // Buscamos el índice del registro actual
        const currentIdx = this.keyAccountCommentsFiltered.findIndex(
            c => c.Account__r.Id === this.selectedAccountId
        );

        // Calculamos el índice anterior, con wrap-around
        const prevIdx = (currentIdx - 1 + this.keyAccountCommentsFiltered.length) % this.keyAccountCommentsFiltered.length;
        this.indexSelected = prevIdx + 1;

        // Actualizamos el id seleccionado y abrimos modal
        this.selectedAccountId = this.keyAccountCommentsFiltered[prevIdx].Account__r.Id;
        this.isModalOpen = true;
    }

    async handleSendEmails() {
        this.isLoading = true;
        this.isModalSendOpen = false;

        sendKeyAccountCommentAnswers({ commentIds: this.selectedIds, isTest: false, removeKeyIds: this.removeIds })
        .then(result => {
            this.isLoading = false;
            this.selectedIds = [];
            this.removeIds = [];
            this.showToast('Success', 'Emails sent successfully', 'success');
            this.loadData();
        })
        .catch(error => {
            console.error(error);
            this.isLoading = false;
        });
    }

    // --- Carga de datos (optimizada con async/await) ---
    async loadData() {
        this.isLoading = true;

        
        try {
            const opportunitys = await getKeyOpportunityComments();
            this.keyOpportunityComments = [...opportunitys] // 👈 clona el array

            const accountIdsWithKeyOpps = new Set(
                opportunitys
                    .map(o => o.Opportunity__r?.AccountId)
                    .filter(id => id) // quitamos null/undefined
            );
            const accounts = await getKeyAccountComments();

            this.keyAccountComments = [...accounts] // 👈 clona el array
            .sort((a, b) => {
                const nameA = (a.Account__r?.Name || '').toLowerCase();
                const nameB = (b.Account__r?.Name || '').toLowerCase();
                return nameA.localeCompare(nameB);
            })
            .map(acc => ({
                ...acc,
                Value2__c: acc.Value2__c || '', // 👈 normalizamos null
                accountLink: `${this.baseUrl}/lightning/r/Account/${acc.Account__r.Id}/view`,
                sendEmail: Array.isArray(this.selectedIds) && this.selectedIds.length > 0 && this.selectedIds.includes(acc.Id),
                removeKey: Array.isArray(this.removeIds) && this.removeIds.length > 0 && this.removeIds.includes(acc.Id),
                emailCC: '',
                hasKeyOpps: accountIdsWithKeyOpps.has(acc.Account__r.Id),
                translatedComment: ''
            }));

            this.populateAccountOptions();
            this.handleFilter();
        } catch (error) {
            this.showToast('Error', error.body?.message || error.message, 'error');
        } finally {
            this.isLoading = false;
            this.isReady = true;
        }
    }

    // Llamar después de cargar los datos
    populateAccountOptions() {
        // Primero, clonar y ordenar los registros por nombre de cuenta
        const sortedAccounts = [...this.keyAccountComments].sort((a, b) => {
            const nameA = a.Account__r?.Name?.toLowerCase() || '';
            const nameB = b.Account__r?.Name?.toLowerCase() || '';
            return nameA.localeCompare(nameB);
        });

        // Luego, crear las opciones con índice
        this.accountOptions = sortedAccounts.map((acc, index) => ({
            label: acc.Account__r.Name,
            value: index // índice ordenado
        }));
    }

    handleFilter() {
        this.keyAccountCommentsFiltered = [...this.keyAccountComments];

        if (this.selectedSalesOrg != null) {
            this.keyAccountCommentsFiltered = [...this.keyAccountCommentsFiltered.filter(
                comment => comment.Account__r.Owner && comment.Account__r.Owner.Default_Sales_Organization__c === this.selectedSalesOrg
            )];
        }

        if (this.selectedOwnerId != null) {
            this.keyAccountCommentsFiltered = this.keyAccountCommentsFiltered.filter(
                c => c.Account__r?.Owner?.Id === this.selectedOwnerId
            );
        }

        if (this.filteredAnswered == '0') {
            this.keyAccountCommentsFiltered = this.keyAccountCommentsFiltered.filter(
                c => c.SentAnswer__c == null
            );
        }
        if (this.filteredAnswered == '1') {
            this.keyAccountCommentsFiltered = this.keyAccountCommentsFiltered.filter(
                c => c.SentAnswer__c != null
            );
        }
        if (this.filteredAnswered == '2') {
            this.keyAccountCommentsFiltered = this.keyAccountCommentsFiltered.filter(
                c => c.sendEmail == true
            );
        }
        if (this.filteredKeyOpps == 'with') {
            this.keyAccountCommentsFiltered = this.keyAccountCommentsFiltered.filter(
                c => c.hasKeyOpps == true
            );
        }
        if (this.filteredKeyOpps == 'without') {
            this.keyAccountCommentsFiltered = this.keyAccountCommentsFiltered.filter(
                c => c.hasKeyOpps == false
            );
        }
    }

    resetFilters() {
        this.selectedSalesOrg = null;
        this.selectedOwnerId = null;
        this.filteredAnswered = null;
        this.filteredKeyOpps = null;
        this.handleFilter();
    }

    handleAnswerFilter(event) {
        this.filteredAnswered = event.target.value;
        this.handleFilter();
    }

    handleSalesOrgFilter(event) {
        this.selectedSalesOrg = event.target.value;
        this.handleFilter();
    }

    handleOwnerFilter(event) {
        this.selectedOwnerId = event.target.value;
        this.handleFilter();
    }

    handleKeyOppFilter(event) {
        this.filteredKeyOpps = event.target.value;
        this.handleFilter();
    }

    handleManageAccount(event) {
        const currentIdx = this.keyAccountCommentsFiltered.findIndex(
            c => c.Account__r.Id === event.target.dataset.id
        );
        this.indexSelected = currentIdx + 1;
        this.selectedAccountId = event.target.dataset.id;
        this.isModalOpen = true;
    }

    // --- Handlers unificados ---
    handleCommentChange(event) {
        this.updateCommentValue(event.target.dataset.id, event.target.value);
    }

    handleSendChange(event) {
        this.updateSendValue(event.target.dataset.id, event.target.checked);
    }

     handleRemoveChange(event) {
        this.updateRemoveValue(event.target.dataset.id, event.target.checked);
    }

    handleRemovedAskey(event) {
        this.keyAccountComments = this.keyAccountComments.map(c =>
            c.Id === event.detail.commentId ? { ...c, removeKey: event.detail.checked } : c
        );

        this.keyAccountCommentsFiltered = this.keyAccountCommentsFiltered.map(c =>
            c.Id === event.detail.commentId ? { ...c, removeKey: event.detail.checked } : c
        );

        this.removeIds = event.detail.checked
            ? [...new Set([...this.removeIds, event.detail.commentId])]
            : this.removeIds.filter(i => i !== event.detail.commentId);
        this.debounceSave();
    }

    handleCommentChanged(event) {
        this.keyAccountComments = this.keyAccountComments.map(c =>
            c.Id === event.detail.commentId ? { ...c, Value2__c: event.detail.comment } : c
        );

        this.keyAccountCommentsFiltered = this.keyAccountCommentsFiltered.map(c =>
            c.Id === event.detail.commentId ? { ...c, Value2__c: event.detail.comment } : c
        );

        this.commentValues[event.detail.commentId] = event.detail.comment;

        this.debounceSave();
    }

    handleSendChanged(event) {
        this.keyAccountComments = this.keyAccountComments.map(c =>
            c.Id === event.detail.commentId ? { ...c, sendEmail: event.detail.checked } : c
        );

        this.keyAccountCommentsFiltered = this.keyAccountCommentsFiltered.map(c =>
            c.Id === event.detail.commentId ? { ...c, sendEmail: event.detail.checked } : c
        );

        this.selectedIds = event.detail.checked
            ? [...new Set([...this.selectedIds, event.detail.commentId])]
            : this.selectedIds.filter(i => i !== event.detail.commentId);

        this.debounceSave();
    }

    handleSort(event) {
        const field = event.currentTarget.dataset.field; // Obtenemos 'AccountName' o 'WeeklyCompleted'
        
        if (this.sortField === field) {
            // Si ya estaba ordenando por este campo, invertimos la dirección
            this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
        } else {
            // Si cambiamos de campo, la dirección inicial es ascendente
            this.sortField = field;
            this.sortDirection = 'asc';
        }
    
        // Aplicamos el ordenamiento
        this.sortComments();
    }

    updateRemoveValue(id, isChecked) {
        this.keyAccountComments = this.keyAccountComments.map(c =>
            c.Id === id ? { ...c, removeKey: isChecked } : c
        );

        this.keyAccountCommentsFiltered = this.keyAccountCommentsFiltered.map(c =>
            c.Id === id ? { ...c, removeKey: isChecked } : c
        );

        this.removeIds = isChecked
            ? [...new Set([...this.removeIds, id])]
            : this.removeIds.filter(i => i !== id);
    }

    sortComments() {
        if (!this.sortField) return;
    
        const direction = this.sortDirection === 'asc' ? 1 : -1;
    
        this.keyAccountCommentsFiltered = [...this.keyAccountCommentsFiltered].sort((a, b) => {
            switch(this.sortField) {
                case 'AccountName':
                    const nameA = a.Account__r?.Name?.toLowerCase() || '';
                    const nameB = b.Account__r?.Name?.toLowerCase() || '';
                    return nameA.localeCompare(nameB) * direction;
    
                case 'WeeklyCompleted':
                    const dateA = a.WeeklyCompleted__c ? new Date(a.WeeklyCompleted__c) : new Date(0);
                    const dateB = b.WeeklyCompleted__c ? new Date(b.WeeklyCompleted__c) : new Date(0);
                    return (dateA - dateB) * direction;
    
                default:
                    return 0;
            }
        });
    }

    // --- Lógica común ---
    updateCommentValue(id, value) {
        this.keyAccountComments = this.keyAccountComments.map(c =>
            c.Id === id ? { ...c, Value2__c: value } : c
        );

        this.keyAccountCommentsFiltered = this.keyAccountCommentsFiltered.map(c =>
            c.Id === id ? { ...c, Value2__c: value } : c
        );

        this.commentValues[id] = value;
        this.debounceSave();
    }

    updateSendValue(id, isChecked) {
        this.keyAccountComments = this.keyAccountComments.map(c =>
            c.Id === id ? { ...c, sendEmail: isChecked } : c
        );

        this.keyAccountCommentsFiltered = this.keyAccountCommentsFiltered.map(c =>
            c.Id === id ? { ...c, sendEmail: isChecked } : c
        );

        this.selectedIds = isChecked
            ? [...new Set([...this.selectedIds, id])]
            : this.selectedIds.filter(i => i !== id);
    }


    handleCloseModal() {
        this.isModalOpen = false;
        this.isModalSendOpen = false;
    }

    // --- Auto guardado con debounce ---
    debounceSave() {
        clearTimeout(this.saveDelay);
        this.saveDelay = setTimeout(() => this.autoSave(), 5000);
    }

    async autoSave() {
        try {
            await saveComments({ mapAnswers: this.commentValues });
            console.log('Auto-saved');
        } catch (err) {
            console.error(err);
        }
    }

    // --- Utilidad ---
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}