/**
* @author 		Ramón Prades
* @date 		February 2022
* @group 		Opportunities
* @description 	Selector class for opportunity facade
*/
public  class OppFacadeSelector {
    /**
     * Returns the raw record selected by Id
     */
    public static OppFacade__c selectById(Id id) {
        return [
            SELECT
                Amount__c, CladdingMaterial__c, CostEstimateMethod__c, CreatedById, CreatedDate, CurrencyIsoCode, 
                DesignPhase__c, Id, IsDeleted, LastModifiedById, LastModifiedDate, Manager__c, MaterialReceived__c, 
                Name, Opportunity__c, ProjectNotes__c, SignedQuote__c, Stage__c, SystemModstamp
            FROM 
                OppFacade__c
            WHERE
                Id = :id 
            LIMIT 1];
    } // selectById

    /**
     * Selects a record from its ID and fills labels and some properties of the related objects
     */
    public static OppFacade__c selectByIdWithLabels(Id id) {
        return [
            SELECT
                Amount__c, toLabel(CladdingMaterial__c), toLabel(CostEstimateMethod__c), CreatedById, CreatedDate, CurrencyIsoCode, 
                toLabel(DesignPhase__c), Id, IsDeleted, LastModifiedById, LastModifiedDate, Manager__c, MaterialReceived__c, 
                Name, Opportunity__c, ProjectNotes__c, SignedQuote__c, toLabel(Stage__c), SystemModstamp,
                Opportunity__r.Id, Opportunity__r.Name, Opportunity__r.Account.Id, Opportunity__r.Account.Name,
                Opportunity__r.Owner.Email, Opportunity__r.Owner.Name, Opportunity__r.Owner.FirstName, 
                Manager__r.Name, Manager__r.EMail, Manager__r.FirstName, GContractorWinner__c, GContractorWinner__r.Name,
                InstallerWinner__c, InstallerWinner__r.Name
            FROM 
                OppFacade__c
            WHERE
                Id = :id 
            LIMIT 1];
    } // selectByIdWithLabels

}