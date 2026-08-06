import { LightningElement, track } from 'lwc';

import controller from '@salesforce/apex/B2B_contactPageController.sendMailtoSupport';

//LABELS
import title from '@salesforce/label/c.b2b_contactTitle';
import subtitle from '@salesforce/label/c.b2b_contactSubtitle';
import commentsBox from '@salesforce/label/c.b2b_contactCommentsBox';
import commentsPlaceholder from '@salesforce/label/c.b2b_contactPlaceholder';
import privacyPolicies1 from '@salesforce/label/c.b2b_contactPrivacyPolicies1';
import privacyPolicies2 from '@salesforce/label/c.b2b_contactPrivacyPolicies2';
import buttonSubmit from '@salesforce/label/c.b2b_contactButtonSubmit';
import privacyPoliciesLink from '@salesforce/label/c.b2b_contactPrivacyPoliciesLink';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class B2B_contactPage extends LightningElement {

    labels = {
        title ,
        subtitle ,
        commentsBox ,
        commentsPlaceholder ,
        privacyPolicies1 ,
        privacyPolicies2 ,
        buttonSubmit,
        privacyPoliciesLink
    }

    @track comments;
    @track privacyPolicies;
    @track enableButton = true;

    handleClickSubmit(){
        this.comments = this.template.querySelector("lightning-textarea").value;
        this.privacyPolicies = this.template.querySelector('[data-id="privacyPolicies"]').checked;
        if(this.privacyPolicies === true){
            controller({ body: this.comments })
            .then((result) => {
                this.comments = '';
                const event = new ShowToastEvent({
                    title: 'Success!',
                    message: 'A notification has been sent to support',
                    variant: 'success'
                });
                this.dispatchEvent(event);
            })
            .catch((error) => {
                this.comments = '';
                const event = new ShowToastEvent({
                    title: 'Error',
                    message: 'An error ocurred, please try again later',
                    variant: 'error'
                });
                this.dispatchEvent(event);
            });
        } else {
            const event = new ShowToastEvent({
                title: '',
                message: 'You must accept the privacy policies before proceed',
                variant: 'warning'
            });
            this.dispatchEvent(event);
        }
    }

    handleCheckComments(){
        console.log('TEST ' + this.template.querySelector("lightning-textarea").value);
        let commentsField = this.template.querySelector("lightning-textarea").value;
        if(commentsField == '' || commentsField == undefined || commentsField == null){
            this.enableButton = true;
        } else {
            this.enableButton = false;
        }
    }

}