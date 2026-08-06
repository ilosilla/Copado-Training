import { LightningElement, api } from 'lwc';
import getOrderDetail from '@salesforce/apex/B2B_SalesDocumentsController.getOrderDetail';

export default class B2bSalesDocDetail extends LightningElement {
    /* =========================================================
       PUBLIC API
       ========================================================= */

    @api docType = 'ORDER';
    @api sapNumber;
    @api orderId;
    @api accountId;
    @api showClose;

    /* =========================================================
       INTERNAL STATE
       ========================================================= */

    ui_isLoading = false;
    st_error = null;

    st_header = {
        accountName: '',
        shipToName: '',
        shipToAddress: '',
        sapNumber: '',
        webOrderNumber: '',
        poNumber: '',
        orderDate: null,
        deliveryDate: null,
        salesOrg: '',
        net: null,
        tax: null,
        total: null,
        currencyCode: 'USD'
    };

    st_lines = [];

    /* =========================================================
       LIFECYCLE
       ========================================================= */

    connectedCallback() {
        this.load();
    }

    async load() {
        this.ui_isLoading = true;
        this.st_error = null;

        try {
            const resp = await getOrderDetail({
                sapId: this.sapNumber,
                orderId: this.orderId,
                accountId: this.accountId
            });
            this.applyResponse(resp);
        } catch (e) {
            this.st_error = e?.body?.message || e?.message || JSON.stringify(e);
            this.st_lines = [];
        } finally {
            this.ui_isLoading = false;
        }
    }

    applyResponse(resp) {
        const dto = resp || {};
        const order = dto.order || {};
        const items = order.items || [];
        this.st_header = {
            billToName: dto.billToName || '',
            billToAddress: dto.billToAddress || '',
            shipToName: dto.shipToName || '',
            shipToAddress: dto.shipToAddress || [],
            // SAP number is `orderNumber` in canonical DTO
            sapNumber: order.orderNumber || this.sapNumber || '',
            webOrderNumber: order.webOrderNumber || '',
            poNumber: order.poNumber || '',
            orderDate: order.orderDate || null,
            deliveryDate: order.deliveryDate || null,
            // Now we prefer the resolved label from the controller
            salesOrg: dto.salesOrgName || order.salesOrg || '',
            net: order.net,
            tax: order.tax,
            total: order.total,
            currencyCode: order.currencyCode || 'USD',
        };

        const ccy = this.st_header.currencyCode;
        this.st_lines = (items || []).map((l, idx) => ({
            key: (l.orderNumber && l.lineNumber)
                ? `${l.orderNumber}-${l.lineNumber}`
                : String(l.lineNumber || idx),
            sku: l.sku || '',
            name: l.name || '',
            qty: l.quantity,
            uom: l.salesUnit || '',
            netLabel: this.formatMoney(l.netAmount, ccy),
            taxLabel: this.formatMoney(l.taxAmount, ccy),
            totalLabel: this.formatMoney(l.totalAmount, ccy)
        }));
    }
    /* =========================================================
       COMPUTED UI
       ========================================================= */

    get ui_showClose() {
        return this.toBoolean(this.showClose);
    }

    get hasLines() {
        return !this.ui_isLoading && !this.st_error && (this.st_lines || []).length > 0;
    }

    get isLinesEmpty() {
        return !this.ui_isLoading && !this.st_error && (this.st_lines || []).length === 0;
    }

     get sfOrderNumber() {
        return this.st_header.webOrderNumber || 'N/A';
    }

    get orderDateLabel() {
        return this.formatDate(this.st_header.orderDate);
    }

    get deliveryDateLabel() {
        return this.formatDate(this.st_header.deliveryDate);
    }

    get netLabel() {
        return this.formatMoney(this.st_header.net, this.st_header.currencyCode);
    }

    get taxLabel() {
        return this.formatMoney(this.st_header.tax, this.st_header.currencyCode);
    }

    get totalLabel() {
        return this.formatMoney(this.st_header.total, this.st_header.currencyCode);
    }

    /* =========================================================
       EVENTS
       ========================================================= */

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    toBoolean(v) {
        if (v === true) {
            return true;
        }
        if (v === false || v === null || v === undefined) {
            return false;
        }
        // Experience Builder may pass strings
        if (typeof v === 'string') {
            return v.toLowerCase() === 'true' || v === '1' || v.toLowerCase() === 'yes';
        }
        if (typeof v === 'number') {
            return v === 1;
        }
        return false;
    }

    /* =========================================================
       FORMATTERS
       ========================================================= */

    formatDate(dt) {
        if (!dt) return '';
        try {
            const d = dt instanceof Date ? dt : new Date(dt);
            if (Number.isNaN(d.getTime())) return '';
            return new Intl.DateTimeFormat('en-US', { year: 'numeric', month: '2-digit', day: '2-digit' }).format(d);
        } catch {
            return '';
        }
    }

    formatMoney(amount, currencyCode) {
        if (amount === null || amount === undefined || amount === '') return '';
        try {
            const ccy = currencyCode || 'USD';
            return new Intl.NumberFormat('en-US', { style: 'currency', currency: ccy }).format(Number(amount));
        } catch {
            return String(amount);
        }
    }
}