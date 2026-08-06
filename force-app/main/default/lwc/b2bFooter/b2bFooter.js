import {api, LightningElement, track} from 'lwc';
export default class B2bFooter extends LightningElement {
    @api companyAddress;
    @api companyPhone;

    @api facebookLink;
    @api linkedinLink;
    @api instagramLink;
    @api companyLink;

    @api menuLabel;
    @api copyrightLabel;

    @api facebookIcon;
    @api instagramIcon;
    @api linkedinIcon;
    @api companyIcon;
    @api pinIcon;
    @api phoneIcon;


    connectedCallback() {
    }//end init Method

    handleClickEmail() {
    }



    get getCopyrightLabel() {
        if (!this.copyrightLabel) {
            return `© ${new Date().getFullYear()} Forte Group All rights reserved`;
        } else {
            return this.copyrightLabel.replace('YYYY', new Date().getFullYear());
        }
    }

    get getPhoneLink() {
        return `tel:${this.companyPhone}`;
    }

    get imageFacebook() {
        if (this.facebookIcon) {
            return `/cms/delivery/media/${this.facebookIcon}`;
        }
    }

    get imageInstagram() {
        if (this.instagramIcon) {
            return `/cms/delivery/media/${this.instagramIcon}`;
        }
    }

    get imageLinkedIn() {
        if (this.linkedinIcon) {
            return `/cms/delivery/media/${this.linkedinIcon}`;
        }
    }

    get imageCompany() {
        if (this.companyIcon) {
            return `/cms/delivery/media/${this.companyIcon}`;
        }
    }

    get imagePin() {
        if (this.pinIcon) {
            return `/cms/delivery/media/${this.pinIcon}`;
        }
    }

    get imagePhone() {
        if (this.phoneIcon) {
            return `/cms/delivery/media/${this.phoneIcon}`;
        }
    }



}