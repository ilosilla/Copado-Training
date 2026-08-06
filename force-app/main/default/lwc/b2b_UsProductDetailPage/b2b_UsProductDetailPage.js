import { LightningElement, api,wire } from 'lwc';
import {  getAppContext } from 'commerce/contextApi';
import { capitalizeWords } from 'c/textCommons';

import { getUnitLabels } from 'c/unitCommons';
import { buildSpecList } from './productSpecs';
import readPDPData from '@salesforce/apex/B2B_ServicesController.readPDPData';
import addNewItem from '@salesforce/apex/B2B_ServicesController.addItemToCart';
//import { publish, MessageContext } from 'lightning/messageService';
//import PDP_DATA_CHANNEL from '@salesforce/messageChannel/B2B_PDPDataChannel__c';
import { CartSummaryAdapter, refreshCartSummary } from "commerce/cartApi";
import Logger from 'c/libLogger';


// ========== CONSTANTS ==========

const SQFT_PER_M2 = 10.7639;
const LB_PER_KG = 2.20462;

// Shared between setStockInfo (text) and setStockFigures (numbers) — same states, same icons
const STOCK_ICON = {
    ERROR: 'utility:close',
    SUCCESS: 'utility:success',
    WARNING: 'utility:info',
    IN_TRANSIT: 'utility:clock',
    OUT_OF_STOCK: 'utility:stop'
};
const STOCK_VARIANT = {
    ERROR: 'error',
    SUCCESS: 'success',
    WARNING: 'warning',
    INFO: 'info'
};
const STOCK_CONTACT_MESSAGE = 'Please contact your sales representative';

export default class B2b_UsProductDetailPage extends LightningElement {
    
    // ========== PUBLIC API ==========

    @api productId;
    @api productCode;
    @api productName;    
    @api 
      get pricebookEntryId() {
        return this._pricebookEntryId;
      }
      set pricebookEntryId(value) {      
        console.log("EL pricebook que me entra en la API es " + value);  
        this._pricebookEntryId = value;
        if (this._pricebookEntryId === null) {
            this.priceWarningRef = "100-NID";
        } 
      }
    @api
        get quantity() {
            return this.selectedUnits;
        };
        set quantity(value) {
            this.selectedUnits = value;
        }
    
    // ========== PRIVATE STATE ==========
    logger = new Logger('b2b_UsProductDetailPage');
    _pricebookEntryId;
    sessionContext;
    cartSummary = {};  
    selectedUnits = 0
    selectedFeet = 0
    pricebookEntry;
    productData;
    pimData;
    palletSurcharge = 0;
    productSpecs = [];
    priceWarningRef = null;
    inputErrorMessage;
    stockInfo;
    stockData;
    stockByLote = [];
    ui_showShadeStockModal = false;
    relatedCodes = null;
    isLoading = true;
    dataReady = false;
    isAddingToCart = false;
    selectedPallets = 0;
    selectedBoxes = 0;
    selectedShade = '';
    ui_showCalculator = false;

    // Unit labels
    listUnitCode;
    listUnitName;
    listUnitAbbr;
    salesUnitCode;
    salesUnitName;    
    salesUnitAbbr;
    salesUnitPlural;
    unitSystem = 'imp';

    toastMessage = '';
    toastVariant = 'success';
    showToastMessage = false;

    // ========== WIRED DATA ==========
    //@wire(MessageContext) messageContext;
    
    @wire(CartSummaryAdapter)
        setCartSummary({ data, error }) {
            if (data) {
                this.cartSummary = data;
            } else if (error) {
                this.logger.error('Error loading cart summary', error);
            }
        }
    @wire(readPDPData, {
            productId: "$productId",
            pricebookEntryId: "$_pricebookEntryId",
            accountId: "$sessionContext.effectiveAccountId"
        })
        setData({error, data}) {
            if (error) {
                let msg = error.body?.message ?? 'ERR_101';
                if (!msg.startsWith('ERR_')) {
                    msg = 'APEX_EXC';
                }
                this.priceWarningRef = msg;
                this.isLoading = false;
                this.logger.error('Error received in apex method readPDPData', error);
            }
            if (data) {
                this.pricebookEntry = data.price;
                this.pimData = data.pimData;                
                this.productData = {...data.product};
                const hasStock = ((data.stock?.stockAvailable > 0) ?? false);
                const hasStockError = (data.stock?.stockError != null);
                this.logger.debug('Stock data received', data.stock, { json: true });
                this.stockByLote = data.stock?.byLote ?? [];
                this.stockData = data.stock;
                if (this.sessionContext?.market?.stockAsQuantity) {
                    this.setStockFigures(data.stock);
                } else {
                    this.setStockInfo(data.stock);
                }
                this.palletSurcharge = data.palletSurcharge ?? 0;
                this.listUnitCode = this.pricebookEntry.SAPPriceUnit__c;
                this.salesUnitCode = this.pricebookEntry.Uprice__c;
                this.listUnitName = (this.setUnitName(this.pricebookEntry.SAPPriceUnit__c) ?? this.pricebookEntry.SAPPriceUnit__c_DisplayValue);    
                this.salesUnitName = (this.setUnitName(this.pricebookEntry.Uprice__c) ?? this.pricebookEntry.Uprice__c_DisplayValue);                 
                this.listUnitAbbr = this.setUnitAbbreviation(this.pricebookEntry.SAPPriceUnit__c);
                this.salesUnitAbbr = this.setUnitAbbreviation(this.pricebookEntry.Uprice__c);
                this.salesUnitPlural = this.setUnitPlural(this.pricebookEntry.Uprice__c);
                this.productData.PesoUMV__c = (this.productData?.PesoUMV__c > 0 ? this.productData?.PesoUMV__c : this.productData?.UnitWeight__c);
                this.priceWarningRef = null;
                this.productSpecs = buildSpecList(this.productData, this.pimData, this.salesUnitCode, this.salesUnitAbbr, this.unitSystem, this.locale);
                this.buildRelatedSource();
                this.isLoading = false;
                this.dataReady = true;
                if (data.stock?.stockError) {
                    this.logger.error('Stock error', data.stock.stockError);
                }

                this.logger.debug('Recargo de despaletizado', this.palletSurcharge);
            }
        }

    /* ========================================================== *
     *  MAIN CONDITIONAL UI TEMPLATE FLAGS                        *
     *  ========================================================= */

    // It's factory direct custoemr
    get isDirectCustomer() {
        return this.sessionContext?.market?.isDirectCustomer ?? false;
    }

    // It's a tile
    get isTile() {
        return this.productData?.IsTile__c ?? false;
    }

    // It's a direct customer and the product is a tile
    get isDirectTile() {
        return this.isDirectCustomer && this.isTile;
    }

    // Shade enabled
    get shadeEnabled() {
        return this.sessionContext?.market?.shadeEnabled ?? false;
    }

    // Shade only applies to tiles (and only if the market enables it)
    get showShade() {
        return this.shadeEnabled && this.isTile;
    }

    // Link to the shade stock breakdown modal: only when shade applies and there's something to show
    get hasShadeStockBreakdown() {
        return this.showShade && this.stockByLote?.length > 0;
    }

    openShadeStockModal(event) {
        event.preventDefault();
        this.ui_showShadeStockModal = true;
    }

    closeShadeStockModal() {
        this.ui_showShadeStockModal = false;
    }

    // Product data shaped for the reusable stock-by-shade modal (clean keys, no SF field names)
    get shadeProduct() {
        return {
            name:           this.productName,
            sku:            this.productCode,
            piecesPerBox:   this.productData?.PcsXBox__c,
            boxesPerPallet: this.productData?.BoxXPal__c,
            m2PerBox:       this.productData?.M2XBox__c,
            isTile:         this.productData?.IsTile__c,
            isSpecialTile:  this.productData?.IsSpecialTile__c
        };
    }

    // Product has surcharge if less than a pallet is ordered
    get hasPalletSurcharge() {
        return this.palletSurcharge > 0;
    }

    // Static banner above the quantity selection — the product carries a surcharge
    get showPalletSurchargeNotice() {
        return this.isDirectCustomer && this.hasPalletSurcharge;
    }

    // Dynamic warning in the summary — the current selection actually triggers the surcharge
    get showPalletSurchargeWarning() {
        if (!this.showPalletSurchargeNotice) return false;
        const boxPerPal = this.productData?.BoxXPal__c ?? 0;
        const totalBoxes = (Number(this.selectedPallets) || 0) * boxPerPal + (Number(this.selectedBoxes) || 0);
        if (boxPerPal <= 0) return (Number(this.selectedBoxes) || 0) > 0;
        // Surcharge applies only when the whole order is below a full pallet.
        return totalBoxes > 0 && totalBoxes < boxPerPal;
    }

    get palletSurchargeWarningText() {
        const boxPerPal = this.productData?.BoxXPal__c ?? 0;
        const totalBoxes = (Number(this.selectedPallets) || 0) * boxPerPal + (Number(this.selectedBoxes) || 0);
        const remainder = boxPerPal > 0 ? totalBoxes % boxPerPal : totalBoxes;
        const boxWord = remainder === 1 ? 'box' : 'boxes';
        const verb = remainder === 1 ? "doesn't" : "don't";
        return `${remainder} ${boxWord} ${verb} complete a full pallet (${boxPerPal} boxes) — ${this.palletSurcharge}% surcharge applies at checkout.`;
    }

    // The grey block shows a thin divider + dynamic notes when any dynamic message applies.
    get showDynamicNotes() {
        return this.showPalletSurchargeWarning || this.showStockShortfallWarning;
    }

    // Selected quantity expressed in the stock unit (pieces for tiles sold by box),
    // so it can be compared against available stock, which is always in pieces/units.
    get selectedQuantityInStockUnit() {
        const qty = Number(this.selectedUnits) || 0;
        if (!this.isTile || this.isSoldByPiece) {
            return qty;
        }
        return qty * (this.productData?.PcsXBox__c ?? 0);
    }

    // Warnings only make sense with real stock figures and something available.
    get hasRealStockFigures() {
        return (this.sessionContext?.market?.stockAsQuantity ?? false)
            && this.stockData != null
            && this.stockData.stockAvailable > 0;
    }

    // M1: the order is larger than the total stock available.
    get showStockExceedsWarning() {
        const qty = this.selectedQuantityInStockUnit;
        return this.hasRealStockFigures && qty > 0 && qty > this.stockData.stockAvailable;
    }

    // M2: total stock covers the order, but the selected shade does not.
    get showShadeShortfallWarning() {
        if (!this.hasRealStockFigures || this.showStockExceedsWarning) {
            return false;
        }
        const shadeQty = this.shadeFilteredQuantity();
        if (shadeQty === null) {
            return false;
        }
        const qty = this.selectedQuantityInStockUnit;
        return qty > 0 && shadeQty < qty;
    }

    // Single slot — M1 and M2 are mutually exclusive.
    get showStockShortfallWarning() {
        return this.showStockExceedsWarning || this.showShadeShortfallWarning;
    }

    get stockShortfallMessage() {
        return this.showStockExceedsWarning
            ? 'Selected quantity exceeds available stock and may affect delivery times.'
            : 'Requested shade is low on stock; part of your order may ship in the closest match.';
    }

    // Filial (non-direct) customer and the product is a tile
    get isFilialCeramics() {
        return !this.isDirectCustomer && this.isTile;
    }

    // Show the surface calculator button (only for tiles)
    get showCalculatorButton() {
        return this.isTile;
    }

    // Product sold by piece (PZS) instead of by box
    get isSoldByPiece() {
        return this.salesUnitCode === 'PZS';
    }

    // "~10% extra for cuts and waste" note — only for filial ceramics
    get showCutWasteNote() {
        return this.isFilialCeramics;
    }





    /* ========================================================= *
     * OTHER GETTERS                                             *
     * ========================================================= */

    // User locale (BCP-47, already normalized in libStoreContextProvider) for number formatting
    get locale() {
        return this.sessionContext?.userLocale ?? 'en-US';
    }

    get showSpinner() {
        return this.isLoading || this.isAddingToCart;
    }

    get toastVariantClass() {
        return this.toastVariant === 'error'
            ? 'pdp-toast-content pdp-toast-error'
            : 'pdp-toast-content pdp-toast-success';
    }
    
    // --> Options and data
    get unitSystemOptions() {
        return [
            { label: 'Imp', value: 'imp' },
            { label: 'Int', value: 'int' },
        ];
    }

    get specifications() {
        return this.productSpecs;
    }

    get propertyFlags() {
        const flags = [];        
        if (this.pimData) {
            this.setPropertyFlag(flags, "Brand__c_DisplayValue", false);
            if (this.pimData.Type__c === '1') {
                this.setPropertyFlag(flags, "ProductApplication__c", true);
                this.setBoolPropertyFlag(flags, "Rectified__c", "Rectified");
                this.setBoolPropertyFlag(flags, "Antislip__c", "Anti-slip");
            } else {
                this.setPropertyFlag(flags, "Type__c_DisplayValue", true);
                this.setPropertyFlag(flags, "ProductApplication__c", true);
            }
            this.setPropertyFlag(flags, "Effect__c_DisplayValue", true);
            this.setPropertyFlag(flags, "Finish2__c_DisplayValue", true);
        }
        return flags.map((f, index) => ({
            ...f,
            isNotLast: index < flags.length - 1
        }));
    }

    // --> Price related properties
    get isPriceAvailable() {
        return (this.priceWarningRef === null || this.priceWarningRef?.length === 0);
    }

    // Quantity selection only once data has loaded (avoids showing it under the loading spinner)
    get showQuantitySection() {
        return this.isPriceAvailable && this.dataReady;
    }

    get mainPriceValue() {
        let text = '';
        if (this.pricebookEntry) {
            text = this.formatCurrency(this.pricebookEntry?.SAPPrice__c); // + ' / ' + this.listUnitAbbr?.toLowerCase();
        }
        return text;
    }

    get mainPriceUnit() {
        return ' / ' + this.listUnitAbbr?.toLowerCase();
    }

    get auxPriceValue() {
        let text = '';
        if (this.pricebookEntry) {
            text = this.formatCurrency(this.pricebookEntry?.UnitPrice); //+ ' / ' + this.salesUnitAbbr?.toLowerCase();
        }
        return text;
    }

    get auxPriceUnit() {
        return ' / ' + this.salesUnitAbbr?.toLowerCase();
    }

    get priceConditionLines() {
        return [
            { id: 'base', text: 'Customer net prices — shipping and taxes not included.' }
        ];
    }

    get itemTotalAmount() {
        if (this.quantityHasError) return '--';
        const units = Number(this.selectedUnits);
        const unitPrice = Number(this.pricebookEntry?.UnitPrice);
        const total = units * unitPrice;
        if (!Number.isFinite(total)) return '--';
        return this.formatCurrency(total);
    }

    get displaySecondPrice() {
        return (this.salesUnitAbbr?.toLowerCase() !== this.listUnitAbbr?.toLowerCase())
    }

    // --> Template conditional formatting

    get isAddToCartDisabled() {
        return !(this.selectedUnits > 0);
    }

    get calcProductInfo() {
        return {
            sku:            this.productCode,
            name:           this.productName,
            m2PerBox:       this.productData?.M2XBox__c   ?? 0,
            boxPerPal:      this.productData?.BoxXPal__c  ?? 0,  // assumption: same naming pattern
            pcsPerBox:      this.productData?.PcsXBox__c  ?? 0,  // assumption: same naming pattern
            useMetricSystem: this.sessionContext?.market?.useMetricSystem ?? true,
            locale:          this.locale
        };
    }

    get showOrderAddition() {
        return (this.productData?.IsTile__c ?? false);
    }

    get hasSpecifications() {
        return (this.productSpecs?.length > 0);
    }

    get displaySurfaceInput() {
        return (this.productData?.M2XBox__c > 0 ?? 0)
    }

    get quantityHasError() {
        return ((this.inputErrorMessage?.length ?? 0) > 0)
    }

    get productSoldBy() {
        return this.dataReady ? "This product is sold by the " + this.salesUnitName?.toLowerCase() : '';
    }

    get errorClass() { return this.inputErrorMessage ? 'number-error-msg show' : 'number-error-msg'; }

    // --> Weight properties

    get showOrderWeight() {
        return (this.productData?.PesoUMV__c > 0 ?? false);
    }

    get itemTotalWeight() {
        const kg = Number(this.itemTotalKg) || 0;
        const value = this.unitSystem === 'imp' ? kg * LB_PER_KG : kg;
        const label = this.unitSystem === 'imp' ? 'lb' : 'kg';
        const formatted = new Intl.NumberFormat(this.locale, {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(value);
        return `${formatted} ${label}`;
    }

    get itemTotalKg() {
        const factor = this.productData?.PesoUMV__c ?? 0;
        let weight = 0;
        if (!this.quantityHasError) {
            weight = (this.selectedUnits ?? 0) * factor;
        }
        return weight?.toFixed(2);
    }

    // --> Quantity summary & surface (tiles)

    // Surface (m²) occupied by the selected quantity
    get selectedSurfaceM2() {
        const m2PerBox = this.productData?.M2XBox__c ?? 0;
        const pcsPerBox = this.productData?.PcsXBox__c ?? 0;
        const units = Number(this.selectedUnits) || 0;
        if (this.isSoldByPiece) {
            return pcsPerBox > 0 ? (units * m2PerBox / pcsPerBox) : 0;
        }
        return units * m2PerBox;
    }

    // Surface in the unit currently selected by the user (imp -> sq ft, int -> m²)
    get selectedSurfaceDisplay() {
        const isImperial = this.unitSystem === 'imp';
        const value = isImperial ? this.selectedSurfaceM2 * SQFT_PER_M2 : this.selectedSurfaceM2;
        const label = isImperial ? 'sq ft' : 'm²';
        const formatted = new Intl.NumberFormat(this.locale, {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(value);
        return `${formatted} ${label}`;
    }

    // Breakdown of the selected quantity: "X pallets · Y boxes" or "N pieces"
    get summaryText() {
        const fmt = (n) => new Intl.NumberFormat(this.locale).format(n);
        const units = Number(this.selectedUnits) || 0;
        if (this.isSoldByPiece) {
            return `${fmt(units)} ${units === 1 ? 'piece' : 'pieces'}`;
        }
        const boxPerPal = this.productData?.BoxXPal__c ?? 0;
        const pallets = boxPerPal > 0 ? Math.floor(units / boxPerPal) : 0;
        const boxes = boxPerPal > 0 ? units % boxPerPal : units;
        const parts = [];
        if (pallets > 0) parts.push(`${fmt(pallets)} ${pallets === 1 ? 'pallet' : 'pallets'}`);
        parts.push(`${fmt(boxes)} ${boxes === 1 ? 'box' : 'boxes'}`);
        return parts.join(' · ');
    }


    // --> Stock related properties

    get stockReady() {
        return (this.stockInfo?.message !== null) ?? false;
    }

    get stockIcon() { 
        return this.stockInfo?.iconName ?? '';
    }

    get stockVariant() { 
        return this.stockInfo?.variant ?? '';
    }

    get stockText() { 
        return this.stockInfo?.message ?? '';
    }

    get stockSubText() {
        return this.stockInfo?.subMessage ?? '';
    }

    get stockLabel() {
        return this.stockInfo?.label ?? '';
    }


    get stockClass() {
        return `pdp-stock-main ${this.stockInfo?.variant ?? ''}`;
    }

    get productFinderUrl() {
        return this.pimData?.URL__c;
    }

    get hasRelated() {
        return this.dataReady;
    }

    // ========== EVENT HANDLERS ==========

    handleContextReceived(event) {
        this.sessionContext = event.detail;
        // Default measurement system follows the market context.
        this.unitSystem = (this.sessionContext?.market?.useMetricSystem ?? true) ? 'int' : 'imp';
        // Context may arrive after the wire — rebuild specs with the right unit system and locale.
        if (this.productData) {
            this.productSpecs = buildSpecList(this.productData, this.pimData, this.salesUnitCode, this.salesUnitAbbr, this.unitSystem, this.locale);
        }
    }

    // Context failed to load — readPDPData's wire is gated on sessionContext and will
    // never fire on its own, so without this the PDP would spin forever.
    handleContextError(event) {
        this.logger.error('Error loading B2B context', event.detail?.message);
        this.priceWarningRef = 'ERR_CONTEXT';
        this.isLoading = false;
    }

    handleOpenCalculator() {
        this.ui_showCalculator = true;
    }

    handleCalculatorClose() {
        this.ui_showCalculator = false;
    }

    handleCalculatorConfirm(event) {
        this.selectedPallets = event.detail.pallets;
        this.selectedBoxes   = event.detail.boxes;
        this.syncSelectedUnitsFromPalletsBoxes();
        this.ui_showCalculator = false;
    }

    async handleAddToCart() {
        try {
            this.isAddingToCart = true;
            this.logger.highlight('Add to cart from PDP');
            this.logger.info('Add to cart details', { productId: this.productId, quantity: this.selectedUnits }, { json: true });
            // const session = await getSessionContext();
            const app = await getAppContext();

            //const result = await addItemToCart(this.productId, this.selectedUnits );
            const itemDTO = {
                webStoreId: app.webstoreId,
                cartId: this.cartSummary.cartId,               // puede ir null
                productId: this.productId,
                pricebookEntryId: null,
                quantity: this.selectedUnits,
                salesUnit: this.salesUnitCode,
                listPriceUnit: this.listUnitCode,
                weightPerUnitKg: this.productData.PesoUMV__c,
                lineWeightKg: this.itemTotalKg
            };
            const result = await addNewItem({itemDTO: itemDTO});
            this.refreshCartData();
            this.selectedUnits = 0;
            this.selectedFeet = 0;
            this.showToast(
                `${this.productName} was added to your cart.`,
                'success'
            );
        } catch (error) {
            this.logger.error('Error adding to cart', error);
            this.showToast(
                'The product could not be added to the cart.',
                'error'
            );
        } finally {
            this.isAddingToCart = false;
        }
    }

    handleUnitSystemChange(event) {
        this.unitSystem = event.detail.value;
        this.productSpecs.forEach(spec => {
            spec.displayValue = this.unitSystem === 'imp' ? spec.impValue : spec.intValue;
        });
    }

    handleChangeUnits(customEvent) {
        this.inputErrorMessage = '';
        this.selectedUnits = (customEvent.detail?.value ?? 0);
        this.convertSelectedBoxesToFeet()
    }

    handleUnitsError(customEvent) {
        const detail = customEvent.detail;
        this.inputErrorMessage = detail?.message;
        this.selectedFeet = 0;
    }        

    handleChangeFeet(customEvent) {
        this.inputErrorMessage = '';
        this.selectedFeet = (customEvent.detail?.value ?? 0);
        this.convertSelectedFeetToBoxes()
    }

    handleFeetError(customEvent) {
        const detail = customEvent.detail;
        this.inputErrorMessage = detail?.message;
        this.selectedUnits = 0;
    }

    // Event handlers for pallets/boxes fields
    handleChangePallets(customEvent) {
        this.inputErrorMessage = '';
        this.selectedPallets = (customEvent.detail?.value ?? 0);
        this.syncSelectedUnitsFromPalletsBoxes();
    }

    handleChangeBoxes(customEvent) {
        this.inputErrorMessage = '';
        this.selectedBoxes = (customEvent.detail?.value ?? 0);
        this.syncSelectedUnitsFromPalletsBoxes();
    }

    handlePalletsError(customEvent) {
        const detail = customEvent.detail;
        this.inputErrorMessage = detail?.message;
    }

    handleBoxesError(customEvent) {
        const detail = customEvent.detail;
        this.inputErrorMessage = detail?.message;
    }

    // Fires on blur/enter (not per keystroke) so the shade is evaluated only when complete.
    handleChangeShade(customEvent) {
        this.selectedShade = (customEvent.target?.value ?? '').trim().toUpperCase();
        if (this.stockData && this.sessionContext?.market?.stockAsQuantity) {
            this.setStockFigures(this.stockData);
        }
    }

    // selectedUnits is the single source of truth for the cart.
    // In direct (pallets/boxes) mode it is derived here.
    syncSelectedUnitsFromPalletsBoxes() {
        const boxPerPal = this.productData?.BoxXPal__c ?? 0;
        const pcsPerBox = this.productData?.PcsXBox__c ?? 0;
        const totalBoxes = (Number(this.selectedPallets) || 0) * boxPerPal + (Number(this.selectedBoxes) || 0);
        this.selectedUnits = this.isSoldByPiece ? totalBoxes * pcsPerBox : totalBoxes;
    }


    /* ============ UTILITY METHODS ============== */


    async refreshCartData() {
        try {
            // Esto disparará el evento que actualiza todos los componentes de Commerce            
              this.dispatchEvent(new CustomEvent("cartchanged", {
                    bubbles: true,
                    composed: true
                }));
            await refreshCartSummary();
        } catch (error) {
            this.logger.error('Error refreshing cart', error);
        }
    }

    setPropertyFlag(flags, propertyName, capitalize) {
        const result = this.pimData[propertyName];        
        if (result) {
            const p = {}
            p.id = propertyName;
            p.value = result;
            if (capitalize) {                
                p.value = capitalizeWords(p.value, { lowerRest: true });                
            }
            flags.push(p);
        }
    }

    setBoolPropertyFlag(flags, propertyName, value) {
        const result = this.pimData[propertyName];        
        if (result) {
            const p = {}
            p.id = propertyName;
            p.value = value;
            flags.push(p);
        }
    }

    formatCurrency(amount) {
        let result = amount;
        if (this.pricebookEntry) {
            const formatter = new Intl.NumberFormat(this.locale, {
                style: 'currency',
                currency: this.pricebookEntry?.CurrencyIsoCode});
            result = formatter.format(amount);
        }
        return result;
    }


    setUnitName(unitCode) {
        const unitLabels = getUnitLabels(unitCode, 'en');
        return unitLabels?.singular;       
    }

    setUnitAbbreviation(unitCode) {
        const unitLabels = getUnitLabels(unitCode, 'en');        
        return (unitLabels?.abbr ?? unitCode);
    }

    setUnitPlural(unitCode) {
        const unitLabels = getUnitLabels(unitCode, 'en');        
        return (unitLabels?.plural ?? unitCode);
    }



    convertSelectedBoxesToFeet() {
        const factor = this.productData?.M2XBox__c;
        this.selectedFeet = this.round(this.selectedUnits * factor * SQFT_PER_M2, 0);
    }

    convertSelectedFeetToBoxes() {
        const factor = this.productData?.M2XBox__c;
        const metres = this.selectedFeet / SQFT_PER_M2;
        this.selectedUnits = Math.ceil(metres / factor);
    }

    round(value, decimals = 2) {
        return Number(Math.round(value + 'e' + decimals) + 'e-' + decimals);
    }

    setStockInfo(stock) {

        this.stockInfo = {};

        const hasError     = !!stock.stockError;
        const hasStock     = stock.stockAvailable > 0;
        const lowStock     = stock.lowStock === true;
        const hasInTransit = stock.stockInTransit > 0;

        // Error técnico
        if (hasError) {
            this.stockInfo.iconName = STOCK_ICON.ERROR;
            this.stockInfo.variant = STOCK_VARIANT.ERROR;
            this.stockInfo.message = "Stock information temporarily unavailable";
            this.stockInfo.subMessage = STOCK_CONTACT_MESSAGE;
            return;
        }

        // Stock disponible
        if (hasStock) {
            this.stockInfo.iconName = lowStock ? STOCK_ICON.WARNING : STOCK_ICON.SUCCESS;
            this.stockInfo.variant  = lowStock ? STOCK_VARIANT.WARNING : STOCK_VARIANT.SUCCESS;
            this.stockInfo.message  = lowStock
                ? "Limited stock available"
                : "Available - ready to ship";
            this.stockInfo.subMessage = '';
            return;
        }

        // No hay stock, PERO hay in-transit → backorder real
        if (hasInTransit) {
            this.stockInfo.iconName = STOCK_ICON.IN_TRANSIT;
            this.stockInfo.variant  = STOCK_VARIANT.INFO;
            this.stockInfo.message  = "Available for backorder";
            this.stockInfo.subMessage = this.getInTransitMessage(stock.firstInTransitDate);
            return;
        }

        // No hay stock ni in-transit → caso excepcional
        this.stockInfo.iconName = STOCK_ICON.OUT_OF_STOCK;
        this.stockInfo.variant  = STOCK_VARIANT.ERROR;
        this.stockInfo.message  = "Out of stock";
        this.stockInfo.subMessage = STOCK_CONTACT_MESSAGE;
    }

    // Stock quantity for the currently typed shade.
    // Returns null when no shade filter applies, 0 when the shade has no stock
    // (or isn't among the available lotes), or the shade's available pieces.
    shadeFilteredQuantity() {
        if (!this.showShade) {
            return null;
        }
        const shade = (this.selectedShade ?? '').trim().toUpperCase();
        if (!shade) {
            return null;
        }
        const match = (this.stockByLote ?? []).find(
            (row) => (row.lote ?? '').toUpperCase() === shade
        );
        return match ? (match.stockAvailable ?? 0) : 0;
    }

    // Eyebrow for the available-stock case. Reflects the shade filter when shade applies.
    stockAvailableLabel(shade) {
        if (!this.showShade) {
            return 'Stock Available';
        }
        return shade ? `Stock Available in ${shade}` : 'Total Stock Available';
    }

    setStockFigures(stock) {

        this.stockInfo = {};

        const hasError     = !!stock.stockError;
        const hasStock     = stock.stockAvailable > 0;
        const hasInTransit = stock.stockInTransit > 0;

        // Error técnico — mismo texto genérico que el modo texto
        if (hasError) {
            this.stockInfo.iconName = STOCK_ICON.ERROR;
            this.stockInfo.variant = STOCK_VARIANT.ERROR;
            this.stockInfo.message = "Stock information temporarily unavailable";
            this.stockInfo.subMessage = STOCK_CONTACT_MESSAGE;
            return;
        }

        // Stock disponible — cifras reales
        if (hasStock) {
            const shadeQty = this.shadeFilteredQuantity();
            const shade = (this.selectedShade ?? '').trim().toUpperCase();

            // Shade selected but not available in that shade (there is stock in others)
            if (shadeQty === 0) {
                this.stockInfo.iconName = STOCK_ICON.WARNING;
                this.stockInfo.variant  = STOCK_VARIANT.INFO;
                this.stockInfo.label    = `Stock Unavailable in ${shade}`;
                this.stockInfo.message  = 'Stock available in other shades';
                this.stockInfo.subMessage = '';
                return;
            }

            // No shade filter -> total; shade with stock -> that shade only
            const quantity = shadeQty === null ? stock.stockAvailable : shadeQty;
            this.stockInfo.iconName = STOCK_ICON.SUCCESS;
            this.stockInfo.variant  = STOCK_VARIANT.SUCCESS;
            this.stockInfo.label    = this.stockAvailableLabel(shade);
            this.stockInfo.message  = this.formatStockFigures(quantity);
            this.stockInfo.subMessage = '';
            return;
        }

        // No hay stock, pero sí en tránsito — cifra simple, no desglose
        if (hasInTransit) {
            this.stockInfo.iconName = STOCK_ICON.IN_TRANSIT;
            this.stockInfo.variant  = STOCK_VARIANT.INFO;
            this.stockInfo.message  = this.formatAvailableSoon(stock.stockInTransit);
            this.stockInfo.subMessage = this.getInTransitMessage(stock.firstInTransitDate);
            return;
        }

        // No hay stock ni en tránsito — mismo texto genérico, nunca "0 piezas"
        this.stockInfo.iconName = STOCK_ICON.OUT_OF_STOCK;
        this.stockInfo.variant  = STOCK_VARIANT.ERROR;
        this.stockInfo.message  = "Out of stock";
        this.stockInfo.subMessage = STOCK_CONTACT_MESSAGE;
    }

    formatStockFigures(quantity) {
        const fmt = (n) => new Intl.NumberFormat(this.locale).format(n);

        // Non-tile → sales unit
        if (!this.isTile) {
            return `Units: ${fmt(quantity)} ${this.salesUnitAbbr}`;
        }

        // Special tile → sold by piece, no box/pallet breakdown
        if (this.productData?.IsSpecialTile__c) {
            return `Pieces: ${fmt(quantity)}`;
        }

        // Standard tile → boxes/pieces notation (as in the stock query) + surface
        const pcsPerBox = this.productData?.PcsXBox__c ?? 0;
        const boxes  = pcsPerBox > 0 ? Math.floor(quantity / pcsPerBox) : 0;
        const pieces = pcsPerBox > 0 ? quantity % pcsPerBox : quantity;

        return `Boxes/Pieces: ${fmt(boxes)}/${String(pieces).padStart(2, '0')} (${this.surfaceDisplayFor(quantity)})`;
    }

    formatAvailableSoon(quantity) {
        const fmt = (n) => new Intl.NumberFormat(this.locale).format(n);

        if (!this.isTile) {
            return `${fmt(quantity)} ${this.salesUnitAbbr} available soon`;
        }
        return `${this.surfaceDisplayFor(quantity)} available soon`;
    }

    // m² o sq ft según unitSystem, a partir de una cantidad en piezas — misma fórmula que selectedSurfaceDisplay
    surfaceDisplayFor(pieces) {
        const m2PerBox = this.productData?.M2XBox__c ?? 0;
        const pcsPerBox = this.productData?.PcsXBox__c ?? 0;
        const m2 = pcsPerBox > 0 ? (pieces * m2PerBox / pcsPerBox) : 0;
        const isImperial = this.unitSystem === 'imp';
        const value = isImperial ? m2 * SQFT_PER_M2 : m2;
        const label = isImperial ? 'sq ft' : 'm²';
        const formatted = new Intl.NumberFormat(this.locale, { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(value);
        return `${formatted} ${label}`;
    }

    buildRelatedSource() {
        if (!this.pimData) {
            return null;
        }

        const parse = (v) => {
            try {
                return JSON.parse(v ?? '[]');
            } catch {

                return [];
            }
        };

        this.relatedCodes = {
            specialPieces: parse(this.pimData.SpecialPieces__c),
            adhesives: parse(this.pimData.Adhesives__c),
            adhesivesWetAreas: parse(this.pimData.AdhesivesWetAreas__c),
            jointMaterials: parse(this.pimData.JointMaterials__c),
            jointMaterialsWetAreas: parse(this.pimData.JointMaterialWetAreas__c)
        };
    }

    showToast(message, variant = 'success') {
        this.toastMessage = message;
        this.toastVariant = variant;
        this.showToastMessage = true;

        setTimeout(() => {
            this.showToastMessage = false;
        }, 9000);
        
    }

    getInTransitMessage(firstInTransitDate) {
        if (!firstInTransitDate) {
            return "More stock expected soon";
        }

        const today = new Date();
        today.setHours(0, 0, 0, 0);

        // Parse fecha Apex (YYYY-MM-DD)
        let adjustedDate = this.parseApexDate(firstInTransitDate);        

        // +2 días
        adjustedDate.setDate(adjustedDate.getDate() + 2);
        adjustedDate.setHours(0, 0, 0, 0);

        // Fin de semana → lunes siguiente
        const day = adjustedDate.getDay();
        if (day === 6) {          // sábado
            adjustedDate.setDate(adjustedDate.getDate() + 2);
        } else if (day === 0) {   // domingo
            adjustedDate.setDate(adjustedDate.getDate() + 1);
        }

        const thisWeekStart = this.startOfWeek(today);
        const targetWeekStart = this.startOfWeek(adjustedDate);

        const msPerWeek = 7 * 24 * 60 * 60 * 1000;
        const weekDiff =
            Math.round((targetWeekStart - thisWeekStart) / msPerWeek);

        if (weekDiff <= 0) {
            return "More stock expected this week";
        } else if (weekDiff === 1) {
            return "More stock expected next week";
        } else if (weekDiff === 2) {
            return "More stock expected in two weeks";
        } else {
            return `More stock expected in ${weekDiff} weeks`;
        }
    }

    startOfWeek(date) {
        const d = new Date(date);
        const day = d.getDay(); // 0=Sun, 1=Mon...
        const diff = day === 0 ? -6 : 1 - day; // lunes
        d.setDate(d.getDate() + diff);
        d.setHours(0, 0, 0, 0);
        return d;
    }

    parseApexDate(dateStr) {
        if (!dateStr) {
            return null;
        }

        const [year, month, day] = dateStr.split('-').map(Number);
        return new Date(year, month - 1, day);
}

}