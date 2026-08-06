import { LightningElement, api } from 'lwc';
import TERMS_URL from '@salesforce/resourceUrl/B2B_USDealers_Terms';

export default class B2bTermsAndConditions extends LightningElement {

    @api open = false;
    @api title = 'Terms & Conditions';
    @api dock = 'right';
    @api size = 'L';

    loading = false;
    loaded = false;

    renderedCallback() {
        // Cargar solo cuando se abre y solo una vez
        if (this.open && !this.loaded && !this.loading) {
            this.loadTerms();
        }
    }

    async loadTerms() {
        this.loading = true;
        try {
            const res = await fetch(TERMS_URL);
            const html = await res.text();
            const host = this.template.querySelector('.terms-body');
            if (host) host.innerHTML = html;
            this.loaded = true;
        } finally {
            this.loading = false;
        }
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}