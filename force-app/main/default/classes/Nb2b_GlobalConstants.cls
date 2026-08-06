/*-----------------------------------------------------------------------------------------
     Apex Class:        Nb2b_GlobalConstants
     Created Date:      05/01/2022
     Author:            Cristobal Acero Lara
     Mail:              cristobal.acero@nubika.com
     Description:       Class dedicated to Global Constants in the proyect
------------------------------------------------------------------------------------------*/

public without sharing class Nb2b_GlobalConstants {

    static Nb2b_GlobalConstants instance;
    
    /*
		PRODUCT Country and Language
	*/
    public static String ZSFMAT_PAIS = 'ZSFMatPais__x';
    public static String ZB2B_PRICE1 = 'ZB2B_PRICE1__x';
    public static String ZB2B_PRICE2 = 'ZB2B_PRICE2__x';
    public static String ZB2B_PRICE3 = 'ZB2B_PRICE3__x';
    public static String WEBSTORE_UK = 'United Kingdom';
    
    /*
		Order Wrapper,Controller and Transaction
	*/
    //Wrapper
    public static String ZERO_DECIMAL_VALUE         = '0.0000';
    public static String ZERO_VALUE                 = '0';
    public static String ORDER_DISTRIBUTION_CHANNEL = '10';
    //Transaction
    public static String TRUE_STRING    = 'true';
    public static String FALSE_STRING   = 'false';
    public static String TOKEN_NAME     = 'token';
    public static String COOKIE_NAME    = 'cookie';
    //Controller
    public static String CURRENCY_ORDER_NAME    = 'currencyOrder';
    public static String CURRENCY_NAME          = 'currency';
    public static String CURRENCY_VALUE_GBP     = 'GBP';
    public static String CURRENCY_VALUE_EUR     = 'EUR';
    //Exceptions
    public static String FIELD_INTEGRITY_EXCEPTION             = 'FIELD_INTEGRITY_EXCEPTION';
    public static String FIELD_CUSTOM_VALIDATION_EXCEPTION     = 'FIELD_CUSTOM_VALIDATION_EXCEPTION';
    public static String ACCOUNT_FIELD_AFFECTED                = 'Account fields that affected this error';
    //Import from external objects
    public static String PEDIDODS_CABECERA  = 'Pedidos_cabeceraSet__x';
    public static String DRAFT_STATUS  = 'Draft';
    public static String ACTIVATED_STATUS  = 'Activated';
    //Load External Object Classes
    public static String CLASS_ORDER  = 'NB2B_OrderSyncJob';
    public static String CLASS_PRICES  = 'NB2B_PriceSyncJob';
    public static String CLASS_PRODUCTS  = 'ProductSyncJob';
    public static String CLASS_PRODUCTDT  = 'Nb2b_ProductDataTranslationSyncJob';
    public static String FACTURAS_CABECERA  = 'Facturas_cabeceraSet__x';
    public static String CLASS_INVOICES = 'NB2B_InvoiceSyncJob';
    public static Map<String, String> UNITCONVERTOR = new Map<String, String>{'CM' => 'CM', 'CM2' => 'CM2', 'CJ' => 'BOX', 'DM2' => 'DM2', 'C/U' => 'EA', 'BID' => 'BID', 'KG' => 'KG', 'M' => 'M', 'M2' => 'M2', 'MT2' => 'MT2'
    , 'PZS' => 'PZS', 'ROL' => 'ROL', 'SAC' => 'SAC', 'UN' => 'ST', 'PD2' => 'FT2', 'FLETE' => 'UN'};
    // public static Map<String, String> UNITLABELS = new Map<String, String>{'CM' => 'Centimeter', 'CM2' => 'Square centimeter', 'CJ' => 'Case', 'DM2' => 'DM2', 'C/U' => 'Each', 'BID' => 'Canister', 
    //                                                                       'KG' => 'Kilogram', 'M' => 'Meter', 'M2' => 'Square meter', 'MT2' => 'MT2',
    //                                                                       'PZS' => 'Piece', 'ROL' => 'Role', 'SAC' => 'Sac', 'UN' => 'Item', 'PD2' => 'Square foot', 'FLETE' => 'Unit','EXT' => 'Unit'};
    public static Map<String, String> UNITLABELS = new Map<String, String>{'CM' => 'Centimeter', 'CM2' => 'Square centimeter', 'CV'=> 'Box', 'CJ' => 'Box', 'DM2' => 'DM2', 'C/U' => 'Each', 'BID' => 'Canister', 
                                                                          'KG' => 'Kilogram', 'M' => 'Meter', 'M2' => 'Square meter', 'MT2' => 'MT2',
                                                                          'PZS' => 'Piece', 'ROL' => 'Role', 'SAC' => 'Sac', 'UN' => 'Item', 'PD2' => 'Square foot', 'FLETE' => 'Unit','EXT' => 'Unit'};
    public static Map<String, String> PLURALUNITLABELS = new Map<String, String>{'CM' => 'Centimeters', 'CM2' => 'Square centimeters', 'CJ' => 'Boxes','CV' => 'Boxes', 'DM2' => 'DM2', 'C/U' => 'Each', 'BID' => 'Canisters', 
                                                                          'KG' => 'Kilograms', 'M' => 'Meters', 'M2' => 'Square meters', 'MT2' => 'MT2',
                                                                          'PZS' => 'Pieces', 'ROL' => 'Roles', 'SAC' => 'Sacs', 'UN' => 'Items', 'PD2' => 'Square foots', 'FLETE' => 'Units', 'EXT' => 'Units'};
    public static Map<String, String> COUNTRYISOCODES = new Map<String, String>{'United States' => 'US', 'Canada' => 'CA', 'France' => 'FR', 'United Kingdom' => 'UK'};
    
    //ORDER
    public static String ORDER_DEFAULT_SALES_ORG = 'NONE';
    public static String ORDER_DEFAULT_SALES_OFFICE = 'NONE';
    public static String ORDER_STATUS_DRAFT = 'Draft';
    public static String ORDER_ORIGIN_B2B = 'B2B';
    public static Map<String,String> ORDER_ITEM_TYPES = new Map<String,String>{
      'Product' => 'Order Product',
      'Charge' => 'Delivery Charge'
    };

    public static final String LOGGER_B2B_SAP_INTEGRATION_TAG = 'NB2B_SAP_Integration';
    public static final String LOGGER_B2B_SAP_INTEGRATION_ERROR_TAG = 'NB2B_SAP_Integration_ERROR';
    public static final String LOGGER_B2B_SEND_EMAIL = 'NB2B_Send_Email';

    /*
        SAP ERRORS METADATA
    */
    public static final String SAP_ERROR_DISPLAY_TYPE_WARNING = 'Warning';
    public static final String SAP_ERROR_DISPLAY_TYPE_ERROR = 'Error';

    public static Map<String, NB2B_SAPOrderError__mdt> M_SAP_ERROR_BY_CODE {
        get {
            if(M_SAP_ERROR_BY_CODE == null){
                M_SAP_ERROR_BY_CODE = new Map<String, NB2B_SAPOrderError__mdt>();
                for(NB2B_SAPOrderError__mdt config: [
                    SELECT Id, MasterLabel, Block_Order__c, Display_Message__c, Display_Type__c, Message__c, Message_Type__c
                    FROM NB2B_SAPOrderError__mdt
                ]){
                    M_SAP_ERROR_BY_CODE.put(config.MasterLabel, config);
                }
                System.debug('Nb2b_GlobalConstants - M_SAP_ERROR_BY_CODE: ' + M_SAP_ERROR_BY_CODE);
            }
            return M_SAP_ERROR_BY_CODE;
        } set;
    }
}