/**
 * 
 * OrderItemForm
 * 
 * Form to add/edit items to an order
 * 
 * Translation prefix: tr0005
 * 
 * Ramón, May 2024
 *  
 * --------
 * API
 * - recordId
 * - order
 * - orderSettings (pricesRequired, isFreeOfCharge)
 * 
 * EVENTS
 * - itemadded
 * - itemchanged
 * - close
 */
import { LightningElement, api, wire } from 'lwc';
import { gql, graphql } from 'lightning/uiGraphQLApi';
import { LABELS } from './labels.js';

const STATUS_ACTIVATE = 'activated';

export default class OrderItemForm extends LightningElement {

    labels = LABELS;
    /*-----------------------------------------------------*/
    /*              COMPONENT API DEFINITION               */
    /*-----------------------------------------------------*/    
    @api recordId;         // Item record Id    
    @api order;             // Order data
    @api orderSettings;

    @api 
        get orderItem() {
            return this._orderItem;
        }
        set orderItem(value) {
            console.info('=================================================');
            console.info('> OrderItemForm.orderItem (API): ' + JSON.stringify(value));
            console.info('=================================================');
            this._orderItem = value;
            if (value != null && value != undefined) {
                this.productSelected(this._orderItem?.PricebookEntryId);
            }
        }            
    /* =================================================== */

    _orderItem = null;
    showSpinner = false;
    productData = {}; 
    priceData = {}; 
    closeForm = false;      
    pricebookEntryId; 
    pricebookId;
    queryName;

    item = {};

    get isNewItem() {
        return (this.recordId == null && this._orderItem == null);
    }

    get isReadonly() {
        return (this.order.Status?.toLowerCase() === STATUS_ACTIVATE);
    }

    get isEditable() {
        return !this.isReadonly;    
    }

    get isProductReady() {
        return (this.productData?.Id != null);
    }

    get orderCurrency() {
        return this.order?.CurrencyIsoCode ?? '';
    }

    get weightString() {
        return this.productData.UnitWeight__c + ' ' + this.productData.Umb__c;
    }

    get isNotFreeOfCharge() {
        return !this.orderSettings.freeOfCharge;
    }

    get strListPrice() {
        return new Intl.NumberFormat().format(this.item.ListPrice ?? 0) + ' ' + this.orderCurrency + '/' + this.item.ListPriceUnitCode__c; 
    }

    get addButtonLabel() {
        if (this.isNewItem) {
            return this.labels.dict_add;
        } else {
            return this.labels.dict_save;
        } 
    }

    get formTitle() {
        if (this.isEditable) {
            return this.isNewItem ? this.labels.tr0005_200 : this.labels.tr0005_201; // 'New Item' : 'Edit Item'
        } else {
            return this.labels.tr0005_202; // View Item
        } 
    }

    errorList = [];
    errorTheme = 'error';

    /*-----------------------------------------------------*/
    /*                     METHODS                         */
    /*-----------------------------------------------------*/  
    
    renderedCallback() {
        //if (this.isProductReady) {
        //    this.setItemDefaults();
        //}
    }
    
    setItemValues() {   
        console.log('===> Entro en el setItemValues');
        if (this.isNewItem) {
            this.item = {};
            this.item.UnitPrice = this.priceData.UnitPrice;    
            this.item.OrderId = this.order.Id;
            this.item.PricebookEntryId = this.pricebookEntryId;
            this.item.Product2Id = this.productData.Id;
            this.item.ProductCode__c = this.productData.ProductCode;
            this.item.ProductName__c = this.productData.Name;
            this.item.Quantity = 0;
            this.item.SalesUnit__c = this.productData.SalesUnit__c;
            this.item.NB2B_Shade__c = '';
            this.item.StockKeepingUnit__c = this.productData.StockKeepingUnit;
            this.item.ListPrice = this.priceData.UnitPrice;
            this.item.ListPriceUnitCode__c = this.priceData.UnitPriceUnitCode__c ?? this.item.SalesUnit__c;
            this.item.UnitPrice = this.priceData.UnitPrice;
            this.item.UnitPriceUnitCode__c = this.priceData.UnitPriceUnitCode__c ?? this.item.SalesUnit__c;
        } else {
            console.log('==> Voy por el else con ' + JSON.stringify(this.item));
            console.log('==> Voy por el else con priceData  ' + JSON.stringify(this.priceData));
            if (this.item.PricebookEntryId === null || this.item.PricebookEntryId === undefined) {
                this.item.PricebookEntryId = this.priceData.Id
                this.item.ListPrice = this.priceData.UnitPrice ?? 0;                
                this.item.ListPriceUnitCode__c = this.priceData.UnitPriceUnitCode__c ?? this.item.SalesUnit__c;
                this.item.UnitPrice = this.priceData.UnitPrice ?? 0;
                this.item.UnitPriceUnitCode__c = this.priceData.UnitPriceUnitCode__c ?? this.item.SalesUnit__c;
                const control = this.refs.PricebookEntryId;    
                if (control) {
                    control.value = this.PricebookEntryId;
                }
            }
            this.item = {...this._orderItem};
        }
    }

    /**
     * Checks all required fields have a value
     */
    checkFieldsValidity() {
        this.errorList = [];
        const allValid = [...this.template.querySelectorAll('lightning-input-field')].reduce((validSoFar, inputCmp) => {
            let fieldOK = true;        
            if (inputCmp.fieldName?.toLowerCase() === 'quantity') {            
                if (inputCmp.value <= 0) {
                    this.errorList.push(this.labels.tr0005_203); // The ordered quantity must be greater than zero
                    fieldOK = false;
                } 
            }
            inputCmp.reportValidity();
            return validSoFar && fieldOK;
        }, true);
        return allValid;
    }

    /*-----------------------------------------------------*/
    /*                   EVENT HANDLERS                    */
    /*-----------------------------------------------------*/    

    handleProductSelect(event) { 
        this.productSelected(event.detail.Id);
    }    

    productSelected(entryId) {
        this.pricebookEntryId = entryId;
        if (this.pricebookEntryId !== null && this.pricebookEntryId !== undefined) {
            this.showSpinner = true;
            this.queryName = 'PricebookEntryQuery';
        } else {
            this.showSpinner = true;
            this.pricebookId = this.order.Pricebook2Id;
            this.productId = this._orderItem.Product2Id;
            this.queryName = 'SearchEntry';            
        }
    }

    handleProductReset() {
        this.priceData = {};
        this.productData = {};
    }

    handleFormClose() {
        this.dispatchEvent(new CustomEvent("close"));
    }

    handleSubmit(event){
        event.preventDefault();       // stop the form from submitting
        if (this.checkFieldsValidity()) {
            const fields = event.detail.fields;             
            fields.StockKeepingUnit__c = this.productData.StockKeepingUnit;
            let eventName = 'itemadded';
            if (!this.isNewItem) {
                fields.Id = this._orderItem.Id;
                this.closeForm = true;
                eventName = 'itemmodified';
            }
            this.returnItem(eventName, fields);
        }
    }

    returnItem(eventName, fields) {    
        console.log("===> Voya  devolver en el submit: " + JSON.stringify(fields));
        const data = {};
        fields.ProductName__c = this.productData.Name;
        data.fields = fields;
        this.dispatchEvent(new CustomEvent(eventName, { detail: data }));
        if (this.closeForm) {
            this.handleFormClose();
        } else {
            this.resetItem();
        }
    }    
    
    resetItem() {
        this.productData = {};
        this.priceData = {};
        this.item = {};
        const lookupField = this.template.querySelector('[data-id = "product-lookup"]');
        if (lookupField) {
            lookupField.clear();
        }
    }

    @wire(graphql, {
        query: gql`                
            query PricebookEntryQuery($priceEntryId: ID!) {
                uiapi {
                    query {
                        PricebookEntry(where: { Id: { eq: $priceEntryId } }) { 
                            edges {
                                node {
                                    Id
                                    IsActive { value }
                                    Name { value }
                                    CurrencyIsoCode { value }
                                    ProductCode { value }
                                    UnitPrice { value }
                                    Uprice__c { value }
                                    SAPPrice__c { value }
                                    SAPPriceUnit__c { value }
                                    UMVPrice__c { value }
                                    UMVPriceUnit__c { value }
                                    Product2Id { value }
                                    Product2 {
                                        Id
                                        Name { value }
                                        StockKeepingUnit { value }
                                        BoxXPal__c { value }
                                        IsSample__c { value }
                                        M2XBox__c { value }
                                        Marca__c { value }
                                        PcsXBox__c { value }
                                        SalesUnit__c { value }
                                        PesoUMV__c { value }  
                                        Umb__c { value }                                      
                                        UnitWeight__c { value }
                                        ProductCode { value }
                                    }
                                }
                            }
                        }
                    }
                }
            },
            query SearchEntry($pricebookId: ID!, $productId: ID!) {
                uiapi {
                    query {
                        PricebookEntry(where: {Pricebook2Id: { eq: $pricebookId }, Product2Id: { eq: $productId }}) {               
                            edges {
                                node {
                                    Id
                                    IsActive { value }
                                    Name { value }
                                    CurrencyIsoCode { value }
                                    ProductCode { value }
                                    UnitPrice { value }
                                    Uprice__c { value }
                                    SAPPrice__c { value }
                                    SAPPriceUnit__c { value }
                                    UMVPrice__c { value }
                                    UMVPriceUnit__c { value }
                                    Product2Id { value }
                                    Product2 {
                                        Id
                                        Name { value }
                                        StockKeepingUnit { value }
                                        BoxXPal__c { value }                                        
                                        IsSample__c { value }
                                        M2XBox__c { value }
                                        Marca__c { value }
                                        PcsXBox__c { value }
                                        SalesUnit__c { value }
                                        PesoUMV__c { value }  
                                        Umb__c { value }                                      
                                        UnitWeight__c { value }
                                        ProductCode { value }
                                    }
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
            if (data) {
                if (data !== undefined) {
                    if (data.uiapi.query.PricebookEntry) {
                        this.parsePricebookEntry(data.uiapi.query.PricebookEntry.edges);
                    }
                } 
            } 
            if (errors) {                
                alert("GRAPHQL ERROR (OrderItemForm");
                console.log("> GRAPH-QL Errors in orderItemFOrm" + JSON.stringify(errors));
            }
            this.showSpinner = false;
            this.errors = errors;
        }

    get graphVariables() {
        return {    
            queryName: this.queryName, 
            priceEntryId: this.pricebookEntryId,
            pricebookId: this.pricebookId,
            productId : this.productId

        }
    }

    parsePricebookEntry(data) {
        const src = data[0].node;

        const result = {priceData:{}, productData: {}};

        if (this.isNewItem || this.PricebookEntryId === null || this.PricebookEntryId === undefined) {
            result.priceData.Id = src.Id;
            result.priceData.IsActive = src.IsActive.value;
            result.priceData.Name = src.Name.value;
            result.priceData.CurrencyIsoCode = src.CurrencyIsoCode.value;
            result.priceData.UnitPrice = src.UnitPrice.value;
            result.priceData.Uprice__c = src.Uprice__c.value;
            result.priceData.SAPPrice__c = src.SAPPrice__c.value;
            result.priceData.SAPPriceUnit__c = src.SAPPriceUnit__c.value;
            result.priceData.UMVPrice__c = src.UMVPrice__c.value;
            result.priceData.UMVPriceUnit__c = src.UMVPriceUnit__c.value;            
        }

        result.productData = {};
        result.productData.Id = src.Product2.Id;
        result.productData.Name = src.Product2.Name.value;
        result.productData.StockKeepingUnit = src.Product2.StockKeepingUnit.value;
        result.productData.BoxXPal__c = src.Product2.BoxXPal__c.value;
        result.productData.M2XBox__c = src.Product2.M2XBox__c.value;
        result.productData.PcsXBox__c = src.Product2.PcsXBox__c.value;
        result.productData.SalesUnit__c = src.Product2.SalesUnit__c.value;
        result.productData.UnitWeight__c = src.Product2.UnitWeight__c?.value;
        result.productData.Umb__c = src.Product2.Umb__c?.value;
        result.productData.PesoUMV__c = src.Product2.PesoUMV__c.value;
        result.productData.Marca__c = src.Product2.Marca__c.value;
        result.productData.ProductCode = src.Product2.ProductCode.value;

        if (result.priceData.UnitPrice === null || result.priceData.UnitPrice === undefined) {
            result.priceData.UnitPrice = 0;
        }

        this.priceData = result.priceData;
        this.productData = result.productData;
        this.setItemValues();
    }



}