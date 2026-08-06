/**
 * @author         Ramón Prades
 * @date           November 2025
 * @layer          Services
 * @description    Acceso a los servicios de stock de SAP
*/
public class SAPStockService {
    
    public static StockResultDTO retrieveStockInSalesOrg(String productCode, String salesOrg) {
        StockResultDTO result = new StockResultDTO();
        result.Productcode = productCode;        
        String serviceUrl = SAPCPIProxy.STOCK_ENDPOINT.replace('{sales-org}', salesOrg).replace('{product-code}', productCode);
        SAPCPIProxy proxy = new SAPCPIProxy(serviceUrl);
        proxy.setMethod('GET');
        proxy.setQueryString('intransit=true&usetoday=true');   // Bring in transit and report first delivery after today
        try {
            String response = proxy.callCPI();
            List<SAPStockItemDTO> sapResults = (List<SAPStockItemDTO>) JSON.deserialize(response, List<SAPStockItemDTO>.class);                        
            if (sapResults.size() > 0) {
                SAPStockItemDTO item = sapResults[0];
                result.productCode = item.product;
                result.productName = item.name;
                result.salesOrg = salesOrg;
                result.plant = item.plant;
                result.warehouse = item.warehouse;
                result.stockAvailable = item.availstk;
                result.stockTotal = item.totalstk;
                result.stockInTransit = item.intransit;
                result.firstInTransitDate = item.next_intransit; // Date.newInstance(2026, 2, 14)
                result.umb = item.umb_en;                
            }
        } catch (HttpException hex) {
            Map<String, Object> context = new Map<String, Object>{
                    'ProductCode' => productCode,
                    'SalesOrg'    => salesOrg,
                    'Endpoint'    => serviceUrl
                };
            String[] hints = new List<String> {
                    'La llamada se hace en la clase SAPStockService.cls', 
                    'Validar usuario y contraseña en las credenciales de aceso a SAP',
                    'Comprobar que CPI está activo',                    
                    'Verificar la configuración de STOCK_ENDPOINT'
                };
            SystemAlert alert = new SystemAlert('B2B - STOCK ERROR', SystemAlert.Severity.HIGH)
                .withContext(context)
                .withHints(hints)
                .withException(hex)
                .withDedupKey('B2B_STOCK_ERROR_' + productCode);
            SystemAlertService.notify(alert);
            throw hex;
        }
        return result;
    }

    /**
     * Stock total agregado de un producto en las plantas dadas, sin desglose por lote.
     * Para markets sin shade (ctx.market.shadeEnabled = false, o producto no es tile).
     *
     * @param plants          Plantas (con sus almacenes) a consultar.
     * @param product         SKU a consultar.
     * @param includeTransit  Si se incluye stock en tránsito (filiales sí, directo no).
     * @return                Una única fila con lote en blanco (agregado). Cantidades a 0 si no hay stock.
     */
    public static StockRowResult getStockTotal(List<PlantInput> plants, String product, Boolean includeTransit) {
        StockQueryOptions opts = buildOptions(includeTransit);
        opts.detailByLote = false;
        StockQueryResponse resp = queryStock(plants, new List<String>{ product }, opts);
        List<StockRowResult> rows = toStockRowResults(resp);
        if (rows.isEmpty()) {
            StockRowResult empty = new StockRowResult();
            empty.availableQty = 0;
            empty.totalQty     = 0;
            empty.inTransitQty = 0;
            return empty;
        }
        return rows[0];
    }

    /**
     * Stock desglosado por lote/tono de un producto en las plantas dadas.
     * Para markets con shade (ctx.market.shadeEnabled = true y producto es tile).
     *
     * @param plants          Plantas (con sus almacenes) a consultar.
     * @param product         SKU a consultar.
     * @param includeTransit  Si se incluye stock en tránsito (filiales sí, directo no).
     * @return                Una fila por lote. Lista vacía si no hay stock en ningún lote.
     */
    public static List<StockRowResult> getStockByLote(List<PlantInput> plants, String product, Boolean includeTransit) {
        StockQueryOptions opts = buildOptions(includeTransit);
        opts.detailByLote = true;
        StockQueryResponse resp = queryStock(plants, new List<String>{ product }, opts);
        return toStockRowResults(resp);
    }

    /**
     * V2 stock query. Reads stock for one or more products across one or more
     * plants (each with optional warehouses) in a single POST call.
     *
     * @param plants    Plants (with their warehouses) to query.
     * @param products  SKUs to query.
     * @param options   Query options (mode, aggregation, in-transit, shade detail...).
     * @return          Parsed V2 response (data rows + errors + status).
     */
    private static StockQueryResponse queryStock(List<PlantInput> plants, List<String> products, StockQueryOptions options) {
        StockQueryRequest requestBody = new StockQueryRequest();
        requestBody.plants = plants;
        requestBody.products = products;
        requestBody.options = options;

        SAPCPIProxy proxy = new SAPCPIProxy(SAPCPIProxy.STOCK_QUERY_ENDPOINT);
        proxy.setMethod('POST');
        proxy.setJSONBody(JSON.serialize(requestBody, true));   // suppress nulls
        try {
            String response = proxy.callCPI();
            return (StockQueryResponse) JSON.deserialize(response, StockQueryResponse.class);
        } catch (HttpException hex) {
            Map<String, Object> context = new Map<String, Object>{
                    'Products' => products,
                    'Endpoint' => SAPCPIProxy.STOCK_QUERY_ENDPOINT
                };
            String[] hints = new List<String> {
                    'La llamada se hace en la clase SAPStockService.cls (queryStock)',
                    'Validar usuario y contraseña en las credenciales de aceso a SAP',
                    'Comprobar que CPI está activo',
                    'Verificar la configuración de STOCK_QUERY_ENDPOINT'
                };
            SystemAlert alert = new SystemAlert('B2B - STOCK ERROR', SystemAlert.Severity.HIGH)
                .withContext(context)
                .withHints(hints)
                .withException(hex)
                .withDedupKey('B2B_STOCK_QUERY_ERROR');
            SystemAlertService.notify(alert);
            throw hex;
        }
    }

    private static StockQueryOptions buildOptions(Boolean includeTransit) {
        StockQueryOptions opts = new StockQueryOptions();
        opts.useDefaultWarehouseWhenMissing = true;
        opts.aggregateByPlant = true;
        opts.mode = 'tolerant';
        opts.includeSpecial = false;
        opts.intransit = includeTransit;
        opts.usetoday = includeTransit;
        return opts;
    }

    private static List<StockRowResult> toStockRowResults(StockQueryResponse resp) {
        if (resp.status == 'ERROR') {
            throw new StockQueryException(String.join(resp.errors, '; '));
        }
        List<StockRowResult> rows = new List<StockRowResult>();
        for (StockQueryItem item : resp.data) {
            StockRowResult row     = new StockRowResult();
            row.lote               = item.lote;
            row.availableQty       = item.availstk;
            row.totalQty           = item.totalstk;
            row.inTransitQty       = item.intransit;
            row.firstInTransitDate = String.isBlank(item.first_transit) ? null : Date.valueOf(item.first_transit);
            row.unit               = item.umb_en;
            rows.add(row);
        }
        return rows;
    }

    public class StockQueryException extends Exception {}

    public class StockRowResult {
        public String  lote;
        public Decimal availableQty;
        public Decimal totalQty;
        public Decimal inTransitQty;
        public Date    firstInTransitDate;
        public String  unit;
    }

    /* ========================================================= */
    /* V2 DTOs                                                    */
    /* ========================================================= */

    public class StockQueryRequest {
        public List<PlantInput>    plants;
        public List<String>        products;
        public StockQueryOptions   options;
    }

    public class PlantInput {
        public String       plant;
        public List<String> warehouses;
    }

    public class StockQueryOptions {
        public Boolean useDefaultWarehouseWhenMissing;
        public Boolean aggregateByPlant;
        public Boolean intransit;
        public Boolean usetoday;
        public Boolean detailByLote;
        public Boolean includeSpecial;
        public String  mode;
    }

    public class StockQueryResponse {
        public List<StockQueryItem> data;
        public List<String>         errors;
        public String               status;   // OK | PARTIAL_SUCCESS | ERROR
    }

    public class StockQueryItem {
        public String  product;
        public String  name;
        public String  plant;
        public String  warehouse;
        public Decimal availstk;
        public Decimal totalstk;
        public Decimal intransit;
        public String  umb;
        public String  umb_en;
        public String  next_production;   // SAP sends "" when not applicable, not a real Date
        public String  first_transit;     // "" or "YYYY-MM-DD"
        public String  lote;
    }

    public class StockResultDTO {
        public String productCode;
        public String productName;
        public String salesOrg;
        public String plant;
        public String warehouse;
        public Decimal stockAvailable;
        public Decimal stockTotal;
        public Decimal stockInTransit;
        public Date firstInTransitDate;
        public String umb;
    }

    private class SAPStockItemDTO {
        public String product;
        public String name;
        public String plant;
        public String warehouse;
        public Decimal availstk;
        public Decimal totalstk;
        public Decimal intransit;
        public String umb;
        public String umb_en;
        public Date next_production;
        public Date next_intransit;
    }
}