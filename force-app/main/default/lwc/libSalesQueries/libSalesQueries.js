/**
 * 
 * OrderEditionModal
 * 
 * Ramón, March 2024
 * 
 * Modal container to display the sales order edit form
 * 
 */
import { LightningElement, api, wire } from 'lwc';
import { gql, graphql, refreshGraphQL } from 'lightning/uiGraphQLApi';

export default class LibSalesQueries extends LightningElement{    

    @api
        querySalesAreas(value) {            
            this.graphQuery = 'SalesAreasQuery';
            this.params.AccountId = value;
        }
    
    @api
        querySalesOrg(value) {            
            this.graphQuery = 'SalesOrgQuery';
            this.params.SalesOrg = value;
        }

    @api 
        querySalesOffices(salesOrg, channel) {
            this.graphQuery = 'SalesOfficesQuery';
            this.params.SalesOrg = salesOrg;
            this.params.Channel = channel;
        }

    @api 
        queryPricebook(pricebookId) {
            this.graphQuery = 'PricebookQuery';
            this.params.pricebookId = pricebookId;
        }        


    graphQuery = null;
    params = {};

    @wire(graphql, {
        query: gql`
            query SalesAreasQuery($accountId: ID) {
                uiapi {
                    query {
                        Sales_Relationship__c(where: { 
                            and: [
                                { Account_Org__c: { eq: $accountId }} ,
                                { IsDeleted: { eq: false }}
                            ]
                        }) { 
                            edges {
                                node {
                                    Id
                                    Account_Org__c { value }
                                    Name { value }
                                    Distribution_Channel__c { value, displayValue }
                                    Sales_Org__c { value, displayValue }
                                    Sales_Office__c { value, displayValue }
                                    B2BEnabled__c { value }
                                    IsDeleted { value }                                
                                }
                            }
                        }
                    }
                }
            },
            query SalesOrgQuery($salesOrg: String) {
                uiapi {
                    query {
                        Sales_Org__c(where: { SalesOrg__c: { eq: $salesOrg }}) { 
                            edges {
                                node {
                                    Id
                                    SalesOrg__c { value }
                                    Name { value }
                                    CurrencyIsoCode { value }
                                    SamplesCutoff__c { value }
                                    SamplesMinDays__c { value }
                                    SamplesWeekendDays__c { value }
                                    TimeZone__c { value }
                                    Autopick__c { value }
                                    IsBlocked__c { value }   
                                    Company__c { value }
                                }
                            }
                        }
                    }
                }
            },
            query SalesOfficesQuery($salesOrg: String, $channel: String) {
                uiapi {
                    query {
                        Master_relations__c(where: {
                            and: [
                                { SalesOrg_code__c: { eq: $salesOrg }} ,
                                { DistributionChannel_code__c: { eq: $channel }} ,
                                { IsDeleted: { eq: false }}
                            ]
                        }) { 
                            edges {
                                node {
                                    Id
                                    SalesOrg_code__c { value }
                                    DistributionChannel_code__c { value }
                                    SalesOffice_code__c { value }
                                    SalesOffice_name__c { value }
                                    IsDeleted  { value }
                                }
                            }
                        }
                    }
                }
            },
            query PricebookQuery($pricebookId: ID) {
                uiapi {
                    query {
                        Pricebook2(where: { Id: { eq: $pricebookId }}) { 
                            edges {
                                node {
                                    Id
                                    Name { value }
                                    Bzirk__c { value }
                                    CurrencyIsoCode { value }
                                    IsRetailReferencePricebook__c { value }
                                }
                            }
                        }
                    }
                }
            }
            `,
            variables: '$graphVariables',
            operationName: '$graphQuery'
        }) graphqlQueryResult({ data, errors }) {           
            if (data) {
                if (data.uiapi.query.Sales_Relationship__c != undefined) {
                    const results = data.uiapi.query.Sales_Relationship__c.edges.map((edge) => ({
                        Id: edge.node.Id,
                        Account_Org__c: edge.node.Account_Org__c.value,
                        Name: edge.node.Name.value,
                        Distribution_Channel__c: edge.node.Distribution_Channel__c.value,
                        DistrChannelName: edge.node.Distribution_Channel__c.displayValue,
                        Sales_Org__c: edge.node.Sales_Org__c.value,
                        SalesOrgName: edge.node.Sales_Org__c.displayValue,
                        Sales_Office__c: edge.node.Sales_Office__c.value, 
                        SalesOfficeName: edge.node.Sales_Office__c.displayValue, 
                        B2BEnabled__c: edge.node.B2BEnabled__c.value
                    }));                    
                    this.returnResults(this.graphQuery, results);
                }
                if (data.uiapi.query.Sales_Org__c != undefined ) {
                    const results = this.parseSalesOrgQuery(data.uiapi.query.Sales_Org__c.edges);
                    this.returnResults(this.graphQuery, results[0]);
                }
                if (data.uiapi.query.Master_relations__c != undefined ) {
                    const results = this.parseSalesOffices(data.uiapi.query.Master_relations__c.edges);
                    this.returnResults(this.graphQuery, results);
                }
            } 
            if (errors) {
                console.log(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
                console.log("> GRAPH-QL ERRORS IN libSalesQueries " + JSON.stringify(errors));
                console.log("> Params are: " + JSON.stringify(this.graphVariables));
            }
        }

    get graphVariables() {
        return {    
            graphQuery: this.graphQuery,            
            accountId: this.params.AccountId ?? null,
            salesOrg: this.params.SalesOrg ?? null,
            channel: this.params.Channel ?? null,
            pricebookId: this.params.PricebookId ?? null
        };
    }

    returnResults(queryName, data) {
        this.dispatchEvent(new CustomEvent('datareceived', { detail: { queryName: queryName, data: data }} ));
    }

    parseSalesOrgQuery(edges) {        
        const results = edges.map((edge) => ({
            Id: edge.node.Id,
            SalesOrg__c: edge.node.SalesOrg__c.value,
            Name: edge.node.Name.value,
            CurrencyIsoCode: edge.node.CurrencyIsoCode.value,
            SamplesCutoff__c: edge.node.SamplesCutoff__c.value,
            SamplesMinDays__c: edge.node.SamplesMinDays__c.value,
            TimeZone__c: edge.node.TimeZone__c.value,
            Autopick__c: edge.node.Autopick__c.value, 
            IsBlocked__c: edge.node.IsBlocked__c.value, 
            Company__c: edge.node.Company__c.value
        }));
       return results;
    }

    parseSalesOffices(edges) {    
        const results = edges.map((edge) => ({
            Id: edge.node.Id,
            SalesOrg_code__c: edge.node.SalesOrg_code__c.value,
            DistributionChannel_code__c: edge.node.DistributionChannel_code__c.value,
            SalesOffice_code__c: edge.node.SalesOffice_code__c.value,
            SalesOffice_name__c: edge.node.SalesOffice_name__c.value
        }));
       return results;
    }

    parsePricebooks(edges) {
        const results = edges.map((edge) => ({
            Id: edge.node.Id,
            Name: edge.node.Name.value,
            Bzirk__c: edge.node.Bzirk__c.value,
            CurrencyIsoCode: edge.node.CurrencyIsoCode.value,
            IsRetailRefecerencePricebook__c: edge.node.IsRetailRefecerencePricebook__c.value
        }));
       return results;
    }

}