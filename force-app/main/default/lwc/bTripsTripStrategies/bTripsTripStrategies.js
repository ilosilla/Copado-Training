import { LightningElement, api, track } from 'lwc';

export default class BTripsTripStrategies extends LightningElement {
    @api strategies;
    @api tripid;

    @track isModalOpenCreateStrategy = false;
    @track isModalOpenDeleteStrategy = false;
    @track selectedStrategy = null;
    @track inputVariables = [];
    @track isLoading = false;

    handleNewStrategy(event) {
        this.inputVariables = [
            {name: 'businessTrip',type: 'String',value: this.tripid}
        ];
        this.isModalOpenCreateStrategy = true;
    }

    handleCloseModal() {
        this.isModalOpenCreateStrategy = false;
        this.isModalOpenDeleteStrategy = false;
        this.selectedStrategy = null;
    }

    handleRowActionEdit(event) {
        this.selectedStrategy = event.target.dataset.id;
        this.inputVariables = [
                {name: 'businessTrip',type: 'String',value: this.tripid},
                {name: 'businessTripStrategyId',type: 'String',value: this.selectedStrategy}
            ];
        this.isModalOpenCreateStrategy = true;
    }

    handleLoad() {
        this.isLoading = false;
    }

    handleRowActionDelete(event) {
        this.selectedStrategy = event.target.dataset.id;
        this.inputVariables = [
                {name: 'strategyId',type: 'String',value: this.selectedStrategy}
            ];
        this.isModalOpenDeleteStrategy = true;
    }

    handleFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            const updateEvent = new CustomEvent('refresh');
            this.dispatchEvent(updateEvent);
            this.selectedStrategy = null;
            this.handleCloseModal();
        }
    }
}