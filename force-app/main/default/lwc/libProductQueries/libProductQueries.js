import { LightningElement, api, wire } from 'lwc';
import { gql, graphql } from 'lightning/uiGraphQLApi';

export default class LibProductQueries extends LightningElement {

    queryName;
    product2Id;
    cachedSuccess;
    cachedData;

    @api queryProductById(productId) {
        const myQueryName = 'ProductByIDQuery';
        
        if (productId === this.product2Id && myQueryName === this.queryName)  {
            this.returnCachedResults();
        } else {
            this.product2Id = productId;
            this.queryName = myQueryName;
        }
    }

    returnResults(success, queryName, data) {      
        this.cachedSuccess = success;
        this.cachedData = data;
        this.dispatchEvent(new CustomEvent('datareceived', { detail: { success: success, queryName: queryName, data: data }} ));
    }

    returnCachedResults() {
        this.dispatchEvent(new CustomEvent('datareceived', { detail: { success: this.cachedSuccess, queryName: this.queryName, data: this.cachedData }} ));
    }

    // ********************************************************************************************************

    @wire(graphql, {
        query: gql`
            query ProductByIDQuery($productId: ID) {
                uiapi {
                    query {
                        Product2(where: { Id: { eq: $productId }}) { 
                            edges {
                                node {
                                    Id
                                    Name { value }
                                    StockKeepingUnit { value }
                                    ProductCode { value }
                                    IsActive { value }
                                }
                            }
                        }
                    }
                }
            }
        `,
        operationName: '$queryName',
        variables: "$productData"
    }) graphqlQueryResult({ data, errors }) {           
        if (data) {
            if (data.uiapi.query.Product2 != undefined) {
                console.info("> [libProductQuery] GRAPH-QL  Result " + JSON.stringify(data.uiapi.query.Product2.edges));
                const results = this.parseProductFields(data.uiapi.query.Product2.edges);
                this.returnResults(true, this.queryName, results[0]);
            }
        } 
        if (errors) {
            console.error("> [libProductQuery] GRAPH-QL Errors " + JSON.stringify(errors));
            console.error("> Params are: " + JSON.stringify(this.graphVariables));
            this.returnResults(false, this.queryName, errors);
        }
    }

    get productData() {
        return {
            queryName: this.queryName,
            productId: this.product2Id
        }
    }

    parseProductFields(edges) {        
        const results = edges.map((edge) => ({
            Id: edge.node.Id,
            Name: edge.node.Name.value,
            StockKeepingUnit: edge.node.StockKeepingUnit.value,
            ProductCode: edge.node.ProductCode.value,
            IsActive: edge.node.IsActive.value
        }));
       return results;
    }
}