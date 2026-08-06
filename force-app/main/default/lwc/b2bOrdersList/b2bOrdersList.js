import { LightningElement } from 'lwc';
import { getSessionContext } from 'commerce/contextApi';
import getOpenOrders from '@salesforce/apex/B2B_SalesDocumentsController.getOpenOrders';
import getOrderHistory from '@salesforce/apex/B2B_SalesDocumentsController.getOrderHistory';

const MAX_RECORDS = 800;

export default class B2bOrdersList extends LightningElement {
    /* ==================================================
     * INTERNAL STATE
     * ================================================== */ 
    st_accountId = null;
    st_accountName = null;
    st_isPreview = false;
    st_orders = [];
    st_total = 0;
    st_error = null;

    ui_isInitialized = false;
    ui_isLoading = false; 
    ui_pageSize = 25;
    ui_pageNumber = 1;
    ui_isDetailOpen = false;    
    ui_selectedSapNumber = null;
    ui_selectedOrderId = null;
    ui_selectedWebOrderNumber = null;
    ui_selectedEntryChannel = null;
    ui_searchText = '';
    searchDebounce = null;
    ui_isTruncated = false;

    _openOrdersCache = null;
    _historyCache = null;
    _historyCachePeriod = null;  // para invalidar si cambia el período

    /* ==================================================
     * FILTERS (DEFAULTS)
     * ================================================== */
    // Date ranges: THIS_MONTH | LAST_3_MONTHS | LAST_12_MONTHS
    ui_dateRange = 'LAST_3_MONTHS';

    // Channel: ALL | B2B | DIRECT
    ui_channel = 'ALL';

    // Sort: ORDER_DATE_DESC | DELIVERY_DATE_ASC | TOTAL_DESC
    ui_sort = 'ORDER_DATE_DESC';

    activeTab = 'open';
    ui_period = 'THIS_YEAR';
    ui_toast = null;


    /* ==================================================
     * LIFECYCLE HOOKS
     * ================================================== */
    async renderedCallback() {
        // Avoid running on every render (renderedCallback can be called many times)
        if (this.ui_isInitialized) {
            return;
        }
        this.ui_isInitialized = true;
        await this.initialize();
    }

    async initialize() {
        this.st_error = null;

        try {
            await this.loadSessionContext();

            // If we couldn't resolve an account, don't proceed
            if (!this.st_accountId) {
                this.st_error = 'Unable to resolve effective account.';
                return;
            }

            // Call with default filters
            await this.loadOrders();
        } catch (e) {
            // Keep it simple; you can normalize later with your error utils
            this.st_error = e?.body?.message || e?.message || JSON.stringify(e);
        }
    }

    /* ==================================================
     * INIT / DATA LOADING
     * ================================================== */

    async loadSessionContext() {
        const session = await getSessionContext();

        this.st_isPreview = !!session?.isPreview;
        this.st_accountId = session?.effectiveAccountId || null;
        this.st_accountName = session?.effectiveAccountName || null;

        // Optional: in preview, ensure you have something to work with
        // (Keep as fallback; normally session already provides effectiveAccountId in preview too)
        if (this.st_isPreview && !this.st_accountId) {
            this.st_accountId = '001RR00000ifl5p'; // example account id (sandbox)
        }
    }

    async loadOrders(forceRefresh = false) {
        this.ui_isLoading = true;
        this.st_error = null;
        try {
            if (this.activeTab === 'open') {
                if (!this._openOrdersCache || forceRefresh) {
                    const response = await getOpenOrders({ accountId: this.st_accountId, maxRecords: MAX_RECORDS + 1 });
                    const rows = response || [];
                    this.ui_isTruncated = rows.length > MAX_RECORDS;
                    this._openOrdersCache = this.ui_isTruncated ? rows.slice(0, MAX_RECORDS) : rows;
                }
                this.st_orders = this._openOrdersCache;
            } else {
                const periodChanged = this._historyCachePeriod !== this.ui_period;
                if (!this._historyCache || forceRefresh || periodChanged) {
                    const response = await getOrderHistory({ accountId: this.st_accountId, period: this.ui_period, maxRecords: MAX_RECORDS + 1 });
                    const rows = response || [];
                    this.ui_isTruncated = rows.length > MAX_RECORDS;
                    this._historyCache = this.ui_isTruncated ? rows.slice(0, MAX_RECORDS) : rows;
                    this._historyCachePeriod = this.ui_period;
                }
                this.st_orders = this._historyCache;
            }
            this.st_total = this.st_orders.length;
            this.ui_pageNumber = 1;
        } catch(e) {
            this.st_error = e?.body?.message || e?.message || JSON.stringify(e);
        } finally {
            this.ui_isLoading = false;
        }
    }

    /* ==================================================
     * OPTIONS (COMBOBOX)
     * ================================================== */
    get ui_sortOptions() {
        return [
            { label: 'Order date (newest)', value: 'ORDER_DATE_DESC' },
            { label: 'Delivery date (soonest)', value: 'DELIVERY_DATE_ASC' },
            { label: 'Total (high to low)', value: 'TOTAL_DESC' }
        ];
    }

    get ui_channelOptions() {
        return [
            { label: 'All', value: 'ALL' },
            { label: 'B2B', value: 'B2B' },
            { label: 'Direct', value: 'DIRECT' }
        ];
    }

    get ui_pageSizeOptions() {
        return [
            { label: '25', value: 25 },
            { label: '50', value: 50 },
            { label: '100', value: 100 }
        ];
    }
   /* ==================================================
     * TABLE / VIEW MODELS (st_ -> ui_ view)
     * ================================================== */
    
    get ui_filteredRows() {
        const q = (this.ui_searchText || '').trim().toLowerCase();
        const channel = this.ui_channel || 'ALL';
        const rows = (this.st_orders || []).filter((r) => {
            // 1) Search text
            const matchesSearch = !q || (
                String(r.sapNumber || '').toLowerCase().includes(q) ||
                String(r.webOrderNumber || '').toLowerCase().includes(q) ||
                String(r.poNumber || '').toLowerCase().includes(q) ||
                String(r.shipToName || '').toLowerCase().includes(q) ||
                String(r.statusLabel || '').toLowerCase().includes(q) ||
                String(r.deliveryStatusLabel || '').toLowerCase().includes(q) ||
                this.formatDate(r.orderDate).toLowerCase().includes(q) ||
                this.formatDate(r.deliveryDate).toLowerCase().includes(q) ||
                this.formatMoney(r.total, r.currencyCode).toLowerCase().includes(q) ||
                String(r.currencyCode || '').toLowerCase().includes(q)
            );

            // 2) Channel
            const rowChannel = String(r.entryChannel || '').toUpperCase();
            const matchesChannel = channel === 'ALL' || rowChannel === channel;

            return matchesSearch && matchesChannel;
        });

        return rows;
    }

    get ui_visibleRows() {
        const filtered = this.ui_filteredRows;

        const pageSize = Number(this.ui_pageSize || 25);
        const pageNumber = Number(this.ui_pageNumber || 1);

        const startIdx = (pageNumber - 1) * pageSize;
        const endIdx = startIdx + pageSize;

        const page = filtered.slice(startIdx, endIdx);

        return page.map((r) => {
            const orderDateLabel = this.formatDate(r.orderDate);
            const deliveryDateLabel = this.formatDate(r.deliveryDate);
            const totalLabel = this.formatMoney(r.total, r.currencyCode);

            return {
                ...r,
                orderDateLabel,
                deliveryDateLabel,
                totalLabel,
                statusLabel: r.statusLabel || 'Open',
                statusClass: 'badge badge--open',
                deliveryStatusLabel: r.deliveryStatusLabel || '',
                deliveryClass: 'badge badge--delivery'
            };
        });
    }    

    get ui_filteredCount() {
        return (this.ui_filteredRows || []).length;
    }

    get ui_totalCount() {
        return (this.ui_filteredRows || []).length;
    }

    get ui_rangeLabel() {
        const total = Number(this.ui_totalCount || 0);
        if (total === 0) {
            return 'Showing 0';
        }
        const pageSize = Number(this.ui_pageSize || 25);
        const pageNumber = Number(this.ui_pageNumber || 1);
        const start = (pageNumber - 1) * pageSize + 1;
        const end = Math.min(total, start + (this.ui_visibleRows?.length || 0) - 1);
        return `Showing ${start}–${end} of ${total}`;
    }

    get ui_hasRows() {
        return (this.ui_visibleRows || []).length > 0 && !this.ui_isLoading && !this.st_error;
    }

    get ui_isEmpty() {
        return !this.ui_isLoading && !this.st_error && (this.ui_visibleRows || []).length === 0;
    }

    get ui_rangeLabel() {
        const total = Number((this.ui_filteredRows || []).length);
        if (total === 0) {
            return 'Showing 0';
        }

        const pageSize = Number(this.ui_pageSize || 25);
        const pageNumber = Number(this.ui_pageNumber || 1);

        const start = (pageNumber - 1) * pageSize + 1;
        const end = Math.min(total, start + (this.ui_visibleRows?.length || 0) - 1);

        const suffix = this.ui_isTruncated && total >= MAX_RECORDS ? '+' : '';
        return `Showing ${start}–${end} of ${total}${suffix}`;
    }

    get ui_showTruncationNotice() {
        return this.ui_isTruncated && !this.ui_isLoading && !this.st_error;
    }

    get ui_truncationNotice() {
        return `More than ${MAX_RECORDS} open orders found. Showing the first ${MAX_RECORDS}.`;
    }
    
    get ui_prevDisabled() {
        return this.ui_isLoading || this.ui_pageNumber <= 1;
    }

    get ui_nextDisabled() {
        const total = Number(this.ui_totalCount || 0);
        const pageSize = Number(this.ui_pageSize || 25);
        const maxPage = total > 0 ? Math.ceil(total / pageSize) : 1;

        return this.ui_isLoading || this.ui_pageNumber >= maxPage;
    }

    get ui_detailNumber() {
        return this.ui_selectedSapNumber || this.ui_selectedWebOrderNumber || '';
    }

    get ui_isDraft() {
        // DRAFT when SAP number is not available yet
        return !this.ui_selectedSapNumber;
    }

    get isOpen() { return this.activeTab === 'open'; }
    get isHistory() { return this.activeTab === 'history'; }
    get tabOpenClass() { return this.activeTab === 'open' ? 'orders__tab orders__tab--active' : 'orders__tab'; }
    get tabHistoryClass() { return this.activeTab === 'history' ? 'orders__tab orders__tab--active' : 'orders__tab'; }

    get ui_periodOptions() {
        return [
            { label: 'This year',    value: 'THIS_YEAR' },
            { label: 'Last year',    value: 'LAST_YEAR' },
            { label: 'Last 3 years', value: 'LAST_N_YEARS:3' },
            { label: 'All',          value: null }
        ];
    }

    /* ==================================================
     * EVENT HANDLERS (STUBS)
     * ================================================== */
    handleTabChange(event) {
        this.activeTab = event.currentTarget.dataset.tab;
        this.loadOrders();
    }

    handlePeriodChange(event) {
        this.ui_period = event.detail.value;
        this.loadOrders();
    }

    handleSearchChange(event) {
        this.ui_searchText = event?.target?.value || '';
        this.ui_pageNumber = 1;
    }
    
    handleSearchInput(event) {
        const value = event?.detail?.value ?? event?.target?.value ?? '';
        window.clearTimeout(this.searchDebounce);
        console.log('ESTOY EN EL SEARCH INPUT', value); // --- IGNORE ---
        this.searchDebounce = window.setTimeout(() => {
            this.ui_searchText = value;
            this.ui_pageNumber = 1;
        }, 250);
    }


    handleDateRangeChange(event) {
        this.ui_dateRange = event.detail.value;
        this.ui_pageNumber = 1;
        //await this.loadOrders();
    }

    handleChannelChange(event) {
        this.ui_channel = event.detail.value;
        this.ui_pageNumber = 1;
        //await this.loadOrders();
    }

    handleSortChange(event) {
        this.ui_sort = event.detail.value;
        this.ui_pageNumber = 1;
        //await this.loadOrders();
    }

    handleRefresh() {
        this.loadOrders(true);
    }

    handleExport() {
        // Stub: later -> call server export/email
        // Keep UI responsive for now
        // eslint-disable-next-line no-console
    }

    async handlePrevPage() {
        if (this.ui_prevDisabled) {
            return;
        }
        this.ui_pageNumber -= 1;
    }

    async handleNextPage() {
        if (this.ui_nextDisabled) {
            return;
        }
        this.ui_pageNumber += 1;
    }

    async handlePageSizeChange(event) {
        this.ui_pageSize = Number(event.detail.value);
        this.ui_pageNumber = 1;
    }

    handleViewClick(event) {
        event.preventDefault();
        event.stopPropagation();

        const sap = event?.currentTarget?.dataset?.sap;
        if (!sap) {
            return;
        }
        this.ui_selectedSapNumber = sap;
        this.ui_isDetailOpen = true;
    }

    handleCloseDetail() {
        this.ui_isDetailOpen = false;
        this.ui_selectedSapNumber = null;
        this.ui_selectedOrderId = null;
        this.ui_selectedWebOrderNumber = null;
    }

    handleRowClick(event) {
        this.openOrderFromRow(event?.currentTarget?.dataset);
    }

    handleRowKeyDown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.openOrderFromRow(event?.currentTarget?.dataset);
        }
    }

    /* ==================================================
     * DETAIL PANEL (STUBS)
     * ================================================== */
    openOrderFromRow(ds) {
        const sapNumber = ds?.sap;
        const orderId = ds?.orderid || null;
        const webOrderNumber = ds?.web || null;

        console.log('VOy conb ' + sapNumber + ' y ' + orderId); // --- IGNORE ---
        if (!sapNumber && !orderId) {
            this.showToast('This order is still being processed by our system. Please try again shortly.', 'warning');
            return;
        }

        this.ui_selectedSapNumber = sapNumber || null;
        this.ui_selectedOrderId = orderId;
        this.ui_selectedWebOrderNumber = webOrderNumber;
        this.ui_isDetailOpen = true;
        this.ui_selectedEntryChannel = ds?.entry || null;
    }

    /* ==================================================
     * FORMATTERS (simple stubs)
     * ================================================== */
    formatDate(dt) {
        if (!dt) {
            return '';
        }
        try {
            const d = dt instanceof Date ? dt : new Date(dt);
            if (Number.isNaN(d.getTime())) {
                return '';
            }
            return new Intl.DateTimeFormat('en-US', {
                year: 'numeric',
                month: '2-digit',
                day: '2-digit'
            }).format(d);
        } catch {
            return '';
        }
    }

    formatTime(dt) {
        try {
            const d = dt instanceof Date ? dt : new Date(dt);
            return new Intl.DateTimeFormat('en-US', {
                hour: '2-digit',
                minute: '2-digit'
            }).format(d);
        } catch {
            return '';
        }
    }

    formatMoney(amount, currencyCode) {
        if (amount === null || amount === undefined || amount === '') {
            return '';
        }
        try {
            const ccy = currencyCode || 'USD';
            return new Intl.NumberFormat('en-US', {
                style: 'currency',
                currency: ccy
            }).format(Number(amount));
        } catch {
            return String(amount);
        }
    }

    /* ==================================================
     * UTILITIES
     * ================================================== */ 

    showToast(message, variant = 'warning') {
        this.ui_toast = { message, variant };
        setTimeout(() => { this.ui_toast = null; }, 5000);
    }
    computeFromTo(preset) {
        const today = new Date();

        const toISODate = (d) => {
            const year = d.getFullYear();
            const month = String(d.getMonth() + 1).padStart(2, '0');
            const day = String(d.getDate()).padStart(2, '0');
            return `${year}-${month}-${day}`;
        };

        let from;
        let to = new Date(today.getFullYear(), today.getMonth(), today.getDate()); // hoy

        switch (preset) {
            case 'THIS_MONTH':
                from = new Date(today.getFullYear(), today.getMonth(), 1);
                break;

            case 'LAST_6_MONTHS':
                from = new Date(today.getFullYear(), today.getMonth() - 6, today.getDate());
                break;

            case 'LAST_12_MONTHS':
                from = new Date(today.getFullYear(), today.getMonth() - 12, today.getDate());
                break;

            case 'THIS_YEAR':
                from = new Date(today.getFullYear(), 0, 1);
                break;

            case 'LAST_YEAR':
                from = new Date(today.getFullYear() - 1, 0, 1);
                to = new Date(today.getFullYear() - 1, 11, 31);
                break;

            default:
                // LAST_3_MONTHS por defecto
                from = new Date(today.getFullYear(), today.getMonth() - 3, today.getDate());
        }

        return {
            fromDate: toISODate(from),
            toDate: toISODate(to)
        };
    }

}