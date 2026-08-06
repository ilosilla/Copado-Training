/**
* @author 		Ivan Losilla
* @date 		July 2022
* @group 		Sap Orders
* @description 	sap orders selector class
*/
public class SAPOrdersSelector extends zflib_SObjectSelector  {
    public Schema.SObjectType getSObjectType(){
        return Pedidos_cabeceraSet__x.sObjectType;
    }

    public List<Pedidos_cabeceraSet__x> selectById(Set<Id> recordIds){
        return (List<Pedidos_cabeceraSet__x>) selectSObjectsById(recordIds);
    }

    public Pedidos_cabeceraSet__x selectById(Id recordId){
        List<Pedidos_cabeceraSet__x> listSapOrders = (List<Pedidos_cabeceraSet__x>) selectSObjectsById(new Set<Id>{recordId});
        if (listSapOrders.size() == 1) {
            return listSapOrders[0];
        }
        return null;
    }

    public String selectSapSyncString(){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('OrderDate__c = LAST_N_DAYS:1');
        return query.toSOQL();
    }
   
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {

            // Salesforce Data
            Pedidos_cabeceraSet__x.Id,
            Pedidos_cabeceraSet__x.Account__c,
            Pedidos_cabeceraSet__x.id18__c,
            Pedidos_cabeceraSet__x.Sfopportunity__c,
            Pedidos_cabeceraSet__x.CurrencyIsoCode,

            // Date Fields
            Pedidos_cabeceraSet__x.Orderdate__c,
            Pedidos_cabeceraSet__x.Ddate__c,
            Pedidos_cabeceraSet__x.Erdat__c,
            
            // Order Data
            Pedidos_cabeceraSet__x.ExternalId,
            Pedidos_cabeceraSet__x.BillTo__c,
            Pedidos_cabeceraSet__x.Comis2__c,
            Pedidos_cabeceraSet__x.Comis__c,
            Pedidos_cabeceraSet__x.Company__c,
            Pedidos_cabeceraSet__x.Credit__c,
            Pedidos_cabeceraSet__x.Customer__c,
            Pedidos_cabeceraSet__x.DisplayUrl,
            Pedidos_cabeceraSet__x.Distchannel__c,
            Pedidos_cabeceraSet__x.Division__c,
            Pedidos_cabeceraSet__x.Doc__c,
            Pedidos_cabeceraSet__x.Exratet__c,
            Pedidos_cabeceraSet__x.Erzet__c,
            Pedidos_cabeceraSet__x.Exrate__c,
            Pedidos_cabeceraSet__x.OpenF__c,
            Pedidos_cabeceraSet__x.Ordernum__c,
            Pedidos_cabeceraSet__x.Ordertype__c,
            Pedidos_cabeceraSet__x.Paid__c,
            Pedidos_cabeceraSet__x.PaisDestino__c,
            Pedidos_cabeceraSet__x.Probld__c,
            Pedidos_cabeceraSet__x.Refer__c,
            Pedidos_cabeceraSet__x.Repo1__c,
            Pedidos_cabeceraSet__x.Repo2__c,
            Pedidos_cabeceraSet__x.Salesoffic__c,
            Pedidos_cabeceraSet__x.Salesorg__c,
            Pedidos_cabeceraSet__x.status__c,
            Pedidos_cabeceraSet__x.Trvog__c,
            Pedidos_cabeceraSet__x.Vbtyp__c,

            // Cost fields
            Pedidos_cabeceraSet__x.Dcurr__c,
            Pedidos_cabeceraSet__x.Dnet__c,
            Pedidos_cabeceraSet__x.Dtax__c,
            Pedidos_cabeceraSet__x.Dtotal__c,
            Pedidos_cabeceraSet__x.Gcurr__c,
            Pedidos_cabeceraSet__x.Gnet__c,
            Pedidos_cabeceraSet__x.Gtax__c,
            Pedidos_cabeceraSet__x.Gtotal__c,
            Pedidos_cabeceraSet__x.Lcurr__c,
            Pedidos_cabeceraSet__x.Lnet__c,
            Pedidos_cabeceraSet__x.Ltax__c,
            Pedidos_cabeceraSet__x.Ltotal__c

        };
    }
}