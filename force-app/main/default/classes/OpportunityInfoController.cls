/**
* @author 		Ramón Prades
* @date 		May 2021
* @group 		Opportunities
* @description 	Handles the additional information users can enter in the opportunity.
*/

public class OpportunityInfoController {
    
    /**
     * Reads the additional info (or returns the available options if no additional info found)
     */
    @AuraEnabled public static InfoDTO readOpportunityInfo(String opportunityId) {
        InfoDTO dto = new InfoDTO();
        dto.options = getUserOptions();
        dto.kitchenId = readKitchenId(opportunityId);
        if (dto.kitchenId != null) {
            dto.isKitchen = true;
            return dto;
        }
        dto.customProjectId = readCustomProjectId(opportunityId);
        if (dto.customProjectId != null) {
            dto.isCustomProject = true;
            return dto;
        }
        dto.facadeId = readFacadeId(opportunityId);
        if (dto.facadeId != null) {
            dto.isFacade = true;
            return dto;
        }
        return dto;
    } // readOpportunityInfo

    @AuraEnabled public static void deleteCustomProject(Id customProjectId) {
        OppCustomProject__c[] cps = [select Id from OppCustomProject__c where id = :customProjectId];
        if (cps.size() > 0) {
            delete cps;
        }
    } // deleteCustomProject

    @AuraEnabled public static void deleteKitchen(Id kitchenId) {
        OppKitchen__c[] cps = [select Id from OppKitchen__c where id = :kitchenId];
        if (cps.size() > 0) {
            delete cps;
        }
    } // deleteKitchen

    @AuraEnabled public static void deleteFacade(Id facadeId) {
        OppFacade__c[] cps = [select Id from OppFacade__c where id = :facadeId];
        if (cps.size() > 0) {
            delete cps;
        }
    } // deleteFacade

    /*********************************************************/
    /******************** INNER CLASSES **********************/
    /*********************************************************/

    public class InfoDTO {        
        @AuraEnabled public Boolean isCustomProject = false;
        @AuraEnabled public Boolean isKitchen = false;
        @AuraEnabled public Boolean isFacade = false;
        @AuraEnabled public Id customProjectId;  
        @AuraEnabled public Id kitchenId;
        @AuraEnabled public Id facadeId;
        @AUraEnabled public OptionDTO[] options = new List<OptionDTO>();
    } // Inner DTO

    public class OptionDTO {
        @AuraEnabled public String key;
        @AuraEnabled public String title;
        @AuraEnabled public String description;
    }

    /*********************************************************/
    /******************** PRIVATE METHODS ********************/
    /*********************************************************/
    private static Id readCustomProjectId(Id opportunityId) {
        OppCustomProject__c[] cps = [select Id from OppCustomProject__c where Opportunity__c = :opportunityId];
        if (cps.size() > 0) {
            return cps[0].Id;
        } else {
            return null;
        }
    } // readCustomProjectId

    private static Id readKitchenId(Id opportunityId) {
        OppKitchen__c[] cps = [select Id from OppKitchen__c where Opportunity__c = :opportunityId];
        if (cps.size() > 0) {
            return cps[0].Id;
        } else {
            return null;
        }
    } // readKitchenId

    private static Id readFacadeId(Id opportunityId) {
        OppFacade__c[] cps = [select Id from OppFacade__c where Opportunity__c = :opportunityId];
        if (cps.size() > 0) {
            return cps[0].Id;
        } else {
            return null;
        }
    } // readFacadeId

    /*
     * Gets thelist of  types of additional info the user can access.
     */
    private static OptionDTO[] getUserOptions() {
        OptionDTO[] options = new List<OptionDTO>();
        Boolean isTester = UserUtils.isTester();
        ExecutionContext context = ExecutionContext.getUserExecutionContext();
        if ( context.extendedOpps.containsIgnoreCase('CUSTOMP') || isTester) {
            OptionDTO opt = new OptionDTO();
            opt.key = 'CUSTOMP';
            opt.title = Label.opp_customProject;
            opt.description = Label.opp_customProjectText;
            options.add(opt);
        }

        if ( context.extendedOpps.containsIgnoreCase('KITCHEN') || isTester) {
            OptionDTO opt = new OptionDTO();
            opt.key = 'KITCHEN';
            opt.title = Label.dict_kitchens + ' & ' + Label.dict_cabinetry;
            opt.description = '&nbsp;';
            options.add(opt);
        }

        if ( context.extendedOpps.containsIgnoreCase('FACADE') || isTester) {
            OptionDTO opt = new OptionDTO();
            opt.key = 'FACADE';
            opt.title = Label.dict_facades;
            opt.description = '&nbsp;';
            options.add(opt);
        }

        return options;
    } // getUserOptions
} // class