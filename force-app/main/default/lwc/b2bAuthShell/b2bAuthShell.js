import { LightningElement, api } from 'lwc';
import BG_URL from '@salesforce/resourceUrl/b2b_authshell_bg';

/**
 * @slot main     Main content (centered)
 */
export default class B2bAuthShell extends LightningElement {

    @api variant;

    get isLogin() {
        return this.variant === 'LOGIN';
    }

    get isForgotPassword() {
        return this.variant === 'FORGOT';
    }

    get subtitle() {
        if (this.isLogin) {
            return 'Sign in to continue';
        } else if (this.isForgotPassword) {
            return 'Pasword reset';
        }
        return '';
    }

    get ui_shellStyle() {
        // Static Resources must be resolved in JS (CSS can't use @salesforce/resourceUrl).
        return BG_URL ? `background-image: url(${BG_URL});` : '';
    }
}