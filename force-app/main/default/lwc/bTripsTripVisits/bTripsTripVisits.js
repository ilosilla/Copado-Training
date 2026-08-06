import { LightningElement, api, track } from 'lwc';

export default class BTripsTripVisits extends LightningElement {
    @api visits;
    @api tripid;

    @track isModalOpenCreateEvent = false;
    @track isModalOpenShowEvent = false;
    @track isModalOpenDeleteEvent = false;
    @track selectedEvent = null;
    @track inputVariables = [];
    @track isLoading = false;

    handleNewEvent(event) {
        this.inputVariables = []
        this.inputVariables = [
            {name: 'businessTrip',type: 'String',value: this.tripid}
        ];
        this.isModalOpenCreateEvent = true;
    }

    handleCloseModal() {
        this.isModalOpenCreateEvent = false;
        this.selectedEvent = null;
        this.isModalOpenShowEvent = false;
        this.isModalOpenDeleteEvent = false;
    }

    handleLoad() {
        this.isLoading = false;
    }

    handleRowActionEdit(event) {
        this.selectedEvent = event.target.dataset.id;
        this.inputVariables = [
            {name: 'businessTrip',type: 'String',value: this.tripid},
            {name: 'businessTripVisitId',type: 'String',value: this.selectedEvent}
        ];
        this.isModalOpenCreateEvent = true;
    }

    handleRowActionDelete(event) {
        this.selectedEvent = event.target.dataset.id;
        this.inputVariables = [
            {name: 'visitId',type: 'String',value: this.selectedEvent}
        ];
        this.isModalOpenDeleteEvent = true;
    }

    handleRowActionShow(event) {
        this.isLoading = true;
        this.selectedEvent = event.target.dataset.id;
        this.isModalOpenShowEvent = true;
    }

    handleFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            const updateEvent = new CustomEvent('refresh');
            this.dispatchEvent(updateEvent);
            this.selectedEvent = null;
            this.handleCloseModal();
        }
    }
}