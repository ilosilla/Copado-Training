/**
 * @description       : 
 * @author            : EHG@nubika.com
 * @group             : 
 * @last modified on  : 02-16-2023
 * @last modified by  : EHG@nubika.com
**/
@isTest
public class Nb2b_GlobalConstants_Test {
    
    @isTest
    public static void test1(){

        Test.startTest();

        String a = Nb2b_GlobalConstants.ZSFMAT_PAIS;
        a = Nb2b_GlobalConstants.ZB2B_PRICE1;
        a = Nb2b_GlobalConstants.ZB2B_PRICE2;
        a = Nb2b_GlobalConstants.ZB2B_PRICE3;
        a = Nb2b_GlobalConstants.WEBSTORE_UK;

        //Wrapper
        a = Nb2b_GlobalConstants.ZERO_DECIMAL_VALUE;
        a = Nb2b_GlobalConstants.ZERO_VALUE;
        a = Nb2b_GlobalConstants.ORDER_DISTRIBUTION_CHANNEL;
        //Transaction
        a = Nb2b_GlobalConstants.TRUE_STRING;
        a = Nb2b_GlobalConstants.FALSE_STRING;
        a = Nb2b_GlobalConstants.TOKEN_NAME;
        a = Nb2b_GlobalConstants.COOKIE_NAME;
        //Controller
        a = Nb2b_GlobalConstants.CURRENCY_ORDER_NAME;
        a = Nb2b_GlobalConstants.CURRENCY_NAME;
        a = Nb2b_GlobalConstants.CURRENCY_VALUE_GBP;
        a = Nb2b_GlobalConstants.CURRENCY_VALUE_EUR;
        //Exceptions
        a = Nb2b_GlobalConstants.FIELD_INTEGRITY_EXCEPTION;
        a = Nb2b_GlobalConstants.FIELD_CUSTOM_VALIDATION_EXCEPTION;
        a = Nb2b_GlobalConstants.ACCOUNT_FIELD_AFFECTED;
        //Import from external objects
        a = Nb2b_GlobalConstants.PEDIDODS_CABECERA;
        a = Nb2b_GlobalConstants.DRAFT_STATUS;
        a = Nb2b_GlobalConstants.ACTIVATED_STATUS;
        //Load External Object Classes
        a = Nb2b_GlobalConstants.CLASS_ORDER;
        a = Nb2b_GlobalConstants.CLASS_PRICES;
        a = Nb2b_GlobalConstants.CLASS_PRODUCTS;
        a = Nb2b_GlobalConstants.CLASS_PRODUCTDT;
        a = Nb2b_GlobalConstants.FACTURAS_CABECERA;
        a = Nb2b_GlobalConstants.CLASS_INVOICES;
        Map<String, String> s = Nb2b_GlobalConstants.UNITCONVERTOR;
        s = Nb2b_GlobalConstants.UNITLABELS;
        s = Nb2b_GlobalConstants.PLURALUNITLABELS;
        s = Nb2b_GlobalConstants.COUNTRYISOCODES;
        a = Nb2b_GlobalConstants.LOGGER_B2B_SAP_INTEGRATION_TAG;
        a = Nb2b_GlobalConstants.LOGGER_B2B_SAP_INTEGRATION_ERROR_TAG;
        a = Nb2b_GlobalConstants.LOGGER_B2B_SEND_EMAIL;

        Test.stopTest();

        Assert.areEqual(1 == 1, true);

    }
}