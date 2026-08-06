import { LightningElement, api, track } from 'lwc';

import labelCompleted from '@salesforce/label/c.dict_completed';
import labelSubject from '@salesforce/label/c.dict_subject';
import labelDate from '@salesforce/label/c.dict_date';
import labelCancelled from '@salesforce/label/c.dict_cancelled';
import labelEdit from '@salesforce/label/c.dict_edit';
import labelEditEvent from '@salesforce/label/c.tr0012_0019';

export default class WeeklyEventManagement extends LightningElement {
    @api events = [];
    @api completed = [];
    @api isreadonly = false;
    @track isModalOpen = false;
    @track selectedEventId;

    label = {
        labelCompleted,
        labelSubject,
        labelDate,
        labelCancelled,
        labelEdit,
        labelEditEvent
    };

    get inputVariables() {
        return [
            {
                name: 'eventId',
                type: 'String',
                value: this.selectedEventId
            }
        ];
    }

    handleFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.handleUpdateEvent();
        }
    }

    handleRowAction(event) {
        this.selectedEventId = event.target.dataset.id;
        this.isModalOpen = true;
    }

    handleCloseModal() {
        this.isModalOpen = false;
        this.selectedEventId = null;
    }

    handleUpdateEvent() {
        // Emitimos un evento hacia el padre para refrescar datos si es necesario
        const updateEvent = new CustomEvent('refresh');
        this.dispatchEvent(updateEvent);
        this.handleCloseModal();
    }
}