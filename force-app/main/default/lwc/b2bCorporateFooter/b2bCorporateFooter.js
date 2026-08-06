import { LightningElement, wire, api } from 'lwc';
import LOGO_GRUPO from '@salesforce/resourceUrl/logo_grupo_white';
import ROYAL_WARRANT from '@salesforce/resourceUrl/logo_royal_white_hi';

export default class B2bCorporateFooter extends LightningElement {
    st_marketContext = null;
    grupoLogoUrl = LOGO_GRUPO;
    royalWarrantUrl = ROYAL_WARRANT;
    footerContext = {};

    /* ===========================================
     * PUBLIC API
     * =========================================== */
    @api variant = 'FULL'; // FULL | COMPACT

    get ui_isCompact() {
        return String(this.variant || 'FULL').toUpperCase() === 'COMPACT';
    }

    get ui_isFull() {
        return !this.ui_isCompact;
    }

    /* ===========================================
     * TEMPLATE GETTERS
     * =========================================== */
    get marketLabel() {
        return this.st_marketContext?.marketDisplayLabel ?? '';
    }

    get salesOrgName() {
        return this.st_marketContext?.salesOrgName ?? ''
    }

    get salesOrgAddress() {
        return this.st_marketContext?.warehouse?.formattedAddress ?? '';
    }

    get salesOrgContact() {
        return this.st_marketContext?.warehouse?.contactLine ?? '';
    }

    get salesOrgPhone() {
        return this.st_marketContext?.warehouse?.phone ?? '';
    }

    get salesOrgEmail() {
        return this.st_marketContext?.warehouse?.email ?? '';
    }

    get salesOrgPhoneHref() {
        return this.salesOrgPhone ? `tel:${this.salesOrgPhone.replace(/[^+\d]/g, '')}` : '';
    }

    get salesOrgEmailHref() {
        return this.salesOrgEmail ? `mailto:${this.salesOrgEmail}` : '';
    }

    /* ===========================================
     * EVENT HANDLERS
     * =========================================== */
    handleContextReceived(event) {
        this.st_marketContext = event.detail;
    }

    handleContextError(event) {
        console.error('Error loading market context', event.detail.message);
    }

}