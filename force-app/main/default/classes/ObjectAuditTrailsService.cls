/**
 * @author         Ramón Prades
 * @date           February 2024
 * @group          Object Audit Trails
 * @description    Service layer to access ObjectAuditTrail__c. This object is used to take a snapshot
 *                 of a set of up to 6 fields before they cahnge.
*/
public without sharing class ObjectAuditTrailsService {

    public static final String CLAIM_SOLUTION_TYPE = 'CLAIM_SOLUTION';

    /**
     * Inserts a new record
     */
    public static ObjectAuditTrail__c[] saveClaimSolutionTrail(Case[] claims) {
        ObjectAuditTrail__c[] trails = new List<ObjectAuditTrail__c>();
        for (Case claim : claims) {
            ObjectAuditTrail__c trail = new ObjectAuditTrail__c();
            trail.CaseId__c = claim.Id;
            trail.Name = 'CLAIM SOLUTION';
            trail.AuditTrailType__c = CLAIM_SOLUTION_TYPE;
            trail.SupplyReplacement__c = claim.SupplyReplacement__c;
            trail.SupplyInstallation__c = claim.SupplyInstallation__c;
            trail.SettlementAmount__c = claim.Compensation__c;
            trails.add(trail);
        }
        insert trails;
        return trails;
    }
    
    /**
     * Check and saves the claim solution when it has changed
     */
    public static void logClaimSolutionChanged(Case[] claims) {
        Case[] changedClaims = new List<Case>();
        for (Case claim : claims) {
            if (claimSolutionChanged(claim)) {
                changedClaims.add(claim);
            }
        }
        if (changedClaims.size() > 0) {
            saveClaimSolutionTrail(claims);
        }
    }

    public static Boolean claimSolutionChanged(Case claim) {
        ObjectAuditTrail__c lastTrail = new ObjectAuditTrailsSelector().getLastCaseTrail(claim.Id, CLAIM_SOLUTION_TYPE);
        if (lastTrail == null) {
            lastTrail = new ObjectAuditTrail__c();
            lastTrail.SupplyReplacement__c = false;
            lastTrail.SupplyInstallation__c = false;
            lastTrail.SettlementAmount__c = 0;
        }
        return (claim.SupplyReplacement__c != lastTrail.SupplyReplacement__c ||
                claim.SupplyInstallation__c != lastTrail.SupplyInstallation__c ||
                claim.Compensation__c != lastTrail.SettlementAmount__c);
    }

}