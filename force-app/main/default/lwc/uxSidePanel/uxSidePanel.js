import { LightningElement, api } from 'lwc';

export default class UxSidePanel extends LightningElement {

    /* =========================================================
       PUBLIC API
       ========================================================= */

    _open = false;

    @api
    get open() { return this._open; }
    set open(value) {
        this._open = value;
        document.body.style.overflow = value ? 'hidden' : '';
    }
    @api loading = false;
    @api title;
    @api showBack = false;    // Shows a back icon on the header, at the left of the title. Emits a 'back' event when clicked.

    @api dock = 'right';     // right | left | top | bottom | center
    @api size = 'M';         // S | M | L | FULL
    @api customWidth;        // e.g. '600px' — overrides size when set
    @api variant = 'rounded'; // rounded | square

    @api stickyFooter = false;

    @api footerVariant;      // ok-cancel | save-cancel | confirm-cancel | yes-no | custom
    @api positiveLabel;
    @api negativeLabel;
    @api positiveDisabled = false;
    @api negativeDisabled = false;

    @api footerLayout = 'stretch'; // right | left | center | stretch


    /* =========================================================
       COMPUTED STATE — VISIBILITY
       ========================================================= */

    get isStickyFooter() {
       return this.stickyFooter;
    }

    get showFooter() {
        return this.footerVariant === 'custom' || this.hasAnyFooterAction;
    }

    get footerVariantIsCustom() {
       return this.footerVariant === 'custom';
    }
    
    get hasAnyFooterAction() {
        return !this.footerVariantIsCustom && Boolean(this.footerVariant || this.positiveLabel || this.negativeLabel);
    }

    get showPositive() {
        return Boolean(this.positiveLabelResolved);
    }

    get showNegative() {
        return Boolean(this.negativeLabelResolved);
    }

    get isPositiveDisabled() {
        return this.loading || this.positiveDisabled;
    }

    get isNegativeDisabled() {
        return this.loading || this.negativeDisabled;
    }

    /* =========================================================
       LABEL RESOLUTION
       ========================================================= */

    get positiveLabelResolved() {
        if (this.positiveLabel) {
            return this.positiveLabel;
        }
        return this.variantLabels?.positive || null;
    }

    get negativeLabelResolved() {
        if (this.negativeLabel) {
            return this.negativeLabel;
        }
        return this.variantLabels?.negative || null;
    }

    get variantLabels() {
        switch (this.footerVariant) {
            case 'ok-cancel':
                return { positive: 'OK', negative: 'Cancel' };
            case 'save-cancel':
                return { positive: 'Save', negative: 'Cancel' };
            case 'confirm-cancel':
                return { positive: 'Confirm', negative: 'Cancel' };
            case 'yes-no':
                return { positive: 'Yes', negative: 'No' };
            default:
                return null;
        }
    }


    /* =========================================================
       CLASSES
       ========================================================= */

    get overlayClass() {
       let cls = 'ux-sidepanel-overlay';
        if (this.dock === 'center') cls += ' ux-sidepanel-overlay--center';        
        return this.open ? cls : cls + ' slds-hide';
    }

    get panelClass() {
        const classes = ['ux-sidepanel'];

        classes.push(`ux-sidepanel--dock-${this.dock.toLowerCase()}`);
        if (!this.customWidth) classes.push(`ux-sidepanel--size-${this.size.toLowerCase()}`);
        if (this.variant === 'square') classes.push('ux-sidepanel--square');

        return classes.join(' ');
    }

    get panelStyle() {
        if (!this.customWidth) return '';
        const w = this.customWidth === 'auto' ? 'fit-content' : this.customWidth;
        return `width: ${w};`;
    }

    get footerClass() {
        const classes = ['ux-sidepanel__footer'];

        classes.push(`ux-footer--${this.footerLayout}`);

        if (!this.isStickyFooter) {
            classes.push('ux-footer--static');
        }

        return classes.join(' ');
    }

    get contentClass() {
        return this.isStickyFooter ? 'ux-sidepanel__content' : 'ux-sidepanel__content non-sticky-content';
    }

    get showPositiveSpacer() {
        return this.showPositive && !this.showNegative;
    }

    /* =========================================================
       EVENTS
       ========================================================= */

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handlePositive() {
        this.dispatchEvent(new CustomEvent('positive'));
    }

    handleNegative() {
        this.dispatchEvent(new CustomEvent('negative'));
    }

    stopPropagation(event) {
        event.stopPropagation();
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('back'));
    }
}