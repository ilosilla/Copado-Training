/**
* @author 		   Ramón Prades
* @date 		   September 2022
* @group 		   SAP Invoices
* @description 	   Factura_PosicionesSet__x selector class
* ---
* We don't follow the naming rule because the name of the table is awful so the more
* descriptive name "SAPInvoiceLines" has been used instead. 
*
* To retrieve the lines of the invoice use class SAPInvoiceLinesSelector.
*
* Also, we do not extend zflib_SObjectSelector because external objects give too many problems.
*/
public class SAPInvoiceLinesSelector {
   
    /**
     * Searches an invoice per number
     */
    public Facturas_posicionesSet__x[] selectByNumber(String num) {
       Set<String> numbers = new Set<String>{num};
       List<Facturas_posicionesSet__x> result = this.selectByNumber(numbers);
       if (result.size() > 0) {
          return result;
       } else {
          throw new ObjectNotFoundException();
       }
    } // selectByNumber
 
    /**
     * Searches invoices per invoice number (it is unique)
     */
    public List<Facturas_posicionesSet__x> selectByNumber(Set<String> numbers){
       String selectSentence = 'select ' + this.getSelectClause() + ' from Facturas_posicionesSet__x where ordernum__c in :numbers';
       if (Test.isRunningTest()) {
          return new DataFactorySAPSalesDocs().getInvoiceLines(numbers);
       } else {
          return Database.query(selectSentence);
       }
    }
 
    public String getSelectClause(){
       String selectClause = 'aubel__c,'
        + 'aupos__c,'
        + 'Cost__c,'
        + 'Dcurr__c,'
        + 'Dnet__c,'
        + 'Dtax__c,'
        + 'Dtotal__c,'
        + 'Erdat__c,'
        + 'Erzet__c,'
        + 'Fecha_Entrega__c,'
        + 'Finishing__c,'
        + 'FormatSf__c,'
        + 'Gcurr__c,'
        + 'Gnet__c,'
        + 'Gtax__c,'
        + 'Gtotal__c,'
        + 'Hierarchy__c,'
        + 'Lcurr__c,'
        + 'Lnet__c,'
        + 'Ltax__c,'
        + 'Ltotal__c,'
        + 'Make__c,'
        + 'Mat3__c,'
        + 'Mat5__c,'
        + 'Name__c,'
        + 'OpenF__c,'
        + 'Orderlin__c,'
        + 'Ordernum__c,'
        + 'Pedido__c,'
        + 'Pospedido__c,'
        + 'Posreferd__c,'
        + 'Quantity__c,'
        + 'Referedoc__c,'
        + 'Salesoffic__c,'
        + 'Series__c,'
        + 'Sku__c,'
        + 'Sqmetres__c,'
        + 'Szone__c,'
        + 'Tariff__c,'
        + 'Unitcode__c,'
        + 'Vrkme__c,'
        + 'Zmetres__c,'
        + 'Zunits__c,'
        + 'Werks__c,' 
        + 'Lgort__c';
       return selectClause;
 
    }
 
 } // class