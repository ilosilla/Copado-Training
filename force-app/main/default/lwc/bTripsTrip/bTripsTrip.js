import { LightningElement, track, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getBTrip from '@salesforce/apex/BusinessTripController.getBusinessTrip';
import sendPdf from '@salesforce/apex/BusinessTripController.sendPdf';


export default class BTripsTrip extends LightningElement {
    @api recordId;

    @track header;
    @track visits = [];
    @track requests = [];
    @track strategyRequests = [];
    @track strategies = [];
    @track strategyActions = [];
    @track visitActions = [];
    @track visitEvents = [];
    @track isLoading = true;
    @track isModalSendPdf = false;
    @track mode = 'view';
    @track emailSendPdf = null;
    @track titleSendPdf = null;
    @track bodySendPdf = null;
    @track baseUrl = window.location.origin;

    get inputVariables() {
        return [
            {
                name: 'tripId',
                type: 'String',
                value: this.recordId
            }
        ];
    }

    get tripName() {
        if (this.header != null) {
            return this.header.Name;
        }
        return null;
    }

    get editMode() {
        return this.mode == 'edit';
    }

    get visitsTabText() {
        return 'Visitas ( ' + this.visits.length + ' )'
    }

    get strategiesTabText() {
        return 'Oportunidades ( ' + this.strategies.length + ' )'
    }

    get requestsTabText() {
        return 'Solicitudes ( ' + (this.requests.length + this.strategyRequests.length ) + ' )'
    }

    get actionsTabText() {
        return 'Acciones ( ' + (this.visitActions.length + this.strategyActions.length ) + ' )'
    }

    get eventsTabText() {
        return 'Eventos ( ' + (this.visitEvents.length) + ' )'
    }

    get headerId() {
        if (this.header != null) {
            return this.header.Id;
        }
        return null;
    }

    connectedCallback() {
        this.loadData();
    }

    handleLoad(event) {
        this.isLoading = false;
    }

    handleEditMode(event) {
        this.mode = 'edit';
    }

    handleSuccess(event) {
        this.showToast('Success','Viaje actualizado', 'success');
        this.mode = 'view';
    }

    handleCancelEdition(event) {
        this.mode = 'view';
    }

    handleSubmit(event){
        event.preventDefault();       // stop the form from submitting
        this.isLoading = true;
        const fields = event.detail.fields;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
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

    handleGeneratePdf() {
        const vfUrl = `${this.baseUrl}/apex/BusinessTripPdf?tripId=${this.recordId}`;
        window.open(vfUrl, '_blank');
    }

    handleEmailChanged(event) {
        this.emailSendPdf = event.detail.value;
    }

    handleEmailTitleChanged(event) {
        this.titleSendPdf = event.detail.value;
    }

    handleEmailBodyChanged(event) {
        this.bodySendPdf = event.detail.value;
    }

    handleSendPdf() {
        this.isLoading = true;
        this.isModalSendPdf = false;
        sendPdf({ tripId: this.recordId, emailAddress: this.emailSendPdf, title: this.titleSendPdf, body: this.bodySendPdf })
        .then(result => {
            this.isLoading = false;
            this.showToast('Success','Datos enviados', 'success');
        })
        .catch(error => {
            console.error(error);
            this.isLoading = false;
            this.isModalSendPdf = false;
        });
    }

    handleOpenSendPdf(event) {
        this.isModalSendPdf = true;
    }

    handleCloseModal(event) {
        this.isModalSendPdf = false;
        this.emailSendPdf = null;
    }

    handleUpdateEvent() {
        this.showToast('Success','Datos actualizados', 'success');
        this.loadData();
    }

    loadData() {
        this.isLoading = true;
        getBTrip({ businessTripId: this.recordId })
            .then(result => {
                // Reemplaza my.site.com por lightning.force.com en la baseUrl
                this.baseUrl = this.baseUrl.replace(/\.my\.site\.com/, '.lightning.force.com');

                const requestCountByStrategy = {};
                if (result.strategyRequests) {
                    result.strategyRequests.forEach(req => {
                        const strategyId = req.BusinessTripStrategy__c;
                        if (strategyId) {
                            requestCountByStrategy[strategyId] = (requestCountByStrategy[strategyId] || 0) + 1;
                        }
                    });
                }

                const actionCountByStrategy = {};
                if (result.strategyActions) {
                    result.strategyActions.forEach(req => {
                        const strategyId = req.BusinessTripStrategy__c;
                        if (strategyId) {
                            actionCountByStrategy[strategyId] = (actionCountByStrategy[strategyId] || 0) + 1;
                        }
                    });
                }

                const requestCountByVisit = {};
                if (result.requests) {
                    result.requests.forEach(req => {
                        const visitId = req.BusinessTripVisit2__c;
                        if (visitId) {
                            requestCountByVisit[visitId] = (requestCountByVisit[visitId] || 0) + 1;
                        }
                    });
                }

                const actionCountByVisit = {};
                if (result.visitActions) {
                    result.visitActions.forEach(req => {
                        const visitId = req.BusinessTripVisit__c;
                        if (visitId) {
                            actionCountByVisit[visitId] = (actionCountByVisit[visitId] || 0) + 1;
                        }
                    });
                }

                const eventCountByVisit = {};
                if (result.visitEvents) {
                    result.visitEvents.forEach(req => {
                        const visitId = req.Business_Trip_Visit__c;
                        if (visitId) {
                            eventCountByVisit[visitId] = (eventCountByVisit[visitId] || 0) + 1;
                        }
                    });
                }

                const actionCountByEvent = {};
                if (result.visitEvents) {
                    result.visitEvents.forEach(req => {
                        const EventId = req.Business_Trip_Visit__c;
                        if (EventId) {
                            actionCountByEvent[EventId] = (actionCountByEvent[EventId] || 0) + 1;
                        }
                    });
                }



                this.header = result.header;
                // Agregar los 3 campos a cada evento
                this.visits = result.visits.map(ev => ({
                    ...ev,
                    accountLink: ev.Account__c ? `${this.baseUrl}/lightning/r/Account/${ev.Account__r.Id}/view` : null,
                    opportunityLink: ev.Opportunity__c ? `${this.baseUrl}/lightning/r/Opportunity/${ev.Opportunity__r.Id}/view` : null,
                    leadLink: ev.Lead__c ? `${this.baseUrl}/lightning/r/Lead/${ev.Lead__r.Id}/view` : null,
                    accountName: ev.Account__c ? ev.Account__r.Name : null,
                    opportunityName: ev.Opportunity__c ? ev.Opportunity__r.Name : null,
                    leadName: ev.Lead__c ? ev.Lead__r.Name : null,
                    requestCount: requestCountByVisit[ev.Id] || 0,
                    actionCount: actionCountByVisit[ev.Id] || 0,
                    eventCount: eventCountByVisit[ev.Id] || 0                   
                }));
                // Agregar los 3 campos a cada evento
                this.strategies = result.strategies.map(ev => ({
                    ...ev,
                    accountLink: ev.Account__c ? `${this.baseUrl}/lightning/r/Account/${ev.Account__r.Id}/view` : null,
                    accountName: ev.Account__c ? ev.Account__r.Name : null,
                    requestCount: requestCountByStrategy[ev.Id] || 0,
                    actionCount: actionCountByStrategy[ev.Id] || 0
                }));
                this.requests = result.requests;
                this.strategyRequests = result.strategyRequests;
                this.visitActions = result.visitActions;
                this.strategyActions = result.strategyActions;
                this.visitEvents = result.visitEvents;
                this.isLoading = false;
            })
            .catch(error => {
                console.error(error);
                this.isLoading = false;
            });
    }
}