/*-----------------------------------------------------------------------------------------
     Apex Class:        NB2B_OpportunitySelector
     Created Date:      27/01/2022
     Author:            Cristobal Acero Lara
     Mail:              cristobal.acero@nubika.com
     Description:       Query collection of object Opportunity
------------------------------------------------------------------------------------------*/

public with sharing class NB2B_OpportunitySelector {

    public static List<Opportunity> getOpportunityByAccount(Set<Id> idAccounts){
        return [
            SELECT ID, Name, AccountId,StageName, CloseDate  
            FROM Opportunity 
            WHERE AccountId IN: idAccounts AND StageName !='Closed'
        ];
    }
}