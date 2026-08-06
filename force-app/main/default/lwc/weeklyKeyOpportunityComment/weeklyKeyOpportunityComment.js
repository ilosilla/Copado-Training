import { LightningElement, api, track } from 'lwc';

export default class WeeklyKeyOpportunityComment extends LightningElement {
    @api opportunities = [];
    @api comments = [];
    @track isModalOpen = false;
    @track selectedCommentId;

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