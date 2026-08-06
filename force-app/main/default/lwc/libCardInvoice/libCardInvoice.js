/**
 * Component to display a SAP invoice information in a card.
 * Can be used in a edit form or in a lightning record page.
 *
 * Ramón
 * Jan 2024
 * 
 * Translation Prefix: tr0004
 * 
 * Params:
 * - header: Object with header information:
 *      * Number
 *      * Date
 *      * SalesOrg
 *      * SalesOrgName
 *      * Net
 *      * Tax
 *      * Total
 *      * Currency
 *      * AccountId
 *      * AccountSAPCode
 *      * AccountName
 * - item:  Object with invoice item info
 *      * Number
 *      * Line
 *      * Net
 *      * Tax
 *      * Total 
 *      * Curr
 *      * ProductCode 
 *      * ProductName
 *      * Quantity
 *      * SalesUnit 
 *      * Make  
 * - variant: To choose the display mode (only "item" implemented so far).
 */
import { LightningElement, api, wire } from 'lwc';
import { gql, graphql } from 'lightning/uiGraphQLApi';
import { downloadInvoice } from 'c/libDownloadSapDocument';

import dict_sap_invoice from "@salesforce/label/c.dict_sap_invoice";
import dict_net_amount from "@salesforce/label/c.dict_net_amount";
import dict_manufacturer from "@salesforce/label/c.dict_manufacturer";
import tr0004_001 from "@salesforce/label/c.tr0004_001";
import dict_invoice_date from "@salesforce/label/c.dict_invoice_date";
import dict_salesOrg from "@salesforce/label/c.dict_salesOrg";
import dict_product from "@salesforce/label/c.dict_product";
import dict_quantity from "@salesforce/label/c.dict_quantity";

export default class LibCardInvoice extends LightningElement {

    label = {
        dict_sap_invoice, dict_net_amount, dict_manufacturer, tr0004_001,
        dict_invoice_date, dict_salesOrg, dict_product, dict_quantity
    };
    

    //==================================================================
    @api header;
    @api item;

    //==================================================================
    salesOrgName = "";
    makeName = "";
    queryName = "SalesOrgQuery";
    downloadDisabled = false;

    get componentReady() {
        return (this.header?.Number != undefined && this.item?.Line != undefined);
    }

    get invoiceString() {
        return this.header?.Number + '-' + this.item?.Line;
    }

    get salesOrgString() {
        return this.header?.SalesOrg + " - " + this.salesOrgName?.toLocaleUpperCase();
    }

    get productString() {
        return this.item?.ProductCode + " - " + this.item?.ProductName;
    }

    get quantityString() {
        return this.item?.Quantity + " " + this.item?.SalesUnit;
    }

    get amountString() {
        return this.item?.Net + " " + this.item.Curr;
    }

    //==================================================================
    handleDownloadClick() {
        this.downloadDisabled = true;
        downloadInvoice(this.header.Number, this.invoiceDownloaded);
    }

    invoiceDownloaded() {
        this.downloadDisabled = true;
    }
    
    //==================================================================
    @wire(graphql, {
        query: gql`
            query SalesOrgQuery($salesOrg: String) {
                uiapi {
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
                }
            },
            query MakeQuery($make: String) {
                uiapi {
                    query {
                        Make__c(where: { SAPCode__c: { eq: $make }})
                        {
                            edges {
                                node {
                                    Name { value }
                                }
                            }
                        }
                    }
                }
            } 
            `,
            variables: '$queryVariables',
            operationName: '$queryName'
        }) graphqlQueryResult({ data, errors }) {
            //(where: { Ordernum__c: { eq: $invoiceNumber } }) {
            if (data) {
                if (data.uiapi.query.Sales_Org__c!= undefined) {
                    const results = data.uiapi.query.Sales_Org__c.edges.map(edge => edge.node);
                    this.salesOrgName = results[0].Name.value;
                    this.queryName = 'MakeQuery';
                } else if (data.uiapi.query.Make__c!= undefined) {
                    const results = data.uiapi.query.Make__c.edges.map(edge => edge.node);
                    this.makeName = results[0]?.Name.value;
                    } 
            } 
            if (errors) {
                console.log("> GRAPH-QL Errors " + JSON.stringify(errors));
            }
        }

    get queryVariables() {
        return {     
            salesOrg: this.header.SalesOrg,
            make: this.item.Make,
            queryName: this.queryName
        };
    }

}