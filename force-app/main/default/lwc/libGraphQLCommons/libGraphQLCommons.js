/**
 * *libGraphQLCommons.js*
 * A JavaScript library providing utility methods to parse the results of a GraphQL query.
 * It transforms query responses into structured JavaScript objects.
 * 
 * version 1.1.0
 * author Ramón Prades 
 * date August 2025
 * 
 * methods
*    - parseResults(graphQLResponse): Parses the query results into an array of objects. 
 *      The resulting object mirrors the structure of the GraphQL query, 
 *      including subqueries and relationships, parsing everything as properties. 
 *      If a DisplayValue is present in the GraphQL response, it is mapped 
 *      to an additional property in the object using the pattern <property>_DisplayValue.
 * 
 *   - parseResultsAsData(graphQLResponse): Parses the query results into an array of structured objects, 
 *      where each object has the following properties:
 *        - record: Contains the main object of the query, mapping only the value properties.
 *        - displayValues: Includes fields where displayValue was specified in the GraphQL query.
 *        - relations: Stores relationship fields, with a property for each related object.
 *        - subqueries: Stores subquery results separately, with a property for each subquery.
 * 
 *     If the GraphQL query includes a relation Account__r with fields Name and Email, 
 *     the resulting object will have:
 *            relations: {
 *              Account__r: {
 *                Name: "Acme Corp",
 *                Email: "contact@acme.com"
 *              }
 *            }
 *
 *     If the GraphQL query includes a subquery "OrderItems", the resulting object will have:
 *            subqueries: {
 *              OrderItems: [
 *                { Id: "1001", Product: "Laptop", Quantity: 2 },
 *                { Id: "1002", Product: "Monitor", Quantity: 1 }
 *              ]
 *            }
 *
 * usage
 *     // Example usage of the library
 *     import LibGraphQLCommons from "c/libGraphQLCommons"; 
 * 
 *     // then, in the graphQLQueryReuslts
 *     const orders = this.parseOrderFields(data.uiapi.query.Order.edges);  
 * 
 *     // And in "parseOrderFields"
 *     parseOrderFields(edges) {    
 *        const cl = new LibGraphQLCommons();
 *        const orders = cl.parseResultsAsData(edges);
 *        console.info(JSON.stringify(orders));
 *     }
 * 
 * dependencies
 *   - None 
 *
 * changelog
 *   - 1.0.0: Initial release with parseResults and parseResultsAsData for structured GraphQL parsing.
 *   - 1.1.0: Improvement in the generation of the result as an object (before, parseObject had no value, and in the recursion it was always true)
 */

export default class LibGraphQLCommons  {

    parseResults(edges) {
        return edges.map(edge => this.parseEdge(edge, true));
    }

    parseResultsAsData(edges) {
        return edges.map(edge => this.parseEdge(edge, false));
    }

    parseEdge(edge, parseAsObject) {
        if (!edge || !edge.node) return null; // Handle edge cases       
        const data = {};     
        data.record = {};
        data.relations = {};
        data.subqueries = {};
        data.displayValues = {};
        Object.keys(edge.node).forEach(key => {
            const field = edge.node[key];    
            if (field && typeof field === "object") {
                if ("edges" in field) {                    
                    if (parseAsObject) {
                        data.record[key] = field.edges.map(this.parseEdge.bind(this), true);  
                    } else {
                        // data.subqueries[key] = field.edges.map(this.parseEdge.bind(this), true);  
                        data.subqueries[key] = field.edges.map(localEdge => this.parseEdge(localEdge, false));                        
                    }
                } else { 
                    const hasValue = ("value" in field);
                    const hasDisplayValue = ("displayValue" in field);
                    if (!hasValue && !hasDisplayValue) {
                        const fakeNode = {
                            node: field
                        }
                        if (parseAsObject) {
                            data.record[key] = this.parseEdge.bind(this)(fakeNode, true);
                        } else {
                            data.relations[key] = this.parseEdge.bind(this)(fakeNode, false);
                        }
                    }
                    if ("value" in field) {
                        data.record[key] = field.value ?? null;
                    }
                    if ("displayValue" in field) {
                        if (parseAsObject) {
                            data.record[`${key}_DisplayValue`] = field.displayValue;
                        } else {
                            data.displayValues[key] = field.displayValue;
                        }
                    }
                }
            } else {
                // Es un campo directo tipo ID
                data.record[key] = field;
            }
        });          
        if (parseAsObject) {
            return data.record;
        }
        return data;
    }


}