import { LightningElement, api, track } from 'lwc';

export default class BTripsTripEvents extends LightningElement {
    @api events;
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
            {name: 'businessTripId',type: 'String',value: this.tripid}
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
            {name: 'actionId',type: 'String',value: this.selectedEvent}            
        ];
        this.isModalOpenCreateEvent = true;
    }

    handleRowActionDelete(event) {
        this.selectedEvent = event.target.dataset.id;
        this.inputVariables = [
            {name: 'EventId',type: 'String',value: this.selectedEvent}
        ];
        this.isModalOpenDeleteEvent = true;
    }

    handleRowActionShow(event) {
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