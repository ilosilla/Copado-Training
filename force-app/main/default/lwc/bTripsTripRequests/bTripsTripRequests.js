import { LightningElement, api, track } from 'lwc';
import LightningConfirm from 'lightning/confirm';

import deleteRequest from '@salesforce/apex/BusinessTripController.deleteTripRequest';

export default class BTripsTripRequests extends LightningElement {
    @api requests;
    @api strategyRequests;
    @api tripid;

    @track isModalOpenCreateRequest = false;
    @track selectedRequest = null;
    @track inputVariables = [];

    get hasVisitRequests() {
        return this.requests && this.requests.length > 0;
    }

    get hasStrategyRequests() {
        return this.strategyRequests && this.strategyRequests.length > 0;
    }

    handleNewRequest(event) {
        this.inputVariables = [
            {name: 'businessTripId',type: 'String',value: this.tripid}
        ];
        this.isModalOpenCreateRequest = true;
    }

    async handleRowActionDelete(event) {
            this.selectedRequest = event.target.dataset.id;
            const result = await LightningConfirm.open({
                message: 'Deseas eliminar la solicitud ?',
                theme: 'warning'
                // setting theme would have no effect
            });
            if (result == true) {
                this.isLoading = true;
                deleteRequest({ requestId: this.selectedRequest })
                .then(result => {
                    this.isLoading = false;
                    this.selectedRequest = null;
                    const updateRequest = new CustomEvent('refresh');
                    this.dispatchEvent(updateRequest);
                })
                .catch(error => {
                    console.error(error);
                    this.isLoading = false;
                });
            }
        }

    handleCloseModal() {
        this.isModalOpenCreateRequest = false;
        this.selectedRequest = null;
    }

    handleRowAction(event) {
        this.selectedRequest = event.target.dataset.id;
        this.inputVariables = [
                {name: 'businessTripId',type: 'String',value: this.tripid},
                {name: 'requestId',type: 'String',value: this.selectedRequest}
            ];
        this.isModalOpenCreateRequest = true;
    }

    handleFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            const updateRequest = new CustomEvent('refresh');
        this.dispatchEvent(updateRequest);
        this.selectedRequest = null;
        this.handleCloseModal();
        }
    }
}