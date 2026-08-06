import { LightningElement, api, wire } from 'lwc';
import { subscribe, unsubscribe, MessageContext, APPLICATION_SCOPE } from 'lightning/messageService';
import PDP_DATA_CHANNEL from '@salesforce/messageChannel/B2B_PDPDataChannel__c';

const LB_PER_KG = 2.20462;
const SQFT_PER_M2 = 10.7639;

export default class B2b_UsRelatedProducts extends LightningElement {
    
    @api productId;

    @wire(MessageContext) messageContext;

    productData
    pimData;
    attributes = []
    skipCounter = 0;

    isOpen = true;

    get renderItems() {
        return this.relatedProducts ?? [];
    }
  
    get toggleSymbol() {
        return this.isOpen ? 'utility:dash' : 'utility:add';
    }
    
    get bodyClass() {
        return `rc-section-body ${this.isOpen ? '' : 'is-closed'}`;
    }

    get renderAttributes() {
        return this.attributes;
    }

    get productFinderUrl() {
        return this.pimData?.URL__c;
    }

    toggleOpen = () => {
        this.isOpen = !this.isOpen;
    }

    connectedCallback() {
        this.subscribeToPdpData();
    }

    disconnectedCallback() {
        this.unsubscribeFromPdpData();
    }

    subscribeToPdpData() {
        if (this.subscription) {
            return;
        }

        this.subscription = subscribe(
            this.messageContext,
            PDP_DATA_CHANNEL,
            (message) => this.handlePdpMessage(message),
            { scope: APPLICATION_SCOPE }
        );
    }

    unsubscribeFromPdpData() {
        if (this.subscription) {
            unsubscribe(this.subscription);
            this.subscription = null;
        }
    }

    handlePdpMessage(message) {
        this.productData = message.productData;
        this.pimData     = message.pimData;        
        if (this.productData?.IsTile__c) {
            this.setTileAttributes();
        } else {
            this.setNonTileAttributes();
        }
    }

    setTileAttributes() {
        this.attributes = [];
        this.addAttribute(this.buildAttribute('Product Name', this.productData.Name));
        this.addAttribute(this.buildAttribute('Product Code', this.productData.StockKeepingUnit));
        this.addAttribute(this.buildAttribute('Family', this.pimData.Family__c));
        this.addAttribute(this.buildAttribute('Manufacturer', this.pimData.Brand__c_DisplayValue));
        this.addAttribute(this.buildAttribute('Product Status', this.pimData.FactoryStatus__c_DisplayValue));
        this.addSkipAttribute(); 

        this.addAttribute(this.buildAttribute('Type', this.pimData.Type__c_DisplayValue));
        this.addAttribute(this.buildAttribute('Subtype', this.pimData.Subtype__c));
        if (this.pimData.Typology__c_DisplayValue !== this.pimData.Type__c_DisplayValue) {
            this.addAttribute(this.buildAttribute('Typology', this.pimData.Typology__c_DisplayValue));
        }
        this.addAttribute(this.buildAttribute('Classification', this.pimData.Classification__c));
        this.addAttribute(this.buildAttribute('Usage', this.pimData.Usage__c_DisplayValue));        
        this.addAttribute(this.buildAttribute('Location', this.pimData.Location__c));
        if (this.pimData.ProductApplication__c !== this.pimData.Usage__c_DisplayValue) {
            this.addAttribute(this.buildAttribute('Product Application', this.pimData.ProductApplication__c));        
        }        
        this.addSkipAttribute(); 

        this.addAttribute(this.buildAttribute('Length', this.pimData.USLength__c));
        this.addAttribute(this.buildAttribute('Width', this.pimData.USWidth__c));
        this.addAttribute(this.buildAttribute('Thickness', this.pimData.USThickness__c));
        
        const surface = (this.productData.M2XBox__c * SQFT_PER_M2).toFixed(2);
        const lbxbox = (this.pimData.WeightXBox__c * LB_PER_KG).toFixed(2) + ' lbs';
        this.addAttribute(this.buildAttribute('Sq Ft per Box', surface));
        this.addAttribute(this.buildAttribute('Weight/Box', lbxbox));        
        // const lbxuni = (this.pimData.WeightXUni__c * LB_PER_KG)).toFixed(0) + ' lbs';            
        // this.addAttribute(this.buildAttribute('Weight/Piece', lbxuni));        
        this.addSkipAttribute(); 

        this.addAttribute(this.buildAttribute('Color', this.pimData.Color__c_DisplayValue));
        this.addAttribute(this.buildAttribute('Effect', this.pimData.Effect__c_DisplayValue));
        this.addAttribute(this.buildAttribute('Finish', this.pimData.Finish__c_DisplayValue));
        this.addAttribute(this.buildAttribute('Relief', this.pimData.Relief__c));
        // this.addAttribute(this.buildAttribute('Anti-slip', this.pimData.Antislip__c));
        this.addAttribute(this.buildAttribute('Rectified', this.pimData.Recitified__c));                        
        this.addAttribute(this.buildAttribute('Slip Resistance', this.pimData.SlipResistance__c_DisplayValue));
        this.addSkipAttribute(); 
    }

    setNonTileAttributes() {
        this.attributes = [];
        this.addAttribute(this.buildAttribute('Product Name', this.productData.Name));
        this.addAttribute(this.buildAttribute('Product Code', this.productData.StockKeepingUnit));
        this.addAttribute(this.buildAttribute('Family', this.pimData.Family__c));
        this.addAttribute(this.buildAttribute('Manufacturer', this.pimData.Brand__c_DisplayValue));
        this.addAttribute(this.buildAttribute('Product Status', this.pimData.FactoryStatus__c_DisplayValue));
        this.addSkipAttribute(); 

        this.addAttribute(this.buildAttribute('Type', this.pimData.Type__c_DisplayValue));
        this.addAttribute(this.buildAttribute('Subtype', this.pimData.Subtype__c));
        if (this.pimData.Typology__c_DisplayValue !== this.pimData.Type__c_DisplayValue) {
            this.addAttribute(this.buildAttribute('Typology', this.pimData.Typology__c_DisplayValue));
        }
        this.addAttribute(this.buildAttribute('Classification', this.pimData.Classification__c));
        this.addAttribute(this.buildAttribute('Usage', this.pimData.Usage__c_DisplayValue));        
        this.addAttribute(this.buildAttribute('Location', this.pimData.Location__c));
        if (this.pimData.ProductApplication__c !== this.pimData.Usage__c_DisplayValue) {
            this.addAttribute(this.buildAttribute('Product Application', this.pimData.ProductApplication__c));        
        }        
        //this.addSkipAttribute(); 

        this.addAttribute(this.buildAttribute('Length', this.pimData.USLength__c));
        this.addAttribute(this.buildAttribute('Width', this.pimData.USWidth__c));
        this.addAttribute(this.buildAttribute('Thickness', this.pimData.USThickness__c));
        
        const lbxbox = (this.productData.PesoUMV__c * LB_PER_KG).toFixed(2) + ' lbs';
        this.addAttribute(this.buildAttribute('Weight/Unit', lbxbox));        
        //this.addSkipAttribute(); 

        this.addAttribute(this.buildAttribute('Color', this.pimData.Color__c_DisplayValue));
        this.addAttribute(this.buildAttribute('Effect', this.pimData.Effect__c_DisplayValue));
        this.addAttribute(this.buildAttribute('Finish', this.pimData.Finish__c_DisplayValue));
        this.addAttribute(this.buildAttribute('Relief', this.pimData.Relief__c));
        this.addAttribute(this.buildAttribute('Rectified', this.pimData.Recitified__c));                        
        this.addAttribute(this.buildAttribute('Slip Resistance', this.pimData.SlipResistance__c_DisplayValue));
        this.addSkipAttribute(); 
    }


    addAttribute(attr) {
        if (attr.value !== null ) {
            this.attributes.push(attr);
        }
    }

    addSkipAttribute() {
        this.attributes.push(
            {
                'label': 'SKIP' + this.skipCounter++,
                'value': '',
                'skip' : true
            }
        );
    }

    buildAttribute(label, value) {
        if (value == null || value === '') {
            value =  null;
        } else if (Array.isArray(value)) {
            value = value.join(', ');
        } else if (/^\[.*\]$/.test(value)) {
            const parsed = JSON.parse(value);
            value = parsed;
        } else if (typeof value === 'boolean') {
            value = value ? 'Yes' : 'No';
        }  
        let key = label.replace(/\s+/g, "_")   
        return {
            'key': key,
            'label': label,
            'value': value,
            'skip' : false
        }
    }

    /* =========================================================================================================== 
     *  DATABASE QUERIES 
     * =========================================================================================================== */
    /*
    @wire(graphql, {
        query: "$mainProductQuery",
        variables: '$mainVariables'
    }) PD_graphqlQueryResult({ data, errors }) {
        if (data) {
            const productEdges = data?.uiapi?.query?.product?.edges;
            const pimEdges = data?.uiapi?.query?.pim?.edges;
            const cl = new LibGraphQLCommons();
            this.productData = cl.parseResults(productEdges)[0];    
            this.productData.PesoUMV__c = (this.productData?.PesoUMV__c > 0 ? this.productData?.PesoUMV__c : this.productData?.UnitWeight__c);
            this.pimData = cl.parseResults(pimEdges)[0];
            if (this.productData?.IsTile__c) {
                this.setTileAttributes();
            } else {
                this.setNonTileAttributes();
            }
        } else if (errors) {
            console.error("Errores GRAPHQL en ProductDetails:mainProductQuery " + JSON.stringify(errors));
        }
    } 

    get mainVariables() {
        return { 
            productId: this.productId
         };
    }

    get mainProductQuery() {
        if (!this.productId) return undefined;
        return gql`
            query getMainProduct($productId: ID!) {
                uiapi {
                    query {
                        product: Product2(where: { Id: { eq: $productId } }, first: 1) {
                            edges {
                                node {
                                    Id
                                    Name { value }
                                    StockKeepingUnit { value }
                                    Umv__c { value }
                                    PesoUMV__c { value }
                                    PcsXBox__c { value }
                                    M2XBox__c { value }
                                    IsTile__c { value }
                                    UnitWeight__c { value }
                                }
                            }   
                        }                    
                        pim: PIMProduct__c(where: { Product__c: { eq: $productId } }, first: 1) {
                            edges {
                                node {
                                    Id
                                    Antislip__c { value }
                                    Rectified__c { value }
                                    Relief__c { value }
                                    Brand__c { value displayValue }
                                    Classification__c { value }
                                    Color__c { value displayValue }
                                    Effect__c { value displayValue }
                                    FactoryStatus__c { value displayValue }
                                    Family__c { value }
                                    Finish__c { value }
                                    Finish1__c { value displayValue }
                                    Finish2__c { value displayValue }
                                    Format__c { value }
                                    Image__c { value }
                                    Length__c { value }
                                    Location__c { value }
                                    Name { value }
                                    ProductApplication__c { value }
                                    Product__c { value }
                                    SlipResistance__c { value displayValue }
                                    StandardDescription__c { value }
                                    StandardFormat__c { value }
                                    USStandardFormat__c { value }
                                    StockKeepingUnit__c { value }
                                    Subtype__c { value }
                                    Thickness__c { value }
                                    Type__c { value displayValue }
                                    Typology__c { value displayValue }
                                    URL__c { value }
                                    USLength__c { value }
                                    USThickness__c { value }
                                    USWidth__c { value }
                                    Unit__c { value }
                                    Usage__c { value displayValue }
                                    Width__c { value }
                                    WeightXBox__c { value }
                                    WeightXUni__c { value }
                                    WeightXMt2__c { value }
                                }
                            }
                        }
                    }
                }
            }
        `;
    }
        */

}