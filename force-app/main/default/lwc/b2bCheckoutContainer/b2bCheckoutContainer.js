import { LightningElement, api } from 'lwc';
import { useCheckoutComponent } from 'commerce/checkoutApi';
import { NavigationMixin } from 'lightning/navigation';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import getCheckoutInfo from '@salesforce/apex/B2B_USCheckoutController.getCheckoutInfo';
import retrieveCustomerCredit from '@salesforce/apex/B2B_USCheckoutController.retrieveCreditStatus';
import validatePrices from '@salesforce/apex/B2B_USCheckoutController.validatePrices';
import saveDeliveryRequirement from '@salesforce/apex/B2B_USCheckoutController.saveDeliveryRequirement';

// Blueprint
import calculateShipping from '@salesforce/apex/B2B_USCheckoutController.calculateShipping';
import prepareShipping from '@salesforce/apex/B2B_USCheckoutController.prepareShipping';

import Logger from 'c/libLogger';

const checkoutState = {
    S_METHOD: 0,
    S_ADDRESS: 1,
    S_DETAILS: 2,
    S_PAYMENT: 3,
    S_ORDERING: 4
}

const componentMode = {
    EDIT: 'edit',
    SUMMARY: 'summary',
    VOID: 'void'
}

/* =========================================================
 * CONSTANTS
 * ========================================================= */

const ICON_SECTION_OPEN = 'utility:chevrondown';
const ICON_SECTION_CLOSED = 'utility:chevronright';

const K_SHIP_TO_CUSTOMER = 'SHIP-TO-CUSTOMER';
const K_CUSTOMER_PICKUP = 'CUSTOMER-PICKUP';

export default class B2bCheckoutContainer extends NavigationMixin(useCheckoutComponent(LightningElement)) {

    /* =========================================================
     * PUBLIC API (@api)
     * ========================================================= */
    @api
    get checkoutDetails() {
        return this._checkoutDetails;
    }
    set checkoutDetails(value) {
        this._checkoutDetails = value;
        if (!this.isCheckoutReady()) {
            return;
        }
        // Notifica a LDS que el CDG puede haber cambiado (e.g. ShippingPending__c = false tras CartExtension)
        const cdgId = value?.deliveryGroups?.items?.[0]?.id;
        if (cdgId) {
            notifyRecordUpdateAvailable([{ recordId: cdgId }]);
        }
        // Switch off loading / calculating spinners
        this.ui_isCalculating = false;

        // Bootstrap (una sola vez)
        this.tryInitialize();

        // Procesar cambios funcionales posteriores
        this.processCheckoutUpdate();  
    }

    /* =========================================================
     * STATE
     *    - Functional state (st_*)
     *    - UI state (ui_*)
     *    - Internal flags, cache, deduplication (_*)
     * ========================================================= */

    ui_isCalculating = false;
    ui_isInitialized = false;
    ui_isLoading = true;
    ui_isOrdering = false;

    // Sistema de errores graves
    ui_errorState = null;  
    ui_firstTime = false;

    // Timeout in case cart is empty or checkoutDetails fails to hydrate for some reason
    ui_watchdogRunning = false;
    ui_whatchdogTimeoutMs = 7000;

    st_currentState = checkoutState.S_METHOD;
    st_stateFlags = [false, false, false, false];   // One position per checkoutState to flag confirmation
    st_deliveryMethod;             // 'SHIP-TO-CUSTOMER' | 'CUSTOMER-PICKUP'
    st_deliveryMethodConfirmed = false; // boolean
    st_deliveryAddressConfirmed = false;
    st_deliveryDetailsConfirmed = false;
    st_selectedAddressId        // string | null
    st_selectedAddress
    st_deliveryRequirement;
    st_deliveryDate = null;
    st_deliveryInstructions = '';
    st_customerReference;
    st_creditInfo = {loading:false, data: null, error: null};
    st_sapPrices = {loading: false, data: null, error: null};
    st_selectedMethod;    

    st_cardSurcharge = 0;
    st_cardSurchargePct = 0;
    st_cartGrandTotal = 0;
    st_cartWeightKg = null;
        
    // SHIPPING COST (resultado backend)
    st_deliveryCost = { 
        loading: false, 
        data: null, 
        error: null 
    };
    deliveryCostStatus = {
        inProgress: false,
        waitingForAddressId: null,   // address Id being calculated (to avoid race conditions)
        retryAfterCurrent: false,    // address Id changed during calculation, needs recalculation after current one finishes
        lastAddressCalculated: null
    };
    

    bootstrapData = {
        checkoutId: null,
        accountId: null,
        cartId: null,
        webstoreId: null,
        deliveryAddresses: [],
        warehouseAddresses: [],
        logisticsContext: null,        
        salesRepName: '',
        salesRepEmail: '',
        isReadOnly: false,
        accountSettings: {},
        deliveryRequirementsMap: {}
    }

    _checkoutDetails;
    _t0 = 0;

    openStep = 'deliveryMethod';
    logger = new Logger('b2bCheckoutContainer');

    /* =========================================================
     * LIFECYCLE HOOKS
     * ========================================================= */

    /**
     * Sets a watchdog to go back to the home page if no valid card is detected
     *  after a certain time (e.g. 7s) to avoid users getting stuck in an unusable 
     * checkout page if checkoutDetails fails to load or hydrate for some reason.
     */
    renderedCallback() {
        if (!this.ui_watchdogRunning && !this.isDesignMode) {
            this.startCheckoutWatchdog();
        }
    }

    startCheckoutWatchdog() {
        if (this.ui_watchdogRunning) {
            return;
        }
        this.ui_watchdogRunning = true;
        this.ui_checkoutWatchdogStartMs = Date.now();
        setTimeout(() => {
            this.evaluateCheckoutWatchdog();
            }, this.ui_whatchdogTimeoutMs);
        }

    evaluateCheckoutWatchdog() {
        if (this._checkoutDetails) {
            return;
        }
        this.gotoHomePage();
    }


    /* =========================================================
     * GETTERS (JS convenience)
     *    - Derived values used by JS logic
     *    - Read-only helpers based on state
     *    - No side effects
     * ========================================================= */
    // --- Computed flags ---
    get isShipToCustomer() {
        return this.st_deliveryMethod === K_SHIP_TO_CUSTOMER;
    }

    get isPickup() {
        return this.st_deliveryMethod === K_CUSTOMER_PICKUP;
    }

    get cartAccountId() {   
        return this.checkoutDetails?.cartSummary?.accountId;
    }

    get defaultDeliveryGroup() {
        return this.checkoutDetails?.deliveryGroups?.items[0] ?? null;    
    }

    get cartTotal() {
        return this._checkoutDetails?.cartSummary?.grandTotalAmount || 0;
    }
    
    /* =========================================================
     * TEMPLATE GETTERS (HTML-facing)
     *    - CSS classes
     *    - Texts and labels
     *    - Conditional rendering flags
     * ========================================================= */
    
    get showSpinner() {        
        return (this.ui_isLoading || this.ui_isCalculating) && !this.isDesignMode();
    }

    get isDeliveryMethodOpen() {
        return this.openStep === 'deliveryMethod';
    }

    get isDeliveryAddressOpen() {
        return this.openStep === 'deliveryAddress';
    }

    get isDeliveryDetailsOpen() {
        return this.openStep === 'deliveryDetails';
    }

    get isPaymentOpen() {
        return this.openStep === 'payment';
    }

    get isReadyToOrder() {
        const customFields = this.defaultDeliveryGroup?.customFields?.[0];
        const shippingReady = customFields?.ShippingPending__c === false;
        const pricesReady   = !this.st_sapPrices.loading;
        const creditReady   = !this.st_creditInfo.loading;

        console.log('[isReadyToOrder]', { 
            ShippingPending__c: customFields?.ShippingPending__c,
            shippingReady, pricesReady, creditReady 
        });

        return shippingReady && pricesReady && creditReady;
    }

    get paymentChevronIcon() {
        return this.isPaymentOpen
            ? ICON_SECTION_OPEN
            : ICON_SECTION_CLOSED;
    }

    get deliveryMethodMode() {
        return this.st_deliveryMethodConfirmed ? 'summary' : 'edit';
    }

    get deliveryAddressMode() {
        return this.st_deliveryAddressConfirmed ? 'summary' : 'edit';
    }

    get deliveryDetailsMode() {
        return this.st_deliveryDetailsConfirmed ? 'summary' : 'edit';
    }

    get showShipToCustomerSections() {
        return this.st_deliveryMethodConfirmed && this.isShipToCustomer;
    }

    get showCheckoutContent() {
        return !this.hasBlockingError;
    }

    get hasError() {
        return this.ui_errorState !== null;
    }

    get hasBlockingError() {
        return this.ui_errorState?.isBlocking === true;
    }

    get canDismissError() {
        return this.ui_errorState && !this.ui_errorState.isBlocking;
    }

    get deliveryMethodSectionClass() {
        let cl = 'checkout-section';
        if (this.deliveryMethodMode === 'summary') {
            cl += ' checkout-section--summary';
        }
        return cl;
    }

    get deliveryAddressSectionClass() {
        let cl = 'checkout-section';
        if (this.deliveryAddressMode === 'summary') {
            cl += ' checkout-section--summary';
        }
        return cl;
    }

    get deliveryDetailsSectionClass() {
        let cl = 'checkout-section';
        if (this.deliveryDetailsMode === 'summary') {
            cl += ' checkout-section--summary';
        }
        return cl;
    }

    get availableAddresses() {
        if (this.isShipToCustomer) {
            return this.bootstrapData.deliveryAddresses || [];
        } else if (this.isPickup) {
            return this.bootstrapData.warehouseAddresses || [];
        }
        return [];
    }

    get preparationTimeMessage() {
        return this.bootstrapData.logisticsContext?.preparationTimeMessage || '';
    }

    /* =========================================================
     * GETTER - STATES (DFA)
     * ========================================================= */
    get sMethodMode() {
        if (this.st_currentState === checkoutState.S_METHOD) return componentMode.EDIT;                
        if (this.st_stateFlags[checkoutState.S_METHOD]) return componentMode.SUMMARY;
        return componentMode.VOID;
    }

    get sAddressMode() {
        if (this.st_currentState === checkoutState.S_ADDRESS) return componentMode.EDIT;                
        if (this.st_stateFlags[checkoutState.S_ADDRESS]) return componentMode.SUMMARY;
        return componentMode.VOID;
    }

    get sDetailsMode() {
        if (this.st_currentState === checkoutState.S_DETAILS) return componentMode.EDIT;                
        if (this.st_stateFlags[checkoutState.S_DETAILS]) return componentMode.SUMMARY;
        return componentMode.VOID;
    }

    get sPaymentMode() {
        if (this.st_currentState === checkoutState.S_PAYMENT) return componentMode.EDIT;                
        if (this.isShipToCustomer && this.st_stateFlags[checkoutState.S_DETAILS]) return componentMode.SUMMARY;
        if (this.isPickup && this.st_stateFlags[checkoutState.S_ADDRESS]) return componentMode.SUMMARY;
        return componentMode.VOID;
    }

    get sMethodShow() {
        return this.sMethodMode !== componentMode.VOID;
    }

    get sAddressShow() {
        return this.sAddressMode !== componentMode.VOID;
    }

    get sDetailsShow() {
        return this.sDetailsMode !== componentMode.VOID;
    }

    get sPaymentShow() {
        return this.sPaymentMode !== componentMode.VOID;
    }

    /* =========================================================
     * EVENT HANDLERS
     *    - UI event handlers only
     *    - Must delegate to component methods
     *    - No business logic here
     * =========================================================  */
    
    handleContinueShopping() {
        this.gotoHomePage();
    }

    handleDeliveryAddressChange(event) {
        const { addressId, address } = event.detail || {};
        this.st_selectedAddressId = addressId;
        this.st_selectedAddress = address; 
        
        if (this.st_selectedAddressId !== this.deliveryCostStatus.lastAddressCalculated) {
            this.requestCostRecalculation();        
        } 
    }

    handleConfirmDeliveryMethod(event) {
        const methodBefore = this.st_deliveryMethod ?? '';
        this.st_deliveryMethod = event.detail?.deliveryMethod;                
        let flags = [...this.st_stateFlags];
        if (this.st_deliveryMethod !== methodBefore) {
            flags = [false, false, false, false];
        }
        flags[checkoutState.S_METHOD] = true;        
        this.st_stateFlags = flags;
        this.st_currentState = checkoutState.S_ADDRESS; //this.isPickup ? checkoutState.S_PAYMENT : checkoutState.S_ADDRESS; 
    }

    handleConfirmDeliveryAddress(event) {
        this.st_deliveryRequirement = this.selectDeliveryRequirement(this.st_selectedAddressId);
        const flags = [...this.st_stateFlags];
        flags[checkoutState.S_ADDRESS] = true;
        this.st_stateFlags = flags; 
        this.st_currentState = this.isPickup ? checkoutState.S_PAYMENT : checkoutState.S_DETAILS; 
    }

    handleConfirmDeliveryDetails(event) {        
        const payload = event.detail;
        this.st_deliveryDate = payload.deliveryDate;
        this.st_deliveryInstructions = payload.deliveryInstructions;
        this.st_deliveryRequirement = payload.deliveryRequirement;
        this.persistDeliveryRequirement();
        const flags = [...this.st_stateFlags];
        flags[checkoutState.S_DETAILS] = true;
        this.st_stateFlags = flags;
        this.st_currentState = checkoutState.S_PAYMENT;
    }

    async handleConfirmPayment(event) {
        // Never confirm payment step to allow users to go back and change details until the moment they click "Place order"
        const payload = event.detail; // PAYMENT or CREDIT
        this.st_customerReference = payload.customerReference;
        this.st_selectedMethod = payload.paymentMethod;
        this.st_cardSurcharge = payload.surcharge || 0;
        this.st_cardSurchargePct = payload.surchargePct || 0;
        this.st_cartGrandTotal = payload.cartTotal || 0;
        this.ui_isOrdering = true;
    }

    handleDeliveryMethodEditRequest() {
        this.st_currentState = checkoutState.S_METHOD;
    }

    handleDeliveryAddressEditRequest() {
        this.st_currentState = checkoutState.S_ADDRESS;
    }

    handleDeliveryDetailsEditRequest() {
        this.st_currentState = checkoutState.S_DETAILS;
    }    

    handlePaymentEditRequest() {
        this.st_currentState = checkoutState.S_PAYMENT;
    }    

    /* =========================================================
        * INTEGRATION & DATA ACCESS
        *    - @wire
        *    - Apex calls
        *    - External services
        * ========================================================= */

    /**
     * Loads persisted checkout-related data from backend services
     * (e.g. previously selected address or pickup point).
     *
     * This method is executed only once during component initialization
     * and is NOT reactive to checkout updates.
     */
    async loadBootstrap() {
        this.ui_isLoading = true;
        // Reads the deliveryGroup from checkoutDetails
        const dg = this.checkoutDetails?.deliveryGroups?.items[0] ?? null;    
        try {
            const data = await getCheckoutInfo({
                cartId: this.checkoutDetails?.cartSummary?.cartId,
                accountId: this.cartAccountId,
                cartDeliveryGroupId: dg?.id
            });
            this.bootstrapData.checkoutId = this.checkoutDetails?.checkoutId;
            this.bootstrapData.cartId = this.checkoutDetails?.cartSummary?.cartId;
            this.bootstrapData.webstoreId = this.checkoutDetails?.cartSummary?.webstoreId;
            this.bootstrapData.accountId = this.cartAccountId
            this.bootstrapData.deliveryAddresses = data.deliveryAddresses || [];
            this.bootstrapData.warehouseAddresses = [data.warehouseAddress] || [];
            this.bootstrapData.salesRepName = data.salesRepName || '';
            this.bootstrapData.salesRepEmail = data.salesRepEmail || '';
            this.bootstrapData.deliveryRequirementsMap = data.deliveryRequirementsMap || {};
            this.bootstrapData.logisticsContext = data.warehouseLogistics || null;
            this.bootstrapData.accountSettings = data.accountSettings || null;

            // Restore previously selected delivery context if available
            if (data.contactPointAddressId) {
                this.st_deliveryMethod = K_SHIP_TO_CUSTOMER;
                this.st_deliveryMethodConfirmed = true;
                this.st_deliveryAddressConfirmed = true;
                this.st_selectedAddressId = data.contactPointAddressId;
                this.st_selectedAddress = this.bootstrapData.deliveryAddresses?.find(a => a.id === data.contactPointAddressId) || null;
                this.st_deliveryRequirement = this.selectDeliveryRequirement(this.st_selectedAddressId);
                this.st_deliveryDetailsConfirmed = (!!this.st_deliveryRequirement?.Id);
            } else if (data.warehouseAddressId) {
                this.st_deliveryMethod = K_CUSTOMER_PICKUP;
                this.st_deliveryMethodConfirmed = true;
                this.st_deliveryAddressConfirmed = true;
                this.st_selectedAddressId = data.warehouseAddressId;
                this.st_selectedAddress = this.bootstrapData.warehouseAddresses?.find(a => a.id === data.warehouseAddressId) || null;
            } else {
                this.st_deliveryMethodConfirmed = false;
                this.st_deliveryAddressConfirmed = false;
                this.st_selectedAddressId = null;
                this.st_selectedAddress = null;
                this.st_deliveryRequirement = null;
            }

            this.st_deliveryDate = data.desiredDeliveryDate || null;
            this.st_deliveryInstructions = data.specialInstructions || '';

            // Reset dispatch — clears TotalChargeAmount in framework
            this.logger.info('Reset delivery details in checkout framework to trigger recalculation with current address and delivery requirements');
            const prepareResult = await prepareShipping({ cdgId: dg?.id });

            this.logger.highlight('Result from prepareShipping', prepareResult);

            this.st_cartWeightKg = prepareResult?.weightKg ?? 0;
            notifyRecordUpdateAvailable([{ recordId: dg?.id }]);
            // Trigger applicator in background — do not await
            this.dispatchShippingCalculation(this.buildResetPayload());

            // Asynchronously load credit status and validate prices against SAP
            this.validateCartPrices();
            this.loadCustomerCredit();

        } catch (error) {
            this.logger.error('Error reading bootstrap data', error);
            //this.hasFatalError = true;
            let addressError = error?.body?.message || JSON.stringify(error);
            this.dispatchError('dataRetrieval', addressError);
        } finally {
            this.dfa_setInitialState();
            this.ui_isLoading = false;
        }        
    }
    
    /**
     * Retrieves credit status for the current account
     */
    async loadCustomerCredit() {
        try {
            this.st_creditInfo = {loading: true, data: null, error: null};
            this.logger.debug('Requesting credit status for ', this.bootstrapData.accountId);
            const result = await retrieveCustomerCredit({
                accountId: this.bootstrapData.accountId
            });
            this.st_creditInfo.data = result;                        
        } catch (error) {
            this.logger.error('Error loading credit info', error);
            this.st_creditInfo.error = error;
        } finally {
            this.st_creditInfo = {...this.st_creditInfo, loading: false};
            this.logger.info('Credit information received ', JSON.stringify(this.st_creditInfo));
        }
    }
    
    /**
     * Retrieves the cart prices from SAP and validates them against the local prices.º
     */
    async validateCartPrices() {
        try {
            this.st_sapPrices = {loading: true, data: null, error: null};
            const result = await validatePrices({
                webstoreId: this.bootstrapData.webstoreId,
                cartId: this.bootstrapData.cartId,
                accountId: this.bootstrapData.accountId 
            });
            this.st_sapPrices.data = result;            
        } catch (error) {
            this.st_sapPrices.error = error;
        } finally {
            this.st_sapPrices = {...this.st_sapPrices, loading: false}; 
            this.logger.info('Price validation result received ', this.st_sapPrices);
        }
    }

     /**
      * Persists the delivery requirement
      */
    async persistDeliveryRequirement() {
        if (!this.st_deliveryRequirement) {
            return;
        }
        try {
            const saved = await saveDeliveryRequirement({
                deliveryRequirement: this.st_deliveryRequirement,
                instructions: this.st_deliveryInstructions,
                deliveryDate: this.st_deliveryDate
            });
            // Actualizamos baseline con lo que vuelve de Apex
            this.st_deliveryRequirement = saved;
        } catch (error) {
            this.logger.error('Error persisting delivery requirements', error);
        }
    }

    async requestCostRecalculation() {
        if (!this.st_selectedAddressId) { 
            return; 
        }

        const addressId = this.st_selectedAddressId;
        if (this.deliveryCostStatus.inProgress) {
            if (this.deliveryCostStatus.waitingForAddressId !== addressId) {
                this.deliveryCostStatus.retryAfterCurrent = true;
            }
            return;
        }
        this.deliveryCostStatus.inProgress = true;
        this.deliveryCostStatus.waitingForAddressId = addressId;
        this.st_deliveryCost = { loading: true, data: null, error: null };
        try {
            this.logger.debug('Calling the calculateShipping Apex method with cdgId: ' + this.defaultDeliveryGroup?.id);
            const result = await calculateShipping({
                cdgId: this.defaultDeliveryGroup?.id,
                addressId: addressId,
                isPickup: this.isPickup
            });
            // UI actualizada inmediatamente desde Apex, sin esperar al applicator
            this.logger.highlight('Result from calculateShipping', result);
            this.st_deliveryCost = { loading: false, data: result, error: null };
            notifyRecordUpdateAvailable([{ recordId: this.defaultDeliveryGroup?.id }]);            

            let payload = {};
            if (result.available) {
                payload = {
                    defaultDeliveryGroup: {
                        deliveryAddress: {
                            city: this.st_selectedAddress?.city,
                            name: this.st_selectedAddress?.name,
                            country: this.st_selectedAddress?.countryCode,
                            postalCode: this.st_selectedAddress?.postCode,
                            region: this.st_selectedAddress?.stateCode,
                            street: this.st_selectedAddress?.street
                        }
                    }
                };
            } else {
                this.logger.highlight('Shipping not available for the selected address.');
                payload = this.buildResetPayload(); 
            }
            this.logger.highlight('Dispatching shipping calculation with payload', payload);    
            this.dispatchShippingCalculation(payload); 
        } catch (error) {
            this.st_deliveryCost = { loading: false, data: null, error: this.reduceError(error) };
            this.logger.error('Error calculating shipping', error);
        } finally {
            this.deliveryCostStatus.inProgress = false;
            this.deliveryCostStatus.waitingForAddressId = null;
            this.ui_isCalculating = false;
            if (this.deliveryCostStatus.retryAfterCurrent) {
                this.deliveryCostStatus.retryAfterCurrent = false;
                this.requestCostRecalculation();
            }
        }
    }

    buildResetPayload() {
        return {
            defaultDeliveryGroup: {
                deliveryAddress: { city: 'TV22', street: 'Reset-' + Date.now(), country: 'US', postalCode: '10000', region: 'CA' },
                selectedDeliveryMethodId: null
            }
        };
    }

    dispatchShippingCalculation(payload) {
        this.logger.debug('Dispatching shipping calculation with payload', payload);
        this.dispatchUpdateAsync(payload)
        .then(() => {
            return this.dispatchCommit();
        })
        .then(() => {
            this.logger.debug('Commit completed');
        })
        .catch(e => this.logger.error('Error in commit', e));
    }

    /* =========================================================
     * DELIVERY COST RECALCULATION
     * Logic to trigger delivery cost recalculation when the 
     * user selects a different shipping address, including:
     * - Building the payload with the new address and existing delivery instructions
     * - Dispatching the async update to trigger recalculation in the backend
     * - Handling loading state and potential errors
     * ========================================================= */

    /**
     * Persists the current delivery selection (mode + address)
     * into Checkout.Details and triggers recalculation.
     *
     * IMPORTANT:
     * - This method is the ONLY place where dispatchUpdateAsync + dispatchCommit
     *   should be called for delivery changes.
     * - Rewsults will arrive asynchronously via checkoutDetails updates.
     *
    async requestCostRecalculation() {
        // Safety guards
        if (!this.ui_firstTime && !this.st_selectedAddressId) { return; }


        // Buffer addressId to ensure no cahnges affect this recalc
        const addressId = this.st_selectedAddressId;
        const address = this.st_selectedAddress;

        // Avoid multiple simultaneous recalculations (e.g. user rapidly changing address selection)
        if (this.deliveryCostStatus.inProgress) {
            if (this.deliveryCostStatus.waitingForAddressId !== addressId) {
                this.deliveryCostStatus.retryAfterCurrent = true;
            }
            return;
        }   
        this.deliveryCostStatus.inProgress = true;
        this.deliveryCostStatus.waitingForAddressId = addressId;
        this.st_deliveryCost = { loading: true, data: null, error: null };

        try {
            let payload = '';
            if (this.ui_firstTime) {
                payload = this.buildDeliveryCostPayload(this.bootstrapData.warehouseAddresses[0].Id, this.bootstrapData.warehouseAddresses[0]);
                this.ui_firstTime = false;
            } else {
                payload = this.buildDeliveryCostPayload(addressId, address);
            }
            await this.dispatchUpdateAsync(payload);
            await this.dispatchCommit();
        } catch (error) {    
            this.ui_isCalculating = false;
            this.deliveryCostStatus.inProgress = false;
            this.deliveryCostStatus.waitingForAddressId = null;
            this.st_deliveryCost = { loading: false, data: null, error: this.reduceError(error) };
            //this.dispatchError('shippingUpdate', error?.body?.message || 'Unable to update delivery details');            
        } 
    }
    */
    
    /**
     * Builds the payload for the async delivery cost recalculation
     */
    buildDeliveryCostPayload(addressId, address) {
        const deliveryAddress = {
            city: address?.city,
            name: address?.name,
            country: address?.countryCode,
            postalCode: address?.postCode,
            region: address?.stateCode,
            shipToPhoneNumber: this.normalizePhoneUS(address?.phone1 || address?.phone2),
            street: address?.street
        };

        const existingInstructions = this.defaultDeliveryGroup?.shippingInstructions ?? '';
        const userInstructions = this.stripAddressMeta(existingInstructions);
        const cookedInstructions = this.composeInstructions(userInstructions, addressId);

        return {
            defaultDeliveryGroup: {
                deliveryAddress: deliveryAddress,
                shippingInstructions: cookedInstructions,
                selectedDeliveryMethodId: null
            }
        };
    }

    /**
     * Receives and applies the delivery cost from checkoutDetails after a recalculation has been triggered.
     */
    XXXreceiveCostRecalculation() {        
        if (this.deliveryCostStatus.retryAfterCurrent) {    
            this.deliveryCostStatus.retryAfterCurrent = false;
            this.deliveryCostStatus.inProgress = false; 
            this.requestCostRecalculation();
            return;
        }
        // Reset recalculation status
        this.deliveryCostStatus.retryAfterCurrent = false;
        this.deliveryCostStatus.inProgress = false; 
        this.deliveryCostStatus.waitingForAddressId = null;        
        this.ui_isCalculating = false;
        this.deliveryCostStatus.lastAddressCalculated = null; // this.st_selectedAddressId;

        const dg = this.checkoutDetails?.deliveryGroups?.items?.[0];
        const method = dg?.selectedDeliveryMethod;        
        if (!method?.id) {
            // We do not have delivery to the selected area
            const result = {
                available: false
            }
            let msg = '';
            if (this.checkoutDetails?.errors?.length > 0) {
                msg = this.checkoutDetails.errors[0].detail || '';
            } else if (this.checkoutDetails?.cartSummary?.messagesSummary?.limitedMessages?.length > 0) {
                msg = this.checkoutDetails.cartSummary.messagesSummary.limitedMessages[0].message || '';
            }
            this.st_deliveryCost = { loading: false, data: result, error: msg };
            return;
        }

        const feeRaw = method?.adjustedShippingFee ?? method?.shippingFee;
        const fee = feeRaw !== null && feeRaw !== undefined && feeRaw !== '' ? Number(feeRaw) : null; 
        const currency = method?.currencyIsoCode || this.checkoutDetails?.cartSummary?.currencyIsoCode;        

        const cos = this.safeJsonParse(method?.classOfService);
        if (this.st_selectedAddressId && cos?.addressId && cos.addressId !== this.st_selectedAddressId) {
            this.requestCostRecalculation();
            return;
        }

        try {
            this.deliveryCostStatus.lastAddressCalculated = this.st_selectedAddressId;
            const costData = {
                available: true,
                methodName: method?.name,
                fee: fee,
                currency: currency,
                weight: cos?.weight,
                rate: cos?.rate,
                perEach: cos?.perEach
            };
            this.st_deliveryCost = { loading: false, data: costData, error: null };
        } catch (error) {
            this.st_deliveryCost = { loading: false, data: null, error: 'Error processing delivery cost' };
        }  
    }

    stripAddressMeta(instructions) {
        if (!instructions) return '';
        return instructions
            .replace(/\n?#ADDR:[A-Za-z0-9]{15,18}\s*/g, '')
            .trim();
    }

    composeInstructions(userText, addressId) {
        const clean = (userText || '').trim();
        const meta = `#ADDR:${addressId}`;
        return clean ? `${clean}\n${meta}` : meta;
    }    

    handleCloseCartToOrder() {
        this.gotoHomePage();
    }
    
    /* =========================================================
     * UTILS
     *    - Reusable utility functions
     *    - Helpers for complex data transformations
     *    - Formatting, parsing, etc.
     * ========================================================= */

    /**
     * Processes checkoutDetails updates after initialization to react rto shipping changes.
     */
    processCheckoutUpdate() {
        this.logger.debug('Processing checkoutDetails update', this.checkoutDetails, { json: true, pretty: false });
        //this.receiveCostRecalculation();        
        this.applyDetailsFromCheckout();
    }


    /**
     * Applies delivery options (date + instructions) from checkoutDetails to local state.
     */
    applyDetailsFromCheckout() {
        try {
            const dg = this.defaultDeliveryGroup;            
            /* Ignore these - Now this fields are in custom fields in the Cart record
            this.st_deliveryInstructions = dg?.shippingInstructions || '';
            this.st_deliveryDate = dg?.desiredDeliveryDate || null;
            */
            this.st_customerReference = this._checkoutDetails?.cartSummary?.purchaseOrderNumber || '';
        } catch (e) {
            this.logger.error('Error parsing delivery options from checkoutDetails', e);
        }
    }

    /**
     * Initializes the componentre (executent once and only once)
     */
    tryInitialize() {
        if (this.ui_isInitialized) {
            return;
        }
        this.ui_isLoading = true;
        const hasCheckout =
            this.checkoutDetails?.checkoutId &&
            this.checkoutDetails?.cartSummary?.accountId &&
            this.defaultDeliveryGroup?.id;
        if (!hasCheckout) {
            return;
        }
        this.ui_isInitialized = true;
        this.loadBootstrap();        
    }
    
    /**
     * Checks if checkoutDetails is ready to be used
     */
    isCheckoutReady() {
        if (!this._checkoutDetails?.checkoutId) {
            return false;
        }
        const formStatus = this._checkoutDetails?.formStatus;
        // Ignorar estados intermedios (dispatchUpdateAsync)
        if (formStatus?.dirty === true ) {
            return false;
        }
        const status = this._checkoutDetails.cartSummary?.asyncOperationStatus?.toLowerCase() || 'completed';
        // Accepting 'errored' too (not just 'completed'): a known Commerce framework issue occasionally
        // leaves asyncOperationStatus stuck as "Errored" when saving CartDeliveryGroupDto, even though the
        // underlying record is fine (confirmed saveable via standard DML). Without this, the spinner never
        // clears because tryInitialize()/loadBootstrap() never run — see checkout_country_validation_bug notes.
        return status === 'completed' || status === 'errored';
    }

    reduceError(e) {
       return e?.body?.message || e?.message || 'Unable to calculate delivery cost.';
    }

    /**
     * Normalizes a phone number to E.164 format assuming US (+1).
     *
     * - Accepts user-friendly inputs like:
     *   "611 222 333", "(714) 772-3183", "714-772-3183"
     * - Returns "+1XXXXXXXXXX"
     * - Returns null if input is empty or invalid
     */
    normalizePhoneUS(rawPhone) {
        if (!rawPhone) {
            return null;
        }

        // Remove everything except digits
        const digits = rawPhone.replace(/[^\d]/g, '');

        // US phone numbers should have at least 10 digits
        if (digits.length < 10) {
            return null;
        }

        // If already includes country code (11 digits starting with 1)
        if (digits.length === 11 && digits.startsWith('1')) {
            return `+${digits}`;
        }

        // Standard US number → prefix with +1
        return `+1${digits.slice(-10)}`;
    }

    safeJsonParse(value) {
        if (!value) {
            return null;
        }
        if (typeof value === 'object') {
            return value; // ya viene parseado
        }
        try {
            return JSON.parse(value);
        } catch (e) {
            return null;
        }
    }

    /**
     * Returns the effective DeliveryRequirement record for a given ContactPointAddress.
     *
     * It uses the last known requirement for that address (loaded in bootstrapData.deliveryRequirementsMap)
     * as a template, clones it to avoid mutations, and enriches missing contact fields (name/phone/email)
     * using the address data as sensible defaults.
     *
     * If the retrieved record belongs to the current cart and the order has not been placed yet,
     * it is returned as-is so it can be updated. Otherwise (old cart / already ordered / template record),
     * it is converted into a new record by clearing Id/Order__c and setting the current Cart__c and
     * ContactPointAddress__c, so it can be inserted as a fresh requirement for this cart.
    */
    selectDeliveryRequirement(contactPointAddressId) {
        if (!contactPointAddressId) {
            return null;
        }

        const templateDr = this.bootstrapData.deliveryRequirementsMap?.[contactPointAddressId] || null;

        // Clone to avoid mutating template
        let effectiveDr = templateDr ? { ...templateDr } : {};

        // Resolve the address that matches the given id (safer than using this.st_selectedAddress blindly)
        const addr =
            (this.st_selectedAddress?.id === contactPointAddressId ? this.st_selectedAddress : null) ||
            this.bootstrapData.deliveryAddresses?.find(a => a.id === contactPointAddressId) ||
            null;

        // The account's own (nominal) address isn't a real ContactPointAddress — never link the lookup to it.
        const isAccountAddress = addr?.className === 'Account';

        const isBlank = (v) => v === null || v === undefined || String(v).trim() === '';

        if (addr) {
            // Name
            if (isBlank(effectiveDr.DeliveryContactName__c) && !isBlank(addr.name)) {
                effectiveDr.DeliveryContactName__c = addr.name;
            }

            // Phone: phone1 > phone2
            if (isBlank(effectiveDr.DeliveryContactPhone__c)) {
                effectiveDr.DeliveryContactPhone__c = addr.phone1 || addr.phone2 || null;
            }

            // Email
            if (isBlank(effectiveDr.DeliveryContactEmail__c) && !isBlank(addr.email)) {
                effectiveDr.DeliveryContactEmail__c = addr.email;
            }
        }

        // Determine whether we should update the existing record or clone as a new one
        if (!effectiveDr.Id) {
            // Case A: brand new (no record read)
            effectiveDr.Cart__c = this.bootstrapData.cartId;
            effectiveDr.ContactPointAddress__c = isAccountAddress ? null : contactPointAddressId;
        } else {
            const isSameCart = effectiveDr.Cart__c === this.bootstrapData.cartId;
            const isNotOrderedYet = !effectiveDr.Order__c;

            if (!(isSameCart && isNotOrderedYet)) {
                // Case B2: template/old cart/already ordered -> clone as new
                effectiveDr.Id = null;
                effectiveDr.Cart__c = this.bootstrapData.cartId;
                effectiveDr.ContactPointAddress__c = isAccountAddress ? null : contactPointAddressId;
                effectiveDr.Order__c = null;
            }
            // Case B1: valid record for this cart and not ordered -> keep as is (update)
        }

        return effectiveDr;
    }

    gotoHomePage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/'
            }
        });
    }

    /* =========================================================
     * DFA METHODS
     * ========================================================= */

    /**
     * Sets initial state after intialization and bootstrap data loading. This method is executed once and only once during the component lifecycle.
     */
    dfa_setInitialState() {        
        this.st_stateFlags = [false, false, false, false];   // One position per checkoutState to flag confirmation
        /*
        this.st_stateFlags[checkoutState.S_METHOD] =  Boolean(this.st_deliveryMethod);        
        this.st_stateFlags[checkoutState.S_ADDRESS] =  Boolean(this.st_selectedAddressId);        
        this.st_stateFlags[checkoutState.S_DETAILS] =  Boolean(this.st_deliveryDate);        
        // Set the first unconfirmed step as the current state
        this.st_currentState = this.st_stateFlags.indexOf(false);
         if (this.st_currentState === -1) {
            this.st_currentState = checkoutState.S_PAYMENT; // All steps confirmed, move to payment
        }
        */
        this.st_currentState = checkoutState.S_METHOD; // Always start in the first step (delivery method) and let users confirm each step in order. 
    }

    isDesignMode() {
        try {
            const host = (window.location && window.location.hostname) ? window.location.hostname : '';
            const search = (window.location && window.location.search) ? window.location.search : '';

            // Experience Builder / Live Preview indicators
            if (host.includes('live-preview.salesforce-experience.com')) return true;
            if (host.includes('builder.salesforce-experience.com')) return true;

            // Editor query params (extra safety)
            if (search.includes('app=commeditor')) return true;
            if (search.includes('view=editor')) return true;

            return false;
        } catch (e) {
            // If anything goes wrong, assume runtime (safer for production)
            return false;
        }
    }

    /* =========================================================
     * ERROR HANDLING
     * ========================================================= */
    showError(title, message, isBlocking = false, technicalDetails = null) {
        this.ui_errorState = {
            title,
            message,
            isBlocking,
            technicalDetails,
            timestamp: new Date()
        };
    }

    handleDismissError() {
        if (this.ui_errorState && !this.ui_errorState.isBlocking) {
            this.ui_errorState = null;
        }
    }


}