/* eslint-disable guard-for-in */
/**
 * 
 * OrderEditionModal
 * 
 * Version 1.0.1
 * 
 * Ramón, March 2024
 * 
 * Modal container to display the sales order edit form
 * 
 * Translation Prefix: tr0005
 * 
 * --------
 * API
 * - caseId - Id del caso asociado al pedido
 * - recordId
 * - order: Order data optionally received and returned
 * - orderItems: Llist of items in the order
 * - orderType: {REPLACEMENT}
 * 
 * Use "order" and "orderItems" to pass default values when creating an order.
 * Use "recordId" to pass the Id of the order to edit. In this case, "order" and "orderItems" are ignored.
 * Use "caseId" if the order has to be linked to a case.
 *
 * Debug notes:
 * - Debug support is provided by the libDebug utility library.
 * - The component exposes a read-only public __debug facade.
 * - Use these commands from the browser console after selecting the component in the Elements panel:
 *   1. $0.__debug.enable()
 *   2. $0.__debug.printState()
 *   3. $0.__debug.getState()
 *   4. $0.__debug.getValue('_orderItems')
 * - __debug.enable() stores the debug flag in sessionStorage for the current tab.
 * - __debug.disable() clears both sessionStorage and localStorage debug flags.
 * - When debug is enabled, debugExpose(...) writes snapshots to the browser console using console.debug(...).
 * - You may still reload the page after enabling it if you want to capture startup flows.
 *
 * --------
 * EVENTS
 * - error: Error returned to the parent (message in field 'detail')
 * 
 * --------
 * DESCRIPTION
 * 
 *  orderSettings
 *  Defines the porperties of the order 
 *      - pricesRequired: If true, prices are required
 *      - freeOfCharge: If true, this is a free order
 * 
 */
import { LightningElement, api, wire } from 'lwc';
import { gql, graphql } from 'lightning/uiGraphQLApi';
import OrderHeaderModal from 'c/orderHeaderModal';
import LightningConfirm from 'lightning/confirm';
import getOrderDefaults from '@salesforce/apex/SalesOrdersController.getOrderDefaults';
import saveCaseOrder from '@salesforce/apex/SalesOrdersController.saveCaseOrder';
import deleteCaseOrder from '@salesforce/apex/SalesOrdersController.deleteCaseOrder';
import deleteOrderItems from '@salesforce/apex/SalesOrdersController.deleteOrderItems';
import activateOrder from '@salesforce/apex/SalesOrdersController.activateOrder';
import getPageConstants from '@salesforce/apex/SalesOrdersController.getPageConstants';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { LABELS } from './labels';
import * as LibCommons from 'c/libCommons';
import * as Debug from 'c/libDebug';

const SUPPORTED_ORDER_TYPES = ["REPLACEMENT"];
const REPLACEMENT_SETTINGS = { pricesRequired: false, freeOfCharge: true};
const STATUS_DRAFT = 'Draft';
const STATUS_ACTIVATED = 'Activated';
let ORDER_STATUS = '';    

export default class OrderEditionModal extends LightningElement {
    
    labels = LABELS;

    columns = [
        { label: this.labels.dict_sku, fieldName: 'StockKeepingUnit__c' },
        { label: this.labels.dict_name, fieldName: 'ProductName__c'},
        { label: this.labels.dict_quantity, fieldName: 'Quantity', type: 'number', 
            typeAttributes: {maximumFractionDigits: '2', minimumFractionDigits: '2'}
        },
        { label: this.labels.dict_sales_unit, fieldName: 'SalesUnitName'},    
        { 
            label: this.labels.dict_status, 
            fieldName: '',
            cellAttributes: { iconName: { fieldName: 'deletedIcon' } },
            hideDefaultActions: true,
            hideLabel: true        
        },       
        {
            type: 'action',
            typeAttributes: { rowActions: this.getRowActions }
        }
    ];

    //=======================================================
    // API
    //=======================================================
    @api recordId;    
    @api caseId;

    @api     
        get order() { return this._order; };
        set order(value) {
            this._order = {...value};
        }

    @api     
        get orderItems() { return this._orderItems; };
        set orderItems(value) {
            if (value) {                
                this.setOrderItems(value);
            } 
        }

    @api
        get orderType() {
            return this._orderType;
        }
        set orderType(value) {
            let otype = value.toUpperCase();
            if (SUPPORTED_ORDER_TYPES.includes(otype)) {
                this._orderType = otype;
            }  else {
                const message = this.labels.tr0005_103.replace('{0}',otype); // Wrong order type
                console.error('API ERROR: ' + message);
                this.dispatchEvent(new CustomEvent('error', { message: message }));
            }
        }

    
    //=======================================================
    // Variables
    //=======================================================
    _order;
    _orderItems = [];
    _orderType;
    _orderAux;
    
    orderReady = false;
    isReadingOrder = false;
    orderSettings;
    orderTypeName;
    queryName;
    salesOrgName;
    salesOfficeName;
    pricebookName;
    isLoading = true;
    isSidePanelVisible = false;
    itemId = null;
    accountName;
    messages;
    messagesTheme;
    originalOrderString;
    statusMap = new Map();
    salesUnitsMap = new Map();
    orderTypesMap = new Map();
    currentItem;
    debugText;

    get isEditable() {
        return (this.orderStatus?.toLowerCase() !== STATUS_ACTIVATED.toLowerCase());
    }

    get isDeletable() {
        return (this.isEditable && this.recordId !== null)
    }

    get tableData() {
        return this._orderItems;
    }

    get accountId() {
        return this.order.AccountId;
    }

    get isNewOrder() {
        return (this.recordId === null || this.recordId === undefined);
    }

    get isCollection() {
        return this.order.Type?.startsWith('Z018');
    }

    get formTitle() {        
        let title = '';
        if (this.isNewOrder) {
            title = (this.isCollection ? this.labels.tr0005_017 : this.labels.tr0005_003); // New Order;
        } else {
            title = (this.isCollection ? this.labels.dict_collection : this.labels.dict_order);       
            title += ' #' +  (this.order.OrderNumber ?? '');
        }
        return title;
    }

    get isReplacement() {
        return (this._orderType === "REPLACEMENT");
    }

    get sidePanelClass() {
        return (this.isSidePanelVisible ? "slds-size_medium" : "sidePanelCollapsed");        
    }

    get sidePanelActionsClass() {
        return (this.isSidePanelVisible ? "slds-list_horizontal" : "");
    }
    
    get sidePanelHeaderClass() {
        return (this.isSidePanelVisible ? "slds-panel__header" : "");
    }

    get isSidePanelCollapsed() {
        return !this.isSidePanelVisible;
    }

    get numberOfItems() {
        return this._orderItems?.length ?? 0;
    }

    get orderHasItems() {
        return (this.numberOfItems > 0);
    }

    get salesArea() {
        return '[' + this._order.SalesOrg__c + '-' + this._order.Distribution_channel__c + '] ' + this.salesOrgName; 
    }

    get salesOffice() {
        return '[' + (this._order.SalesOffice__c??'') + '] ' + (this.salesOfficeName??'');
    }

    get orderStatus() {
        return this._order.Status ?? STATUS_DRAFT;
    }

    get orderStatusName() {
        return this.statusMap.get(this.orderStatus);
    }
    get orderRecordTypeId() {
        return this._order?.RecordTypeId??null;
    }

    get sapIdString() {
        let result = '--';
        if (this._order?.Status?.toLowerCase() === STATUS_ACTIVATED.toLowerCase()) {
            result = (this._order.Sap_Id__c ?? this.labels.tr0005_013); // In Queue
        }
        return result;
    }

    @api
    get __debug() {
        return Debug.getFacade(this);
    }

    /*
    get orderCurrency() {
        return this._order?.CurrencyIsoCode ?? '';
    }
    */

    //=======================================================
    // Events
    //=======================================================
    connectedCallback() {        
        // Validate required API properties
        if (this.isNewOrder) {
            this.isLoading = false;
            if (this.validateComponentAPI()) {
                this.orderReady = true;
                this.loadPageConstants();                
                this.loadNewOrderFields();                
                this.takeOrderSnapshot();
                this.editHeader(true);
            }
        }        
    }

    renderedCallback() {        
        // I use the rendered because the graphQL section needs to be loaded
        // Read the order from database when it is not new and it has not been read
        if (!this.isNewOrder  && !(this.orderReady || this.isReadingOrder)) {            
            this.isReadingOrder = true;
            this.readOrder();
        }        
    }

    handleHeaderClick() {
        this.editHeader(false);
    }  
    
    handleCancelClick() {
        this.cancelEdition();
    }

    handleSaveClick() {
        this.launchSaveOrder();
    }

    handleClosePanelClick() {
        this.isSidePanelVisible = false;
    }

    handleOpenPanelClick() {
        this.isSidePanelVisible = true;
    }

    handleAddItemClick() {
        this.isSidePanelVisible = true;
    }

    handleItemFormClose() {
        this.isSidePanelVisible = false;
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'delete':
                this.deleteItem(row);
                break;
            case 'undelete':
                this.undeleteItem(row);
                break;    
            case 'edit':
                this.editItem(row);
                break;
            case 'view':
                this.viewItem(row);
                break;
    
            default:
        }
    }

    async handleDeleteOrderClick(event) {
        if (this.isEditable) {
            const result = await LibCommons.showConfirmationDialog(this.labels.tr0005_025, 'warning');
            if (result) {
                this.deleteOrder();
            }
        }
    }

    //=======================================================
    // Header
    //=======================================================

    async editHeader(firstTime) {
        if (!this._order.Id && !this._order.RecordTypeId) {
            this.isLoading = true;
            try {
                const defaults = await getOrderDefaults({order: this._order});
                if (defaults) {   
                    this._order.RecordTypeId = defaults.defaultRecordType;
                    this._order.Pricebook2Id = defaults.pricebookId;
                    this.takeOrderSnapshot();
                } 
                this.isLoading = false;
            } catch (ex) {
                console.error('==> [orderEditionModal] Error in editHeader: ' + JSON.stringify(ex));
                let errorMessage = ex.body?.message;
                if (LibCommons.isBlank(errorMessage)) {
                    errorMessage = this.labels.tr0005_104;
                }
                this.isLoading = false;
                this.showFatalError(errorMessage); // Error: Unable to read the default values for the order
                return;
            }
        }
        this.isLoading = false;
        const result = await OrderHeaderModal.open({
            size: 'large',
            order: this._order
        });
        if (result?.success) {
            this._order = result.data;            
        } else if (result?.data) {
            this.showFatalError(result.data);
        }  else {
            if (firstTime) {
                this.handleCancelClick();
            }
        }      
        this.isLoading = false;
    }    

    handleOrderQuery(event) {  
        this.debugExpose('handleOrderQuery.start', {
            success: event.detail?.success,
            rawOrderItems: event.detail?.data?.subqueries?.OrderItems
        });

        if (!this.orderReady) {
            this.isReadingOrder = false;
            this.isLoading = false;
            if (event.detail.success) {
                this.orderReady = true;
                this._order = event.detail.data.record;                 
                this._orderAux = event.detail.data.displayValues;  
                this._order.CreatedByName = event.detail.data.relations.CreatedBy?.record?.Name;
                this._order.LastModifiedByName = event.detail.data.relations.LastModifiedBy?.record?.Name;
                ORDER_STATUS = this._order.Status;
                this.setOrderItems(event.detail.data.subqueries.OrderItems);
                this.configureOrder();
                this.loadNewOrderFields();
                this.takeOrderSnapshot();
                this.setInitialMessages();
            } else { 
                this.messages = event.detail.data;
                this.messagesTheme = 'error';
            }
        }

        this.debugExpose('handleOrderQuery.end');
    }

    handleConfirmOrder() {
        this.sendOrderToSAP();
    }

    //========================================================
    // Item form methods
    //========================================================
    handleItemAdded(event) {
        const data = event.detail.fields;
        this.addItemToOrder(data);
    }

    handleItemModified(event) {        
        const data = event.detail.fields;
        this.modifyItemAt(this.currentItem.index, data);
    }


    //========================================================
    // Methods
    //========================================================

    getRowActions(row, doneCallback) {
        const actions = [];
        if (ORDER_STATUS?.toLocaleLowerCase() !== STATUS_ACTIVATED.toLowerCase()) {
            if (row['deleted']) {
                actions.push({
                    'label': LABELS.dict_undelete,
                    'name': 'undelete'
                });
            } else {
                actions.push({
                    'label': LABELS.dict_edit,
                    'name': 'edit'
                });    
                actions.push({
                    'label': LABELS.dict_delete,
                    'name': 'delete'
                });
            }
        } else {
            actions.push({
                'label': LABELS.dict_view,
                'name': 'view'
            }); 
        }
        doneCallback(actions);
    }

    takeOrderSnapshot() {
        this.originalOrderString = this.getOrderString();
    }

    async readOrder() {
        await this.loadPageConstants();
        const helper = this.template.querySelector('[data-id = "LibOrderQuery"]');
        if (helper) {
            helper.queryOrder(this.recordId);
        }
    }

    setInitialMessages() {
        this.messages = new Array();
        if (!this.isNewOrder && this.orderStatus?.toLocaleLowerCase() === 'draft') {
            this.messages.push(this.labels.tr0005_105); // Order is in draft status. Activate it to submit to SAP.
            this.messagesTheme = 'warning';
        } else if (this.orderStatus?.toLocaleLowerCase() === STATUS_ACTIVATED.toLowerCase()) {
            if (this._order.Sap_Id__c === null) {
                this.messages.push(this.labels.tr0005_106); // This order is read-only as it’s been sent to SAP. Check SAP for updates.
                this.messagesTheme = 'warning';
            } else {
                this.messages.push(this.labels.tr0005_107); // This order is read-only. It has been sent to SAP for processing.
                this.messagesTheme = 'warning';
            }
        }
    }

    addItemToOrder(item) {
       const items = new Array();
       items.push(item);
       this.addItemsToOrder(items);
    }

    modifyItemAt(index, item) {
        item.index = index;
        item.deleted = false;
        item.deletedIcon = '';
        item.SalesUnitName = this.salesUnitsMap.get(item.SalesUnit__c) ?? item.SalesUnit__c;
        this._orderItems[index-1] = item;        
        this._orderItems = [...this._orderItems];
    }

    setOrderItems(items) {
        this._orderItems = [];
        this.addItemsToOrder(items);
    }

    addItemsToOrder(items) {
        for (let i = 0; i < items.length; i++) {
            const item = this.normalizeOrderItem(items[i]);
            item.index = this._orderItems.length + 1;
            item.deleted = false;
            item.deletedIcon = '';
            //alert("Name es " + this.salesUnitsMap.get(item.SalesUnit__c));
            item.SalesUnitName = this.salesUnitsMap.get(item.SalesUnit__c) ?? item.SalesUnit__c;
            this._orderItems.push(item);        
        }
        this._orderItems = [...this._orderItems];
        this.debugExpose('addItemsToOrder', {
            normalizedItems: this._orderItems
        });
    }

    deleteItem(item) {
        this._orderItems[item.index - 1].deleted = true;
        this._orderItems[item.index - 1].deletedIcon = 'utility:delete';
        this._orderItems = [...this._orderItems];
    }

    undeleteItem(item) {
        this._orderItems[item.index - 1].deleted = false;
        this._orderItems[item.index - 1].deletedIcon = '';
        this._orderItems = [...this._orderItems];
    }

    editItem(item) {        
        this.currentItem = item;
        this.isSidePanelVisible = true;
    }

    viewItem(item) {
        this.currentItem = item;
        this.isSidePanelVisible = true;
    }

    validateComponentAPI() {
        if (!this._orderType) {
            this.dispatchEvent(new CustomEvent("error", { detail: this.labels.tr0005_108})); // Order Type not defined
            return false;
        }
        return true;
    }

    configureOrder() {
        this.orderSettings = {};
        if (this.isReplacement) {            
            this.orderTypeName = this.orderTypesMap?.get(this._order.Type);
            this.orderSettings = REPLACEMENT_SETTINGS;
        }
    }

    loadNewOrderFields() {
        this.queryName = 'BackofficeQuery';
    }

    showFatalError(errorMessage) {
        LibCommons.showErrorToast(errorMessage, true);
        this.dispatchEvent(new CustomEvent('close', {}));
    }

    /*
     * Builds a string with the relevant order fields. The string is used to take a snapshot
     * of the order and to compare it with another one to detect if the object has changed.
     */
    getOrderString() {
        const sep = '-';
        let str = this._order.Pricebook2Id;
        str += sep + this._order.PONumber;
        str += sep + this._order.AccountId;
        str += sep + this._order.PONumber;
        str += sep + this._order.SalesOffice__c;
        str += sep + this._order.SalesOrg__c;
        str += sep + this._order.Distribution_channel__c;
        str += sep + this._order.NBK_Contact_Point_Address__c;
        str += sep + this._order.EffectiveDate;
        str += sep + this._order.Type;
        str += sep + this._order.DeliveryDate__c;
        str += sep + this.numberOfItems;
        str += sep + this._order.NB2B_Delivery_Method__c;
        str += sep + this._order.Autopick__c;
        str += sep + this._order.TotalAmount;
        for (let i = 0; i<this.numberOfItems; i++) {
            const item = this._orderItems[i];
            str += sep + item.Product2Id;
            str += sep + item.Quantity;
            str += sep + item.UnitPrice;
        }
        return str;
    }

    async cancelEdition() {
        const currentOrderString = this.getOrderString();
        let quit = true;
        if (currentOrderString !== this.originalOrderString) {
            quit = await this.confirmCancel();
        }
        if (quit) {
            this.dispatchEvent(new CustomEvent('cancel'));
        }
    }

    async confirmCancel() {
        const result = await LightningConfirm.open({
            message: this.labels.tr0005_109, // 'Discard changes and exit the order?',
            variant: 'header',
            label: this.labels.dict_warning,
            theme: 'warning'
        });
        return result;
    }

    async confirmSave() {
        /*
        let message = 'Do you want to save the order?';
        if (this._orderItems?.length === 0) {
            message = 'The order has no items. Would you still like to save it?';        
        }        
        const result = await LightningConfirm.open({
            message: message,
            variant: 'header',
            label: 'Warning',
            theme: 'warning'            
        });
        return result;
        */
       return true;
    }

    async launchSaveOrder() {
        if (await this.confirmSave()) {
            this.isLoading = true;
            if (await this.saveOrder()) {
                this.dispatchEvent(new CustomEvent('close', { detail: { success: true, order: this._order, items: this._orderItems } }));
            }
            this.isLoading = false;
        }
    }

    async saveOrder() {
        let success = true;        
        try {
            const itemsToDelete = this.extractItemsToDelete();
            if (itemsToDelete.length > 0) {
                await this.deleteItems(itemsToDelete);
            }
            console.info('=========================================================================================');
            console.info('Saving order for case ' + this.caseId);
            console.info('Order is:');
            console.info('JSON.stringify(this._order');
            console.info('JSON.stringify(this._orderItems');
            console.info('=========================================================================================');
            const result = await saveCaseOrder({ caseId: this.caseId, order: this._order, items: this._orderItems });
            if (result) {
                this._order = result.order;
                this.setOrderItems(result.items);
                let changed = [];                
                changed.push({recordId: this._order.Id});
                changed.push({recordId: this.caseId});
                notifyRecordUpdateAvailable(changed);
                this.configureOrder();
                this.takeOrderSnapshot();
                this.setInitialMessages();                
            }
        } catch(ex) {  
            success = false;
            console.error('**************************************************************');
            console.error('*** OrderEditionModal.saveOrder Error ' + ex);
            console.error('*** JSON(ex): ' + JSON.stringify(ex));
            console.error('**************************************************************');
            this.messages = ex;
            this.messagesTheme = 'error';
        }
        return success;
    }    

    async deleteItems(itemsToDelete) {
        await deleteOrderItems({items: itemsToDelete});
    }

    async deleteOrder() {
        let success = true;  
        this.isLoading = true;
        try {
            console.info('=========================================================================================');
            console.info('Deleting order for case ' + this.caseId);
            console.info('Order Id is: ' + this._order.Id);
            console.info('=========================================================================================');
            const result = await deleteCaseOrder({ caseId: this.caseId, orderId: this._order.Id });
            if (result) {
                this.isLoading = false;
                let changed = [];                
                changed.push({recordId: this._order.Id});
                changed.push({recordId: this.caseId});
                notifyRecordUpdateAvailable(changed);
                this.dispatchEvent(new CustomEvent('delete', { detail: { success: true, orderId: this._order.Id }}));  
            }
        } catch(ex) {  
            this.isLoading = false;
            success = false;
            console.error('**************************************************************');
            console.error('*** OrderEditionModal.deleteOrder Error ' + ex);
            console.error('*** JSON(ex): ' + JSON.stringify(ex));
            console.error('**************************************************************');
            this.messages = ex;
            this.messagesTheme = 'error';
        }
        return success;
    }


    async confirmSAP() {
        let message = this.labels.tr0005_110; // Activating the order will lock it. Further changes must be made in SAP. Proceed?
        const result = await LightningConfirm.open({
            message: message,
            variant: 'header',
            label: this.labels.tr0005_111, // Order Activation
            theme: 'warning'            
        });
        return result;
    }

    async sendOrderToSAP() {
        if (this._orderItems?.length === 0) {
            this.messages = this.labels.tr0005_112; //The order cannot be activated as it has no items.
            this.messagesTheme = "warning";
            return;
        }
        if (await this.confirmSAP()) {
            try {            
                this.isLoading = true;
                await this.saveOrder();
                await activateOrder({ orderId: this._order.Id });                  
                this._order.Status = STATUS_ACTIVATED;            
                notifyRecordUpdateAvailable([{recordId: this._order.Id}]);   
                this.configureOrder();
                this.takeOrderSnapshot();
                this.setInitialMessages();   
                this.dispatchEvent(new CustomEvent('close', { detail: { success: true, order: this._order, items: this._orderItems } }));                  
                const event = new ShowToastEvent({
                    message: this.labels.tr0005_113, // The order has been activated and will be processed by SAP shortly.
                    variant: 'success'
                });
                this.dispatchEvent(event);                 
            } catch(ex) {  
                console.error('===> OrderEditionModal.sendOrderToSAO Error');
                console.error(JSON.stringify(ex));
                this.messages = ex;
                this.messagesTheme = 'error';
            } finally {
                this.isLoading = false;
            }
        }
    }

    async loadPageConstants() {
        try {
            const pageDefaults = await getPageConstants();
            this.salesUnitsMap = this.convertFromApexMap(pageDefaults.unitsMap);
            this.statusMap = this.convertFromApexMap(pageDefaults.statusMap);
            this.orderTypesMap = this.convertFromApexMap(pageDefaults.orderTypesMap);
            this.configureOrder();
        } catch(error) {
            console.error('==> [orderEditionModal] Error reading page constants: ' + error);
            console.error('--> ' + JSON.stringify(error));
        }
    }

    extractItemsToDelete() {        
        const toDelete = new Array();
        const toSave = new Array();
        for (const item of this._orderItems) {
            if (item.deleted) {
                if (item.Id != null) {
                    toDelete.push(item);
                }
            } else {
                toSave.push(item);
            }
        }
        this._orderItems = [...toSave];
        return toDelete;
    }

    convertFromApexMap(apexMap) {
        let newMap = new Map();
        for (const key in apexMap) {         
            newMap.set(key, apexMap[key]);
        }
        return newMap;
    }

    normalizeOrderItem(item) {
        const rawItem = item?.record ? item.record : item;
        return { ...rawItem };
    }

    debugExpose(label, extra = {}) {
        Debug.debugExpose(this, label, extra);
    }

    //=======================================================
    // GraphQL
    //=======================================================
    @wire(graphql, {
        query: gql`       
            query BackofficeQuery($accountId: ID!, $salesOffice: String, $salesOrg: String, $pricebookId: ID) {
                uiapi {
                    query {
                        Account(where: { Id: { eq:  $accountId} }) {
                            edges {
                                node {
                                    Name { value }
                                }
                            }
                        }
                    }
                    query {
                        Master_relations__c(where: { SalesOffice_code__c: { eq: $salesOffice } }) { 
                            edges {
                                node {
                                    SalesOffice_name__c { value }
                                }
                            }
                        }
                    }
                    query {
                        Sales_Org__c(where: { SalesOrg__c: { eq: $salesOrg }})
                        {
                            edges {
                                node {
                                    Name { value }
                                }
                            }
                        }
                    }
                    query {
                        Pricebook2(where: { Id: { eq: $pricebookId }}) 
                        {
                            edges {
                                node {
                                    Name {value }
                                }
                            }
                        }
                    }
                }
            }                        
            `,
            variables: '$graphVariables',
            operationName: '$queryName'
        }) graphqlQueryResult({ data, errors }) {
            //(where: { Ordernum__c: { eq: $invoiceNumber } }) {
            if (data) {
                if (data !== undefined) {
                    if (data.uiapi.query.Account !== undefined) {
                        const results = data.uiapi.query.Account.edges.map(edge => edge.node);
                        if (results.length > 0) {
                            this.accountName = results[0].Name.value;
                        } 
                    } 
                    if (data.uiapi.query.Sales_Org__c!== undefined) {
                        const results = data.uiapi.query.Sales_Org__c.edges.map(edge => edge.node);
                        if (results.length > 0) {
                            this.salesOrgName = results[0].Name.value;
                        } 
                    }
                    if (data.uiapi.query.Master_relations__c !== undefined) {
                        const results = data.uiapi.query.Master_relations__c.edges.map(edge => edge.node);
                        if (results.length > 0) {
                            this.salesOfficeName = results[0].SalesOffice_name__c.value;
                        }
                    }
                    if (data.uiapi.query.Pricebook2 !== undefined) {
                        const results = data.uiapi.query.Pricebook2.edges.map(edge => edge.node);
                        if (results.length > 0) {
                            this.pricebookName = results[0].Name.value;
                        }
                    }

                } 
            } 
            if (errors) {
                alert("GRAPHQL error");
                console.error("> GRAPH-QL ERRORS IN OrderEditionModal.js");
                console.error(">  " + JSON.stringify(errors));
            }
            this.errors = errors;
        }

    get graphVariables() {
        return {    
            queryName: this.queryName, 
            salesOrg: this._order.SalesOrg__c ?? null,
            salesOffice: this._order.SalesOffice__c ?? null,
            accountId: this._order.AccountId ?? null,
            pricebookId: this._order.Pricebook2Id ?? null
        };
    }

    
}