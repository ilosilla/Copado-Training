/**
* @author 		Ivan Losilla
* @date 		July 2022
* @group 		SapQuotes
* @description 	sap quotes selector class
*/
public class SapQuotesSelector extends zflib_SObjectSelector  {
    public Schema.SObjectType getSObjectType(){
        return Ofertas_cabeceraSet__x.sObjectType;
    }

    public List<Ofertas_cabeceraSet__x> selectById(Set<Id> recordIds){
        return (List<Ofertas_cabeceraSet__x>) selectSObjectsById(recordIds);
    }

    public Ofertas_cabeceraSet__x selectById(Id recordId){
        List<Ofertas_cabeceraSet__x> listSapQuotes = (List<Ofertas_cabeceraSet__x>) selectSObjectsById(new Set<Id>{recordId});
        if (listSapQuotes.size() == 1) {
            return listSapQuotes[0];
        }
        return null;
    }

    public String selectSapSyncString(){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('OrderDate__c = LAST_N_DAYS:1');
        return query.toSOQL();
    }

    public String selectAllString(){
        zflib_QueryFactory query = newQueryFactory();
        return query.toSOQL();
    }
   
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {

            // Salesforce Data
            Ofertas_cabeceraSet__x.Id,
            Ofertas_cabeceraSet__x.Account__c,
            Ofertas_cabeceraSet__x.CurrencyIsoCode,
            Ofertas_cabeceraSet__x.ID18__c,
            Ofertas_cabeceraSet__x.Sfopportunity__c,

            // Date Fields
            Ofertas_cabeceraSet__x.Ddate__c,
            Ofertas_cabeceraSet__x.Erdat__c,
            Ofertas_cabeceraSet__x.Orderdate__c,
            
            // Order Data
            Ofertas_cabeceraSet__x.BillTo__c,
            Ofertas_cabeceraSet__x.Comis2__c,
            Ofertas_cabeceraSet__x.Comis__c,
            Ofertas_cabeceraSet__x.Company__c,
            Ofertas_cabeceraSet__x.Credit__c,
            Ofertas_cabeceraSet__x.Customer__c,
            Ofertas_cabeceraSet__x.Dcurr__c,
            Ofertas_cabeceraSet__x.DisplayUrl,
            Ofertas_cabeceraSet__x.Distchannel__c,
            Ofertas_cabeceraSet__x.Division__c,
            Ofertas_cabeceraSet__x.Erzet__c,
            Ofertas_cabeceraSet__x.Exratet__c,
            Ofertas_cabeceraSet__x.Exrate__c,
            Ofertas_cabeceraSet__x.ExternalId,
            Ofertas_cabeceraSet__x.OpenF__c,
            Ofertas_cabeceraSet__x.Ordernum__c,
            Ofertas_cabeceraSet__x.Ordertype__c,
            Ofertas_cabeceraSet__x.Paid__c,
            Ofertas_cabeceraSet__x.PaisDestino__c,
            Ofertas_cabeceraSet__x.Probld__c,
            Ofertas_cabeceraSet__x.Refer__c,
            Ofertas_cabeceraSet__x.Repo1__c,
            Ofertas_cabeceraSet__x.Repo2__c,
            Ofertas_cabeceraSet__x.Salesoffic__c,
            Ofertas_cabeceraSet__x.Salesorg__c,
            Ofertas_cabeceraSet__x.Trvog__c,
            Ofertas_cabeceraSet__x.Vbtyp__c,

            // Cost fields
            Ofertas_cabeceraSet__x.Dnet__c,
            Ofertas_cabeceraSet__x.Doc__c,
            Ofertas_cabeceraSet__x.Dtax__c,
            Ofertas_cabeceraSet__x.Dtotal__c,
            Ofertas_cabeceraSet__x.Gcurr__c,
            Ofertas_cabeceraSet__x.Gnet__c,
            Ofertas_cabeceraSet__x.Gtax__c,
            Ofertas_cabeceraSet__x.Gtotal__c,
            Ofertas_cabeceraSet__x.Lcurr__c,
            Ofertas_cabeceraSet__x.Lnet__c,
            Ofertas_cabeceraSet__x.Ltax__c,
            Ofertas_cabeceraSet__x.Ltotal__c
        };
    }
}