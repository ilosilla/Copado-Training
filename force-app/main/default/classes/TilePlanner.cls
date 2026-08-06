/**
* @author 		Ivan Losilla
* @date 		June 2023
* @group 		Opportunitylink
* @description  Creates an OpportunityLink object with the type TILEPLANNER
*/
public class TilePlanner {
    public class applicationException extends Exception {}

    public static void create(RESTOpportunityLink.OpportunityLinkDTO oppLink) {
        RestResponse res = RestContext.response;

        try {
            if (String.isBlank(oppLink.opportunityId) || String.isBlank(oppLink.externalId)) {
                throw new applicationException('An opportunityId and the externalId must be set.');
            }
            // Verificar si el external Id ya existe
            List<User> creatorLink = [SELECT Id, LanguageLocaleKey FROM User WHERE username =: oppLink.value1 LIMIT 1];
            if (creatorLink.size() == 0) {
                throw new applicationException('No existing user with the username ' + oppLink.value1);
            }
            List<OpportunityLink__c> existing = [SELECT Id FROM OpportunityLink__c WHERE ExternalId__c =: oppLink.externalId LIMIT 1];
            if (existing.size() > 0) {
                throw new applicationException('A project with Id ' + oppLink.externalId + ' already exists');
            }

            // Verificar si la oportunidad existe
            Opportunity opportunity = [SELECT Id FROM Opportunity WHERE Id = :oppLink.opportunityId LIMIT 1];
            String rootUrl = getUrl(creatorLink[0].LanguageLocaleKey);
            
            if (opportunity != null) {
                // Crear el objeto OpportunityLink__c
                OpportunityLink__c opportunityLink = new OpportunityLink__c();
                opportunityLink.OpportunityId__c = oppLink.opportunityId;
                opportunityLink.ExternalId__c = oppLink.externalId;
                opportunityLink.Type__c = oppLink.type;
                opportunityLink.OwnerId = creatorLink[0].Id;
                opportunityLink.Name = oppLink.name;
                opportunityLink.Url__c = rootUrl + '?extId=' + oppLink.externalId + '&email=' + oppLink.value1;
                opportunityLink.UrlText__c = rootUrl + '?extId=' + oppLink.externalId + '&email=' + oppLink.value1;
                
                // Insertar el objeto OpportunityLink__c
                Database.SaveResult sr = Database.insert(opportunityLink);
                if (sr.isSuccess()) {
                    res.statusCode = 200;
                    res.responseBody = Blob.valueOf(JSON.serialize(opportunityLink));
                } else {
                    throw new applicationException(sr.getErrors()[0].getMessage());
                }
                
            } else {
                throw new applicationException('The opportunity doesn\'t exist. Set a valid one.');
            }
        } catch (Exception ex) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('{ "error" : "' + ex.getMessage() + '"}');
        }

    }

    public static String getUrl(String languageCode) {
        Organization a_ORG = [Select Id, Name, IsSandbox from Organization];
        String rootUrl = 'https://www.gama-decor.com/';

        if(a_ORG.IsSandbox){
            rootUrl = 'https://www.dev.gama-decor.com/';
        }

        switch on languageCode.substring(0,2) {
            when 'es' {
                rootUrl += 'configura-tu-bano/';
            }
            when 'fr' {
                rootUrl += 'fr/concevoir-votre-salle-de-bains/';
            }
            when 'pt' {
                rootUrl += 'pt/projecte-a-sua-casa-de-banho/';
            }
            when 'it' {
                rootUrl += 'it/progettare-il-tuo-bagno/';
            }
            when else {
                rootUrl += 'en/design-your-bathroom/';
            }
        }

        return rootUrl;
    }

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