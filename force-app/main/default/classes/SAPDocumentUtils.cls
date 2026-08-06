/**
* @author 			Ramón Prades
* @date 			February-2021
* @group 			SAP Documents
* @group-content 	../../ApexDocContent/sapdocs.htm
* @description 	    Utility methods tfpor sap documents (Z-tables)
*/
public class SAPDocumentUtils {

    private static String completed = 'C';
    private static String partial = 'B';

    public static Map<String, Double> getInvoiced(String orderNum) {
        Double net = 0;
        Double tax = 0;
        List<Facturas_posicionesSet__x> facturas = [select aubel__c, lnet__c, ltax__c, ltotal__c from Facturas_posicionesSet__x where aubel__c = :orderNum.leftPad(10, '0')];
        for(Facturas_posicionesSet__x factura :facturas) {
            net += factura.lnet__c;
            tax += factura.ltax__c;                
        }
        Map<String, Double> m = new Map<String, Double>();       
        m.put('net', net);
        m.put('tax', tax);
        return m;
    }

    public static Boolean isSamplesDocument(String docType, String sapType, Double amount) {
        if (amount == 0) {
            return true;
        }
        if (docType == 'O' && sapType == 'Z010') {
            return true;
        }
        if (docType == 'I' && sapType == 'Z004') {
            return true;
        }
        return false;
    }

    public static Boolean isQuoteClosed(String status) {
        return (status == completed);
    }

    public static Boolean isOrderClosed(String status) {
        return (status == completed);
    }

    public static Boolean isQuotePartiallyClosed(String status) {
        return (status == partial);
    }

    public static Boolean isOrderPartiallyClosed(String status) {
        return (status == partial);
    }


}