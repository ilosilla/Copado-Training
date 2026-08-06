import { LightningElement, wire, api } from 'lwc';
import { gql, graphql, refreshGraphQL } from 'lightning/uiGraphQLApi';
import LibGraphQLCommons from "c/libGraphQLCommons";

let LAST_ORDER_ID = null;
let LAST_QUERY = '';
let LAST_RESULT = null;

export default class LibOrderQuery extends LightningElement {

    queryName;
    orderId;
    orderItems;
    refresh = false;
    isRefreshing = false;

    @api queryOrder(order_Id) {    
        this.isRefreshing = false;
        const myQueryName = 'OrderByIdQuery';      
        if (LAST_ORDER_ID === order_Id) {
            this.refresh = true;
        } 
        this.queryName = myQueryName;
        this.orderId = order_Id;
        LAST_ORDER_ID = order_Id;             
    }

    async refreshData(result) {
        return refreshGraphQL(result);
      }

    @api querySAPStatus(order_Id) {
        const myQueryName = 'SAPStatusQuery';        
        this.queryName = myQueryName;
        this.orderId = order_Id;
    }

    returnResults1(success, qName, data) {    
        if (qName === null) {
            success = false;
        }  
        this.queryName = null;
        this.dispatchEvent(new CustomEvent('datareceived', { detail: { success: success, queryName: qName, data: data }} ));        
    }

    //------------------------------------------------------------------------------------

    @wire(graphql, {
        query: gql`
            query OrderByIdQuery($orderId: ID) {
                uiapi {
                    query {
                        Order(where: { Id: { eq: $orderId }}) { 
                            edges {
                                node {
                                    Id
                                    OrderNumber {value}
                                    OrderReason__c {value, displayValue}
                                    Type {value, displayValue}
                                    DeliveryDate__c {value, displayValue}
                                    EffectiveDate { value, displayValue }
                                    CurrencyIsoCode {value}                                    
                                    Pricebook2Id {value}
                                    Pricebook2 { 
                                        Name {value}
                                    }
                                    AccountId {value}
                                    Account {
                                        Name {value}
                                    }
                                    PoNumber {value}
                                    Sap_Id__c {value}
                                    TotalAmount {value}
                                    GrandTotalAmount {value}
                                    SalesOffice__c {value}
                                    SalesOrg__c {value}
                                    Distribution_channel__c {value}
                                    RecordTypeId {value}  
                                    NBK_Contact_Point_Address__c {value}
                                    NB2B_Delivery_Method__c {value}
                                    CreatedById {value }
                                    CreatedBy {
                                        Name { value }
                                    }
                                    CreatedDate {value, displayValue}
                                    LastModifiedById {value }
                                    LastModifiedBy {
                                        Name { value }
                                    }
                                    Status { value, displayValue}
                                    ReferredInvoice__c { value }
                                    LastModifiedDate {value, displayValue}
                                    OrderItems {
                                        edges {
                                            node {
                                                Id
                                                Product2Id {value}
                                                ProductName__c {value}
                                                ProductCode__c {value}
                                                StockKeepingUnit__c {value}
                                                Quantity { value } 
                                                NB2B_Shade__c {value }
                                                SalesUnit__c {value}
                                                UnitPrice { value }
                                                UnitPriceUnitCode__c {value}
                                                ListPrice { value }
                                                ListPriceUnitCode__c {value}     
                                                PricebookEntryId { value }     
                                                OrderId { value }
                                                LineNumber { value }
                                                ReferredLine__c { value }                                                
                                            }
                                        }
                                    }                                  
                                }
                            }
                        }
                    }
                }
            },
            query SAPStatusQuery($orderId: ID) {
                uiapi {
                    query {
                        OrderSAPStatus: Order(where: { Id: { eq: $orderId }}) { 
                            edges {
                                node {
                                    Id
                                    OrderNumber {value}
                                    Status {value, displayValue}
                                    Sap_Id__c {value}
                                    SAPDeliveryNumber__c { value }
                                    SAPGoodsPosted__c { value }
                                    SAPRequestStatus__c { displayValue }
                                }
                            }
                        }
                    }
                }
            }
        `,
        operationName: '$queryName',
        variables: "$querySalesData"
    }) graphqlQueryResult(result) {   
        if (this.refresh) {
            this.refresh = false;
            this.isRefreshing = true;
            this.refreshData(result);
            return;            
        }
        const { data, errors } = result;
        if (data) {
            this.isRefreshing = false;
            if (data.uiapi.query.Order !== undefined) {
                const orders = this.parseOrderFields(data.uiapi.query.Order.edges);  
                console.info("Tengo el resultado " + JSON.stringify(orders))
                this.returnResults1(true, this.queryName, orders[0]);
            }            
            if (data.uiapi.query.OrderSAPStatus !== undefined) {
                const results = this.parseSAPStatusFields(data.uiapi.query.OrderSAPStatus.edges);
                this.returnResults1(true, this.queryName, results[0]);
            }
        } 
        if (errors) {
            console.error("> [libOrderQuery] GRAPH-QL Errors " + JSON.stringify(errors));
            console.error("> Params are: " + JSON.stringify(this.graphVariables));
            this.returnResults1(false, this.queryName, errors);
            throw new Error("LIBORDERQUERY: GRAPH-QL Error");
        }
    }
    
    get querySalesData() {
        return {            
            queryName: this.queryName,
            orderId: this.orderId   
        }   
    }   Order

    parseOrderFields(edges) {    
        const cl = new LibGraphQLCommons();
        const data = cl.parseResultsAsData(edges);
        this.orderItems = data[0].subqueries.OrderItems;
        return data;
    }   

    /*
    parseEdgex(edge) {     
        const aux = {};            
        const order = {};
        order.Id = edge.node.Id;
        order.OrderNumber = edge.node.OrderNumber.value;
        order.Type = edge.node.Type.value;        
        order.DeliveryDate__c = edge.node.DeliveryDate__c.value;
        order.CurrencyIsoCode = edge.node.CurrencyIsoCode.value;
        order.Pricebook2Id = edge.node.Pricebook2Id.value;
        order.PricebookName = edge.node.Pricebook2.Name?.value;
        order.AccountId = edge.node.AccountId.value;
        order.AccountName = edge.node.Account?.Name?.value;
        order.PoNumber = edge.node.PoNumber.value;
        order.Sap_Id__c = edge.node.Sap_Id__c.value;
        order.TotalAmount = edge.node.TotalAmount.value;
        order.GrandTotalAmount = edge.node.GrandTotalAmount.value;
        order.SalesOffice__c = edge.node.SalesOffice__c.value;
        order.SalesOrg__c = edge.node.SalesOrg__c.value;
        order.Distribution_channel__c = edge.node.Distribution_channel__c.value;
        order.RecordTypeId = edge.node.RecordTypeId.value;
        order.EffectiveDate = edge.node.EffectiveDate.value;
        // order.FormattedEffectiveDate = edge.node.EffectiveDate.displayValue;
        order.CreatedById = edge.node.CreatedById.value;
        order.CreatedByName = edge.node.CreatedBy?.Name.value;
        order.CreatedDate = edge.node.CreatedDate.value;
        // order.FormattedCreatedDate = edge.node.CreatedDate.displayValue;
        order.LastModifiedById = edge.node.LastModifiedById.value;
        order.LastModifiedByName = edge.node.LastModifiedBy?.Name.value;
        order.LastModifiedDate = edge.node.LastModifiedDate.value;
        // order.FormattedLastModifiedDate = edge.node.LastModifiedDate?.displayValue;
        order.ReferredInvoice__c = edge.node.ReferredInvoice__c?.value;
        order.NBK_Contact_Point_Address__c = edge.node.NBK_Contact_Point_Address__c?.value;
        order.Status = edge.node.Status?.value;
        order.OrderReason__c = edge.node.OrderReason__c.value;
        order.DisplayOrderReason__c = edge.node.OrderReason__c.displayValue;

        aux.StatusName = edge.node.Status?.displayValue;
        aux.TypeName = edge.node.Type?.displayValue;

        const items = edge.node.OrderItems.edges.map(line => {
            const item = {};
            item.Id = line.node.Id;
            item.LineNumber = line.node.LineNumber.value;
            item.Product2Id = line.node.Product2Id.value;
            item.ProductName__c = line.node.ProductName__c.value;
            item.ProductCode__c = line.node.ProductCode__c.value;
            item.StockKeepingUnit__c = line.node.StockKeepingUnit__c.value;
            item.Quantity = line.node.Quantity.value;
            item.NB2B_Shade__c = line.node.NB2B_Shade__c.value;
            item.SalesUnit__c = line.node.SalesUnit__c.value;
            item.UnitPrice = line.node.UnitPrice.value;
            item.UnitPriceUnitCode__c = line.node.UnitPriceUnitCode__c.value;
            item.ListPrice = line.node.ListPrice.value;
            item.ListPriceUnitCode__c = line.node.ListPriceUnitCode__c.value;
            item.PricebookEntryId = line.node.PricebookEntryId.value;
            item.ReferredLine__c = line.node.ReferredLine__c.value;
            item.OrderId = line.node.OrderId.value;
            return item;
        });   

        const data = {};
        data.order = order;
        data.items = items;
        data.aux = aux;
        return data;
    }
    */

    parseSAPStatusFields(edges) {
        const results = edges.map( edge =>  {
            const data = {};
            data.Id = edge.node.Id;
            data.Status = edge.node.Status.displayValue;
            data.Sap_Id__c = edge.node.Sap_Id__c.value;
            data.SAPDeliveryNumber__c = edge.node.SAPDeliveryNumber__c.value;
            data.SAPGoodsPosted__c = edge.node.SAPGoodsPosted__c.value; 
            data.SAPRequestStatus__c = edge.node.SAPRequestStatus__c.displayValue; 
            return data;
        });   
        return results; 
    }   

}

/*
Product2 {
    Id
    BoxXPal__c { value }
    Category__c { value }
    GrupoArticulos__c { value }
    IsSample__c { value }
    Item_Type__c { value }
    M2XBox__c { value }
    Marca__c { value }
    PcsXBox__c { value }
    PesoUMV__c { value }  
    Umb__c { value }                                      
    UnitWeight__c { value }
}                 
*/