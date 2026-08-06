/**
 * @author         Ramón Prades
 * @date           January 2026
 * @layer          Services
 * @description    Returns stock figures for a list of SKUs.
 *                 Stock values are derived from periodic SAP stock snapshots
 *                 and do not reflect real-time availability.
 */
public without sharing class StockSnapshotService {
    
    /**
     * @description Returns aggregated stock snapshot figures for a list of SKUs.
     *              Data is taken from the latest SAP stock snapshots (hourly),
     *              not from real-time stock.
     */
    public static Map<String, StockSnapshotDTO> getStockBySku(String plant, List<String> warehouses, List<String> skus) {
        Map<String, StockSnapshotDTO> result = new Map<String, StockSnapshotDTO>();

        if (skus == null || skus.isEmpty()) {
            return result;
        }
        if (String.isBlank(plant) || warehouses == null || warehouses.isEmpty()) {
            return result;
        }

        List<SAP_StockSnapshots__x> rows = [
            SELECT
                StockKeepingUnit__c,
                StockUnit__c,
                AvailableStock__c,
                OnHandStock__c,
                InTransitStock__c
            FROM SAP_StockSnapshots__x
            WHERE
                Plant__c = :plant
                AND Warehouse__c IN :warehouses
                AND StockKeepingUnit__c IN :skus
        ];

        return parseStockResults(rows);

    }

    private static Map<String, StockSnapshotDTO> parseStockResults(List<SAP_StockSnapshots__x> rows) {
        Map<String, StockSnapshotDTO> result = new Map<String, StockSnapshotDTO>();
        for (SAP_StockSnapshots__x row : rows) {
            String sku = row.StockKeepingUnit__c;
            if (String.isBlank(sku)) {
                continue;
            }
            StockSnapshotDTO dto;
            if (!result.containsKey(sku)) {
                dto = new StockSnapshotDTO();
                dto.sku = sku;
                dto.stockUnit = row.StockUnit__c;
                dto.availableStock = 0;
                dto.onHandStock = 0;
                dto.inTransitStock = 0;
                result.put(sku, dto);
            } else {
                dto = result.get(sku);
            }
            // Aggregate
            dto.availableStock += row.AvailableStock__c != null ? row.AvailableStock__c : 0;
            dto.onHandStock    += row.OnHandStock__c    != null ? row.OnHandStock__c    : 0;
            dto.inTransitStock += row.InTransitStock__c != null ? row.InTransitStock__c : 0;
        }
        return result;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    @testVisible private static Map<String, StockSnapshotDTO> getMockStockBySku(String plant, List<String> warehouses, List<String> skus, List<SAP_StockSnapshots__x> mockData) {
        return parseStockResults(mockData);
    }

    public class StockSnapshotDTO {
        public String sku;
        public Decimal availableStock;
        public Decimal onHandStock;
        public Decimal inTransitStock;
        public String stockUnit;
    }

}