/**
 * 
 * libProductLookupBar
 * 
 * Ramón, May 2024
 * 
 * Displays an empty canvas with the following slots (the slot names are given in brackets):
 * - A header (header)
 * - A body (body())
 * - A footer (footer). This includes a slot (custom-actions) to add buttons on the left side of the footer-
 * - Optional left and right toolbars (left-bar and right-bar)
 * - A modal panel docked to the right (docked-panel)
 * 
 * --------
 * API
 * - showViewport   
 * - showHeader
 * - headerText (Default Header)
 * - showDocked
 * - showPositiveButton
 * - showNegativeButton
 * - positiveButtonLabel (OK)
 * - negativeButtonLabel (Cancel)
 * - autoClose (false)
 * - showSpinner (false)
 * 
 */
import { LightningElement, api } from 'lwc';
import cancelLabel from '@salesforce/label/c.dict_button_cancel';

export default class LibCustomViewPort extends LightningElement {
  @api positiveButtonLabel = 'OK';
  @api negativeButtonLabel = cancelLabel;
  @api autoClose = false;
  @api headerText = 'Default Header';
  @api showSpinner = false;

  @api 
    get showViewport() {
        return this._showViewport;
    }
    set showViewport(value) {    
        this._showViewport = true;
    }

  @api
    get showHeader() {return this._showHeader;}
    set showHeader(value)  {this._showHeader = this.toBoolean(value);}

    @api
    get showDocked() {return this._showDocked;}
    set showDocked(value) {this._showDocked = this.toBoolean(value);}

    @api
    get showPositiveButton() { return this.showPositive; }
    set showPositiveButton(value) { this.showPositive = this.toBoolean(value);}

  @api
    get showNegativeButton() { return this.showNegative; }
    set showNegativeButton(value) { this.showNegative = this.toBoolean(value)};

    _showDocked = false;
    showPositive = false;
    showNegative = false;
    _showHeader = true;
    _showViewport = false;
  
  get showCanvas() {
    return (this._showViewport );
  }

  handlePositive() {
    if (this.autoClose) {
      this._showViewport = false;
    }
    this.dispatchEvent(new CustomEvent('positive'));
  }
  
  handleNegative() {
    if (this.autoClose) {
      this._showViewport = false;
    }
    this.dispatchEvent(new CustomEvent('negative'));
  }


  toBoolean(val) {
    return (val.toString().toLowerCase() === 'true');
  }

}