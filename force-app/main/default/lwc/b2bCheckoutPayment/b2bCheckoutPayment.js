import { LightningElement, api } from 'lwc';
import Logger from 'c/libLogger';

const DEFAULT_PAYMENT_METHOD = 'CREDIT';
const TERMS_KEY = 'b2b_termsAccepted_US_DEALERS';

export default class B2bCheckoutPayment extends LightningElement {
    
    /* =========================================================
     * PUBLIC API
     * ========================================================= */
    
    @api mode = 'edit';
    @api isReadyToOrder = false;

    get customerReference() {
        return this.st_customerReference;
    }
    set customerReference(value) {
        this.st_customerReference = value;
    }

    @api 
    set creditInfo(value) {
        this.ui_creditLoading = value?.loading;
        this.st_creditError = value?.error ?? null;
        this.st_creditInfo = this.normalizeCreditInfo(value?.data ?? {});   
        this.logger.info('Received credit info', this.st_creditInfo, { json: true, pretty: false });    
        this.ensureValidPaymentMethod();
    }   
    get creditInfo() {        
        return this.st_creditInfo;        
    }

    @api 
    set pricesInfo(value) {
        this.ui_pricesLoading = value?.loading;
        this.st_pricesError = value?.error ?? null;
        this.st_pricesInfo = value?.data ?? { error: 'No data' };
    }   
    get pricesInfo() {        
        return this.st_pricesInfo;        
    }

    @api 
    set accountSettings(value) {
        this.st_accountSettings = value;
        this.ensureValidPaymentMethod();
    }
    get accountSettings() {
        return this.st_accountSettings;
    }

    @api 
    set cartTotal(value) {
        this.st_cartTotal = Number(value) ?? 0;      
        this.ensureValidPaymentMethod();      
    }  
    get cartTotal() {
        return this.st_cartTotal;
    }
            
    /* =========================================================
     * INTERNAL STATE
     * ========================================================= */
    st_customerReference = '';
    st_paymentMethod = DEFAULT_PAYMENT_METHOD;
    st_creditInfo = {};
    st_pricesInfo = {};
    st_cartTotal = 0;
    st_pricesError = null;
    st_creditError = null;
    st_termsAccepted = false;

    ui_hasSetDefaultPaymentMethod = false;
    ui_pricesLoading = false;
    ui_creditLoading = false;
    ui_showTerms = false;

    logger = new Logger('b2bCheckoutPayment');

    /* =========================================================
     * LIFECYCLE
     * ========================================================= */
    connectedCallback() {
        // Cargar estado de aceptación de términos desde localStorage
        const accepted = window.sessionStorage.getItem(TERMS_KEY);        
        this.st_termsAccepted = (accepted === '1');        
    }

    renderedCallback() {
        if (this.ui_hasSetDefaultPaymentMethod) return;
        //const defaultMethod = DEFAULT_PAYMENT_METHOD;
        // this.st_paymentMethod = defaultMethod;
        if (this.showCreditOption) {
            this.st_paymentMethod = 'CREDIT';
        } else if (this.showCardOption) {
            this.st_paymentMethod = 'CARD';
        }
        this.ui_hasSetDefaultPaymentMethod = true;
    }

    /* =========================================================
     * GETTERS (CREDIT)
     * ========================================================= */

    get isEditing() {
        return this.mode === 'edit';
    }

    get isSummary() {
        return this.mode === 'summary';
    }

    get hasCreditError() {
        return (this.st_creditError)
    }

    get isLoading() {
        return (this.ui_pricesLoading ?? false) || (this.ui_creditLoading?.loading ?? false);
    }
    get customerUsesCredit() {
        return !this.creditInfo?.requiresDeposits ?? false;
    }

    get isBlocked() {
        return !this.creditInfo?.globalCreditOk ?? true;
    }

    get hasCredit() {
        return !this.isBlocked && (this.st_cartTotal <= this.creditInfo?.creditAvailable);
    }

    get creditTitle() {
        if (this.hasCreditError) {
            return 'Credit status unavailable';
        } else if (this.isBlocked) {
            return 'Credit on hold';
        } else if (this.hasCredit) {
            return 'Credit available';
        } 
        return 'Insufficient credit';
    }

    get creditLine() {

        const fmtLimit = this.formatMoney(this.creditInfo?.creditLimit, this.creditInfo?.currencyCode);
        const fmtAvailable = this.formatMoney(this.creditInfo?.creditAvailable, this.creditInfo?.currencyCode);        

        if (this.hasCreditError) {
            return 'We can’t retrieve your credit information right now. Credit purchases may be unavailable at the moment.';
        } else if (this.isBlocked) {
            return 'Credit purchases aren’t available for this account at the moment. For assistance, please contact your sales rep.';
        } else if (this.hasCredit) {
            return this.buildCreditAvailableMessage(this.creditInfo?.creditAvailable, this.creditInfo?.creditLimit, this.creditInfo?.currencyCode);
        }   
    
        return `You have ${fmtAvailable} available out of your ${fmtLimit} credit limit, but it isn’t enough to cover this order total.`;

    }

    get isCreditCardAllowed() {
        return this.st_accountSettings?.CreditCardAllowed__c ?? true;
    }

    get hasCardSurcharge() {
        return this.surchargePct > 0;
    }

    get surchargePct() {
        if (this.isCreditCardAllowed) {
            return (this.st_accountSettings?.CreditCardSurcharge__c ?? 0);
        }
        return 0;
    }

    get surchargeAmount() {
        let amount = 0;
        if (this.isCardSelected && this.hasCardSurcharge) {
            amount = this.st_cartTotal * this.surchargePct / 100;
            amount = Math.round(Number(amount) * 100) / 100; // redondeamos a 2 decimales
        }
        return amount;
    }

    get cartTotalIncludingSurcharge() {
        return this.st_cartTotal + this.surchargeAmount;
    }

    get surchargeText() {
        if (this.hasCardSurcharge) {
            return ` A ${this.surchargePct}% fee will be added.`;
        }
        return '';
    }

    get isCreditSelected() {
        return this.st_paymentMethod === 'CREDIT';
    }

    get isCreditDisabled() {
        return this.hasCreditError || (this.customerUsesCredit && !this.hasCredit);
    }

    get isCardSelected() {
        return this.st_paymentMethod === 'CARD';
    }
    
    get ctaLabel() {
        return this.isCreditSelected ? 'Place Order' : 'Pay & Place Order';
    }

    get isCtaDisabled() {
        return !this.st_termsAccepted 
            || !this.st_paymentMethod 
            || !String(this.st_customerReference || '').trim()
            || !this.isReadyToOrder;
    }

    get showCreditBlock() {
        return this.customerUsesCredit;
    }

    get showCreditOption() {
        return this.customerUsesCredit;
    }

    get showCardOption() {
        if (this.isCreditCardAllowed) return true;
        return !this.customerUsesCredit; // fallback: si no hay crédito, mostramos tarjeta aunque no allowed
    }

    get optionsCount() {
        return (this.showCreditOption ? 1 : 0) + (this.showCardOption ? 1 : 0);
    }

    get creditOptionClass() {
        let cls = 'option';
        if (this.isCreditDisabled) cls += ' option--disabled';
        return cls;
    }   

    get creditOptionText() {
        if (this.isCreditDisabled) {
            if (this.hasCreditError) {
                return "Credit information unavailable — please try again shortly.";
            } else if (this.isBlocked) {
                return "Not available.";
            }
            return 'Not enough available credit for this order.';
        }
        return "This order total will be charged against your credit limit.";
    }

    /* =========================================================
     * GETTERS (PRICES)
     * ========================================================= */

    get priceValidationIssue() {
        return (!this.st_pricesInfo.isOk || this.st_pricesError !== null);
    }

    get priceIssueTitle() {
        if (this.st_pricesInfo.error) {
            return 'Price validation unavailable';
        }
        return 'Price review in progress';       
    }

    get priceIssueBody() {
        if (this.st_pricesError) {
            return "We’re unable to validate prices for this cart right now, so the order can’t be placed at the moment.";
        }
        return "Some prices in your cart need to be reviewed before the order can be placed.";
    }   

    get priceIssueLine2() {
        if (this.st_pricesError) {
            return "Please try again shortly. If you need assistance, contact your sales representative.";
        }
        return "No action is required — we’ll review the prices and get back to you shortly.";
    }

    /* ======================================================== 
     * EVENT HANDLERS
     * ========================================================= */

    handlePaymentMethodChange(event) {
        this.st_paymentMethod = event.target.value;
    }

    handlePoNumberChange(event) {
        this.st_customerReference = event.target.value;
    }

    handleBackToShopping() {
        const baseUrl = window.location.origin;
        const path = window.location.pathname;
        // Quita '/checkout' si existe
        const homePath = path.replace(/\/checkout\/?$/, '');
        window.location.href = baseUrl + homePath;
    }

    handleTermsChange(event) {
        this.st_termsAccepted = event.target.checked;
        window.sessionStorage.setItem(TERMS_KEY, this.st_termsAccepted ? '1' : '0');
    }

    handleOpenTerms(event) {
        event.preventDefault();
        this.ui_showTerms = true;
    }

    handleCloseTerms() {
        this.ui_showTerms = false;
    }

    async handlePlaceOrderClick() {
        if (this.isCreditSelected) {
            const confirmed = await this.confirmCreditOrder();
            if (!confirmed) return;
        } else if (this.isCardSelected && this.hasCardSurcharge) {
            const confirmed2 = await this.confirmCardOrder();
            if (!confirmed2) return;
        }
        const payload = {
            paymentMethod: this.st_paymentMethod,           // CREDIT or CARD
            customerReference: this.st_customerReference,
            surchargePct: this.surchargePct ?? 0,
            surcharge: this.surchargeAmount,
            cartTotal: this.cartTotalIncludingSurcharge
        };
        this.dispatchEvent(new CustomEvent('confirmdata', {detail: payload, bubbles: true, composed: true}));
    }

    handleChange() {
        this.dispatchEvent(new CustomEvent('changedata', {bubbles: true, composed: true}));
    }

    /* ======================================================
     * UTILITIES
     * ====================================================== */
    normalizeCreditInfo(dto, orderTotal) {
        const creditLimit = this.toNumber(dto?.creditLimit);
        const creditCommitted = this.toNumber(dto?.creditCommitted);
        const creditAvailable = Math.max(0, creditLimit - creditCommitted);
        const urate = this.toNumber(dto?.creditUtilizationRate); // puede venir 0..1 o 0..100
        const creditUtilizationRate = this.normalizePercent(urate, creditLimit, creditCommitted);
        const currencyCode = dto?.currencyCode || 'USD';
        const financeBlock = Boolean(dto?.financeBlock);
        const blockedByCreditLimit = Boolean(dto?.blockedByCreditLimit);
        const blockedByUnpaidItems = Boolean(dto?.blockedByUnpaidItems);
        const blockedByOverdueItems = Boolean(dto?.blockedByOverdueItems);
        const blockedByOverdueOthers = Boolean(dto?.blockedByOverdueOthers);
        const globalCreditOk = Boolean(dto?.globalCreditOk);        
        const isCreditSufficient = orderTotal == null ? creditAvailable > 0 : creditAvailable >= this.toNumber(orderTotal);
        const reasons = this.buildCreditBlockingReasons(dto);

        return {
            currencyCode,
            creditCategory: dto?.creditCategory || null,
            creditStatus: dto?.creditStatus || null,
            creditLimit,
            creditCommitted,
            creditAvailable,
            creditUtilizationRate,
            globalCreditOk,
            financeBlock,
            requiresDeposits: Boolean(dto?.requiresDeposits),
            blockedByUnpaidItems,
            blockedByOverdueItems,
            blockedByOverdueOthers,
            blockedByCreditLimit,
            isCreditSufficient,
            reasons
        };
    }

    toNumber(value) {
        const n = Number(value);
        return Number.isFinite(n) ? n : 0;
    }

    normalizePercent(utilizationRate, creditLimit, creditCommitted) {
        if (utilizationRate > 0) return utilizationRate <= 1 ? utilizationRate : utilizationRate / 100;
        if (creditLimit <= 0) return 0;
        return Math.min(1, Math.max(0, creditCommitted / creditLimit));
    }

    buildCreditBlockingReasons(dto) {
        const reasons = [];

        if (dto?.financeBlock) reasons.push({ code: 'FINANCE_BLOCK', label: this.labels.creditReasonFinanceBlock });
        if (dto?.blockedByUnpaidItems) reasons.push({ code: 'UNPAID_ITEMS', label: this.labels.creditReasonUnpaidItems });
        if (dto?.blockedByOverdueItems) reasons.push({ code: 'OVERDUE_ITEMS', label: this.labels.creditReasonOverdueItems });
        if (dto?.blockedByOverdueOthers) reasons.push({ code: 'OVERDUE_OTHERS', label: this.labels.creditReasonOverdueOthers });
        if (dto?.blockedByCreditLimit) reasons.push({ code: 'CREDIT_LIMIT', label: this.labels.creditReasonCreditLimit });

        if (!reasons.length && dto?.creditStatus) reasons.push({ code: 'STATUS', label: dto.creditStatus });

        return reasons;
    }

    formatMoney(amount, currencyCode) {
        try {
            return new Intl.NumberFormat('en-US', { style: 'currency', currency: currencyCode || 'USD' }).format(this.toNumber(amount));
        } catch (e) {
            return String(this.toNumber(amount));
        }
    }

    buildCreditAvailableMessage(available, creditLimit, currencyCode) {
        const a = this.toNumber(available);
        const l = this.toNumber(creditLimit);
        if (l > 0 && Math.abs(a - l) < 0.01) {
            return `You have ${this.formatMoney(a, currencyCode)} available.`;
        }
        return `You have ${this.formatMoney(a, currencyCode)} available out of your ${this.formatMoney(l, currencyCode)} credit limit.`;
    }

    ensureValidPaymentMethod() {
        const creditVisible = this.showCreditOption;
        const cardVisible = this.showCardOption;

        const creditSelectable = creditVisible && !this.isCreditDisabled;
        const cardSelectable = cardVisible; // en tu modelo, si está visible se puede elegir

        // Si el método actual ya no es válido, lo cambiamos
        if (this.st_paymentMethod === 'CREDIT' && !creditSelectable) this.st_paymentMethod = null;
        if (this.st_paymentMethod === 'CARD' && !cardSelectable) this.st_paymentMethod = null;

        // Si no hay método elegido, elegir por defecto
        if (!this.st_paymentMethod) {
            if (this.optionsCount === 1) {
                this.st_paymentMethod = creditVisible ? 'CREDIT' : 'CARD';
            } else {
                // Preferencia: si crédito es seleccionable, default crédito; si no, tarjeta
                this.st_paymentMethod = creditSelectable ? 'CREDIT' : 'CARD';
            }
        }
    }
    
    async confirmCreditOrder() {
        const dialog = this.template.querySelector('c-ux-modal-dialog');
        dialog.variant = 'confirm';
        dialog.title = 'Confirm order';
        dialog.message = 'This order will be placed using your available credit.';
        const confirmed = await dialog.showDialog();
        return confirmed;
    }

    async confirmCardOrder() {
        const fmt = this.formatMoney(this.surchargeAmount, this.currencyCode);
        const txt = 'A ' + fmt + ' credit card surcharge (' + this.surchargePct + '%) will be added on the payment page.'
        const dialog = this.template.querySelector('c-ux-modal-dialog');
        dialog.variant = 'confirm';
        dialog.title = 'Confirm credit card surcharge';
        dialog.message = txt;
        const confirmed = await dialog.showDialog();
        return confirmed;
    }


}