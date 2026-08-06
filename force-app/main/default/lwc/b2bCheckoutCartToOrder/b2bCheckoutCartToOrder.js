import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import createCreditOrder from '@salesforce/apex/B2B_UsCartToOrderController.createCreditOrder';
import prepareCardPaymentRedirect from '@salesforce/apex/B2B_UsCartToOrderController.prepareCardPaymentRedirect';
import { refreshCartSummary } from 'commerce/cartApi';

const STATE_PROCESSING = 'PROCESSING';
const STATE_SUCCESS = 'SUCCESS';
const STATE_ERROR = 'ERROR';

export default class B2bCheckoutCartToOrder extends NavigationMixin(LightningElement) {

    /* =====================================================
     * PUBLIC API
     * ===================================================== */
    @api 
        set cartId(value) {
            this.st_cartId = value;
            this.flag_cartId = true;
            this.tryInitialize();
        }
        get cartId() {
            return this.st_cartId;
        }

    @api 
    set webstoreId(value) {
        this.st_webstoreId = value;
        this.flag_webstoreId = true;
        this.tryInitialize();
    }
    get webstoreId() {
        return this.st_webstoreId;
    }

    @api 
    set paymentMethod(value) {; // 'CREDIT' | 'PAYMENT'
        this.st_paymentMethod = value;
        this.st_flag_paymentMethod = true;
        this.tryInitialize();
    }
    get paymentMethod() {
        return this.st_paymentMethod;
    }

    @api 
    set poNumber(value) {
        this.st_poNumber = value;
        this.st_flag_poNumber = true;
        this.tryInitialize();
    }
    get poNumber() {
        return this.st_poNumber;
    }  
    
    /**
     * @param {number} value
     */
    @api
    set cardSurcharge(value) {
        this.st_cardSurcharge = value;
        this.flag_cardSurcharge = true;
        this.tryInitialize();
    }
    get cardSurcharge() {
        return this.st_cardSurcharge;
    }

    @api
    set cardSurchargePct(value) {
        this.st_cardSurchargePct = value;
        this.flag_cardSurchargePct = true;
        this.tryInitialize();
    }
    get cardSurchargePct() {
        return this.st_cardSurchargePct;
    }


    @api
    set cartAmount(value) {
        this.st_cartAmount = value;
        this.flag_cartAmount = true;
        this.tryInitialize();
    }
    get cartAmount() {
        return this.st_cartAmount;
    }   

    /* =====================================================
     * STATE
     * ===================================================== */
    st_state = STATE_PROCESSING;
    st_orderNumber;
    st_orderErrorMessage;
    st_cardSurcharge = 0;
    st_cardSurchargePct = 0;
    st_cartAmount = 0;

    flag_cartId = false;
    flag_webstoreId = false;
    flag_paymentMethod = false;
    flag_poNumber = false;
    flag_cartAmount = false;
    flag_cardSurcharge = false;
    flag_cardSurchargePct = false;
    flag_initialized = false;

    ui_cardPrimaryMessage = 'Preparing payment';
    ui_CardSecondaryMessage = 'Building secure payment request...';

    /* =====================================================
     * LIFECYCLE
     * ===================================================== */
    tryInitialize() {
        console.log('Me entra en el initialize');
        if (this.flag_initialized) {
            return;
        }
        if (this.flag_cartId && this.flag_webstoreId && this.st_flag_paymentMethod 
            && this.st_flag_poNumber && this.flag_cardSurcharge && this.flag_cartAmount
            && this.flag_cardSurchargePct) {
            this.flag_initialized = true;
            if (this.isCredit) {
                this.processCreditOrder();
            } else {
                this.processCardPayment();
            }
        }
    }

    startProcessingSimulation() {
        // Tiempo artificial para demo (4s)
        window.setTimeout(() => {
            this.onOrderCreated();
        }, 8000);
    }

    onOrderCreated() {        
        // Simulamos número de pedido
        this.st_orderNumber = '001245';
        this.st_state = STATE_SUCCESS;
        console.log('LLEGA EL TIMEOUT ' + this.st_state);
    }


    /* =====================================================
     * GETTERS – UI STATE
     * ===================================================== */

    get isProcessing() {
        return this.st_state === STATE_PROCESSING;
    }

    get isSuccess() {
        return this.st_state === STATE_SUCCESS;
    }

    get isError() {
        return this.st_state === STATE_ERROR;
    }

    get currentState() {
        return this.st_state;
    }

    get buttonClass() {
        let baseClass = 'cart-to-order-action-btn';
        if (this.isSuccess || this.isError) {
            baseClass += ' cart-to-order-action-btn--visible';
        }
        return baseClass;
    }

    /* =====================================================
     * GETTERS – TEXTS
     * ===================================================== */

    get title() {
        if (this.isSuccess) {
            return 'Order created';
        }
        return 'Processing your cart';
    }

    get primaryMessage() {
        if (this.isCredit) {
            if (this.isSuccess) {
                return `Order number ${this.st_orderNumber} created with reference ${this.poNumber}.`;
            } else if (this.isError) {
                return 'We couldn’t place your order!';            
            }
            return `Creating your order with reference ${this.poNumber}.`;
        } 
        return this.ui_cardPrimaryMessage;
    }

    get secondaryMessage() {
        if (this.isCredit) {
            if (this.isSuccess) {
                return 'A confirmation has been sent to your email.';
            } else if (this.isError) {
                return `Unable to create order: ${this.st_orderErrorMessage}`;
            }
            return 'Please do not close or refresh this page while the process is completed.';
        }    
        return this.ui_CardSecondaryMessage;
    }

    get isCredit() {
        return this.paymentMethod === 'CREDIT';
    }

    /* =====================================================
     * ACTIONS (future)
     * ===================================================== */

    handleClose() {
        const result = {
            success: false,
            orderNumber: null,
            errorMessage: null
        };
        if (this.st_state === STATE_SUCCESS) {            
            result.success = true;
            result.orderNumber = this.st_orderNumber;    
            this.continueShopping();
        } else {
            result.success = false;
            result.errorMessage = 'Order creation failed (' + this.st_orderErrorMessage + ')';
        }
        this.dispatchEvent(
            new CustomEvent('close', {
                detail: result,
                bubbles: true,
                composed: true
        }) );        
        // Para más adelante:
        // - navegar a Order
        // - o volver a Home
    }

    /* =====================================================
     * CORE METHODS
     * ===================================================== */
    async processCreditOrder() {
        console.group('==> [B2BCheckoutCartToOrder] Starting credit order creation process');
        console.info('- Webstore Id : ' + this.webstoreId);
        console.info('- Cart Id     : ' + this.cartId);
        console.info('- Payment method : ' + this.paymentMethod);
        console.info('- PO Number   : ' + this.poNumber);                   
        try {
            this.st_state = STATE_PROCESSING;          // estado UI
            const result = await createCreditOrder({
                webstoreId: this.webstoreId,
                cartId: this.cartId,
                purchaseOrderReference: this.poNumber
            });
            console.info('RESULTADO: ');                        
            console.info('- Result: ' + JSON.stringify(result));   
            if (result?.success) {
                await refreshCartSummary();
                this.st_state = STATE_SUCCESS;
                this.st_orderNumber = result.orderNumber; 
                this.st_orderErrorMessage = null;
                console.info('- Order created: ' + this.st_orderNumber);                  
            } else {
                this.st_state = STATE_ERROR;
                this.st_orderErrorMessage = result?.errorMessage || 'Unknown error';    
                console.error('- Error received: ' + this.st_orderErrorMessage);
            }            
        } catch (error) {
            this.st_state = STATE_ERROR;
            console.error('*** Exception received: ', error);
            this.st_orderErrorMessage = error || 'Unexpected error while creating the order.';            
        } finally {
            console.groupEnd();
        }
    }

    /**
     * Launch card payment process, which is a redirection to the payment gateway, so no order is created at this moment. 
     * The order will be created asynchronously when the payment gateway calls back to our B2B_PaymentGatewayCapture endpoint.
     */
    async processCardPayment() {
        console.group('==> [B2BCheckoutCartToOrder] Starting credit order creation process');
        console.info('- Webstore Id : ' + this.st_webstoreId);
        console.info('- Cart Id     : ' + this.st_cartId);
        console.info('- Payment method : ' + this.st_paymentMethod);
        console.info('- PO Number   : ' + this.st_poNumber);
        console.info('- Card surcharge : ' + this.cardSurcharge);
        console.info('- Card surcharge %: ' + this.cardSurchargePct);
        console.info('- Cart amount : ' + this.cartAmount);
        try {
            this.ui_cardPrimaryMessage = 'Preparing payment';
            this.ui_CardSecondaryMessage = 'Building secure payment request...';
            this.st_state = STATE_PROCESSING;          // estado UI
            const result = await prepareCardPaymentRedirect({
                webstoreId: this.st_webstoreId,
                cartId: this.st_cartId,
                purchaseOrderReference: this.st_poNumber,
                cardSurcharge: this.st_cardSurcharge,
                cardSurchargePct: this.st_cardSurchargePct,
                cartTotal: this.st_cartAmount
            });
            console.info('======> RESULTADO: ' + JSON.stringify(result)); 
            if (result?.redirectUrl) {
                console.info('- Redirecting to payment gateway: ' + result.redirectUrl);
                this.submitRedirect(result.redirectUrl, result.fields);
            } else {
                this.st_state = STATE_ERROR;                
                this.st_orderErrorMessage = 'No redirect URL received from server.';
                console.error('- Error: ' + this.st_orderErrorMessage);
                this.ui_cardPrimaryMessage = 'We couldn’t redirect you to the payment gateway.';
                this.ui_CardSecondaryMessage = 'Please try again later or contact support (reason: no redirect URL)';
            }               
        } catch (error) {
            this.st_state = STATE_ERROR;
            console.error('*** Exception received: ', JSON.stringify(error));
            this.st_orderErrorMessage = error?.body?.message  || 'Unexpected exception while preparing payment';            
            this.ui_cardPrimaryMessage = 'We couldn’t redirect you to the payment gateway.';
            this.ui_CardSecondaryMessage = 'Please try again later or contact support (reason: ' + this.st_orderErrorMessage + ')';
        } finally {
            console.groupEnd();
        }
    }  
    
    /**
     * Builds the form and redirects to th Payment Gateway
     */
    submitRedirect(url, fields) {
        this.ui_cardPrimaryMessage = 'Redirecting to payment gateway';
        this.ui_CardSecondaryMessage = 'You’ll be redirected in a second. Please don’t close or refresh this page...';
        const form = document.createElement('form');
        form.method = 'POST';
        form.action = url;
        form.style.display = 'none';
        Object.entries(fields || {}).forEach(([name, value]) => {
            const input = document.createElement('input');
            input.type = 'hidden';
            input.name = name;
            input.value = value ?? '';
            form.appendChild(input);
        });
        document.body.appendChild(form);
        form.submit();
    }

    continueShopping() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/'
            }
        });
    }

    backToCheckout() {
        this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: { url: '/checkout' }
            });
    }    
     
}