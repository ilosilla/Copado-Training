@SuppressWarnings('PMD.IfStmtsMustUseBraces, PMD.IfElseStmtsMustUseBraces')
/**
 * BatchPIMReader
 * 
 * @author          Ramón Prades
 * @date            September 2024
 * @description
 * 
 * This batch job is responsible for synchronizing product attributes from the external PIM
 * (Product Information Management) system into Salesforce.
 *
 * The process works as follows: 
 * - First, it queries the eCommerce tables to determine the list 
 *   of products that need to be retrieved. 
 * - Then, it splits this list into blocks that match the 
 *   maximum size allowed by the PIM API and requests product data via SAP CPI. 
 *  The returned information is processed and normalized when needed to ensure consistency, and a record 
 *  is created in the PIMProduct__c object for each product. 
 *  - Before inserting new records, existing ones are deleted to avoid duplicates.
 *
 * *Responsibilities
 * - Identify the set of products to be synchronized based on active Entitlement Policies
 *   linked to enabled B2B Stores.
 * - Chunk products in groups of BATCH_SIZE (maximum allowed per request by the PIM API).
 * - Build a JSON request body containing the fixed list of attributes and the SKUs
 *   of the products in the current chunk.
 * - Invoke the SAP CPI proxy (PIM endpoint) to fetch product data.
 * - Log execution details, successes, and errors through SystemLog.
 *
 * *Key Characteristics
 * - Implements Database.Batchable to support large-scale processing.
 * - Implements Database.Stateful to maintain context and logging across batches.
 * - Implements Database.AllowsCallouts to perform external HTTP requests.
 * - Implements Schedulable to allow scheduled executions (e.g., nightly sync).
 *
 * *Usage
 * To launch the batch manually:
 *
 *     BatchPIMReader.executeBatch();
 *
 * The batch size is fixed at BATCH_SIZE to respect PIM API constraints.
 *
 * *Configuration
 * - Controlled by custom setting PORSAStoreSettings__c, field EnablePIMSync__c.
 * - Products are resolved via CommerceEntitlementProduct and related Buyer Groups/Policies.
 *
 */
global class BatchPIMReader implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts, Schedulable { 

    private static final Integer BATCH_SIZE = 100;

    private static List<String> ATTRIBUTES = new List<String>{
        'ACABADO',                  // Finish__c
        'ACABADO1',                 // Antislip__c and Finish1__c
        'ACABADO2',                 // Finish2__c 
        'APLICACION',               // ProductApplication__c
        'ASPECTO',                  // Effect__c
        'CLASCOMERCIAL',            // CLassification__c  
        'COLOR',                    // Color__c
        //'COLORCOMERCIAL',
        //'DESTONIFICADO',
        'FAMILIA',                  // Family__c
        'FORMATO',                  // Format__c
        'GROSOR',                   // Thickness__c and USThickness__c
        'ANCHO_NOM',                // Width__c and USWidth__c
        'LARGO_NOM',                // Length__c and USLength__c
        'MATADHESIVO',             // Adhesives__c
        'MATADHESIVO_ZONAHUMEDA',     // AdhesivesWetAreas__c
        'MATJUNTA',                 // JointMaterials__c
        'MATJUNTA_ZONAHUMEDA',      // JointMaterialWetAreas__c
        //'PESOBRUTO',
        //'PESONETO',
        'PIES_DESCALZOS',           // SlipResistance__c
        'PIEZASESPECIALES',         // SpecialPieces
        'RECTIFICADO',              // Rectified__c
        'RELIEVE',                  // Relief__c
        'SITUACIONEMPRESA',         // FactoryStatus__c
        //'TAMANYO',
        'TIPOPRODUCTO',              // Subtype__c
        'UBICACION',                 // Location__c
        'USO'                        // Usage__c
    };

    Map<String, String> colorReplaceMap = new Map<String, String>{
        'DOUSSIE'           => 'MADERA',
        'IROKO'             => 'MADERA',
        'OAK'               => 'MADERA',
        'MAPLE'             => 'MADERA',
        'BEECH'             => 'MADERA',
        'ELM'               => 'MADERA',
        'ASH'               => 'MADERA',
        'WENGE'             => 'MADERA',
        'WENGUE'            => 'MADERA',
        'ACERO BRILLO'      => 'ACERO',
        'BLANCO BRILLO'     => 'BLANCO',
        'GRIS CLARO'        => 'GRIS',
        'GREY'              => 'GRIS',
        'MARRÓN'            => 'MARRON',
        'CROMO'             => 'CROMADO',
        'GRAFITO'           => 'GRIS'
    };

    Map<String, String> effectReplaceMap = new Map<String, String>{
        'XL_MARMOL'         => 'MARMOL'
    };

    Map<String, String> finishReplaceMap = new Map<String, String>{
        'BRILLO/MATE'       => 'MATE-BRILLO'
    };

    Set<String> openPicklists = new Set<String>{'Effect__c', 'Brand__c', 'Type__c', 'Typology__c', 'Color__c', 'Finish1__c', 'Finish2__c', 'Usage__c', 'FactoryStatus__c', 'SlipResistance__c'};
    private Map<String, Set<String>> openPicklistsMap;
    private List<String> missingValues;

    private List<CommerceEntitlementProduct> products;
    private Map<String, CommerceEntitlementProduct> selectedProductsMap; // Products to fetch from the PIM per SKU
    private Set<Id> selectedProductIds;
    private Map<Id, PIMProduct__c> existingPIMProducts;
    private SystemLog logger;

    private Integer totalInserts = 0;
    private Integer totalDeletes = 0;

    private Boolean chainToImages = false;
    private Id workspaceId;
    private Id catalogId;

    public void setChainToImages(Boolean value) { this.chainToImages = value; }
    public void setWorkspaceId(Id value) { this.workspaceId = value; }
    public void setCatalogId(Id value) { this.catalogId = value; }

    /**
     * Launches the batch process with a fixed scope size to comply with the maximum
     * number of products allowed per request by the PIM API.
     */
    global static void executeBatch() {
        Database.executeBatch(new BatchPIMReader(), BATCH_SIZE);
    }

    // Constructor vacío
    global BatchPIMReader() {   
        this.logger = new SystemLog('PIM');
        this.products = this.getProductList();
        this.logger.addInfo('Se han preparado ' + this.products.size() + ' productos para su lectura desde el PIM');
        this.totalInserts = 0;
        this.totalDeletes = 0;
        this.missingValues = new List<String>();
        this.setOpenPicklistsMap();
    }
    
    //global Database.QueryLocator start(Database.BatchableContext bc) {

    global Iterable<CommerceEntitlementProduct> start(Database.BatchableContext bc) {
        // Devuelve directamente la lista interna de productos como iterable
        return this.products;
    }   

    global void execute(Database.BatchableContext bc, List<CommerceEntitlementProduct> scope) {
        this.logger.addInfo('Procesando un lote de ' + scope.size() + ' productos');
        this.selectedProductsMap = new Map<String, CommerceEntitlementProduct>();
        this.selectedProductIds = new Set<Id>();
        List<PIMResponseDTO> pimData = new List<PIMResponseDTO>();
        List<CommerceEntitlementProduct> chunk = new List<CommerceEntitlementProduct>();
        Integer lastIndex = scope.size() - 1;
        for (Integer i = 0; i < scope.size(); i++) {
            this.selectedProductsMap.put(scope[i].Product.StockKeepingUnit, scope[i]);
            this.selectedProductIds.add(scope[i].ProductId);
            chunk.add(scope[i]);
            if (chunk.size() == BATCH_SIZE || i == lastIndex) {
                try {
                    pimData.add(this.getPIMData(chunk));
                } catch(Exception ex) {                    
                    this.logger.addError(ex);
                }
                chunk.clear();
            }
        }  
        this.logger.addInfo('Se han construido ' + pimData.size() + ' chunks.');          
        this.readExistingPIMProducts();
        try {            
            this.processPIMData(pimData);
        } catch(Exception ex) {                    
            this.logger.addError(ex);
        }
    }

    // Método finish: acciones al finalizar el batch
    global void finish(Database.BatchableContext bc) {
        
        Boolean hasWarnings = false;

        this.logger.addSection('Resumen');
        this.logger.addInfo('BatchPIMReader finalizado.');
        this.logger.addInfo('==> TOTAL DELETES: ' + this.totalDeletes);
        this.logger.addInfo('==> TOTAL INSERTS: ' + this.totalInserts);
        if (this.missingValues.size() > 0) {
            hasWarnings = true;
            this.logger.addSection('Missing Picklist Values');
            for (String msg : this.missingValues) {
                this.logger.addWarning(msg);
            }
        } else {
            this.logger.addInfo(' ==> NO WARNINGS ISSUED (PICKLISTS)');
        }

        String summary = 'Leyendo ' + this.products.size() + ' productos del PIM';
        if(this.logger.hasErrors()) {
            summary = 'ERRORS: ' + summary;
        } else if (hasWarnings)   {
            summary = 'WARNINGS: ' + summary;
        }      
        this.logger.setSummary(summary);
        this.logger.saveLog(true);

        if (this.chainToImages) {
            BatchPIMImageReader next = new BatchPIMImageReader(false);
            next.setChainToCMS(this.workspaceId != null && this.catalogId != null);
            next.setWorkspaceId(this.workspaceId);
            next.setCatalogId(this.catalogId);
            Database.executeBatch(next, BatchPIMImageReader.CHUNK_SIZE);
        }
    }

    // Método execute para Schedulable: ejecuta el batch
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchPIMReader(), BATCH_SIZE);
    }

    /* ==================================================================================== */
    
    /*
     * Construye la lista de productos que tenemos que leer del PIM
     */
    private List<CommerceEntitlementProduct> getProductList() {        
        Map<Id, CommerceEntitlementProduct> productMap = new Map<Id, CommerceEntitlementProduct>();
        Set<Id> policies = this.getEntitlementPolicies();    
        this.logger.addInfo('Se han identificado ' + policies.size() + ' policies');
        List<CommerceEntitlementProduct> eps = [
            select 
                ProductId, Product.StockKeepingUnit, Product.Name, Product.Umv__c, Product.PcsXBox__c, 
                Product.M2XBox__c, Product.PesoUMV__c 
            from CommerceEntitlementProduct 
            where PolicyId in :policies
        ];
        for (CommerceEntitlementProduct ep : eps) {
            if (!productMap.containsKey(ep.ProductId)) {
                productMap.put(ep.ProductId, ep);
            }
        }
        return productMap.values();
    }

    /*
     * Devuelve la lista de entitlement policies que tenemos que leer
     */
    private Set<Id> getEntitlementPolicies() {
        // Leemos la lista de store ids que tenemso que soncronizar
        PORSAStoreSettings__c[] settings = [select Id, StoreId__c from PORSAStoreSettings__c where EnablePIMSync__c = true];
        List<String> stores = TypeConversionCommons.extractFieldValues(settings, 'StoreId__c');
        // Ahora la lista de Buyer Groups
        WebStoreBuyerGroup[] buyerGroups = [select Id, BuyerGroupId from WebStoreBuyerGroup where WebStoreId in :stores];
        List<String> buyers = TypeConversionCommons.extractFieldValues(buyerGroups, 'BuyerGroupId');
        // Y finalmente la lista de Entitlement Policies
        CommerceEntitlementBuyerGroup[] entitlements = [select PolicyId from CommerceEntitlementBuyerGroup where BuyerGroupId in :buyers] ;
        Set<Id> policies = new Set<Id>();
        for (CommerceEntitlementBuyerGroup entitlement :entitlements) {
            policies.add(entitlement.PolicyId);
        }
        return policies;        
    }

    /*
     * Gets data from the PIM
     */
    private PIMResponseDTO getPIMData(List<CommerceEntitlementProduct> chunk) {
        PIMResponseDTO pimData = null;
        String body = getJSONBody(chunk);
        SAPCPIProxy proxy = new SAPCPIProxy(SAPCPIProxy.PIM_ENDPOINT);
        proxy.setMethod('POST');
        proxy.setQueryString('language=en&unitsystem=imp');
        proxy.setJSONBody(body);        
        try {
            String response = proxy.callCPI();
            if (proxy.isSuccess()) {
                this.logger.addInfo('Se han leído con éxito ' + chunk.size() + ' productos del PIM' );
                this.logger.addInfo(SystemLog.splitter);
                String norm = this.normalizeRawValues(response);
                pimData = (PIMResponseDTO) JSON.deserialize(norm, PIMResponseDTO.class);
                this.logger.addInfo('Respuesta convertida con éxito a JSON: ' + pimData?.data?.size() + ' productos');                
            } else {
                //this.logger.setInputData(response);
                this.logger.addError('Se ha recibido un error al leer del PIM. El status es ' + proxy.getResponseCode() + '.');
            }
        } catch (HttpException hex) {
            this.logger.addError(hex);
        }        
        return pimData;
    } 

    /*
     * Process the data received from the PIM
     */
    private void processPIMData(PIMResponseDTO[] pimData) {
        PIMProduct__c[] toDelete = new List<PIMProduct__c>();
        PIMProduct__c[] toInsert = new List<PIMProduct__c>();
        // this.readExistingAttributes();
        for (PIMResponseDTO responseDTO : pimData) {        
            for(ProductDTO productDTO : responseDTO?.data ) {
                CommerceEntitlementProduct ep = this.selectedProductsMap.get(productDTO.code);
                if (ep == null) {
                    this.logger.addWarning('Product Id not found for SKU ' + productDTO.code);
                    continue;
                } 
                // Add current product to the deletion list
                PIMProduct__c existing = this.existingPIMProducts.get(ep.ProductId);
                if (existing != null) {
                    toDelete.add(existing);
                }
                toInsert.add(buildProductRecord(ep, productDTO));
            }
        }
        this.logger.addInfo(SystemLog.splitter);
        this.logger.addInfo('Se van a borrar ' + toDelete.size() + ' registros.');
        this.logger.addInfo('Se van a grabar ' + toInsert.size() + ' registros.');
        this.deleteRecords(toDelete);
        this.insertRecords(toInsert);
    }

    /*
     * Builds the product record with the info received from the PIM
     */
    private PIMProduct__c buildProductRecord(CommerceEntitlementProduct policy, ProductDTO productDTO) {

        Id productId = policy.ProductId;
        // First, the direct attributes
        PIMProduct__c pim = new PIMProduct__c();
        pim.Product__c = productId;
        pim.StockKeepingUnit__c = productDTO.code;

        pim.Name = productDTO.description;
        pim.StandardDescription__c = productDTO.standardDescription;
        pim.Brand__c = productDTO.brand;
        pim.Image__c = productDTO.imagen;
        pim.URL__c = productDTO.url;
        pim.StandardFormat__c = productDTO.standardFormat;
        pim.USStandardFormat__c = productDTO.standardFormatUSA;
        pim.Type__c = String.valueOf(productDTO.typeCode);
        pim.Typology__c = productDTO.typology_code;

        // Second, build the attributes map
        Map<String, AttributeDTO> attributesMap =  this.buildAttributtesMap(productDTO.attributes);

        // Assign plain text attributes without transformation
        pim.Family__c = (attributesMap.get('FAMILIA')?.value ?? '');
        pim.ProductApplication__c = (attributesMap.get('APLICACION')?.value ?? '');
        pim.Format__c = (attributesMap.get('FORMATO')?.value ?? '');
        pim.Relief__c =  Boolean.valueOf(attributesMap.get('RELIEVE')?.value ?? 'false');
        pim.Rectified__c =  Boolean.valueOf(attributesMap.get('RECTIFICADO')?.value ?? 'false');
        pim.Classification__c = this.setListValue(attributesMap.get('CLASCOMERCIAL')?.value ?? '');
        pim.Finish__c = attributesMap.get('ACABADO')?.value;

        pim.Location__c = this.cleanValue(this.setListValue(attributesMap.get('UBICACION')?.value));
        pim.Subtype__c = this.cleanValue(this.setListValue(attributesMap.get('TIPOPRODUCTO')?.value));
        pim.JointMaterials__c = this.cleanValue(this.setListValue(attributesMap.get('MATJUNTA')?.value));
        pim.JointMaterialWetAreas__c = this.cleanValue(this.setListValue(attributesMap.get('MATJUNTA_ZONAHUMEDA')?.value));
        pim.Adhesives__c = this.cleanValue(this.setListValue(attributesMap.get('MATADHESIVO')?.value));
        pim.AdhesivesWetAreas__c = this.cleanValue(this.setListValue(attributesMap.get('MATADHESIVO_ZONAHUMEDA')?.value));
        pim.SpecialPieces__c = this.cleanValue(this.setListValue(attributesMap.get('PIEZASESPECIALES')?.value));        

        // Picklists
        pim.Color__c = this.getPicklistValue(attributesMap.get('COLOR')?.rawValue, this.colorReplaceMap);
        pim.Effect__c = this.getPicklistValue(attributesMap.get('ASPECTO')?.rawValue, this.effectReplaceMap);
        pim.FactoryStatus__c = attributesMap.get('SITUACIONEMPRESA')?.value;
        pim.Antislip__c = ((attributesMap.get('ACABADO1')?.value == 'ANTIDESLIZANTE') ?? false);        
        pim.Finish1__c = this.getPicklistValue(attributesMap.get('ACABADO1')?.rawValue, this.finishReplaceMap);
        pim.Finish2__c = this.getPicklistValue(attributesMap.get('ACABADO2')?.rawValue, this.finishReplaceMap);
        pim.Usage__c = this.transformUsage(attributesMap.get('USO')?.rawValue);
        pim.SlipResistance__c = attributesMap.get('PIES-DESCALZOS')?.rawValue;

        // Dimensions
        pim.Width__c = this.extractNumber(attributesMap.get('ANCHO_NOM')?.rawValue);
        pim.Length__c = this.extractNumber(attributesMap.get('LARGO_NOM')?.rawValue);
        pim.Thickness__c = this.extractNumber(attributesMap.get('GROSOR')?.rawValue);

        pim.USWidth__c = attributesMap.get('ANCHO_NOM')?.value;
        pim.USLength__c = attributesMap.get('LARGO_NOM')?.value;
        pim.USThickness__c = attributesMap.get('GROSOR')?.value;

        // New fields
        pim.isTile__c = (policy.Product.M2XBox__c > 0);
        if (pim.isTile__c) {
            UnitConversionCommons.Factors factors = new UnitConversionCommons.Factors();
            factors.M2XBox = policy.Product.M2XBox__c;
            factors.PcsXBox = Integer.valueOf(policy.Product.PcsXBox__c);
            Decimal peso = (policy.Product.PesoUMV__c ?? 0);
            pim.WeightXBox__c = UnitConversionCommons.ConvertWeightFromTo(peso, policy.product.Umv__c, 'BOX', factors);
            pim.WeightXMt2__c = UnitConversionCommons.ConvertWeightFromTo(peso, policy.product.Umv__c, 'MT2', factors);
            pim.WeightXUni__c = UnitConversionCommons.ConvertWeightFromTo(peso, policy.product.Umv__c, 'PCS', factors);
        } else {
            pim.WeightXUni__c = policy.Product.PesoUMV__c;
        }

        // Validate picklist values
        this.validatePicklists(pim);

        return pim;
    }

    private String cleanValue(String v) {
        if (v?.toUpperCase().contains('NO ADMITE') || v?.toUpperCase().contains('NO PROCEDE')) {
            v = '';
        }
        return v;
    }

    /*
     * Single values for list fields come from the PIM without brackets ([]).
     */
    private String setListValue(String input) {
        if (String.isBlank(input) ) {
            return '';
        }
        String trimmed = input?.trim();
        Boolean isArray = trimmed.startsWith('[') && trimmed.endsWith(']');
        if (!isArray) {
            String[] arr = new List<String>{input};
            input = JSON.serialize(arr);
        }
        return input;
    }

    /*
     * Transform picklist values
     */
    private String getPicklistValue(String value, Map<String, String> replaceMap) {
        if (String.isBlank(value) ) {
            return '';
        }
        if (replaceMap.containsKey(value.toUpperCase())) {
            value = replaceMap.get(value);
        }	
        return value;
    }

    /*
     * Transforms  USAGE
     */
    private String transformUsage(String value) {
        value = value?.replace(' ', '-');
        value = value?.replace('.', '-');
        return value;
    }

    /*
     * Removes all alphabetic characters from the input string
     * and returns the numeric value as Decimal.
     * Example: "12.5MM" -> 12.5
     */
    private Decimal extractNumber(String inputValue) {
        if (String.isBlank(inputValue)) {
            return null;
        }
        String numericPart = inputValue.replaceAll('[a-zA-Z]', '');
        try {
            return Decimal.valueOf(numericPart);
        } catch (Exception e) {
            return null;
        }
    }

    private Map<String, AttributeDTO> buildAttributtesMap(AttributeDTO[] attributes) {
        Map<String, AttributeDTO> attributesMap = new Map<String, AttributeDTO>();
        for (AttributeDTO dto : attributes) {
            attributesMap.put(dto.code, dto);
        }
        return attributesMap;
    }


    /*
     * Bulds an attribute from a PIM attribute
     *
    private PIMProduct__c XXXXbuildAttribute(Id productId, String productCode, AttributeDTO dto) {
        PIMProduct__c pim = new PIMProduct__c();
        pim.Product__c = productId;
        pim.AttributeCode__c = dto.code;
        //pim.RawValue__c = dto.rawValue;
        //pim.Value__c = dto.value ?? dto.rawValue;
        pim.Unit__c = dto.unit;
        pim.Name = productCode + '--' + dto.code;
        return pim;
    }
        */

    /*
     * Reads the existing attributes of the products we are going to process
     */
    private void readExistingPIMProducts() {
        this.existingPIMProducts = new Map<Id, PIMProduct__c>();
        PIMProduct__c[] prods = [
            select Id, Product__c //, RawValue__c, Value__c
            from PIMProduct__c
            where Product__c in :this.selectedProductIds
        ];
        for (PIMProduct__c prod : prods) {
            this.existingPIMProducts.put(prod.Product__c, prod);
        }
    }

    /**
     * Builds the JSON body for a PIM request.
     * Includes a fixed list of attributes and the SKUs of the given products.
     */
    private String getJSONBody(List<CommerceEntitlementProduct> chunk) {
        
        // Lista dinámica de SKUs a partir del chunk
        List<String> products = new List<String>();
        for (CommerceEntitlementProduct cep : chunk) {
            if (cep.Product != null && String.isNotBlank(cep.Product.StockKeepingUnit)) {
                products.add(cep.Product.StockKeepingUnit);
            }
        }

        // Construir un mapa para serializar a JSON
        Map<String, Object> body = new Map<String, Object>();
        body.put('attributes', ATTRIBUTES);
        body.put('products', products);

        return JSON.serialize(body);
    }
    
    public  String normalizeRawValues(String rawJson) {
        rawJson = rawJson.replace('"date"', '"xdate"');
        Map<String,Object> parsed = (Map<String,Object>) JSON.deserializeUntyped(rawJson);             
        List<Object> data = (List<Object>) parsed.get('data');
        for (Object pObj : data) {
            Map<String,Object> product = (Map<String,Object>) pObj;            
            product.put('markets', normalizeValue(product.get('markets')));
            List<Object> attrs = (List<Object>) product.get('attributes');
            for (Object aObj : attrs) {
                Map<String,Object> attr = (Map<String,Object>) aObj;                
                attr.put('value', normalizeValue(attr.get('value')));
                attr.put('rawValue', normalizeValue(attr.get('rawValue')));
            }
        }

        return JSON.serialize(parsed);
    }

    private String normalizeValue(Object rv) {
        String normalizedValue;   
        if (rv instanceof List<Object>) {
            List<Object> lst = (List<Object>) rv;
            // Une los valores entre comillas
            List<String> quoted = new List<String>();
            for (Object o : lst) {
                quoted.add(String.valueOf(o));
            }
            normalizedValue = '[' + String.join(quoted, ',') + ']';
            normalizedValue = JSON.serialize(rv);
        } else if (rv != null) {
            normalizedValue = String.valueOf(rv);                    
        }
        return normalizedValue;
    }

    private void deleteRecords(List<SObject> records) {
        this.totalDeletes += (records?.size());
        Integer blockSize = 200;
        List<SObject> block = new List<SObject>();
        for (SObject obj : records) {
            block.add(obj);
            if (block.size() == blockSize) {
                delete block;
                block.clear();
            }
        }
        if (block.size() > 0) {
            delete block;
        }
    }

    private void insertRecords(List<SObject> records) {
        this.totalInserts += (records?.size());
        Integer blockSize = 200;
        List<SObject> block = new List<SObject>();
        for (SObject obj : records) {
            block.add(obj);
            if (block.size() == blockSize) {
                insert block;
                block.clear();
            }
        }
        if (block.size() > 0) {
            insert block;
        }
    }

    /**
     * Returns a map of picklist fields and their allowed values
     * for the PIMProduct__c object. The input is a set of field API names,
     * and the output is a map where the key is the field name and the value
     * is the list of valid picklist entries.
     */
    private void setOpenPicklistsMap() {
        this.openPicklistsMap = new Map<String, Set<String>>();
        if (this.openPicklists == null || this.openPicklists.isEmpty()) {
            return;
        }
        // Get the describe map for the object
        Map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.PIMProduct__c.fields.getMap();
        // Iterate requested fields
        for (String fieldName : this.openPicklists) {
            if (fieldsMap.containsKey(fieldName)) {
                Schema.DescribeFieldResult dfr = fieldsMap.get(fieldName).getDescribe();
                Set<String> picklistValues = new Set<String>();
                for (Schema.PicklistEntry entry : dfr.getPicklistValues()) {
                    picklistValues.add(entry.getValue());
                }
                this.openPicklistsMap.put(fieldName, picklistValues);
            }
        }
    }

    /**
     * Validates picklist values on the given PIMProduct__c record against the
     * allowed value set defined in this.openPicklistsMap. For any value not found,
     * appends a message like:
     *   'Valor no definido para picklist ***<nombre>*** (<valor>)'
     * to this.missingValues.
     *
     * - Supports single-select and multi-select picklists (splits by ';').
     * - Ignores null/blank values.
     */
    public void validatePicklists(PIMProduct__c rec) {
        if (rec == null || this.openPicklists == null || this.openPicklists.isEmpty()) return;
        if (this.missingValues == null) this.missingValues = new List<String>();

        Map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.PIMProduct__c.fields.getMap();

        for (String fieldName : this.openPicklists) {
            // Verifica que el campo exista en el objeto
            if (!fieldsMap.containsKey(fieldName)) {
                // Campo inexistente: lo consideramos como “no definible” (opcionalmente puedes registrar log)
                continue;
            }

            Schema.DescribeFieldResult dfr = fieldsMap.get(fieldName).getDescribe();

            // Obtiene el valor almacenado en el registro
            Object raw = rec.get(fieldName);
            if (raw == null) continue;

            String stored = String.valueOf(raw).trim();
            if (String.isBlank(stored)) continue;

            // Obtiene el set de valores permitidos para el campo
            Set<String> allowed = (this.openPicklistsMap != null) ? this.openPicklistsMap.get(fieldName) : null;
            if (allowed == null || allowed.isEmpty()) {
                // Si no hay catálogo para este campo, no podemos validar (opcionalmente notificar)
                continue;
            }

            // Multi-select: separar por ';' y validar cada token
            if (dfr.isAccessible() && dfr.getType() == Schema.DisplayType.MultiPicklist) {
                for (String token : stored.split(';')) {
                    String val = token.trim();
                    if (val != '' && !allowed.contains(val)) {
                        this.missingValues.add('Valor no definido para picklist ***' + fieldName + '*** (' + val + ')');
                    }
                }
            } else {
                // Single-select
                if (!allowed.contains(stored)) {
                    this.missingValues.add('Valor no definido para picklist ***' + fieldName + '*** (' + stored + ')');
                }
            }
        }
    }


    public class PIMResponseDTO {
        public String status;
        public String xdate;
        public List<ProductDTO> data;
        public String message;

    }

    /** Modelo de producto */
    public class ProductDTO {
        public String code;
        public String type;
        public Integer typeCode;
        public String typology;
        public String typology_code;
        public String description;
        public String standardDescription;
        public String standardFormat;
        public String standardFormatUSA;
        public String aproximatedFormatUSA; // puede venir null -> String permite null
        public String brand;
        public String status;
        public String priceGroup;
        public String markets;
        public String url;
        public String brandUrl; // puede ser null
        public String imagen;
        public List<AttributeDTO> attributes;

    }

    /** Modelo de atributo */
    public class AttributeDTO {
        public String code;
        public Integer id;
        public String materialSapCode;
        public String description;
        public String type;      // "N", "B", "C", etc.
        public String value;     // puede ser String, Boolean o List<String>
        public String unit;      // puede ser "-" o "approx"
        public String normative; // puede ser null
        public String rawValue;  // puede ser Number, String o List<String>
        public Boolean informative;

        /** Convierte value a String de forma segura 
        public String valueAsString() {
            if (value == null) return null;
            // Boolean
            if (value instanceof Boolean) {
                return String.valueOf((Boolean) value);
            }
            // Lista de strings
            if (value instanceof List<Object>) {
                List<Object> lst = (List<Object>) value;
                List<String> out = new List<String>();
                for (Object o : lst) out.add(o == null ? null : String.valueOf(o));
                return String.join(out, ',');
            }
            // String/Number
            return String.valueOf(value);
        }

        /** Convierte rawValue a String de forma segura (útil para logs) 
        public String rawValueAsString() {
            if (rawValue == null) return null;
            if (rawValue instanceof List<Object>) {
                List<Object> lst = (List<Object>) rawValue;
                List<String> out = new List<String>();
                for (Object o : lst) out.add(o == null ? null : String.valueOf(o));
                return String.join(out, ',');
            }
            return String.valueOf(rawValue);
        }
            */
    }
}