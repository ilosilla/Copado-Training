/**
 * 
 * libMessageBar
 * 
 * Reusable component to show a message bar
 * 
 * Ramón, June 2024
 *  
 * --------
 * API 
 * - messages: Messages to didsplay (list or string)
 * - theme: shade|warning|error|info|success 
 * - hideCloseButton - Hides the close button
 * - align: left|center|right
 * - font: normal|bold|italic
 * - bullets: auto|true|false
 * - margin: small|medium|large
 * - customClass: A list of CSS classes to apply to the main container. This overrides the default margin property.
 * 
 * Align and font apply only when bullets is false.
 * 
 * Note:The default value is the first one listed
 */
import { LightningElement, api } from 'lwc';
import { reduceErrors } from 'c/ldsUtils';

export default class LibMessageBar extends LightningElement {


    //////////////////////////////////////
    // API
    //////////////////////////////////////

    @api hideCloseButton = false;
    @api theme = 'shade';
    @api align = 'left';
    @api font = 'normal';
    @api bullets = 'auto';
    @api margin;
    @api customClass = null;

    /** Array opf messages */
    @api 
        get messages() {
            return this._messages;
        }
        set messages(value) {
            this._messages = value;
            this.setComponentContent();
        }    

    //////////////////////////////////////
    // VARIABLES
    //////////////////////////////////////

    get baseTheme() {
        return 'slds-box_x-small slds-is-open slds-theme_alert-texture';
    }

    get showComponent() {
        return (this.parsedMessages?.length > 0);
    }
    get multiMessageMode() {
        return (this.parsedMessages?.length > 1);
    }

    get itemClass() {
        return 'slds-text-align_' + this.align;
    }

    get marginClass() {
        return (this.customClass ?? (this.margin != null ? 'slds-var-m-around_' + this.margin :  ''));
    }

    get cssTheme() {
        return this.baseTheme + ' ' + this.marginClass + ' slds-theme_' + this.theme?.toLowerCase();
    }

    get styleString() {
        let str = '';
        if (this.font?.toLowerCase() === 'bold') {
            str += 'font-weight: 700;';
        }
        if (this.font?.toLowerCase() === 'italic') {
            str += 'font-style: italic;';
        }
        return str;
    }

    get useBullets() {
        return (this.bullets === 'true' || this.bullets === 'auto' && this.parsedMessages?.length > 1);
    }

    _messages = new Array();
    parsedMessages;
    isOpen = true;
    title;
    viewDetails = false;
    baseTheme = "slds-box_x-small slds-is-open slds-theme_alert-texture";
    
    //////////////////////////////////////
    // PRIVATE METHODS
    //////////////////////////////////////

    setComponentContent() {     
        if (this._messages === null || this._messages === undefined || this._messages === '') {
            this.parsedMessages = this._messages;
            return;
        }
        this.parsedMessages = this.parseErrors(this._messages);
        if (!Array.isArray(this.parsedMessages) || this.parsedMessages.length == 0) {
            this.parsedMessages = [];
            if (typeof this._messages === 'string' ) {
                this.parsedMessages.push(this._messages);
            } else {
                this.parsedMessages = this._messages;
            }
        }

        if (Array.isArray(this.parsedMessages)) {
            this.title = `There are ${this.parsedMessages.length} messages`;
        } else {
            this.title = '';
        } 
    }

    handleOnErrorsClose() {
        this.parsedMessages = null;
    }

    handleOnErrorsCollapse() {
        this.isOpen = !this.isOpen;
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
                } else if (errors.body?.message && (typeof errors.body.message === 'string')) {
                    return this.parseErrorString(errors.body.message);
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
     * Parses an error string
     */
    parseErrorString(errorString) {
        let messages = [];
        let objects = [];
        const obj = JSON.parse(errorString);
        if (typeof obj === 'object') {
            if (!Array.isArray(obj)) {
                objects.push(obj);
            } else {
                objects = obj;
            }
            objects.forEach((item) => {
                if (item.hasOwnProperty("message")) {
                    messages.push(item.message);
                }
            });
            return messages;
        } else {
            return reduceErrors(errorString);
        }
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