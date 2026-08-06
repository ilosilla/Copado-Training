// b2bPaymentGatewayResponse.js
import { LightningElement, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { refreshCartSummary } from 'commerce/cartApi';
import getPaymentRequestStatus from '@salesforce/apex/B2B_UsCartToOrderController.getPaymentRequestStatus';

const STATE_WAITING = 'WAITING';
const STATE_PAYMENT_RECEIVED = 'PAID';
const STATE_COMPLETED = 'COMPLETED';
const STATE_FAILED = 'FAILED';
const STATE_CANCELLED = 'CANCELLED';
const STATE_TIMEOUT = 'TIMEOUT';
const STATE_EXCEPTION = 'EXCEPTION';

export default class B2bPaymentGatewayResponse extends NavigationMixin(LightningElement) {

    /* =====================================================
     * STATE
     * ===================================================== */
    st_token;
    st_state = STATE_WAITING;

    st_orderNumber;
    st_errorMessage;

    st_pollMs = 3000;
    st_timeoutMs = 180000;

    pollTimerId;
    timeoutTimerId;

    @wire(CurrentPageReference)
    capturePageRef(pageRef) {
        const token = pageRef?.state?.token;
        
        if (token === 'CAN') {
            this.stopPolling();
            this.st_state = STATE_CANCELLED;
            this.st_orderNumber = null;
            this.st_errorMessage = null;
            return;
        }

        if (token === 'ERR') {
            this.stopPolling();
            this.st_state = STATE_FAILED;
            this.st_orderNumber = null;
            this.st_errorMessage = 'The payment gateway returned an error. Please return to checkout and try again.';
            return;
        }

        if (token && token !== this.st_token) {
            this.st_token = token;
            this.startPolling();
        }

    }

    disconnectedCallback() {
        this.stopPolling();
    }

    /* =====================================================
     * POLLING
     * ===================================================== */
    startPolling() {

        this.stopPolling();

        if (!this.st_token) {
            this.setError('Missing token in URL.');
            return;
        }

        this.st_state = STATE_WAITING;
        this.st_orderNumber = null;
        this.st_errorMessage = null;

        this.checkNow();

        this.pollTimerId = window.setInterval(() => {
            this.checkNow();
        }, this.st_pollMs);

        this.timeoutTimerId = window.setTimeout(() => {
            if (this.isWaitingOrProcessing) {
                this.st_state = STATE_TIMEOUT;
                this.st_errorMessage = null;
                this.st_orderNumber = null;
                this.stopPolling();
            }
        }, this.st_timeoutMs);
    }

    stopPolling() {
        if (this.pollTimerId) {
            window.clearInterval(this.pollTimerId);
            this.pollTimerId = null;
        }
        if (this.timeoutTimerId) {
            window.clearTimeout(this.timeoutTimerId);
            this.timeoutTimerId = null;
        }
    }

    async checkNow() {
        try {
            const dto = await getPaymentRequestStatus({ token: this.st_token });
            console.log('Payment status response', JSON.stringify(dto));
            const status = dto?.status;

            if (!status) {
                // Record not visible yet or not created -> keep waiting
                this.st_state = STATE_WAITING;
                return;
            }

            if (status === STATE_PAYMENT_RECEIVED) {
                this.st_state = STATE_PAYMENT_RECEIVED;
                return;
            }

            if (status === STATE_COMPLETED) {
                await refreshCartSummary();
                this.st_state = STATE_COMPLETED;
                this.st_orderNumber = dto?.orderNumber;
                this.stopPolling();
                return;
            }

            if (status === STATE_EXCEPTION) {
                this.st_state = STATE_EXCEPTION;
                this.stopPolling();
                return;
            }            

            if (status === STATE_FAILED || status === STATE_CANCELLED) {
                this.st_state = status;
                this.st_errorMessage = dto?.errorMessage;
                this.stopPolling();
                return;
            }

            // Unknown status -> keep waiting but store debug
            this.st_state = STATE_WAITING;

        } catch (e) {
            this.setError(this.normalizeError(e));
            this.stopPolling();
        }
    }

    setError(message) {
        this.st_state = STATE_FAILED;
        this.st_errorMessage = message;
    }

    normalizeError(error) {
        try {
            if (error?.body?.message) return error.body.message;
            if (Array.isArray(error?.body)) return error.body.map(x => x?.message).filter(Boolean).join(' | ');
            if (error?.message) return error.message;
        } catch (e) {}
        return 'Unexpected error while confirming payment.';
    }

    /* =====================================================
     * GETTERS – UI STATE
     * ===================================================== */
    get isWaitingOrProcessing() {
        return this.st_state === STATE_WAITING || this.st_state === STATE_PAYMENT_RECEIVED;
    }
    get isSuccess() {
        return this.st_state === STATE_COMPLETED;
    }
    get isError() {
        return this.st_state === STATE_FAILED || this.st_state === STATE_CANCELLED;
    }
    get isTimeout() {
        return this.st_state === STATE_TIMEOUT;
    }

    get isRecovery() {
        return this.st_state === STATE_EXCEPTION; // o el estado que decidas
    }

    get title() {
        if (this.st_state === STATE_PAYMENT_RECEIVED) return 'Payment received';
        if (this.st_state === STATE_COMPLETED) return 'Thank you!';
        if (this.st_state === STATE_CANCELLED) return 'Payment cancelled';
        if (this.st_state === STATE_TIMEOUT) return 'Still processing…';
        if (this.st_state === STATE_FAILED) return 'We couldn’t confirm your payment';
        if (this.st_state === STATE_EXCEPTION) return 'Payment received!';
        return 'Confirming your payment…';
    }

    get subtitle() {
        if (this.st_state === STATE_PAYMENT_RECEIVED) return 'Creating your order now. This may take a few seconds.';
        if (this.st_state === STATE_COMPLETED) return 'Your order has been created successfully.';
        if (this.st_state === STATE_CANCELLED) return 'No payment was processed. You can return to checkout to try again.';
        if (this.st_state === STATE_TIMEOUT) return 'Your payment is taking longer than expected. Please refresh this page in a moment.';
        if (this.st_state === STATE_FAILED) return this.st_errorMessage ? this.st_errorMessage : 'Please try again or contact support.';
        if (this.st_state === STATE_EXCEPTION) return 'However, due to a technical issue we couldn’t create your order automatically. '
                +  ' You don’t need to do anything—our team has been notified and will complete it shortly. You’ll receive an email confirmation once it’s done.';
        return 'Please wait. This usually takes a few seconds. Don’t close this tab.';
    }

    get orderNumber() {
        return this.st_orderNumber || '';
    }

    /* =====================================================
     * ACTIONS
     * ===================================================== */
    handleContinueShopping() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url: '/' }
        });
    }

    handleBackToCheckout() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url: '/checkout' }
        });
    }

    handleRefresh() {
        window.location.reload();
    }
}