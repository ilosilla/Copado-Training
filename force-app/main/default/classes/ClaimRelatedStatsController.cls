/**
 * @author         Ramón Prades
 * @date           February 2024
 * @group          Cases
 * @description    ClaimRelatedStats LWX component controller
*/
public without sharing class ClaimRelatedStatsController {    

    @AuraEnabled(cacheable=true) public static DataDTO getClaimStats(Id claimId) {

        Case claim = new CasesSelector().selectById(new Set<Id>{claimId})[0];
        Case[] productClaims = readProductClaims(claim);
        Case[] accountClaims = readAccountClaims(claim);
        Case[] invoiceClaims = readInvoiceClaims(claim);

        DataDTO dto = new DataDTO();
        dto.productClaims = productClaims.size();
        dto.accountClaims = accountCLaims.size();
        dto.invoiceClaims = invoiceClaims.size();
        
        return dto;
    }

    private static List<Case> readInvoiceClaims(Case claim) {
        return [select Id, AccountId, ProductId, ProductCode__c, ProductName__c, Status from Case where 
                    SAPInvoice__c = :claim.SAPInvoice__c and
                    SAPInvoiceLine__c = :claim.SAPInvoiceLine__c and
                    Id != :claim.Id and
                    IsCLaim__c = true
                    ];
    }


    private static List<Case> readProductClaims(Case claim) {
        return [select Id, AccountId, ProductId, ProductCode__c, ProductName__c, Status from Case where 
                    ProductId = :claim.ProductId and
                    Id != :claim.Id and
                    IsCLaim__c = true
                    ];
    }

    private static List<Case> readAccountClaims(Case claim) {
        return [select Id, AccountId, ProductId, ProductCode__c, ProductName__c, Status from Case where 
                    AccountId = :claim.AccountId and
                    Id != :claim.Id and
                    IsCLaim__c = true
                    ];
    }

    public class DataDTO {
        @AuraEnabled public Integer invoiceClaims;
        @AuraEnabled public Integer productClaims;
        @AuraEnabled public Integer accountClaims;
    }

}