/**
 * uxModalDialog
 * ------------------------------------------------------------
 * Lightweight modal dialog component intended to be embedded
 * once in the parent component (e.g. an orchestrator) and
 * controlled imperatively via public properties and methods.
 *
 * Usage pattern:
 * --------------
 * 1. Include the component once in the parent HTML:
 *
 *    <c-ux-modal-dialog></c-ux-modal-dialog>
 *
 * 2. From the parent JS, configure it by setting its public
 *    properties and then call showDialog():
 *
 *    const dialog = this.template.querySelector('c-ux-modal-dialog');
 *
 *    dialog.variant = 'confirm';        // visual variant (e.g. confirm, warning, error)
 *    dialog.title = 'Confirm order';
 *    dialog.message = 'This order will be placed using your available credit.';
 *    dialog.confirmLabel = 'Continue';
 *    dialog.cancelLabel = 'Cancel';
 *
 *    const confirmed = await dialog.showDialog();
 *
 *    if (confirmed) {
 *        // user confirmed the action
 *    } else {
 *        // user cancelled
 *    }
 *
 * Design notes:
 * -------------
 * - The dialog is NOT created dynamically and does NOT extend
 *   LightningModal. This avoids layout issues and gives full
 *   control over positioning and styling.
 *
 * - Visibility is controlled internally via an `isOpen` state
 *   and an SLDS backdrop, so the parent never manipulates DOM
 *   visibility directly.
 *
 * - showDialog() returns a Promise<boolean> that resolves when
 *   the user clicks Confirm (true) or Cancel (false), making
 *   it easy to use in async flows.
 *
 * - The modal layout and size are stable between states to
 *   avoid visual jumps.
 *
 * ------------------------------------------------------------
 */
import { LightningElement, api } from 'lwc';

export default class UxModalDialog extends LightningElement {

    /* =========
     * API
     * ========= */
    @api title;
    @api message;
    @api variant = 'confirm';

    @api confirmLabel;
    @api cancelLabel;

    isOpen = false;
    // resolver de la Promise
    _resolve;
    
    /* =========
     * PUBLIC METHODS
     * ========= */
    @api
    showDialog() {
        this.isOpen = true;
        return new Promise(resolve => {
            this._resolve = resolve;
        });
    }

    closeDialog() {
        this.isOpen = false;
    }

    /* =========
     * COMPUTED
     * ========= */

    get hasTitle() {
        return !!this.title;
    }

    get showCancel() {
        return this.variant === 'confirm' || this.variant === 'destructive';
    }

    get confirmVariant() {
        return this.variant === 'destructive' ? 'destructive' : 'brand';
    }

    get variantBarClass() {
        return `ux-modal__bar ux-modal__bar--${this.variant}`;
    }

    /* =========
     * ACTIONS
     * ========= */
    handleConfirm() {
        this.isOpen = false;
        if (this._resolve) {
            this._resolve(true);
            this._resolve = null;
        }
    }

    handleCancel() {
        this.isOpen = false;
        if (this._resolve) {
            this._resolve(false);
            this._resolve = null;
        }
    }

    /* =========
     * DEFAULT LABELS
     * ========= */

    connectedCallback() {
        if (!this.confirmLabel) {
            this.confirmLabel = this.variant === 'destructive'
                ? 'Confirm'
                : 'Continue';
        }

        if (!this.cancelLabel) {
            this.cancelLabel = 'Cancel';
        }
    }


}