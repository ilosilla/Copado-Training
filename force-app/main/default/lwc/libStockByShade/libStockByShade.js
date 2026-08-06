/**
 * libStockByShade
 * Reusable modal showing available stock broken down by shade (lote).
 *
 * Two display modes, driven by the product:
 *  - Ceramic tile (isTile && !isSpecialTile): boxes/pieces UK notation ("10/05") per shade,
 *    plus a Surface column and the total available surface in the header.
 *  - Special piece / non-ceramic: plain integer units per shade, no surface, no total.
 *
 * Surface is the only additive aggregate across shades, so it's the only total shown.
 * Direct-customer oriented: in-transit is intentionally not shown here.
 *
 * Emits: close
 * Depends on: libModal (rendered with variant="seamless")
 */
import { LightningElement, api } from 'lwc';

const SQFT_PER_M2 = 10.7639;

export default class LibStockByShade extends LightningElement {
    @api showModal = false;
    // { name, sku, piecesPerBox, boxesPerPallet, m2PerBox, isTile, isSpecialTile }
    @api product = {};
    @api shades = [];          // [{ lote, stockAvailable }] — quantities in pieces
    @api unitSystem = 'int';   // 'imp' | 'int'
    @api locale = 'en-US';

    /* ========================================================= */
    /* TEMPLATE GETTERS                                          */
    /* ========================================================= */

    // Surface mode: ceramic tiles. Otherwise plain integer units, no surface.
    get isSurfaceMode() {
        return this.product?.isTile === true && this.product?.isSpecialTile !== true;
    }

    get productName() {
        return this.product?.name;
    }

    get sku() {
        return this.product?.sku;
    }

    // One row per shade, sorted by quantity (== surface order, same m²/box for every shade).
    get rows() {
        const surfaceMode = this.isSurfaceMode;
        return [...(this.shades ?? [])]
            .sort((a, b) => (b.stockAvailable ?? 0) - (a.stockAvailable ?? 0))
            .map((row) => {
                const qty = row.stockAvailable ?? 0;
                return {
                    lote:           row.lote,
                    quantity:       surfaceMode ? this.boxesPiecesNotation(qty) : this.fmt(qty),
                    surfaceDisplay: surfaceMode ? this.surfaceDisplay(qty) : null
                };
            });
    }

    // Total available surface across all shades (additive, unlike physical units).
    get totalSurfaceDisplay() {
        if (!this.isSurfaceMode) {
            return null;
        }
        const totalPieces = (this.shades ?? []).reduce((sum, row) => sum + (row.stockAvailable ?? 0), 0);
        return this.surfaceDisplay(totalPieces);
    }

    get showSurfaceColumn() {
        return this.isSurfaceMode;
    }

    get quantityHeader() {
        return this.isSurfaceMode ? 'Boxes / Pieces' : 'Units';
    }

    // Packaging reference for the product (same for every shade).
    get packagingLine() {
        const parts = [];
        if (this.product?.boxesPerPallet > 0) parts.push(`${this.fmt(this.product.boxesPerPallet)} boxes/pallet`);
        if (this.product?.piecesPerBox > 0)   parts.push(`${this.fmt(this.product.piecesPerBox)} pieces/box`);
        if (this.isSurfaceMode && this.product?.m2PerBox > 0) parts.push(`${this.surfacePerBox} /box`);
        return parts.join(' · ');
    }

    /* ========================================================= */
    /* EVENTS                                                    */
    /* ========================================================= */

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    /* ========================================================= */
    /* PRIVATE HELPERS                                           */
    /* ========================================================= */

    // Pieces -> "10/05" (boxes / pieces, pieces zero-padded to 2 digits), never merging across shades.
    boxesPiecesNotation(quantity) {
        const pcsPerBox = this.product?.piecesPerBox || 0;
        const boxes  = pcsPerBox > 0 ? Math.floor(quantity / pcsPerBox) : 0;
        const pieces = pcsPerBox > 0 ? quantity % pcsPerBox : quantity;
        return `${this.fmt(boxes)}/${String(pieces).padStart(2, '0')}`;
    }

    // Pieces -> "123.45 m²" (or sq ft), locale-aware.
    surfaceDisplay(pieces) {
        const pcsPerBox = this.product?.piecesPerBox || 0;
        const m2 = pcsPerBox > 0 ? (pieces * (this.product?.m2PerBox || 0) / pcsPerBox) : 0;
        return this.formatSurface(m2);
    }

    get surfacePerBox() {
        return this.formatSurface(this.product?.m2PerBox || 0);
    }

    formatSurface(m2) {
        const isImperial = this.unitSystem === 'imp';
        const value = isImperial ? m2 * SQFT_PER_M2 : m2;
        const label = isImperial ? 'sq ft' : 'm²';
        const formatted = new Intl.NumberFormat(this.locale, { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(value);
        return `${formatted} ${label}`;
    }

    fmt(n) {
        return new Intl.NumberFormat(this.locale).format(n);
    }
}