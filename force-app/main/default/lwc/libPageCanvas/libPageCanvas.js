import { LightningElement, api } from 'lwc';
import cancelLabel from '@salesforce/label/c.dict_button_cancel';

export default class libModal extends LightningElement {
  @api positiveButtonLabel = 'OK';
  @api negativeButtonLabel = cancelLabel;
  @api autoClose = false;
  @api showModal;
  @api headerText = 'Default Header';
  @api showSpinner = false;

  @api 
    get mode() {return this.canvasMode;}
    set mode(value) {
      this.canvasMode = value.toLowerCase();
      if (!this.modeValueSet.has(this.canvasMode)) {
        throw new Error('Wrong mode value: ' + value);
      }
      if (this.canvasMode === 'panel') {
        this._width = (this._width == null) ? "100%" : this._width;
        this._height = (this._height == null) ? "100%" : this._height;
        this.recalcSize();
      }
    }

  @api
    get width() { return this._width;}
    set width(value) {
      this._width = value;
      this.recalcSize();
    }

  @api
    get height() { return this._height;}
    set height(value) {
      this._height = value;
      this.recalcSize();
    }
    
  @api
    get showHeader() {return this._showHeader;}
    set showHeader(value)  {this._showHeader = this.toBoolean(value);}

  @api
    get showPositiveButton() { return this.showPositive; }
    set showPositiveButton(value) { this.showPositive = this.toBoolean(value);}

  @api
    get showNegativeButton() { return this.showNegative; }
    set showNegativeButton(value) { this.showNegative = this.toBoolean(value)};

  @api
    get size() { return this._size; }
    set size(value) {
      this._size = value.toLowerCase();
      if (this._size === 'medium') {
        this._width = "50%";
        this._height = "50%";
      } else if (this._size === 'large') {
        this._width = "80%";
        this._height = "90%";
      } else if (this._size === 'narrow') {
        this._width = "60%";
        this._height = "50%";
      } else if (this._size === 'small') {
        this._width = "30%";
        this._height = "30%";
      } else if (this._size === 'full') {
        this._width = "100%";
        this._height = "100%";
      }
      this.recalcSize();
    }

  modeValueSet = new Set(["panel", "modal"]);
  canvasMode = "panel";
  _size="";
  sizeString;
  widthString;
  heightString;
  _width;
  _height;

  showPositive = false;
  showNegative = false;
  _showHeader = true;
  
  get showCanvas() {
    return (this.showModal || this.canvasMode == 'panel');
  }

  get isModal() {
    return (this.canvasMode == 'modal');
  }

  get topClass() {
    if (this.isModal) {
      return "slds-modal slds-fade-in-open";
    } 
    return "";
  }

  get containerClass() {
    if (this.isModal) {
      return "slds-modal__container slds-var-p-around_medium";
    } else {
      return "slds-modal__container panel-container";
    }
  }

  get canvasBodyClass() {
    if (this.showHeader) {
      return 'slds-modal__content';
    } else {
      return 'slds-modal__content';
    }
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

  recalcSize() {
    this.sizeString = "";
    this.widthString = "";
    this.heightString = "";
    if (this._width != null && this._width.length > 0)  {
      this.widthString = 'min-width:' + this._width + ";";
      this.sizeString += 'width: ' + this._width + '  !important;max-width: ' + this._width + '  !important;';
    }
    if (this._height != null && this._height.length > 0)  {
      this.heightString = 'max-height:' + this._height + ";height:" + this._height + " !important;";
      this.sizeString += 'height: ' + this._height + '  !important;';
    }
  }

  toBoolean(val) {
    return (val.toString().toLowerCase() === 'true');
  }

}