/**
 * ----------------------------------------------------------------------------------------------------------
 *  COMPONENT NAME: b2b_usCartSummary
 *  DESCRIPTION:
 *      Custom Cart Summary component for B2B Checkout (USA).
 *      Displays order totals, optional credit information and primary CTA,
 *      and an optional read-only list of cart items.
 *
 *      Totals are derived from Checkout.Details.
 *      Cart lines are loaded via CartItemsAdapter.
 *
 *  AUTHOR: Ramon
 *  CREATED: 2025-01
 *
 *  NOTES:
 *      - Checkout.Details is the single source of truth for totals.
 *      - CartItemsAdapter is used exclusively for cart line display.
 *      - Fully reactive to Checkout changes (shipping, address, etc.).
 * ---------------------------------------------------------------------------------------------------------- */

import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { CartItemsAdapter } from 'commerce/cartApi';
import { formatQuantityWithUnit } from 'c/libUnitLabels';
import Logger from 'c/libLogger';

/* =========================================================
 * 1. CONSTANTS
 *    - Static values
 *    - Enums
 *    - Labels, magic strings, configuration
 * ========================================================= */

const CDG_FIELDS = [
    'CartDeliveryGroup.ShippingCost__c',
    'CartDeliveryGroup.ShippingPending__c'
];

export default class B2b_UsCartSummary extends LightningElement {

    /* =========================================================
     * 2. PUBLIC API (@api)
     *    - Properties exposed to parent components
     *    - Public setters/getters
     * ========================================================= */
    
    @api showSummary;
    @api allowPlaceOrder;
    @api showDetail;

    @api
        set checkoutDetails(value) {
            this._checkoutDetails = value;
            this.logger.debug('checkoutDetails updated', value, { json: true });
        }
        get checkoutDetails() {
            return this._checkoutDetails;
        }

    /* =========================================================
     * 3. STATE
     *    - Functional state (st_*)
     *    - UI state (ui_*)
     *    - Internal flags, cache, deduplication
     * ========================================================= */    
    _checkoutDetails;
    _cdgRecord = null;
    cartItems = [];
    cartItemsError;    
    logger = new Logger('B2B_USCartSummary');
    
    /* =========================================================
     * 4. GETTERS (JS convenience)
     *    - Derived values used by JS logic
     *    - Read-only helpers based on state
     * ========================================================= */

    get cartSummary() {
        return this.checkoutDetails?.cartSummary;
    }

    get cdgId() {
        return this._checkoutDetails?.deliveryGroups?.items?.[0]?.id ?? null;
    }

    get subtotal() {
        return this.cartSummary?.totalProductAmount;
    }

    /*get shipping() {
        return this.cartSummary?.totalChargeAmount;
    }*/

    get shipping() {
        return getFieldValue(this._cdgRecord, 'CartDeliveryGroup.ShippingCost__c') ?? 0;
    }

    get shippingPending() {
        return getFieldValue(this._cdgRecord, 'CartDeliveryGroup.ShippingPending__c') ?? true;
    }    

    get tax() {
        return this.cartSummary?.totalTaxAmount;
    }

    get total() {
        //return this.cartSummary?.grandTotalAmount;
       return Number(this.subtotal ?? 0) + Number(this.shipping ?? 0) + Number(this.tax ?? 0);
    }

    get placeOrderState() {
        const missing = [];

        if (!this.hasShipping) {
            missing.push('shipping');
        }

        if (!this.hasReference) {
            missing.push('reference');
        }

        if (this.requiresDeliveryDate && !this.hasDeliveryDate) {
            missing.push('date');
        }

        return {
            canPlace: missing.length === 0,
            missing
        };
    }
    get canPlaceOrder() {
        return this.placeOrderState.canPlace;
    }

    get hasShipping() {
        return this.shipping !== null && this.shipping !== undefined;
    }

    get hasReference() {
        return !!this.checkoutDetails?.purchaseOrderNumber?.trim();
    }

    get hasDeliveryDate() {
        if (!this.requiresDeliveryDate) {
            return true;
        }
        return !!this.checkoutDetails?.deliveryGroups?.items?.[0]?.desiredDeliveryDate
            && this.checkoutDetails.deliveryGroups.items[0].desiredDeliveryDate !== '1970-01-01T00:00:00.000Z';
    }

    get isPickup() {
        const cos = this.checkoutDetails?.deliveryGroups?.items?.[0]?.selectedDeliveryMethod?.classOfService;
        if (!cos) {
            return false; // default conservador
        }

        try {
            const parsed = JSON.parse(cos);
            return parsed?.isPickup === true;
        } catch (e) {
            return false;
        }
    }

    get requiresDeliveryDate() {
        return !this.isPickup;
    }
        
    /* =========================================================
     * 5. TEMPLATE GETTERS (HTML-facing)
     *    - CSS classes
     *    - Texts and labels
     *    - Conditional rendering flags
     * ========================================================= */

    get placeOrderHint() {
        const missing = this.placeOrderState.missing;

        if (!missing.length) {
            return '';
        }

        if (missing.length > 1) {
            return 'Please complete the required delivery information to place the order.';
        }

        switch (missing[0]) {
            case 'shipping':
                return 'Shipping cost will be calculated once delivery details are completed.';
            case 'reference':
                return 'Please enter your reference (PO) to place the order.';
            case 'date':
                return 'Please select a desired delivery date.';
            default:
                return '';
        }
    }

    get currencyIsoCode() {
        return this.cartSummary?.currencyIsoCode ?? 'USD';
    }

    get formattedSubtotal() {
        return this.formatCurrency(this.subtotal);
    }

    get formattedShipping() {
        return this.formatCurrency(this.shipping);
    }

    get formattedTax() {
        return this.formatCurrency(this.tax);
    }

    get formattedTotal() {
        return this.formatCurrency(this.total);
    }

    get primaryActionLabel() {
        return 'Place order';
    }

    get isPrimaryActionDisabled() {
       return !this.allowPlaceOrder || !this.placeOrderState.canPlace;
    }

  // CART LINES (display)
    get lines() {

        const MULTIPLIER = 1; // for testing large carts
        
        if (!this.showDetail || !this.cartItems?.length) {
            return [];
        }

        const baseLines = this.cartItems.map(item => {
            const cartItem = item.cartItem ?? item;

            const quantity = Number(cartItem.quantity);
            const unitCode = this.extractUnit(cartItem);

            return {
                id: cartItem.cartItemId,
                name: cartItem.name,
                sku: cartItem.productDetails?.sku,

                quantityLabel: formatQuantityWithUnit(
                    quantity,
                    unitCode,
                    'en' // más adelante dinámico
                ),

                formattedTotal: this.formatCurrency(cartItem.totalPrice),
                imageUrl: cartItem.productDetails?.thumbnailImage?.url
            };
        });

        if (MULTIPLIER === 1) {
            return baseLines;
        }

        return Array.from({ length: MULTIPLIER })
            .flatMap((_, i) =>
            baseLines.map(l => ({ ...l, id: `${l.id}-test-${i}` }))
        );
    }
    
    /* =========================================================
     * 6. LIFECYCLE & INITIALIZATION
     *    - connectedCallback / renderedCallback
     *    - One-time initialization logic
     *    - Init guards and bootstrapping
     * ========================================================= */

    /* =========================================================
     * 7. INTEGRATION & DATA ACCESS
     *    - @wire
     *    - Apex calls
     *    - GraphQL or external services
     * ========================================================= */

    @wire(CartItemsAdapter)
    wiredCartItems({ data, error }) {
        if (data) {
            // this.logger.debug('CartItemsAdapter data', data, { json: true, pretty: false });
            this.cartItems = data.cartItems ?? [];
            this.cartItemsError = undefined;
        } else if (error) {
            console.error('[B2B_USCartSummary] CartItemsAdapter error', error);
            this.cartItems = [];
            this.cartItemsError = error;
        }
    }

    @wire(getRecord, { recordId: "$cdgId", fields: CDG_FIELDS })
    wiredCdg({ data, error }) {
        if (data) {
            this._cdgRecord = data;
            this.logger.highlight('CDG wire updated', {
                ShippingCost__c: getFieldValue(data, 'CartDeliveryGroup.ShippingCost__c'),
                ShippingPending__c: getFieldValue(data, 'CartDeliveryGroup.ShippingPending__c')
            });
        } else if (error) {
            this.logger.error('CDG wire error', error);
        }
    }

    /* =========================================================
     * 8. DOMAIN METHODS
     *    - Core business logic of the component
     *    - Complex state transitions
     *    - Rules that define component behavior
     * ========================================================= */
    
    
    /* =========================================================
     * 9. VALIDATION
     *    - Business validations
     *    - UI validation rules
     *    - Field and consistency checks
     * ========================================================= */
    
    
    /* =========================================================
     * 10. ORCHESTRATORS
     *     - High-level flows coordinating domain logic
     *     - Integration calls + UI state updates
     * ========================================================= */
    
    
    /* =========================================================
     * 11. EVENT HANDLERS
     *     - UI event handlers
     *     - Should delegate to orchestrators or domain methods
     * ========================================================= */
    
    handlePrimaryAction() {
        this.dispatchEvent(
            new CustomEvent('placeorder', {
                bubbles: true,
                composed: true
            })
        );
    }
    
    /* =========================================================
     * 12. HELPERS & UTILITIES
     *     - Pure helper functions
     *     - Formatters, parsers, date utilities
     *     - No side effects
     * ========================================================= */    

    extractUnit(cartItem) {
        if (cartItem.customFields?.length) {
            const field = cartItem.customFields[0];
            if (field.QuantityUnit__c) {
                return field.QuantityUnit__c;
            }
        }
        return 'BOX';
    }

    formatCurrency(value) {
        if (value === null || value === undefined) {
            return '';
        }

        try {
            return new Intl.NumberFormat('en-US', {
                style: 'currency',
                currency: this.currencyIsoCode
            }).format(Number(value));
        } catch (e) {
            return value;
        }
    }
}