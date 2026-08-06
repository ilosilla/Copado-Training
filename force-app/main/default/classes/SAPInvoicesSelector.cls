/**
* @author 		   Ramón Prades
* @date 		      May 2022
* @group 		   SAP Invoices
* @description 	Factura_CabeceraSet__x selector class
* ---
* We don't follow the naming rule because the name of the table is awful so the more
* descriptive name "SAPInvoices" has been used instead. 
*
* To retrieve the lines of the invoice use class SAPInvoiceLinesSelector.
*
* Also, we do not extend zflib_SObjectSelector because external objects give too many problems.
*/
public class SAPInvoicesSelector  {   
   
   /**
    * Searches an invoice per number
    */
   public Facturas_cabeceraSet__x selectByNumber(String num) {
      Set<String> numbers = new Set<String>{num};
      List<Facturas_cabeceraSet__x> result = this.selectByNumber(numbers);
      if (result.size() >= 1) {
         return result[0];
      } else {
         throw new ObjectNotFoundException('Invoice ' + num + ' not found!');
      }
   } // selectByNumber

   /**
    * Searches invoices per invoice number (it is unique)
    */
   public List<Facturas_cabeceraSet__x> selectByNumber(Set<String> numbers){
      String selectSentence = 'select ' + this.getSelectClause() + ' from Facturas_CabeceraSet__x where ordernum__c in :numbers';
      if (Test.isRunningTest()) {
         return new DataFactorySAPSalesDocs().getInvoiceHeaders(numbers);
      } else {
         return Database.query(selectSentence);
      }
   }

   public String getSelectClause(){
      String selectClause = 'Account__c,' +
                              'BillTo__c,' +
                              'Comis__c,' +
                              'Comis2__c,' +
                              'Company__c,' +
                              'credit__c,' +
                              'customer__c,' +
                              'Dcurr__c,' +
                              'Ddate__c,' +
                              'Distchannel__c,' +
                              'Division__c,' +
                              'Dnet__c,' +
                              'Dtax__c,' +
                              'Dtotal__c,' +
                              'Exrate__c,' +
                              'Gcurr__c,' +
                              'Gnet__c,' +
                              'Gtax__c,' +
                              'Gtotal__c,' +
                              'id18__c,' +
                              'Lcurr__c,' +
                              'Lnet__c,' +
                              'Ltax__c,' +
                              'Ltotal__c,' +
                              'OpenF__c,' +
                              'Orderdate__c,' +
                              'Ordernum__c,' +
                              'Ordertype__c,' +
                              'Paid__c,' +
                              'PaisDestino__c,' +
                              'Refer__c,' +
                              'Repo1__c,' +
                              'Repo2__c,' +
                              'SALESOFFIC__c,' +
                              'Salesorg__c,' +
                              'Sfopportunity__c,' +
                              'Szone__c';      
      return selectClause;

   }

} // class