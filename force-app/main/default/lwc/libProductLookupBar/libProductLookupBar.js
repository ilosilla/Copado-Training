/**
 * 
 * libProductLookupBar
 * 
 * Form to add/edit items to an order
 * 
 * Ramón, May 2024
 *  
 * --------
 * API
 * - pricebookId
 * - currencyCode
 * - getData (returns pricebookEntry and product data when true or just the pricebookEntry.Id when false - defaults to false)
 * 
 * EVENTS
 * - select: A product has been selected
 * - reset: The produvt has been cleared
 * 
 */
import { LightningElement, api, wire } from 'lwc';
import { gql, graphql } from 'lightning/uiGraphQLApi';

export default class LibProductLookupBar extends LightningElement {

    @api pricebookId;
    @api currencyCode;
    @api entryId;
    @api 
        get getData() { 
            return this._getData; 
        }
        set getData(value) {
            this._getData = (typeof value === 'boolean') ? value : (value.toLowerCase() === 'true');
        }
    @api clear() {
        const picker = this.template.querySelector('[data-id = "recordPicker"]');
        if (picker) {
            picker.clearSelection();
        }
        //this.refs.recordPicker.clearSelection();
    }

    _getData = false;
    pricebookEntryId;
    queryName;

    get productFilter() {   
        //this.pricebookId = '01s1r000002bmqZAAQ';
        return {
            criteria: [
                {
                    fieldPath: 'Pricebook2Id',
                    operator: 'eq',
                    value: this.pricebookId,
                },
                {
                    fieldPath: 'CurrencyIsoCode',
                    operator: 'eq',
                    value: this.currencyCode                
                }
            ]
        }
    }

    get productMatchingInfo() {
        return {
            primaryField: { fieldPath: 'Name' },
            additionalFields: [{ fieldPath: 'ProductCode' }],
        }
    }

    get productDisplayInfo() {
        return {
            primaryField: 'Name',
            additionalFields: ['ProductCode']
        }
    }

    /*-----------------------------------------------------*/
    /*                   EVENT HANDLERS                    */
    /*-----------------------------------------------------*/    

    handleProductChange(event) {
        if (event.detail.recordId != null) {;
            this.pricebookEntryId = event.detail.recordId;
            if (this._getData) {
                this.queryName = 'PricebookEntryQuery';
            } else {
                this.raiseSelectEvent({Id: event.detail.recordId});
            }
        } else {
            this.raiseResetEvent();
        }
    }

    /*-----------------------------------------------------*/
    /*                     METHODS                         */
    /*-----------------------------------------------------*/    

    raiseSelectEvent(data) {
        this.dispatchEvent(new CustomEvent('select', { detail: data }));
    }

    raiseResetEvent() {
        this.dispatchEvent(new CustomEvent('reset'));
    }

    /*-----------------------------------------------------*/
    /*                  GRAPHQL QUERIES                    */
    /*-----------------------------------------------------*/    

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
                alert("GRAPHQL error");
                console.log("> GRAPH-QL Errors " + JSON.stringify(errors));
            }
            this.errors = errors;
        }

    get graphVariables() {
        return {    
            queryName: this.queryName, 
            priceEntryId : this.pricebookEntryId ?? null
        };
    }

    parsePricebookEntry(data) {
        const src = data[0].node;

        const result = {priceData:{}, productData: {}};

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

        this.raiseSelectEvent(result);

    }



}