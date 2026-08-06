import { LightningElement, api, track } from 'lwc';
import LightningConfirm from 'lightning/confirm';

import deleteAction from '@salesforce/apex/BusinessTripController.deleteAction';

export default class BTripsTripActions extends LightningElement {
    @api actions;
    @api strategyActions;
    @api tripid;

    @track isModalOpenCreateAction = false;
    @track selectedAction = null;
    @track inputVariables = [];

    get hasVisitActions() {
        return this.actions.length > 0;
    }

    get hasStrategicActions() {
        return this.strategyActions.length > 0;
    }

    handleNewAction(event) {
        this.inputVariables = [
            {name: 'businessTripId',type: 'String',value: this.tripid}
        ];
        this.isModalOpenCreateAction = true;
    }

    async handleRowActionDelete(event) {
        this.selectedAction = event.target.dataset.id;
        const result = await LightningConfirm.open({
            message: 'Deseas eliminar la acción ?',
            theme: 'warning'
            // setting theme would have no effect
        });
        if (result == true) {
            this.isLoading = true;
            deleteAction({ actionId: this.selectedAction })
            .then(result => {
                this.isLoading = false;
                this.selectedAction = null;
                const updateAction = new CustomEvent('refresh');
                this.dispatchEvent(updateAction);
            })
            .catch(error => {
                console.error(error);
                this.isLoading = false;
            });
        }
    }

    handleCloseModal() {
        this.isModalOpenCreateAction = false;
        this.selectedAction = null;
    }

    handleRowAction(event) {
        this.selectedAction = event.target.dataset.id;
        this.inputVariables = [
                {name: 'businessTripId',type: 'String',value: this.tripid},
                {name: 'actionId',type: 'String',value: this.selectedAction}
            ];
        this.isModalOpenCreateAction = true;
    }

    handleFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            const updateAction = new CustomEvent('refresh');
        this.dispatchEvent(updateAction);
        this.selectedAction = null;
        this.handleCloseModal();
        }
    }
}