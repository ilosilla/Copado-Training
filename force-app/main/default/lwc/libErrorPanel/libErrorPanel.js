import { LightningElement, api } from 'lwc';
import { reduceErrors } from 'c/ldsUtils';
import noDataIllustration from './templates/noDataIllustration.html';
import inlineMessage from './templates/inlineMessage.html';

export default class LibErrorPanel extends LightningElement {

    //////////////////////////////////////
    // API
    //////////////////////////////////////

    @api hideCloseButton=false;

    /** Component theme **/
    @api get theme() {
        return this._theme;
    }
    set theme(value) {
        this._theme = value;
        this.setComponentTheme();
    }

    /** Array opf errors */
    @api get errors() {
        return this._errors;
    }
    set errors(value) {
        this._errors = value;
        this.setComponentContent();
    }

    //////////////////////////////////////
    // VARIABLES
    //////////////////////////////////////

    get showComponent() {
        return (this.errorMessages != null && this.errorMessages.length > 0);
    }
    get multiMessageMode() {
        return (this.errorMessages.length > 1);
    }

    _errors = new Array();
    _theme = 'error';
    isOpen = true;
    title;
    errorMessages;
    viewDetails = false;
    errorTheme="slds-box_x-small slds-section slds-is-open slds-theme_error slds-theme_alert-texture";
    warningTheme="slds-box_x-small slds-section slds-is-open slds-theme_warning slds-theme_alert-texture"
    cssTheme = this.detaultTheme;
    
    //////////////////////////////////////
    // PRIVATE METHODS
    //////////////////////////////////////

    setComponentContent() {     
        if (this._errors == null || this._errors == undefined || this._errors == '') {
            this.errorMessages = this._errors;
            return;
        }
        this.errorMessages = this.parseErrors(this._errors);
        if (!Array.isArray(this.errorMessages) || this.errorMessages.length == 0) {
            this.errorMessages = this._errors;
        }
        if (Array.isArray(this.errorMessages)) {
            this.title = `There are ${this.errorMessages.length} errors in the form`;
        } else {
            this.title = '';
        } 
    }

    setComponentTheme() {
        if (this._theme == 'warning') {
            this.cssTheme = this.warningTheme;
        } else {
            this.cssTheme = this.errorTheme;
        }
    }
    
    handleOnErrorsClose() {
        this.errors = null;
    }

    handleOnErrorsCollapse() {
        this.isOpen = !this.isOpen;
    }

    render() {
            return inlineMessage;
    }

    /*
     * Returns an array of messages
     */
    parseErrors(errors) {
        let messages = [];
        let message = '';
        try {
            let mtype = errors.body.exceptionType;
            if (mtype && mtype.toLowerCase() == 'errorlistexception')  {
                let parsed = this.fixSAPMessages(JSON.parse(errors.body.message));                
                return parsed;
            }
            if (errors.status == 500) {  // Server error                
                if (mtype) {
                    return reduceErrors(errors);        
                    //message = ' Error 500 received from the server ' + JSON.stringify(errors);
                } else {
                    const traceArray = errors.body.stackTrace.split("\n");
                    message = mtype + ': ' + errors.body.message + ' (' + traceArray[0] + ')';    
                }
                messages.push(message);
                return messages;
            } 
        } catch (ex) {
            if (typeof errors === 'string') {
                messages.push(errors);
                return messages;
            }
        }
        return reduceErrors(errors);        
    }

    /*
     * Fixes some problems with errors received from SAP
     */
    fixSAPMessages(arr) {
        const modifiedArr = [];
        for (let i = 0; i < arr.length; i++) {
          const str = arr[i];
          const modifiedStr = this.removeAmpersands(str);
          modifiedArr.push(modifiedStr);
        }
        return modifiedArr;
    }

    /*
     * Removes the ampersand that enclses a string received from SAP
     */
    removeAmpersands(str) {
        let modified = str;
        if (str.length >= 2) {
            if (str.startsWith('&')) {
              modified = modified.substring(1, modified.length);
            }
            if (str.endsWith('&')) {
              modified = modified.substring(0, modified.length - 1);
            } else   if (str.endsWith('&.')) {
              modified = modified.substring(0, modified.length - 2);
            }          
          }
        return modified;
    }
      
} // class