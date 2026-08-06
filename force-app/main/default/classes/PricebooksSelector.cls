/**
* @author 		Ivan Losilla
* @date 		July 2022
* @group 		Pricebooks
* @description 	pricebooks selector class
*/
public class PricebooksSelector extends zflib_SObjectSelector  {
    public Schema.SObjectType getSObjectType(){
        return Pricebook2.sObjectType;
    }

    public List<Pricebook2> selectById(Set<Id> recordIds){
        return (List<Pricebook2>) selectSObjectsById(recordIds);
    }

    public Pricebook2 selectCountryReference(String country){
        Pricebook2 pb = null;
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('IsRetailReferencePricebook__c = true and CountryCode__c = :country');
        Pricebook2[] results = (List<Pricebook2>) Database.query(query.toSOQL());
        if (results.size() > 0) {
            pb = results[0];
        } else {
            throw new ObjectNotFoundException('No referecne pricebook found for this country');
        }
        return pb;
    }

    public Pricebook2 selectSalesOrgReference(String salesOrg) {
        Sales_Org__c[] orgs = [select CountryCode__c, CurrencyIsoCode from Sales_Org__c where SalesOrg__c = :salesOrg];
        if (orgs.size() == 0) {
            throw new ObjectNotFoundException('Sales Org ' + salesOrg + ' not found');
        }
        return this.selectCountryReference(orgs[0].CountryCode__c);
    }

    public List<Pricebook2> selectByExecutionContext(String executionContextCode){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('ExecutionContext__c = :executionContextCode');
        return (List<Pricebook2>) Database.query( query.toSOQL() );
    }

    public List<Pricebook2> selectStandardPricebook(){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('IsStandard = true');
        return (List<Pricebook2>) Database.query( query.toSOQL() );
    }

    public Pricebook2 selectClaimsPricebook(String currencyCode){
        Pricebook2 book = null;
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('IsForClaims__c = true AND currencyIsoCode = \'' + currencyCode + '\'');
        List<Pricebook2> books = (List<Pricebook2>) Database.query( query.toSOQL() );
        if (books.size() > 0) {
            book = books[0];
        } else {
            throw new ObjectNotFoundException('No claims pricebooks found for the given currency');
        }
        return book;
    }

    public List<Pricebook2> selectByTariffs(Set<String> tariffsCodes){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('Bzirk__c IN :tariffsCodes');
        return (List<Pricebook2>) Database.query( query.toSOQL() );
    }

    public List<Pricebook2> selectBySapSync(){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('SapSync__c = true and isActive = true');
        return (List<Pricebook2>) Database.query( query.toSOQL() );
    }

    public List<Pricebook2> selectByName(String pricebookName){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('Name = :pricebookName');
        return (List<Pricebook2>) Database.query( query.toSOQL() );
    }
   
    public List<Schema.SObjectField> getSObjectFieldList() {
        SObjectType caseType = Schema.getGlobalDescribe().get('Pricebook2');
        Map<String,Schema.SObjectField> mfields = caseType.getDescribe().fields.getMap();
        List<Schema.SObjectField> fields = mfields.values();
        return fields;
    }
}