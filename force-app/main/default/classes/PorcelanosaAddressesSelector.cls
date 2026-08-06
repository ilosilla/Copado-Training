/**
* @author         Ramón Prades
* @date           May 2023
* @group          Product List Items
* @description    Selector class. 
*                 Aprovechamos esta clase y su test como test de zflib_SObejctSelectoir_v2
*/
public class PorcelanosaAddressesSelector extends zflib_SObjectSelector_v2 {

    public override String getTypeName() {
        return 'PorcelanosaAddress__c';
    }

    public List<PorcelanosaAddress__c> selectByCountry(Set<String> countryCodes){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('NBK_Address__CountryCode__s IN :countryCodes AND NBK_isActive__c = true');
        return (List<PorcelanosaAddress__c>) Database.query( query.toSOQL() );
    }

    /**
     * Selects addresses in the oassed SAO salkes org codes
     */
    public List<PorcelanosaAddress__c> selectBySalesOrg(Set<String> salesOrgs){
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('SAPSalesOrg__c IN :salesOrgs AND NBK_isActive__c = true');
        return (List<PorcelanosaAddress__c>) Database.query( query.toSOQL() );
    }

    /**
     * Selects colleciton points in a list of sales orgs
     */
    public List<PorcelanosaAddress__c> selectCollectionPoints(Set<String> salesOrgs){
        String spoint = '(\'Collection Point\')';
        zflib_QueryFactory query = newQueryFactory();
        query.setCondition('SAPSalesOrg__c IN :salesOrgs AND NBK_Address_Type__c includes ' + spoint + ' AND NBK_isActive__c = true ');
        return (List<PorcelanosaAddress__c>) Database.query( query.toSOQL() );
    }



} // class