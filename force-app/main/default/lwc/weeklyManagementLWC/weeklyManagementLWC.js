import { LightningElement, track, wire } from 'lwc';
import LightningConfirm from 'lightning/confirm';

import currentUserId from '@salesforce/user/Id';
import UserNameFIELD from '@salesforce/schema/User.Name';
import userEmailFIELD from '@salesforce/schema/User.Email';
import userIsActiveFIELD from '@salesforce/schema/User.IsActive';
import userAliasFIELD from '@salesforce/schema/User.Alias';
import userProfileNameFIELD from '@salesforce/schema/User.Profile.Name';

import getWeeklyData from '@salesforce/apex/WeeklyManagementController.getWeeklyData';
import sendWeeklyReport from '@salesforce/apex/WeeklyManagementController.sendWeeklyReport';
import sendAndSaveWeeklyReport from '@salesforce/apex/WeeklyManagementController.sendAndSaveWeeklyReport';
import downloadSelectedWeeklyReport from '@salesforce/apex/ReportsHelper.downloadWeeklyReport';
import getUsersUnder from '@salesforce/apex/WeeklyManagementController.getUsersUnderRole';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';

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


export default class WeeklyManagementLWC extends LightningElement {
    @track selectedWeek;
    @track valueCurrentWeek;
    @track weekOptions = [];
    @track weeksFiltered = [];
    @track events = [];
    @track keyAccountsComments = [];
    @track keyOpportunities = [];
    @track keyOpportunitiesComments = [];
    @track weeklyManagement = [];
    @track weeklyReports = [];
    @track isLoading = false;
    @track totalTasks = 0;
    @track completedTasks = 0;
    @track completedPercentage = 0;
    @track stepStages = 'step1';
    @track isConfirmModalOpen = false;
    @track isAlreadySentModalOpen = false;
    @track ownerId = currentUserId;
    @track baseUrl = window.location.origin;
    @track isConfirmModalOpen = false;
    @track isModalNewEventOpen = false;
    @track confirmComment = '';
    @track usersUnder = [];

    @track currentUserName;
    @track currentUserProfileName;
    @track currentUserEmail;
    @track currentIsActive;
    @track currentUserAlias;

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
        labelNewEventMessage
    };

    connectedCallback() {
        this.initWeekOptions();
        // Cargar datos de la semana actual por defecto
        const selectedWeekObj = this.weekOptions.find(w => w.value === this.selectedWeek);
        if (selectedWeekObj) {
            const startDate = selectedWeekObj.startDate.toISOString().split('T')[0];
            const endDate = selectedWeekObj.endDate.toISOString().split('T')[0];
            this.loadData(startDate, endDate);
        }

        this.filterWeeks();
    }

    get hasKeyOppComments() {
        return this.keyOpportunitiesComments.length > 0;
    }

    get isCurrentWeek() {
        return this.selectedWeek == this.valueCurrentWeek;
    }

    get hasDownloadableReports() {
        return this.weeklyReports.length > 0;
    }

    get labelAlreadySentBody() {
        if (this.weeklyManagement == null) {
            return 'no date';
        } else {
            let formatedDate = this.weeklyManagement.CreatedDate ? new Date(this.weeklyManagement.CreatedDate).toLocaleDateString() : 'unknown date';
            return this.label.labelReportAlreadySentBody.replace('###DATE###', formatedDate);
        }
    }

    get haskeyAccComments() {
        return this.keyAccountsComments.length > 0;
    }

    get labelCompletion() {
        return `${this.label.labelTasksCompletedStage} ${this.completedTasks} / ${this.totalTasks}`;
    }

    get isCommentEmpty() {
        return !this.confirmComment || this.confirmComment.trim().length === 0;
    }

    get canSendReport() {
        return this.stepStages == 'step2' || this.stepStages == 'step3';
    }

    get weekCompleted() {
        return this.stepStages == 'step3';
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

    handleChangeOwner(event) {
        if (event.target.value != null) {
            this.ownerId = event.target.value;
            this.handleReloadData();
        } else {
            this.ownerId = currentUserId;
        }
    }

    async handleNewEvent(event) {
        const result = await LightningConfirm.open({
            message: this.label.labelNewEventMessage,
            theme: 'info'
            // setting theme would have no effect
        });
        if (result == true) {
            this.isModalNewEventOpen = true;
        }
    }

    filterWeeks() {
        const today = new Date();

        const getWeekNumber = (date) => {
            const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
            const dayNum = d.getUTCDay() || 7;
            d.setUTCDate(d.getUTCDate() + 4 - dayNum);
            const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
            return Math.ceil(((d - yearStart) / 86400000 + 1) / 7);
        };

        const currentWeek = getWeekNumber(today);
        const currentYear = today.getFullYear();

        const prevDate = new Date(today);
        prevDate.setDate(today.getDate() - 7);
        const prevWeek = getWeekNumber(prevDate);
        const prevYear = prevDate.getFullYear();

        this.weeksFiltered = this.weekOptions
            .filter(w => w.value === `${currentYear}-${currentWeek}` || w.value === `${prevYear}-${prevWeek}`)
            .map(w => ({
                ...w,
                isCurrent: w.value === `${currentYear}-${currentWeek}`
            }));

        // Selección por defecto
        const current = this.weeksFiltered.find(w => w.isCurrent);
        if (current) {
            this.selectedWeek = current.value;
        }
    }

    initWeekOptions() {
        const today = new Date();
        const lastYearDate = new Date();
        lastYearDate.setFullYear(today.getFullYear() - 1);

        const weeks = [];
        let current = this.getStartOfWeek(lastYearDate);

        let currentWeekValue;

        while (current <= today) {
            const start = new Date(current);
            const end = new Date(current);
            end.setDate(end.getDate() + 6);

            const weekNumber = this.getWeekNumber(start);
            const year = start.getFullYear();
            const value = `${year}-${weekNumber}`;

            weeks.push({
                label: `Week ${weekNumber} (${start.toLocaleDateString()} - ${end.toLocaleDateString()})`,
                value: value,
                startDate: start,
                endDate: end
            });

            // Si esta es la semana de hoy, guardamos el valor para seleccionarla
            if (this.isDateInRange(today, start, end)) {
                currentWeekValue = value;
                this.valueCurrentWeek = value;
            }

            // Siguiente semana
            current.setDate(current.getDate() + 7);
        }

        this.weekOptions = weeks;

        // Selecciona la semana actual por defecto
        this.selectedWeek = currentWeekValue;
    }

    // Devuelve el lunes de la semana de una fecha
    getStartOfWeek(date) {
        const d = new Date(date);
        const day = d.getDay() || 7;
        d.setDate(d.getDate() - (day - 1));
        return d;
    }

    // Número de semana ISO (1-53)
    getWeekNumber(date) {
        const d = new Date(date);
        d.setHours(0,0,0,0);
        d.setDate(d.getDate() + 3 - (d.getDay() + 6) % 7);
        const week1 = new Date(d.getFullYear(),0,4);
        return (1 + Math.round(((d - week1) / 86400000 - 3 + (week1.getDay() + 6) % 7) / 7));
    }

    isDateInRange(date, start, end) {
        return date >= start && date <= end;
    }

    handleWeekChange(event) {
        this.selectedWeek = event.target.value;
        this.handleReloadData();
    }

    handleReloadData() {
        const selectedWeekObj = this.weekOptions.find(w => w.value === this.selectedWeek);
        if (selectedWeekObj) {
            const startDate = selectedWeekObj.startDate.toISOString().split('T')[0];
            const endDate = selectedWeekObj.endDate.toISOString().split('T')[0];
            this.loadData(startDate, endDate);
        }
    }

    handleUpdateEvent() {
        this.showToast(this.label.labelSuccess,this.label.labelUpdated, 'success');
        this.handleReloadData();
    }

    calculateProgress() {
        this.totalTasks = this.events.length + this.keyAccountsComments.length + this.keyOpportunitiesComments.length;
        this.completedTasks = this.events.filter(e => e.LoginFlowCompleted__c).length + this.keyAccountsComments.filter(e => e.WeeklyCompleted__c).length + this.keyOpportunitiesComments.filter(e => e.WeeklyCompleted__c).length;
        this.completedPercentage = (this.completedTasks / this.totalTasks) * 100;

        if (this.totalTasks == this.completedTasks) {
            if (this.weeklyManagement != null) {
                this.stepStages = 'step3';
            } else {
                this.stepStages = 'step2';
            }
        } else {
            this.stepStages = 'step1';
        }
    }

    loadData(startDate, endDate) {
        this.isLoading = true;
        getWeeklyData({ startDate: startDate, endDate: endDate, userId: this.ownerId })
            .then(result => {
                // Reemplaza my.site.com por lightning.force.com en la baseUrl
                this.baseUrl = this.baseUrl.replace(/\.my\.site\.com/, '.lightning.force.com');
                
                this.events = result.events.map(event => ({
                    ...event,
                    eventLink: `${this.baseUrl}/lightning/r/Event/${event.Id}/view`
                }));
                this.keyAccounts = result.keyAccounts;
                this.keyAccountsComments = result.keyAccountsComments;
                this.keyAccountsComments = result.keyAccountsComments.map(keyAccountsComment => ({
                    ...keyAccountsComment,
                    accountLink: `${this.baseUrl}/lightning/r/Account/${keyAccountsComment.Account__r.Id}/view`
                }));
                this.keyOpportunities = result.keyOpportunities;
                this.keyOpportunitiesComments = result.keyOpportunitiesComments.map(keyOpportunitiesComment => ({
                    ...keyOpportunitiesComment,
                    opportunityLink: `${this.baseUrl}/lightning/r/Opportunity/${keyOpportunitiesComment.Opportunity__r.Id}/view`,
                    accountLink: `${this.baseUrl}/lightning/r/Account/${keyOpportunitiesComment.Opportunity__r.Account.Id}/view`
                }));
                this.weeklyManagement = result.weeklyManagement;
                // Añadimos campos isPdf e isXls a cada weeklyReport
                this.weeklyReports = result.weeklyReports.map(report => ({
                    ...report,
                    isPdf: report.FileName__c ? report.FileName__c.toLowerCase().endsWith('.pdf') : false,
                    isXls: report.FileName__c ? report.FileName__c.toLowerCase().endsWith('.xls') || report.FileName__c.toLowerCase().endsWith('.xlsx') : false
                }));

                this.calculateProgress();
                this.isLoading = false;
            })
            .catch(error => {
                this.showToast('Error',error, 'error');
                this.isLoading = false;
            });
    }

    // Abrir modal
    openConfirmModal() {
        this.isConfirmModalOpen = true;
    }

    // Cerrar modal
    closeConfirmModal() {
        this.isConfirmModalOpen = false;
    }

    handleConfirmSendReport() {
        // lógica para enviar el report
        this.isConfirmModalOpen = false;
    }

    closeAlreadySentModal() {
        this.isAlreadySentModalOpen = false;
    }

    handleCommentChange(event) {
        this.confirmComment = event.target.value;
    }

    downloadReport(event) {
        this.isLoading = true;
        downloadSelectedWeeklyReport({ wreportId: event.target.dataset.id })
            .then(result => {
                const byteArray = this.base64ToUint8Array(result.data);
                const mimeType = this.getMimeTypeFromExtension(result.filename);
                const blob = new Blob([byteArray], { type: mimeType });
    
                const link = document.createElement('a');
                link.href = URL.createObjectURL(blob);
                link.download = result.filename;
                document.body.appendChild(link);
                link.click();
                this.isLoading = false;
            })
            .catch(error => {
                console.log('Error downloadRepor')
                this.showToast('Error',error, 'error');
                this.isLoading = false;
            });
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

    handleCloseModal(event) {
        this.isModalNewEventOpen = false;
    }

    handleSendReportClick() {
        const today = new Date();
        const dayOfWeek = today.getDay(); // 0=Domingo, 5=Viernes
        const isFriday = dayOfWeek === 5;

        const currentWeek = this.getCurrentWeekString(); // 'YYYY-Www'
        const isCurrentWeekSelected = this.selectedWeek.padStart(2, '0') === currentWeek;
        const isPastWeekSelected = this.isPastWeek(this.selectedWeek);

        // Semana actual y no es viernes
        if (isCurrentWeekSelected && !isFriday) {
            this.showToast('Info', this.label.labelReportFridays, 'error');
        } else if (this.stepStages == 'step3') {
            this.isAlreadySentModalOpen = true; // abrimos modal
        } else {
            this.isConfirmModalOpen = true;
        }
    }

    // Devuelve la semana actual en formato YYYY-Www
    getCurrentWeekString() {
        const today = new Date();
        const date = new Date(Date.UTC(today.getFullYear(), today.getMonth(), today.getDate()));
        
        // Día de la semana (1 = lunes, 7 = domingo)
        const dayNum = date.getUTCDay() || 7;
        
        // Ajustar al jueves de la semana actual
        date.setUTCDate(date.getUTCDate() + 4 - dayNum);
        
        // Primer día del año
        const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1));
        
        // Calcular el número de semana
        const weekNo = Math.ceil((((date - yearStart) / 86400000) + 1) / 7);
        
        // Año ISO (puede diferir del año actual en la semana 1 o 52/53)
        const year = date.getUTCFullYear();
        
        return `${year}-${String(weekNo)}`;
    }

    // Verifica si selectedWeek es anterior a la semana actual
    isPastWeek(selectedWeek) {
        const [yearStr, weekStr] = selectedWeek.split('-');
        const year = parseInt(yearStr, 10);
        const week = parseInt(weekStr, 10);

        const [currentYearStr, currentWeekStr] = this.getCurrentWeekString().split('-');
        const currentYear = parseInt(currentYearStr, 10);
        const currentWeek = parseInt(currentWeekStr, 10);

        return year < currentYear || (year === currentYear && week < currentWeek);
    }

    handleFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.isModalNewEventOpen = false;
            this.handleReloadData();
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

    handleSendReport() {
        this.closeConfirmModal();
        this.isLoading = true;

        const selectedWeekObj = this.weekOptions.find(w => w.value === this.selectedWeek);
        if (selectedWeekObj) {
            const startDate = selectedWeekObj.startDate.toISOString().split('T')[0];
            const endDate = selectedWeekObj.endDate.toISOString().split('T')[0];
            this.isLoading = true;
            sendAndSaveWeeklyReport({ startDate: startDate, endDate: endDate, userId: this.ownerId, weeklyComment: this.confirmComment })
            .then(result => {
                this.closeAlreadySentModal();
                this.handleReloadData();
                this.isConfirmModalOpen = false;
                this.confirmComment = '';
                this.showToast(this.label.labelSuccess,this.label.labelReportSentSuccess, 'success');
            })
            .catch(error => {
                this.showToast('Error',error, 'error');
                this.isLoading = false;
            });
        }
    }

    // Acción al confirmar
    handleSendReportAgain() {
        this.closeAlreadySentModal();
        this.isLoading = true;

        const selectedWeekObj = this.weekOptions.find(w => w.value === this.selectedWeek);
        if (selectedWeekObj) {
            const startDate = selectedWeekObj.startDate.toISOString().split('T')[0];
            const endDate = selectedWeekObj.endDate.toISOString().split('T')[0];
            this.isLoading = true;
            sendWeeklyReport({ startDate: startDate, endDate: endDate, userId: this.ownerId })
            .then(result => {
                this.handleReloadData();
                this.showToast(this.label.labelSuccess,this.label.labelReportSentSuccess, 'success');
            })
            .catch(error => {
                this.showToast('Error',error, 'error');
                this.isLoading = false;
            });
        }
    }
}