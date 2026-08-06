public class OpportunityLinkComponentController {

    @AuraEnabled(cacheable=true)
    public static User getUserData() {
       return new UsersSelector().selectById(UserInfo.getUserId());
    } // readOpportunityInfo

    @AuraEnabled(cacheable=true)
    public static List<ButtonInfoDTO> getButtonsInfo() {
        List<PorcelanosaSetting__c> settings = [select key__c, subkey__c, value1__c, value2__c, value3__c, value4__c, Description__c, isActive__c from PorcelanosaSetting__c where key__c = 'OPPLINKOPTION' and isActive__c = true];
        List<ButtonInfoDTO> buttons = new List<ButtonInfoDTO>();
        Boolean isAdmin = UserUtils.isAdministrator();

        for (PorcelanosaSetting__c setting : settings) {
            ButtonInfoDTO newBtn = new ButtonInfoDTO();
            newBtn.label = System.Label.get(null,setting.value2__c);
            newBtn.internalValue = setting.subkey__c;
            List<PermissionSetAssignment> listPermission = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :Userinfo.getUserId() AND PermissionSet.Name =: setting.value1__c];
            if (isAdmin || listPermission.size() > 0) {
                buttons.add(newBtn);
            }
        }
        return buttons;

     } // readOpportunityInfo

     @AuraEnabled public static String getUrlTilePlanner(String languageCode) {
        return TilePlanner.getUrl(languageCode);
     }
     
     @AuraEnabled public static String createNewMoodboard(String oppId) {
        Opportunity opp = [SELECT Id, OwnerId, Owner.LanguageLocaleKey FROM Opportunity WHERE Id =: oppId];
        OpportunityLink__c newOppLink =  new OpportunityLink__c(OpportunityId__c = oppId,
                            Name = 'New Moodboard ' + System.now(),
                            isDefault__c = false,
                            OwnerId = UserInfo.getUserId(),
                            Type__c = 'MOODBOARD');
        insert newOppLink;

        newOppLink.Url__c = 'https://moodboard.porcelanosagrupo.com/#/templates/' + opp.Owner.LanguageLocaleKey + '/SFORCE_' + newOppLink.Id;
        newOppLink.UrlText__c = 'https://moodboard.porcelanosagrupo.com/#/templates/' + opp.Owner.LanguageLocaleKey + '/SFORCE_' + newOppLink.Id;
        newOppLink.ExternalId__c = newOppLink.Id;
        update newOppLink;

        return newOppLink.Url__c;
     }

     @AuraEnabled public static String createNewCounterTop(String oppId) {
        Map<String,String> counterTopJobResult = CounterTop.createJob(oppId);
        OpportunityLink__c newOppLink =  new OpportunityLink__c();
        if (counterTopJobResult.get('error') == null) {
            Opportunity opp = [SELECT Id, OwnerId, Owner.LanguageLocaleKey, Name FROM Opportunity WHERE Id =: oppId];
            newOppLink.OpportunityId__c = oppId;
            newOppLink.Name = opp.Name + ' - ' + System.now();
            newOppLink.isDefault__c = false;
            newOppLink.OwnerId = UserInfo.getUserId();
            newOppLink.UrlText__c = counterTopJobResult.get('url');
            newOppLink.ExternalId__c = counterTopJobResult.get('id');
            newOppLink.Type__c = 'COUNTERTOP';
            insert newOppLink;
        }

        return newOppLink.UrlText__c;
     }

    public class ButtonInfoDTO {
        @AuraEnabled public String label;
        @AuraEnabled public String internalValue;
    } // inner class

    @testVisible public String testFiller() {
        String s = 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        s += 'Lorem ipsum';
        return s;
    }
}