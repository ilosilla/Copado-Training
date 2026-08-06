@SuppressWarnings('PMD.ExcessiveParameterList')
public without sharing class B2B_PLPController {

    /**
     * Reads the context necessary to get prices and stock for the PLP.
     * It is kept separate to take advantage of the session cache in the LWC layer.
     */
    @AuraEnabled(cacheable=true)
    public static PLPContextDTO getPLPContext(Id buyerGroupId, String currencyCode, Boolean includePrices, Boolean includeStock) {
        if (buyerGroupId == null) {
            throw new AuraHandledException('BuyerGroupId is required');
        }

        PLPContextDTO ctx = new PLPContextDTO();
        ctx.buyerGroupId  = buyerGroupId;
        ctx.pricesEnabled = includePrices;
        ctx.stockEnabled  = includeStock;

        // 1. Resolve Sales Org from User
        User u = [
            SELECT DEFAULT_Sales_Organization__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        ctx.salesOrg = u.DEFAULT_Sales_Organization__c;

        // 2. Resolve Pricebook (BuyerGroup → Pricebook)
        if (ctx.pricesEnabled) {
            BuyerGroupPricebook bgpb = [
                SELECT Pricebook2Id
                FROM BuyerGroupPricebook
                WHERE BuyerGroupId = :buyerGroupId
                LIMIT 1
            ];
            ctx.pricebookId = bgpb.Pricebook2Id;

            ctx.currencyIsoCode = currencyCode;
        } // prices enabled

        // 3. Resolve Plant (SalesOrg → Plant)
        if (ctx.stockEnabled) {
            SAP_Plants__x plantRec = [
                SELECT Plant__c
                FROM SAP_Plants__x
                WHERE Vkorg__c = :ctx.salesOrg
                LIMIT 1
            ];
            ctx.plant = plantRec.Plant__c;

            // 4. Resolve Warehouses (Plant → ZSTK Warehouses)
            List<SAP_StockWarehouses__x> whs = [
                SELECT Warehouse__c
                FROM SAP_StockWarehouses__x
                WHERE Plant__c = :ctx.plant
                AND IsZSTK__c = true
            ];
            ctx.warehouses = new List<String>();
            for (SAP_StockWarehouses__x w : whs) {
                if (w.Warehouse__c != null) {
                    ctx.warehouses.add(w.Warehouse__c);
                }
            }
        } // stock enabled
        return ctx;
    }

    /**
     * Loads PLP data (prices and stock) for the given products in the given context.
     */
    @AuraEnabled(cacheable=true)
    public static List<PLPItemDTO> loadPLPData(PLPContextDTO context, List<PLPProductRefDTO> products) {
        if (context == null) {
            throw new AuraHandledException('Context is required');
        }

        List<Id> productIds = new List<Id>();
        List<String> productSkus = new List<String>();        
        for (PLPProductRefDTO p : products) {            
            productIds.add(p.productId);
            productSkus.add(p.sku);
        }
        List<PLPItemDTO> items = getPrices(context.PricebookId, context.currencyIsoCode, productIds);

         // Stock')
        if (context.stockEnabled) {
            Map<String, StockSnapshotService.StockSnapshotDTO> stockBySku = StockSnapshotService.getStockBySku(context.plant, context.warehouses, productSkus);
            for (PLPItemDTO itemDto : items) {
                StockSnapshotService.StockSnapshotDTO stockDto = stockBySku.get(itemDto.sku);
                itemDto.availableStock = stockDto?.availableStock ?? 0;
                itemDto.onHandStock    = stockDto?.onHandStock ?? 0;
                itemDto.inTransitStock = stockDto?.inTransitStock ?? 0;
                itemDto.stockUnit      = stockDto?.stockUnit ?? '';
                itemDto.stockStatus    = B2B_CommerceUtils.getStockStatus(
                    itemDto.availableStock,
                    itemDto.onHandStock,
                    itemDto.inTransitStock,
                    itemDto.salesUnitPriceUnit,
                    itemDto.pcsPerBox,
                    itemDto.boxPerPal
                );                
            }
        }        
        return items;
    }
    
    /*
     * ===============================================
     * PRIVATE METHODS
     * ===============================================
     */  
    private static List<PLPItemDTO> getPrices(Id pricebookId, String currencyCode, List<Id> productIds) {
        List<PLPItemDTO> result = new List<PLPItemDTO>();

        for (Pricebookentry entry : [
                SELECT
                    Product2Id, UnitPrice, Uprice__c, SAPPrice__c, SAPPriceUnit__c, UMVPrice__c, UMVPriceUnit__c, 
                    CurrencyIsoCode, Product2.StockKeepingUnit, Product2.PcsXBox__c, Product2.BoxXPal__c
                FROM PricebookEntry
                WHERE
                    Product2Id IN :productIds
                    AND CurrencyIsoCode = :currencyCode
                    AND Pricebook2Id = :pricebookId
                    AND IsActive = true
            ] 
        ) {
            PLPItemDTO dto = new PLPItemDTO();
            dto.productId = entry.Product2Id;
            dto.sku = entry.Product2.StockKeepingUnit;
            dto.unitPrice = entry.UnitPrice;
            dto.unitPriceUnit = entry.Uprice__c;
            dto.sapPrice = entry.SAPPrice__c;
            dto.sapPriceUnit = entry.SAPPriceUnit__c;
            dto.salesUnitPrice = entry.UMVPrice__c;
            dto.salesUnitPriceUnit = entry.UMVPriceUnit__c;
            dto.currencyIsoCode = entry.CurrencyIsoCode;     
            dto.boxPerPal = (Integer) entry.Product2.BoxXPal__c;  
            dto.pcsPerBox = (Integer) entry.Product2.PcsXBox__c;
            result.add(dto);           
        }

        return result;

    }

    /* 
     * ===============================================
     * DTOs 
     * ===============================================
     */
    
    public class PLPItemDTO {
        @AuraEnabled public Id productId;
        @AuraEnabled public String sku;

        // Pricing
        @AuraEnabled public Decimal unitPrice;
        @AuraEnabled public String unitPriceUnit;
        @AuraEnabled public Decimal sapPrice;
        @AuraEnabled public String sapPriceUnit;
        @AuraEnabled public Decimal salesUnitPrice;
        @AuraEnabled public String salesUnitPriceUnit;
        @AuraEnabled public String currencyIsoCode;

        @AuraEnabled public Integer pcsPerBox;
        @AuraEnabled public Integer boxPerPal;
        @AuraEnabled public Decimal availableStock; 
        @AuraEnabled public Decimal onHandStock;    
        @AuraEnabled public Decimal inTransitStock; 
        @AuraEnabled public String stockUnit;
        @AuraEnabled public String stockStatus;       // IN_STOCK | LOW | SOON | OUT
    }

    public class PLPProductRefDTO {
        @AuraEnabled public Id productId { get; set; }
        @AuraEnabled public String sku { get; set; }
    }

    public class PLPContextDTO {
        @AuraEnabled public Id buyerGroupId { get; set; }

        // Pricing
        @AuraEnabled public Id pricebookId { get; set; }
        @AuraEnabled public String currencyIsoCode { get; set; }

        // Org / logistics
        @AuraEnabled public String salesOrg { get; set; }
        @AuraEnabled public String plant { get; set; }
        @AuraEnabled public List<String> warehouses { get; set; }

        // Flags
        @AuraEnabled public Boolean pricesEnabled { get; set; }
        @AuraEnabled public Boolean stockEnabled { get; set; }
    }

}