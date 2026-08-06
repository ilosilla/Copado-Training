import { LightningElement, api, track } from 'lwc';

export default class LibFormElement extends LightningElement {
    @api label;
    @api value;
    @api currency;
    @api digits = 0;
    @api downloadButton=false;
    @api tooltip;
    
    @api 
        get format() {
            return this._format;
        }
        set format(value) {
            this._format = value?.toLowerCase();
            this.isPlain = false;
            if (this.format != undefined && this.format != null) {
                if (this._format == 'date') {
                    this.isDate = true;
                } else if (this._format == 'email') {
                    this.isEmail = true;
                } else if (this._format == 'currency') {
                    this.isCurrency = true;
                } else if (this._format == 'decimal') {
                    this.isDecimal = true;                    
                } else if (this._format == 'phone') {
                    this.isPhone = true;
                } else if (this._format == 'url') {
                    this.isUrl = true;
                } else if (this._format == 'badge') {
                    this.isBadge = true;
                } else {
                    this.isPlain = true;
                }
            } else {
                this.isPlain = true;
            }
        }

    @api    
        get className() {
            return this._class;
        }
        set className(value) {
            this._class = value;
        }
    
    @api
        isLoading(value) {
            this.isDownloading = value;
        }

    get classes() {
        return 'slds-form-element slds-form-element_readonly ' + this._class;
    }

    get hasTooltip() {
        return (this.tooltip !== null && this.tooltip !== undefined && this.tooltip.length > 0);
    }

    _format;
    isDate = false;
    isEmail = false;
    isCurrency = false;
    isDecimal = false;
    isPhone = false;
    isUrl=false;
    isPlain = true;
    isDownloading = false;
    isBadge = false;

    handleIconClick() {
        this.dispatchEvent(new CustomEvent("download", { detail: { value: this.value, label: this.label }}));
    }
}