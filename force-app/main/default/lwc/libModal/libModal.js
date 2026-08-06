import { LightningElement, api, track } from 'lwc';
import cancelLabel from '@salesforce/label/c.dict_button_cancel';
import A_task_has_been_scheduled_to_remind_you_to_call_the_customer_again_tomorrow from '@salesforce/label/c.A_task_has_been_scheduled_to_remind_you_to_call_the_customer_again_tomorrow';
import TimeRemainingInHrs from '@salesforce/schema/CaseMilestone.TimeRemainingInHrs';

export default class libModal extends LightningElement {
  @api positiveButtonLabel = 'OK';
  @api negativeButtonLabel = cancelLabel;
  @api autoClose = false;
  @api showModal;
  @api headerText = 'Modal Window';
  @api showSpinner = false;
  @api variant = 'standard';   // 'standard' (default) | 'seamless' (no header/body divider)

  @track showClose = false;
  @track showPositive = false;
  @track showNegative = false;
  @track _showHeader = true;
  _width='';
  _height='';
  style='';
  baseStyle='align-items: center;';

  msize;
  modalClass;
  modalBodyClass;
  baseModalClass = 'slds-modal__container slds-var-p-around_medium';
  baseModalBodyClass = 'slds-modal__content slds-p-around_medium';

  @api
    get width() { return this._width;}
    set width(value) {
      this._width = value;
      this.buildStyle();
    }
  @api
    get showHeader() {return this._showHeader;}
    set showHeader(value)  {this._showHeader = this.toBoolean(value);}

  @api
    get showCloseIcon() {return this.showClose;}
    set showCloseIcon(value)  {this.showClose = this.toBoolean(value);}

  @api
    get showPositiveButton() { return this.showPositive; }
    set showPositiveButton(value) { this.showPositive = this.toBoolean(value);}

  @api
    get showNegativeButton() { return this.showNegative; }
    set showNegativeButton(value) { this.showNegative = this.toBoolean(value)};

  @api
    get modalSize() {return this.msize;}
    set modalSize(value)  {
      this.msize = value.toLowerCase();
    };

  get headerClass() {
    return this.variant === 'seamless'
      ? 'slds-modal__header modal-header_seamless'
      : 'slds-modal__header';
  }

  connectedCallback() {
    if (this.msize == undefined) {
      this.msize = 'medium';
    }
    this.setClasses(this.msize);
  }

  constructor() {
    super();
    this.showModal = false;
  }

  handlePositive() {
    if (this.autoClose) {
      this.showModal = false;
    }
    this.dispatchEvent(new CustomEvent('positive'));
  }
  
  handleNegative() {
    if (this.autoClose) {
      this.showModal = false;
    }
    this.dispatchEvent(new CustomEvent('negative'));
  }

  handleClose() {
    this.showModal = false;
    this.dispatchEvent(new CustomEvent('close'));
  }

  setClasses() {
    if ( (this.msize == 'full') || (this.msize == 'large') || (this.msize == 'medium') || (this.msize == 'small') || (this.msize == 'narrow') || (this.msize == 'auto') || 
      (this.msize == 'medium-tall')) {
        this.modalClass = this.baseModalClass + ' ' + this.msize + '_modal';
        this.modalBodyClass = this.baseModalBodyClass + ' ' + this.msize + '_modal_body';
    }  else {
      this.modalClass = this.baseModalClass;
      this.modalBodyClass = this.baseModalBodyClass;
    }
  }
  
  buildStyle() {
    this.style = this.baseStyle;
    if (this._width.length > 0)  {
      this.style += 'width: ' + this._width + '  !important;max-width: ' + this._width + '  !important;';
    }
    if (this._height.length > 0)  {
      this.style += 'height: ' + this._height + '  !important;';
    }
  }
  
  toBoolean(val) {
    return (val.toString().toLowerCase() === 'true');
  }

}