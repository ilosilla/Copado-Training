/**
 * libToast
 * Reusable component to display html messages in a toast
 * Ramón, Feb 2023
 */

import { LightningElement, track, api} from 'lwc';

export default class libToast extends LightningElement {

    @api type = 'success';
    @api header;
    @api message;
    @api messageList;
    @api autoCloseTime = 0;    

    showToastBar = false;
    
    @api
    showToast() {
        this.showToastBar = true;
        if (this.autoCloseTime > 0) {
            setTimeout(() => {
                this.closeToast();
            }, this.autoCloseTime);
        }
    }
    
    closeToast() {
        this.showToastBar = false;
        this.type = '';
        this.message = '';
    }
 
    get iconName() {
        return 'utility:' + this.type;
    }
    get innerClass() {
        return 'slds-icon_container slds-icon-utility-' + this.type + ' slds-var-m-right_small slds-no-flex slds-align-top';
    }
 
    get outerClass() {
        return 'slds-var-m-top_large slds-notify slds-notify_toast slds-theme_alert-texture slds-theme_' + this.type;
    }

    get messageBody() {
        let body = ''
        if (this.messageList && this.messageList.length > 0) {
            if (this.messageList.length == 1) {
                body = this.messageList[0];
            } else {
                body = '<ul>';
                for (var i = 0; i < this.messageList.length; i++) {
                    body += '<li>' + this.messageList[i] + '</li>';
                }
                body += '</li>';
            }
        } else {
            body = this.message;
        }
        return body;
    }
}