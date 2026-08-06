import { LightningElement, api } from 'lwc';

const SQFT_PER_M2 = 10.7639;

/**
 * uxSurfaceCalculator
 * -----------------------------------------------------------
 * Reusable surface calculator panel.
 * Converts between m²/sq ft and Pal/Box quantities,
 * always rounding up to the next full box.
 *
 * @api open        — controls panel visibility
 * @api productInfo — { sku, name, m2PerBox, boxPerPal, pcsPerBox, useMetricSystem, locale }
 *
 * @fires close   — user dismissed without confirming
 * @fires confirm — user confirmed; detail: { pallets, boxes }
 */
export default class UxSurfaceCalculator extends LightningElement {

    /* =========================================================
       PUBLIC API
       ========================================================= */

    @api open = false;
    @api productInfo; // { sku, name, m2PerBox, boxPerPal, pcsPerBox, useMetricSystem, locale }

    /* =========================================================
       PRIVATE STATE
       ========================================================= */

    inputSurface  = 0;
    inputPallets  = 0;
    inputBoxes    = 0;

    resultPallets = 0;
    resultBoxes   = 0;
    resultSurface = 0;
    wasRounded    = false;

    /* =========================================================
       GETTERS
       ========================================================= */

    get surfaceLabel() {
        return (this.productInfo?.useMetricSystem ?? true) ? 'm²' : 'sq ft';
    }

    get surfaceInputLabel() {
        return (this.productInfo?.useMetricSystem ?? true) ? 'Sq. Metres' : 'Sq. Ft.';
    }

    get surfaceFactorLabel() {
        return (this.productInfo?.useMetricSystem ?? true) ? 'M² / Box' : 'Sq. Ft. / Box';
    }

    get m2PerBoxDisplay() {
        const val = this.productInfo?.m2PerBox ?? 0;
        const display = (this.productInfo?.useMetricSystem ?? true)
            ? val
            : val * SQFT_PER_M2;
        return this._formatSurface(display);
    }

    get hasNoResult() {
        return this.resultPallets === 0 && this.resultBoxes === 0;
    }

    get hasResult() {
        return !this.hasNoResult;
    }

    get resultSummaryText() {
        const parts = [];
        if (this.resultPallets > 0) {
            parts.push(`${this.resultPallets} pallet${this.resultPallets > 1 ? 's' : ''}`);
        }
        if (this.resultBoxes > 0) {
            parts.push(`${this.resultBoxes} box${this.resultBoxes > 1 ? 'es' : ''}`);
        }
        const rounded = this.wasRounded ? ' *' : '';
        return parts.join(' · ') + ` (${this.resultSurface} ${this.surfaceLabel})${rounded}`;
    }

    /* =========================================================
       EVENT HANDLERS — INPUTS
       ========================================================= */

    handleSurfaceChange(event) {
        const surface = event.detail?.value ?? 0;
        this.inputSurface = surface;
        this._calculateFromSurface(surface);
    }

    handlePalletsChange(event) {
        this.inputPallets = event.detail?.value ?? 0;
        this._calculateFromQuantities();
    }

    handleBoxesChange(event) {
        this.inputBoxes = event.detail?.value ?? 0;
        this._calculateFromQuantities();
    }

    /* =========================================================
       EVENT HANDLERS — PANEL
       ========================================================= */

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleConfirm() {
        this.dispatchEvent(new CustomEvent('confirm', {
            detail: { pallets: this.resultPallets, boxes: this.resultBoxes }
        }));
    }

    /* =========================================================
       CALCULATION LOGIC
       ========================================================= */

    _m2PerBoxNative() {
        const m2 = this.productInfo?.m2PerBox ?? 0;
        return (this.productInfo?.useMetricSystem ?? true) ? m2 : m2 * SQFT_PER_M2;
    }

    _calculateFromSurface(surface) {
        const m2PerBox  = this._m2PerBoxNative();
        const boxPerPal = this.productInfo?.boxPerPal ?? 1;
        if (m2PerBox <= 0 || surface <= 0) {
            this._resetResult();
            return;
        }

        const exactBoxes = surface / m2PerBox;
        const totalBoxes = Math.ceil(exactBoxes);
        this.wasRounded  = exactBoxes !== totalBoxes;

        this.resultPallets = Math.floor(totalBoxes / boxPerPal);
        this.resultBoxes   = totalBoxes % boxPerPal;
        this.resultSurface = this._formatSurface(totalBoxes * m2PerBox);

        this.inputPallets = this.resultPallets;
        this.inputBoxes   = this.resultBoxes;
    }

    _calculateFromQuantities() {
        const m2PerBox  = this._m2PerBoxNative();
        const boxPerPal = this.productInfo?.boxPerPal ?? 1;

        const totalBoxes   = (this.inputPallets * boxPerPal) + this.inputBoxes;
        this.resultPallets = this.inputPallets;
        this.resultBoxes   = this.inputBoxes;
        this.resultSurface = this._formatSurface(totalBoxes * m2PerBox);
        this.wasRounded    = false;

        this.inputSurface = Math.round(totalBoxes * m2PerBox * 100) / 100;
    }

    _formatSurface(value) {
        return new Intl.NumberFormat(this.productInfo?.locale ?? 'en-US', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(value);
    }

    _resetResult() {
        this.resultPallets = 0;
        this.resultBoxes   = 0;
        this.resultSurface = 0;
        this.wasRounded    = false;
    }
}