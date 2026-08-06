import { LightningElement, api, track } from 'lwc';

import labelEdit from '@salesforce/label/c.dict_edit';
import labelCompleted from '@salesforce/label/c.dict_completed';
import labelName from '@salesforce/label/c.dict_name';
import labelEditComment from '@salesforce/label/c.tr0012_0021';
import labelAccountName from '@salesforce/label/c.tr0012_0022';
import labelOpportunityName from '@salesforce/label/c.tr0012_0023';

export default class WeeklyKeyOpportunityManagement extends LightningElement {
    @api opportunities = [];
    @api comments = [];
    @api completed = false;
    @api isreadonly = false;
    @track isModalOpen = false;
    @track selectedCommentId;

    label = {
        labelEdit,
        labelCompleted,
        labelName,
        labelEditComment,
        labelAccountName,
        labelOpportunityName
    };

    get inputVariables() {
        return [
            {
                name: 'CommentId',
                type: 'String',
                value: this.selectedCommentId
            }
        ];
    }

    handleRowAction(event) {
        this.selectedCommentId = event.target.dataset.id;
        this.isModalOpen = true;
    }

    handleCloseModal() {
        this.isModalOpen = false;
        this.selectedCommentId = null;
    }

    handleFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.handleUpdateComment();
        }
    }

    handleUpdateComment() {
        // Emitimos un evento hacia el padre para refrescar datos si es necesario
        const updateEvent = new CustomEvent('refresh');
        this.dispatchEvent(updateEvent);
        this.handleCloseModal();
    }
}