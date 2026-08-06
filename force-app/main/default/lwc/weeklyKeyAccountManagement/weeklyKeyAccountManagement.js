import { LightningElement, api, track } from 'lwc';

import labelEdit from '@salesforce/label/c.dict_edit';
import labelCompleted from '@salesforce/label/c.dict_completed';
import labelName from '@salesforce/label/c.dict_name';
import labelSalesMaturity from '@salesforce/label/c.tr0012_0020';
import labelEditComment from '@salesforce/label/c.tr0012_0021';

export default class WeeklyKeyAccountManagement extends LightningElement {
    @api accounts = [];
    @api comments = [];
    @api completed = false;
    @api isreadonly = false;
    @track isModalOpen = false;
    @track selectedCommentId;

    label = {
        labelEdit,
        labelCompleted,
        labelName,
        labelSalesMaturity,
        labelEditComment
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