import {  api, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import { getRecord } from 'lightning/uiRecordApi';
import { gql, graphql } from 'lightning/uiGraphQLApi';
import USER_ID from '@salesforce/user/Id';
import USER_NAME from '@salesforce/schema/User.Name';
import USER_DEFAULT_SORG from '@salesforce/schema/User.Default_Sales_Organization__c';
import USER_SORGS from '@salesforce/schema/User.Sales_Org__c';
import readInvoices from '@salesforce/apex/SAPInvoiceSearchController.readInvoices';
import { LABELS } from './labels';


export default class SapInvoiceSearch extends LightningModal {

    labels = LABELS;

    invoiceColumns = [
        { label: this.labels.dict_invoice, fieldName: 'Ordernum__c', sortable: true },
        { label: this.labels.dict_date, fieldName: 'Orderdate__c', type: 'date', sortable: true },
        { label: this.labels.dict_customer, fieldName: 'accountName', sortable: true },
        { label: this.labels.dict_currency, fieldName: 'Dcurr__c' },
        { label: this.labels.dict_net, fieldName: 'Dnet__c', type: 'number',
            typeAttributes: { minimumFractionDigits: '2', maximumFractionDigits: '2'},
        },
        /*
        { label: 'Tax', fieldName: 'Dtax__c', type: 'number',
            typeAttributes: { minimumFractionDigits: '2', maximumFractionDigits: '2'},
        },
        */
        { label: this.labels.dict_total, fieldName: 'Dtotal__c', type: 'number', sortable: true,
            typeAttributes: { minimumFractionDigits: '2', maximumFractionDigits: '2'},
        },
        { label: this.labels.dict_distChannel, fieldName: 'Distchannel__c' },
        { label: this.labels.dict_order, fieldName: 'orderNumber' }
    ];

    
    errors = [];
    showSpinner = true;
    userId = USER_ID;
    allSalesOrgs = [];
    user = {};
    invoices = [];
    invoiceLinesMap = new Map();
    currentInvoice = {};
    currentLines = [];
    salesUnitsMap = new Map();
    defaults = {
        salesOrg: ''
    }
    tableSortedBy;
    tableSortedDirection;

    componentData = {
        salesOrgs: []
    };

    searchFields = {};
    showDetail = false;
    showSearchResults = false;

    defaultTimeframe = 'LAST_90_DAYS';

    get timeframeOptions() {
        return [
            { label: this.labels.tr0010_004, value: '' }, // No Restriction
            { label: this.labels.tr0010_005, value: 'THIS_MONTH' }, // This Month
            { label: this.labels.tr0010_006, value: 'LAST_MONTH' }, // Last Month
            { label: this.labels.tr0010_007, value: 'LAST_90_DAYS' }, // Last 90 Days
            { label: this.labels.tr0010_008, value: 'THIS_YEAR' }, // This Year
            { label: this.labels.tr0010_009, value: 'LAST_YEAR' }, // Last Year
            { label: this.labels.tr0010_010, value: 'LAST_N_YEARS:2' }, // Last 2 Years
        ];
    }

    get numberOfResults() {
        let text = this.labels.tr0009_032; // No results found for your search. Please check your criteria and try again
        if (this.invoices?.length > 0) {
            text = this.labels.tr0009_033.replace('{number}', this.invoices.length); // n SAP Invoice(s) found matching your search.  
        }
        return text;
    }

    get showTable() {
        return (this.invoices?.length > 0 ?? false);
    }

    get okDisabled() {
        return !(this.currentInvoice?.Ordernum__c !== undefined);
    }

    get accountMatchingInfo() {
        return {
            primaryField: { fieldPath: 'Name' },
            additionalFields: [{ fieldPath: 'SAP_Id__c' }],
        }
    }
    
    get productMatchingInfo() {
        return {
            primaryField: { fieldPath: 'Name' },
            additionalFields: [{ fieldPath: 'StockKeepingUnit' }],
        }
    }

    get productDisplayInfo() {
        return {
            primaryField: 'Name',
            additionalFields: ['StockKeepingUnit']
        }
    }

    get productFilter() {   
        return {
            criteria: [
                {
                    fieldPath: 'IsActive',
                    operator: 'eq',
                    value: true
                }
            ]
        }
    }

    //================================================
    // METHODS
    //================================================
    initializeComponent() {
        if ((this.user?.Id) && this.allSalesOrgs.length > 0) {
            this.setUSerSalesOrgs();
            this.setDefaults();
            this.showSpinner = false;
        }
    }

    setUSerSalesOrgs() {
        const userSalesOrgs = this.user.SalesOrgs.split(';');
        this.componentData.salesOrgs = [];        
        for (const salesOrg of this.allSalesOrgs) {
            if (userSalesOrgs.includes(salesOrg.SAPCode)) {
                this.componentData.salesOrgs.push({label: salesOrg.Name, value: salesOrg.SAPCode});
            }
        }
    }

    setDefaults() {
        this.defaults.salesOrg = this.user.DefaultSalesOrg;
    }

    searchInvoices() {
        this.readSearchCriteria();
        if (this.validateSearchCriteria()) {
            this.readInvoices();
        }
    }

    readSearchCriteria() {
        this.searchFields.salesOrg = this.template.querySelector('[data-id="SalesOrg"]').value;
        this.searchFields.accountId = (this.template.querySelector('[data-id="Account"]').value ?? null);
        this.searchFields.productId = (this.template.querySelector('[data-id="Product"]').value ?? null);
        this.searchFields.orderNumber = (this.template.querySelector('[data-id="OrderNumber"]').value ?? null);
        this.searchFields.timeframe = (this.template.querySelector('[data-id="timeframe"]').value ?? null);        
    }

    validateSearchCriteria() {
        this.errors = [];
        let isValid = true;
        if (this.isEmpty(this.searchFields.accountId) && this.isEmpty(this.searchFields.orderNumber)) {
            isValid = false;
            this.errors.push(this.labels.tr0010_001); // Account or Order Number are required');
        } else {
            isValid = this.template.querySelector('[data-id="Account"]').checkValidity();
            isValid = isValid &&  this.template.querySelector('[data-id="Product"]').checkValidity();
            isValid = isValid &&  this.template.querySelector('[data-id="OrderNumber"]').checkValidity();
        }
        return isValid;        
    }

    sortBy(field, reverse) {
        const key = function (x) {
            return x[field];
        };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    formatNumber(number) {
        return number.toLocaleString(undefined, {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2,
        });
    }

    translateUnit(key) {
        return (this.salesUnitsMap[key] ?? key);
    }

    //================================================
    // ACCESS TO APEX CONTROLLERS
    //================================================    
    async readInvoices() {
        this.showDetail = false;        
        this.invoices = [];
        this.currentInvoice = {};
        this.currentLines = [];
        this.showSpinner = true;
        try {
            const searchResults = await readInvoices({searchCriteria: this.searchFields});
            this.showSearchResults = true;
            this.salesUnitsMap = searchResults.unitsMap;
            this.invoices = [...searchResults.invoices];
            this.invoiceLinesMap = searchResults.invoiceLines;
            for (const invoice of this.invoices) {
                const items = this.invoiceLinesMap[invoice.Ordernum__c];
                invoice.accountName = invoice.Account__r?.Name ?? this.labels.tr0009_034; // Customer not mapped
                invoice.orderNumber = (items.length > 0) ? items[0].aubel__c : '';  
            }  
            this.tableSortedBy = 'Orderdate__c';
            this.tableSortedDirection = 'desc';            
            this.showSpinner = false;            
        } catch(error) {
            this.showSpinner = false;
            this.showSearchResults = false;
            console.log('--> [sapInvoiceSearch.readInvoices] Error reading invoices: ' + error);
            console.log('--> ' + JSON.stringify(error));
            this.errors = error;
        } 
    }    
    
    //================================================
    // EVENT HANDLERS
    //================================================
    handleSearch() {
        this.searchInvoices();
    }
        
    handleColumnSorting2(event) {
        var fieldName = event.detail.fieldName;
        var sortDirection = event.detail.sortDirection;
        // assign the latest attribute with the sorted column fieldName and sorted direction
        this.tableSortedBy = fieldName;
        this.tableSortedDirection = sortDirection;
        this.invoices = this.sortInvoices(fieldName, sortDirection);
    }
    
    handleColumnSorting(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.invoices];
        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.invoices = cloneData;
        this.tableSortedDirection = sortDirection;
        this.tableSortedBy = sortedBy;
    }

    handleRowSelection(event) {
        this.currentInvoice = event.detail?.selectedRows[0];
        if (this.currentInvoice !== null) {
            // Copy the array and add a new field to each row
            this.currentLines = this.invoiceLinesMap[this.currentInvoice.Ordernum__c].map(row => ({
                ...row, // Copy existing fields
                skuString: `${this.labels.dict_sku}: ${row.Sku__c} ${row.aubel__c !== null ? "· " + this.labels.dict_order + ": " + row.aubel__c + "-" + row.aupos__c?.replace(/^0+/, ''): ""}`, 
                amountString: `${this.labels.dict_net_amount}: ${this.formatNumber(row.Dnet__c)} ${row.Dcurr__c}`, 
                quantityString: `${this.formatNumber(row.Quantity__c)} ${this.translateUnit(row.Vrkme__c)}`                                
            }));
            this.showDetail = true;
        }        
    }

    handleSidePanelClosed() {
        this.showDetail = false;
        this.currentInvoice = {};
        this.currentLines = [];
        const dtable = this.template.querySelector('[data-id="invoices-list"]');
        if (dtable) {
            dtable.selectedRows = [];
        }
    }

    handleOKClick() {
        this.close(this.currentInvoice?.Ordernum__c);
    }

    handleCancelClick() {
        this.close();
    }

    isEmpty(value) {
        return value === null || value === undefined || (typeof value === 'string' && value.trim() === '');
    }


    //================================================
    // WIRED INFO
    //================================================
    @wire(getRecord, { recordId: '$userId', fields: [USER_NAME, USER_DEFAULT_SORG, USER_SORGS] })
        userRecord({ error, data }) {
            if (data) {
                this.user.Id = this.userId;
                this.user.Name = data.fields.Name.value;
                this.user.DefaultSalesOrg = data.fields.Default_Sales_Organization__c.value;
                this.user.SalesOrgs = data.fields.Sales_Org__c.value;
                this.initializeComponent();
            } else if (error) {
                console.error('Error retrieving user record:', error);
            }
        }

        @wire(graphql, {
            query: gql`
                query AllSalesOrgs {
                    uiapi {
                        query {
                            Sales_Org__c (orderBy: { SalesOrg__c: { order: ASC }}, first: 2000) {
                                edges {
                                    node {
                                        Id
                                        Name { value }
                                        SalesOrg__c { value }
                                    }
                                }
                            }
                        }
                    }
                }
            `,
            })
            graphqlQueryResult({ data, errors }) {
                if (data) {
                    this.allSalesOrgs = data.uiapi.query.Sales_Org__c.edges.map((edge) => ({
                        Id: edge.node.Id,
                        Name: edge.node.Name.value,
                        SAPCode: edge.node.SalesOrg__c.value
                    }));
                    this.initializeComponent();
                }
                if (errors) {
                    alert("GRAPHQL error");
                    console.log("> GRAPH-QL Errors " + JSON.stringify(errors));
                }
            }

}