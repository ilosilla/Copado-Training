/**
 * @author         Ramón Prades
 * @date           January 2026
 * @layer          Utils
 * @description    Utility method to support B2B Commerce operations
*/
@SuppressWarnings('PMD.ExcessiveParameterList')
public without sharing class B2B_CommerceUtils {

    public static final Integer MIN_PALLETS = 0;
    public static final Integer MIN_PIECES  = 0;

    /**
     * Obtiene el Pricebook2Id aplicable para una cuenta en una tienda específica.
     * Prioriza según el campo Priority de la asociación del Buyer Group.
     */
    public static Id getApplicablePricebookId(Id accountId, Id webStoreId) {
        Id pricebookId = null;

        // 1. Buscamos los Price Books a través de los Buyer Groups vinculados a la tienda
        // que contienen a la cuenta especificada.
        List<BuyerGroupPricebook> bgPricebooks = [
            SELECT Pricebook2Id, Priority
            FROM BuyerGroupPricebook
            WHERE BuyerGroupId IN (
                SELECT BuyerGroupId 
                FROM WebStoreBuyerGroup 
                WHERE WebStoreId = :webStoreId
            )
            AND BuyerGroupId IN (
                SELECT BuyerGroupId 
                FROM BuyerGroupMember 
                WHERE BuyerId = :accountId
            )
            AND IsActive = true
            ORDER BY Priority ASC NULLS LAST, Pricebook2.Name ASC
            LIMIT 1
        ];

        if (!bgPricebooks.isEmpty()) {
            pricebookId = bgPricebooks[0].Pricebook2Id;    
        }

        return pricebookId;
    }

    /**
     * Decide si un producto está en stock según las reglas de negocio definidas.
     */
    public static String getStockStatus(Decimal availableStock, Decimal onHandStock, Decimal inTransitStock, String salesUnit, Integer pcsPerBox, Integer boxPerPal) {
        // Hay stock disponible
        if (availableStock > 0) {
            // Unidades que dependen de pallets
            /*
            if (salesUnit == 'BOX' || salesUnit == 'CJ' || salesUnit == 'SQF' || salesUnit == 'MT2') {
                // available → pallets
                Decimal pallets = availableStock / pcsPerBox / boxPerPal;
                if (pallets <= MIN_PALLETS) {
                    return 'LOW';
                }
                return 'IN_STOCK';
            }

            // Otras unidades: umbral fijo
            if (availableStock > MIN_PIECES) {
                return 'IN_STOCK';
            }
            return 'LOW';
            */
            return 'IN_STOCK';
        }

        // No hay disponible, pero viene en camino
        if (inTransitStock > 0) {
            return 'SOON';
        }

        // 3 Nada de nada
        return 'OUT';
    }

    /**
     * Devuelve los datos de configuración del almacen B2B de una store
     */
    public PorcelanosaAddress__c getB2BWarehouse(String salesOrg) { 
        PorcelanosaAddress__c address = null;       
        PorcelanosaAddress__c[] addresses = new PorcelanosaAddressesSelector().selectBySalesOrg(new Set<String>{salesOrg});
        for (PorcelanosaAddress__c addr : addresses) {
            address = addr; //
            if (addr.NBK_Address_Type__c != null && addr.NBK_Address_Type__c.contains('B2B-Warehouse')) {
                break;
            } 
        }
        return address;
    }

    /**
     * Recupera el custom setting de configuración de la store
     */
    public static PORSAStoreSettings__c resolveStoreSettings() {
        String storeVariant = 'US_DEALERS';
        PORSAStoreSettings__c cfg = PORSAStoreSettings__c.getInstance(storeVariant);
        if (cfg == null) {
            // Intentamos con el default
            cfg = new PORSAStoreSettings__c();
            cfg.EnableSAPPriceValidation__c = true;
        }

        return cfg;

        // FUTURO
        // User u = [
        //   SELECT CustomStoreVariant__c
        //   FROM User
        //   WHERE Id = :UserInfo.getUserId()
        // ];
        // return String.isBlank(u.CustomStoreVariant__c)
        //     ? 'DEFAULT'
        //     : u.CustomStoreVariant__c;
    }

}