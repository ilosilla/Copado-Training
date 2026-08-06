/**
* @author 		Ramón Prades
* @date 		September 2022
* @group 		Products
* @description 	Class to calculate conversions from one unit to another.
*/
public class ProductConverter {

    public static final Double SQF_TO_METRES = 10.7639;

    Product2 product;
    Boolean isTile = false;

    /**
     * Constructor 1
     */
    public ProductConverter(Product2 product) {
        this.product = product;
        this.isTile = (product.StockUnit__c == 'PZS' && product.UnitsXM2__c != 0);
    }

    /**
     * Constructor 2
     */
    public ProductConverter(String productCode) {
        Product2[] products = new ProductsSelector().selectByProductCode(new Set<String>{productCode});
        if (products.size() == 0) {
            throw new ObjectNotFoundException('Product ' + productCode + ' not found!');
        } else {
            this(products[0]);
        }
    }

    /**
     * Constructor 3
     */
    public ProductConverter(Id productId) {
        Product2[] products = new ProductsSelector().selectById(new Set<Id>{productId});
        if (products.size() == 0) {
            throw new ObjectNotFoundException('Product Id ' + productId + ' not found!');
        } else {
            this(products[0]);
        }
    }

    /**
     * Getter
     */
    public Product2 getProduct2() {
        return this.product;
    }

    /**
     * Converts a quantity to UK units (Boxes/Pieces))
     */
    public UKUNits convertToUKUnits(Double quantity, String unit) {
        UKUnits ukUnit = new UKUnits();        
        ukUnit.isTile = this.isTile;
        if (this.isTile) {
            Double umb = this.convertToStockUnit(quantity, unit);
            ukUnit.boxes = Integer.valueOf(Math.floor(umb / this.product.PcsXBox__c));
            ukUnit.pieces = Integer.valueOf(umb - ukUnit.boxes * this.product.PcsXBox__c);
        } else {
            ukUnit.boxes = 0;
            ukUnit.pieces = Integer.valueOf(this.convertToStockUnit(quantity, unit));
            ukUnit.unitCode = this.product.stockUnit__c;
        }
        return ukUnit;
    }

    /**
     * Converts a quantity to stock unit (UMB)
     */
    public Double convertToStockUnit(Double quantity, String unit) {        
        Double result = quantity;
        Double pieces = quantity;
        if (this.isTile) {
            // Stock unit is PZS
            switch on (unit.toUpperCase()) {
                when 'CJ' {
                    pieces = quantity * this.product.UnitsXBox__c;
                }
                when 'MT2' {
                    pieces = quantity * this.product.UnitsXM2__c;
                }
                when 'SQF' {
                    double metres = quantity / SQF_TO_METRES;
                    pieces = metres  * this.product.UnitsXM2__c;
                }
                when 'PAL' {
                    pieces = quantity * this.product.UnitsXPal__C;
                }
            } // switch
            result = Math.ceil(pieces);
        } else {
            if (unit.toUpperCase() == 'KG') {
                result = this.adjustKilos(quantity);
            }
        }
        return result;
    }

    /**
     * Converts a quantity to boxes
     */
    public Double convertToBoxes(Double quantity, String unit) {
        Double boxes = 0;
        switch on (unit) {
            when 'PZS' {
                boxes = quantity / this.product.PcsXBox__c;
            }
            when 'CJ' {
                boxes = quantity;
            }
            when 'PAL' {
                boxes = quantity * this.product.BoxXPal__c;
            }
            when 'MT2' {
                boxes = quantity / this.product.M2XBox__c;
            }
            when 'SQF' {
                double metres = quantity / SQF_TO_METRES;
                boxes = metres / this.product.M2XBox__c;
            }
        }
        return boxes;
    }

    public Double convertFromTo(Double quantity, String unitFrom, String unitTo) {
        Double result = 0;
        if (unitTo == 'PZS') {
            result = this.convertToStockUnit(quantity, unitFrom);
        } else {
            // Convert to boxes and then to the unit
            Double boxes = this.convertToBoxes(quantity, unitFrom);
            switch on (unitTo) {
                when 'CJ' {
                    result = boxes;
                }
                when 'PAL' {
                    result = boxes/this.product.BoxXPal__c;
                }
                when 'MT2' {
                    result = boxes * this.product.M2XBox__c;
                }
                when 'SQF' {
                    result = boxes * this.product.M2XBox__c * SQF_TO_METRES;
                }
            }
        }
        return result;
    }

    /**
     * Converts kilos to sacs
     */
    public Double adjustKilos(Double quantity) {
        Double result = quantity;
        if (this.product.stockUnit__c != 'KG') {
            result = quantity / this.product.UnitWeight__c;
        }
        return result;
    } 

    /* 
     * UK units refers to using boxes and pieces to express quantities. It can be used in other countries 
     * but it is common in the UK and that's the reason for the name.
     */
    public class UKUnits {
        public Boolean isTile;
        public Integer boxes;
        public Integer pieces;
        public String unitCode;
    } // inner class
}