import { LightningElement, api } from 'lwc';
import { classSet, normalizeBoolean, normalizeString } from 'c/b2B_LwcUtils';
 
 const DIALOG_SIZES = {
     valid: ['x-small', 'small', 'medium', 'large'],
     default: 'medium'
 };
 
 /**
  * @class
  * @descriptor avonni-dialog
  * @storyId example-dialog--base
  * @public
  */
 export default class Nb2bDialog extends LightningElement {
     /**
      * Dialog name.
      *
      * @type {string}
      * @public
      */
     @api dialogName;
     /**
      * The title can include text, and is displayed in the header. To include additional markup or another component, use the title slot.
      *
      * @type {string}
      * @public
      */
     @api title;
     /**
      * Message displayed while the modal box is in the loading state.
      *
      * @type {string}
      * @public
      */
     @api loadingStateAlternativeText;

     @api showFooter = false;    
     @api positiveButtonLabel = "Confirm";
     @api negativeButtonLabel = "Cancel";
     @api showPositiveButton = false;
     @api showNegativeButton = false;
     @api excludeXButton = false;

     _size = DIALOG_SIZES.default;
     _isLoading;
     _showDialog = false;//Change to prube
     haFooterSlot = false;
     showHeader = true;

     connectedCallback() {
         this.setAttribute('dialog-name', this.dialogName);
     }

     renderedCallback() {
         if (this.titleSlot) {
             this.showTitleSlot = this.titleSlot.assignedElements().length !== 0;
             this.showHeader = this.title || this.showTitleSlot;
         }

         if (this.titleSlot) {
            this.haFooterSlot = true;
         }
     }

     /**
      * Title Slot DOM element
      *
      * @type {HTMLElement}
      */
     get titleSlot() {
         return this.template.querySelector('slot[name=title]');
     }

     /**
      * Footer Slot DOM element
      *
      * @type {HTMLElement}
      */
     get footerSlot() {
         return this.template.querySelector('slot[name=footer]');
     }

     /**
      * Width of the modal. Accepted sizes include small, medium, large.
      *
      * @type {string}
      * @public
      * @default medium
      */
     @api
     get size() {
         return this._size;
     }

     set size(size) {
         this._size = normalizeString(size, {
             fallbackValue: DIALOG_SIZES.default,
             validValues: DIALOG_SIZES.valid
         });
     }

     /**
      * If present, the modal box is in a loading state and shows a spinner.
      *
      * @public
      * @type {boolean}
      * @default false
      */
     @api
     get isLoading() {
         return this._isLoading;
     }

     set isLoading(value) {
         this._isLoading = normalizeBoolean(value);
     }

     @api
     showSpinner(){
        this._isLoading = true;
     }

     @api
     closeSpinner(){
        this._isLoading = false;
     }

     /**
      * If present, the dialog is open by default.
      *
      * @type {boolean}
      * @default false
      * @public
      */
     @api
     get showDialog() {
         return this._showDialog;
     }

     set showDialog(value) {
         this._showDialog = normalizeBoolean(value);
     }

     /**
      * Verify if Title string present.
      *
      * @type {boolean}
      */
     get hasStringTitle() {
         return !!this.title;
     }

     /**
      * Open the modal box.
      *
      * @public
      */
     @api
     show() {
         this._showDialog = true;
     }

     /**
      * Close the modal box.
      *
      * @public
      */
     @api
     hide() {
         this._showDialog = false;
         /**
          * The event fired when the dialog closes.
          *
          * @event
          * @name closedialog
          */
         this.dispatchEvent(new CustomEvent('closedialog'));
     }

     /**
      * Set the focus on the close button.
      *
      * @public
      */
     @api
     focusOnCloseButton() {
         const button = this.template.querySelector('.slds-modal__close');
         if (button) button.focus();
     }

     /**
      * Computed Header class styling.
      *
      * @type {string}
      */
     get computedHeaderClass() {
         return classSet('slds-modal__header')
             .add({
                 'slds-modal__header_empty': !this.showHeader
             })
             .toString();
     }

     /**
      * Computed Modal class styling
      *
      * @type {string}
      */
     get computedModalClass() {
         return classSet('slds-modal slds-fade-in-open')
             .add(`slds-modal_${this._size}`)
             .toString();
     }

    handlePositive() {
        this.dispatchEvent(new CustomEvent('positive'));
    }

    handleNegative() {
        this.dispatchEvent(new CustomEvent('negative'));
    }     
 }