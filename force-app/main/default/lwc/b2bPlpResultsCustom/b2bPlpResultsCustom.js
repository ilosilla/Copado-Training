import { LightningElement, api } from 'lwc';
import {  getSessionContext } from 'commerce/contextApi';
import loadPLPData from '@salesforce/apex/B2B_PLPController.loadPLPData';
import getPLPContext from '@salesforce/apex/B2B_PLPController.getPLPContext';
import { formatPricePerUnit } from 'c/libUnitLabels';
import communityBasePath from '@salesforce/community/basePath';

const PLP_STOCK_CLASS = 'plp-stock';

const STOCK_UI_MAP = {
    IN_STOCK: {
        class: 'success',
        label: 'In Stock'
    },
    LOW: {
        class: 'warning',
        label: 'Last Units'
    },
    SOON: {
        class: 'error',
        label: 'Available Soon'
    },
    OUT: {
        class: 'error',
        label: 'Unavailable'
    }
};

export default class B2bPlpResultsCustom extends LightningElement {

    /* ===================================================
     * API PROPERTIES
     * =================================================== */
    @api
        get results() {
            return this._results;
        }
        set results(value) {
            this._results = value;
            if (!this.isStableResult(value)) {
                return; // ignorar fases intermedias
            }
            this.processFinalResults(value);
        }
        
    @api 
        get loading() {
            return this._loading;
        }
        set loading(value) {
            this._loading = value;
            console.log('PLP loading:', value);
        }

    /* ===================================================
     * INTERNAL STATE
     * =================================================== */
    
    // internal backing fields for API properties
    _results;
    _loading = false;

    // main state variables
    st_buyerGroupId = null;
    st_currencyCode = null;
    st_context = null;    
    st_items = [];

    // main ui valriables
    ui_isLoading = false;

    // Other internal variables
    lastProcessedIds = '';

    /* ===================================================
     * TEMPLATE GETTERS
     * =================================================== */        
    get hasItems() {
        return this.st_items?.length > 0;
    }

    /* ===================================================
     * DATA METHODS
     * =================================================== */

    async readSessionContext() {
        const session = await getSessionContext();
        this.st_buyerGroupId = session?.buyerGroups?.[0]?.id;
    }

    async loadPLPData(products) {
        this.ui_isLoading = true;
        try {
            if (this.st_buyerGroupId === null) {
                await this.readSessionContext();
            }
            if (this.st_context === null) { 
                this.st_currencyCode = 'USD';
                console.log('Voy con this.st_buyerGroupId ' + this.st_buyerGroupId + ' y this.st_currencyCode ' + this.st_currencyCode);          
                this.st_context = await getPLPContext({
                    buyerGroupId: this.st_buyerGroupId,
                    currencyCode: this.st_currencyCode,
                    includePrices: true,
                    includeStock: true
                });
            }
            const prices = await loadPLPData({
                context: this.st_context,
                products: products
            });
            console.log('Los prices que me devuelve el tema son ' + JSON.stringify(prices));
            this.st_items = this.buildPlpItems(this._results, prices);
            console.log('PLP items ready', JSON.stringify(this.st_items));
        } catch (e) {
            console.error('Error loading PLP products', e);
        } finally {
            this.ui_isLoading = false;
        }
    }

    /* ===================================================
     * CORE METHODS
     * =================================================== */
    buildPlpItems(results, pricesFromApex) {
        if (!results?.cardCollection?.length) {
            return [];
        }

        // Indexar precios por productId si vienen como array
        const pricesById = Array.isArray(pricesFromApex)
            ? pricesFromApex.reduce((acc, p) => {
                acc[p.productId] = p;
                return acc;
            }, {})
            : pricesFromApex ?? {};

        return results.cardCollection.map(card => {
            const productId = card.id;
            const price = pricesById[productId];

            const imageUrl =
                card.image?.url
                || card.mediaGroups?.[0]?.mediaItems?.[0]?.url
                || '/img/b2b/default-product-image.svg';

            const displayPrice = price
                ? formatPricePerUnit({
                    amount: price.sapPrice,
                    currencyIsoCode: price.currencyIsoCode,
                    unitCode: price.sapPriceUnit,
                    locale: this.locale ?? 'en-US'
                })
                : null;

            const stockUI = price?.stockStatus   ? this.resolveStockUI(price.stockStatus)  : null;

            return {
                // Core identifiers
                productId,
                sku: card.fields?.StockKeepingUnit?.value ?? null,
                name: card.name,

                // Navigation
                pageReference: card.pageReference,
                url: this.buildProductUrl(productId),

                // Stock
                stockStatus: price?.stockStatus,
                stockClass: 'plp-stock ' + stockUI?.class,
                stockLabel: stockUI?.label,

                // Media                
                imageUrl,
                imageAlt: card.image?.alternateText ?? card.name,

                // Pricing (ready for UI)
                displayPrice,

                // Raw price data (future)
                prices: price ?? null,

                // Raw card (debug / ext)
                // _raw: card
            };
        });
    }

    /* ===================================================
     * UTILITY METHODS
     * =================================================== */
    isStableResult(results) {
        if (!results?.cardCollection?.length) return false;
        if (results.productLoadedCount !== results.cardCollection.length) return false;
        return true;
    }

    processFinalResults(results) {
        if (!results?.cardCollection?.length) {
            return;
        }

        // While we are here, we het the currency of the store
        //this.st_currencyCode = results.cardCollection[0]?.prices?.currencyIsoCode ?? 'USD';  
        //console.log('=====> La currency es ' + this.st_currencyCode );

        const products = results.cardCollection
            .map(c => ({
                productId: c.id,
                sku: c.fields?.StockKeepingUnit?.value ?? null
            }))
            .filter(p => p.sku); // seguridad
        
        const key = products
            .map(p => p.productId)
            .sort()
            .join(',');

        if (key === this.lastProcessedIds) {
            return;
        }

        this.lastProcessedIds = key;
        this.loadPLPData(products);
    }

    buildProductUrl(productId) {
         return `${communityBasePath}/product/${productId}`;
    }

    resolveStockUI(stockStatus) {
       return STOCK_UI_MAP[stockStatus] ?? null;
    }

}