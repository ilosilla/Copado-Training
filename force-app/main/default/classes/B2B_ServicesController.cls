/**
 * @author         Ramón Prades
 * @date           November 2025
 * @layer          LWC Controller
 * @description    Global services for the B2B stores custom components
*/
public without sharing class B2B_ServicesController {

    public static final String UNIT_BOXES = 'CJ';
    public static final String UNIT_PALLET = 'PAL';

    private static final String PRODUCT_MISSING = 'ERR_PRODUCT';
    private static final String PRICE_MISSING = 'ERR_PRICE';
    private static final String PIMDATA_MISSING = 'ERR_PIMDATA';
    private static final String CONTEXT_MISSING = 'ERR_CONTEXT';
            
    @AuraEnabled
    public static ConnectApi.CartItem addItemToCart(CartItemDTO itemDTO){
        try {
            // Crear el input para el item
            ConnectApi.CartItemInput cartItemInput = new ConnectApi.CartItemInput();
            cartItemInput.productId = itemDTO?.productId;
            cartItemInput.quantity = String.valueOf(itemDTO?.quantity);
            cartItemInput.type = ConnectApi.CartItemType.PRODUCT;

            // Custom fields en el CartItem
            List<SObject> cartItemList = new List<SObject>();
            CartItem cartItem = new CartItem();
            cartItem.SalesPriceUnit__c = itemDTO?.salesUnit;
            cartItem.ListPriceUnit__c = itemDTO?.listPriceUnit;
            cartItemList.add(cartItem);            
            cartItemInput.customFields = cartItemList;            

            if (itemDTO?.cartId == null) {
                ConnectApi.CartInput cartInput = new ConnectApi.CartInput();
                ConnectApi.CartSummary cartSummary = ConnectApi.CommerceCart.createCart(itemDTO.webStoreId, cartInput);
                itemDTO.cartId = cartSummary.cartId;
            }

            // Añadir al carrito
            ConnectApi.CartItem addedItem = ConnectApi.CommerceCart.addItemToCart(
               itemDTO.webStoreId,
                null,
                itemDTO.cartId,
                cartItemInput
            );

            // Graba información de peso en CartItem
            // CartItem newItem = new CartItem();
            // newItem.Id = addedItem.cartItemId;
            // newItem.WeightUnit = itemDTO.salesUnit;
            // newItem.PerUnitWeight = itemDTO.weightPerUnitKg;
            // update newItem;

            return addedItem;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static PDPDataDTO readPDPData(Id productId, Id pricebookEntryId, Id accountId){
        PDPDataDTO result = new PDPDataDTO();

        // B2B context (loaded earlier this session by libStoreContextProvider)
        B2BContextProvider.B2BContext ctx = B2BContextProvider.getContext(accountId);
        if (ctx == null) {
            throw new ObjectNotFoundException(CONTEXT_MISSING);
        }

        // Product
        Product2[] products = new ProductsSelector().selectById(new Set<Id>{productId});
        if (products.size() == 0) {
            throw new ObjectNotFoundException(PRODUCT_MISSING);
        }    
        result.product = new Map<String, Object>(products[0].getPopulatedFieldsAsMap());

        // Pricebook
        PricebookEntry[] entries = new PricebookEntriesSelector().selectById(new Set<Id>{pricebookEntryId});
        if (entries.size() == 0) {
            throw new ObjectNotFoundException(PRICE_MISSING);
        }    
        result.price = new Map<String, Object>(entries[0].getPopulatedFieldsAsMap());
        setFieldLabel(PricebookEntry.Uprice__c, result.price);
        setFieldLabel(PricebookEntry.SAPPriceUnit__c, result.price);

        // PIMProduct
        PIMProduct__c[] pims = new PIMProductsSelector().selectByProductId(new Set<Id>{productId});
        if (pims.size() == 0) {
            throw new ObjectNotFoundException(PIMDATA_MISSING + '__' + productId);
        }    
        result.pimData = new Map<String, Object>(pims[0].getPopulatedFieldsAsMap());            
        setFieldLabel(PIMProduct__c.Brand__c, result.pimData);
        setFieldLabel(PIMProduct__c.Type__c, result.pimData);
        setFieldLabel(PIMProduct__c.Typology__c, result.pimData);
        setFieldLabel(PIMProduct__c.Effect__c, result.pimData);
        setFieldLabel(PIMProduct__c.Finish1__c, result.pimData);
        setFieldLabel(PIMProduct__c.Finish2__c, result.pimData);
        setFieldLabel(PIMProduct__c.Color__c, result.pimData);
        setFieldLabel(PIMProduct__c.SlipResistance__c, result.pimData);
        setFieldLabel(PIMProduct__c.FactoryStatus__c, result.pimData);
        setFieldLabel(PIMProduct__c.Usage__c, result.pimData);

        // Stock
        result.stock = getRealTimeStock(products[0], ctx);

        // Pallet surcharge
        result.palletSurcharge = new B2BPalletSurchargeCalculator(ctx.market.palletSurchargeMode, ctx).getSurcharge(productId);

        return result;
    }

    /**
     * Reads the related products for a given product Id (reads data from the PIM)
     */
    @AuraEnabled(cacheable=true)
    public static List<RelatedProductDTO> readRelatedProductsList(Id productId, Id pricebookEntryId, Id buyerGroupId) {
        // 1. Leer PIM
        PIMProduct__c pim = new PIMProductsSelector()
            .selectByProductId(new Set<Id>{ productId })
            .get(0);

        if (pim == null) {
            return new List<RelatedProductDTO>();
        }

        // 2. Construir source
         RelatedSourceDTO dto = new RelatedSourceDTO();
        dto.specialPieces = parse(pim.SpecialPieces__c);
        dto.adhesives = parse(pim.Adhesives__c);
        dto.adhesivesWetAreas = parse(pim.AdhesivesWetAreas__c);
        dto.jointMaterials = parse(pim.JointMaterials__c);
        dto.jointMaterialsWetAreas = parse(pim.JointMaterialWetAreas__c);

        // 3. Resolver productos
        return getRelatedProducts(JSON.serialize(dto), pricebookEntryId, buyerGroupId);
    }

    /**
     * Gets the list of related products once the codes are known
     */
    @AuraEnabled(cacheable=true)
    public static List<RelatedProductDTO> getRelatedProducts(String sourceCodesJson, Id pricebookEntryId, Id buyerGroupId) {
        RelatedSourceDTO source = (RelatedSourceDTO) JSON.deserialize(sourceCodesJson, RelatedSourceDTO.class);
        if (source == null) {
            return new List<RelatedProductDTO>();
        }
        Set<String> relatedSkus = new Set<String>();
        relatedSkus.addAll(source.specialPieces ?? new List<String>());
        relatedSkus.addAll(source.adhesives ?? new List<String>());
        relatedSkus.addAll(source.adhesivesWetAreas ?? new List<String>());
        relatedSkus.addAll(source.jointMaterials ?? new List<String>());
        relatedSkus.addAll(source.jointMaterialsWetAreas ?? new List<String>());

        if (relatedSkus.isEmpty()) {
            return new List<RelatedProductDTO>();
        }

        return readRelatedProductsInternal(relatedSkus, source, pricebookEntryId, buyerGroupId  );
    }

    private static List<RelatedProductDTO> readRelatedProductsInternal(Set<String> relatedSkus, RelatedSourceDTO source, Id pricebookEntryId, Id buyerGroupId) {

        // 0. Leer la entitlementPolicy del usuario para determinar si mostrar o no los productos relacionados
        Set<Id> entitled = new Set<Id>();
        CommerceEntitlementBuyerGroup[] groups = [SELECT Id, Policy.Name FROM CommerceEntitlementBuyerGroup WHERE BuyerGroupId = :buyerGroupId];
        if (groups.size() > 0) {
            String policyId = groups[0].Policy.Id;
            CommerceEntitlementProduct [] entitlements = [
                SELECT Id, ProductId FROM CommerceEntitlementProduct 
                 WHERE PolicyId = :policyId
                   AND IsDeleted = false
            ];
            for (CommerceEntitlementProduct ent : entitlements) {
                entitled.add(ent.ProductId);
            }
            // Seguimos por cobertura, que no haría falta si vacío
        }

        List<RelatedProductDTO> results = new List<RelatedProductDTO>();

        PricebookEntry masterEntry = [
            SELECT Pricebook2Id, CurrencyIsoCode
            FROM PricebookEntry
            WHERE Id = :pricebookEntryId
            LIMIT 1
        ];

        List<PricebookEntry> relatedEntries = [
            SELECT Id, Product2Id, Product2.Name, Product2.StockKeepingUnit
            FROM PricebookEntry
            WHERE Product2.StockKeepingUnit IN :relatedSkus
            AND Pricebook2Id = :masterEntry.Pricebook2Id
            AND CurrencyIsoCode = :masterEntry.CurrencyIsoCode
        ];

        Set<Id> productIds = new Set<Id>();
        for (PricebookEntry pbe : relatedEntries) {
            productIds.add(pbe.Product2Id);
        }

        List<PIMProduct__c> pimList = [SELECT Product__c, Image__c FROM PIMProduct__c WHERE Product__c IN :productIds];
        Map<String, SObject> imagesMap = TypeConversionCommons.listToMap(pimList, 'Product__c', false);

        for (PricebookEntry entry : relatedEntries) {
            PIMProduct__c pimRecord = (PIMProduct__c) imagesMap.get(entry.Product2Id);
            RelatedProductDTO dto = new RelatedProductDTO();
            dto.Id = entry.Product2Id;
            dto.Name = entry.Product2.Name;
            dto.Code = entry.Product2.StockKeepingUnit;

            dto.Image = pimRecord?.Image__c;
            dto.Tag = resolveTags(entry.Product2.StockKeepingUnit, source);
            if (entitled.contains(entry.Product2Id)) {
                results.add(dto);
            }
        }
        return results;
    }

    private static String resolveTags(String sku, RelatedSourceDTO source) {
        Set<String> tags = new Set<String>();

        if (source.specialPieces?.contains(sku)) {
            tags.add('Special');
        }
        if (source.adhesives?.contains(sku)) {
            tags.add('Thinset');
        }
        if (source.adhesivesWetAreas?.contains(sku)) {
            tags.add('Thinset');
            tags.add('Wet Area');
        }
        if (source.jointMaterials?.contains(sku)) {
            tags.add('Grout');
        }
        if (source.jointMaterialsWetAreas?.contains(sku)) {
            tags.add('Grout');
            tags.add('Wet Area');
        }
        // Salida estable y simple para JS
        return String.join(new List<String>(tags), '|');
    }

    private static List<String> parse(String jsonString) {
        return (List<String>) JSON.deserialize(jsonString ?? '[]', List<String>.class);
    }

    private static RealTimeStockDTO getRealTimeStock(Product2 product, B2BContextProvider.B2BContext ctx) {
        RealTimeStockDTO resultDTO = new RealTimeStockDTO();

        if (ctx.market.showStock != true) {
            return resultDTO;   // stock desactivado para este market: nada que resolver, no es un error
        }

        B2BContextProvider.PlantDTO targetPlant = resolvePlant(product, ctx);
        if (targetPlant == null) {
            System.debug(LoggingLevel.WARN, 'B2B - STOCK PLANT NOT RESOLVED | '
                + 'Account=' + ctx.effectiveAccountId
                + ' Product=' + product.StockKeepingUnit
                + ' SAPFactory=' + product.SAPFactory__c
                + ' IsDirectCustomer=' + ctx.market.isDirectCustomer);
            resultDTO.stockText = 'Stock information currently unavailable';
            resultDTO.stockError = 'No plant resolved for this product/account';
            return resultDTO;
        }

        SAPStockService.PlantInput plantInput = new SAPStockService.PlantInput();
        plantInput.plant = targetPlant.plant;
        plantInput.warehouses = targetPlant.warehouses;
        List<SAPStockService.PlantInput> plants = new List<SAPStockService.PlantInput>{ plantInput };

        Boolean includeTransit = !ctx.market.isDirectCustomer;
        Boolean useLoteDetail  = ctx.market.shadeEnabled && product.IsTile__c;

        try {
            if (useLoteDetail) {
                List<SAPStockService.StockRowResult> rows = SAPStockService.getStockByLote(plants, product.StockKeepingUnit, includeTransit);
                fillFromLoteRows(resultDTO, rows);
            } else {
                SAPStockService.StockRowResult row = SAPStockService.getStockTotal(plants, product.StockKeepingUnit, includeTransit);
                fillFromRow(resultDTO, row);
            }

            if (resultDTO.stockAvailable > 0) {
                if (product.isTile__c && !product.IsSpecialTile__c) {
                    ProductConverter converter = new ProductConverter(product);
                    Double quantity = converter.convertFromTo((Double) resultDTO.stockAvailable, resultDTO.unit, UNIT_PALLET);
                    resultDTO.lowStock = false; //(quantity <= B2B_CommerceUtils.MIN_PALLETS);
                } else {
                    resultDTO.lowStock = false; // (resultDTO.stockAvailable <= B2B_CommerceUtils.MIN_PIECES);
                }
            }
        } catch (Exception ex) {
            resultDTO.stockText = 'Stock information currently unavailable';
            resultDTO.stockError = ex.getMessage();
        }

        return resultDTO;
    } // getProductStock

    private static B2BContextProvider.PlantDTO resolvePlant(Product2 product, B2BContextProvider.B2BContext ctx) {
        B2BContextProvider.PlantDTO result = null;

        if (ctx.stock?.plants != null && !ctx.stock.plants.isEmpty()) {
            if (ctx.market.isDirectCustomer) {
                for (B2BContextProvider.PlantDTO p : ctx.stock.plants) {
                    if (p.company == product.SAPFactory__c) {
                        result = p;
                        break;
                    }
                }
            } else {
                result = ctx.stock.plants[0];
            }
        }

        return result;
    }

    private static void fillFromRow(RealTimeStockDTO dto, SAPStockService.StockRowResult row) {
        dto.stockTotal = Integer.valueOf(row.totalQty ?? 0);
        dto.stockAvailable = Integer.valueOf(row.availableQty ?? 0);
        dto.stockInTransit = Integer.valueOf(row.inTransitQty ?? 0);
        dto.firstInTransitDate = row.firstInTransitDate;
        dto.unit = row.unit;
    }

    private static void fillFromLoteRows(RealTimeStockDTO dto, List<SAPStockService.StockRowResult> rows) {
        dto.byLote = new List<StockByLoteDTO>();
        Decimal totalQty = 0;
        Decimal availableQty = 0;
        Decimal inTransitQty = 0;

        for (SAPStockService.StockRowResult row : rows) {
            StockByLoteDTO loteDTO = new StockByLoteDTO();
            loteDTO.lote = row.lote;
            loteDTO.stockTotal = Integer.valueOf(row.totalQty ?? 0);
            loteDTO.stockAvailable = Integer.valueOf(row.availableQty ?? 0);
            loteDTO.stockInTransit = Integer.valueOf(row.inTransitQty ?? 0);
            dto.byLote.add(loteDTO);

            totalQty += row.totalQty ?? 0;
            availableQty += row.availableQty ?? 0;
            inTransitQty += row.inTransitQty ?? 0;

            if (dto.unit == null) {
                dto.unit = row.unit;
            }
            if (row.firstInTransitDate != null && (dto.firstInTransitDate == null || row.firstInTransitDate < dto.firstInTransitDate)) {
                dto.firstInTransitDate = row.firstInTransitDate;
            }
        }

        dto.stockTotal = Integer.valueOf(totalQty);
        dto.stockAvailable = Integer.valueOf(availableQty);
        dto.stockInTransit = Integer.valueOf(inTransitQty);
    }

    private static void setFieldLabel(Schema.sObjectField apiName, Map<String, Object> data) {        
        String fieldName = apiName.getDescribe().getName();
        String value = String.valueOf(data.get(fieldName));
        Map<String, String> valueSet = PicklistCommons.getValues(apiName);
        String label = valueSet.get(value);
        if (label == null) {
            label = '';
        }
        String newField = fieldName + '_DisplayValue';
        data.put(newField, label);
    }

    public class PDPDataDTO {
        // A Map is used instead of the SObject itself to allow adding display labels for picklist fields as <fieldName>_DisplayValue entries.
        @AuraEnabled public Map<String, Object> product;
        @AuraEnabled public Map<String, Object> price;
        @AuraEnabled public Map<String, Object> pimData;
        @AuraEnabled public RealTimeStockDTO stock;
        @AuraEnabled public Decimal palletSurcharge;
    }

    public class RealTimeStockDTO {
        @AuraEnabled public Integer stockTotal;
        @AuraEnabled public Integer stockAvailable;
        @AUraEnabled public Integer stockInTransit;
        @AuraEnabled public Date firstInTransitDate;
        @AuraEnabled public String unit;
        @AuraEnabled public Boolean lowStock = false;
        @AuraEnabled public String stockText;
        @AuraEnabled public String stockError;
        @AuraEnabled public List<StockByLoteDTO> byLote;
    }

    public class StockByLoteDTO {
        @AuraEnabled public String lote;
        @AuraEnabled public Integer stockTotal;
        @AuraEnabled public Integer stockAvailable;
        @AuraEnabled public Integer stockInTransit;
    }

    public class RelatedSourceDTO {
        @AuraEnabled public List<String> specialPieces;
        @AuraEnabled public List<String> adhesives;
        @AuraEnabled public List<String> adhesivesWetAreas;
        @AuraEnabled public List<String> jointMaterials;
        @AuraEnabled public List<String> jointMaterialsWetAreas;
    }

    public class RelatedProductDTO {
        @AuraEnabled public Id Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String Code;
        @AuraEnabled public String Tag;
        @AuraEnabled public String Slug;
        @AuraEnabled public String Image;
    }

    public class CartItemDTO {
        @AuraEnabled public String webStoreId {get; set;}
        @AuraEnabled public String cartId {get; set;}
        @AuraEnabled public String productId {get; set;}
        @AuraEnabled public String pricebookEntryId {get; set;}
        @AuraEnabled public Decimal quantity {get; set;}
        @AuraEnabled public String salesUnit {get; set;}
        @AuraEnabled public String listPriceUnit {get; set;}
        @AuraEnabled public Decimal weightPerUnitKg {get; set;}
        @AuraEnabled public Decimal lineWeightKg {get; set;}
    }

}