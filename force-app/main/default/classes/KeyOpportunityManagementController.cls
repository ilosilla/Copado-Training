/**
* @author 	Ivan Losilla
* @date 	November 2025
* @group 	Key Opportunitys
* @description Controller of the Component KeyOpportunityManagement LWC
* @test KeyOpportunityManagementControllerTest
*/
public class KeyOpportunityManagementController {
    
    public static List<OpportunityAdditionalInfo__c> getComments(String opportunityId) {
        List<OpportunityAdditionalInfo__c> result = [
            SELECT Id, Opportunity__r.Name, Opportunity__r.Id, Opportunity__r.Last_Activity_Date__c, Value3__c,Value4__c,SentAnswer__c,Opportunity__r.Owner.Name,Opportunity__r.Owner.IsActive,Opportunity__r.Owner.Email,Opportunity__r.OwnerId,
                     Opportunity__r.Owner.Default_Sales_Organization__c, Opportunity__r.Owner.Manager.Name, Value__c, Value2__c, WeeklyCompleted__c, CreatedDate
            FROM OpportunityAdditionalInfo__c
            WHERE Opportunity__c =: opportunityId
            AND Infotype__c = 'WEEKLYCOMMENT'
            AND WeeklyCompleted__c != NULL
            ORDER BY WeeklyCompleted__c DESC
        ];

        return result;
    }

    @AuraEnabled(cacheable=false)
    public static void removeAsKey(String opportunityId) {
        Savepoint sp = Database.setSavepoint();

        try {
            Opportunity opp = [SELECT Id,LeadSource FROM Opportunity WHERE Id =: opportunityId];
            opp.LeadSource = 'PorsamarketOld';
            update opp;
        } catch (Exception e) {
            database.rollback(sp);
            throw(e);
        }        
    }

    @future
    public static void removeAsKey(List<String> opportunityIds) {
        Savepoint sp = Database.setSavepoint();

        try {
            List<Opportunity> opps = [SELECT Id,LeadSource FROM Opportunity WHERE Id IN :opportunityIds];
            for (Opportunity o : opps) {
                o.LeadSource = 'PorsamarketOld';
            }
            update opps;
        } catch (Exception e) {
            database.rollback(sp);
            throw(e);
        }        
    }

    @AuraEnabled(cacheable=false)
    public static void addSpecialProduct(String commentId, String product) {
        Savepoint sp = Database.setSavepoint();

        Map<String, List<String>> listUsersOffsite = new Map<String, List<String>>{
            'GB' => new List<String>{
                'filippo.ciadamidaro@porcelanosa.com',
                'maria.vazquez@porcelanosa.co.uk'
            },
            'FR' => new List<String>{
                'filippo.ciadamidaro@porcelanosa.com',
                'maria.vazquez@porcelanosa.co.uk',
                'ruben.urbaneja@butech.es'
            },
            'US' => new List<String>{
                'filippo.ciadamidaro@porcelanosa.com',
                'maria.vazquez@porcelanosa.co.uk'
            },
            'CA' => new List<String>{
                'filippo.ciadamidaro@porcelanosa.com',
                'maria.vazquez@porcelanosa.co.uk'
            }
        };

        Map<String, List<String>> listUsersKitchen = new Map<String, List<String>>{
        };

        try {
            OpportunityAdditionalInfo__c comment = [SELECT Id, Value3__c,Value4__c,Opportunity__c FROM OpportunityAdditionalInfo__c WHERE Id =: commentId];
            Opportunity opp = [SELECT Id,Product_categories__c,Owner.countryCode FROM Opportunity WHERE Id =: comment.Opportunity__c];
            switch on product.toUpperCase() {
                when 'OFFSITE' {
                    List<String> aux = new List<String>();
                    if (String.isBlank(opp.Product_Categories__c) == false) {
                        aux = opp.Product_Categories__c.split(';');
                        if (aux.contains('Offsite') == false) {
                            aux.add('Offsite');
                        }
                    } else {
                        aux.add('Offsite');
                    }
                    opp.Product_Categories__c = String.join(aux, ';');
                    if (listUsersOffsite.containsKey(opp.Owner.countryCode)) {
                        addCCEmailsToComment(listUsersOffsite.get(opp.Owner.countryCode), comment.Id);
                    }
                }
                when 'KITCHEN' {
                    List<String> aux = new List<String>();
                    if (String.isBlank(opp.Product_Categories__c) == false) {
                        aux = opp.Product_Categories__c.split(';');
                        if (aux.contains('Offsite') == false) {
                            aux.add('Kitchen furniture');
                        }
                    } else {
                        aux.add('Kitchen furniture');
                    }
                    opp.Product_Categories__c = String.join(aux, ';');
                    if (listUsersKitchen.containsKey(opp.Owner.countryCode)) {
                        addCCEmailsToComment(listUsersKitchen.get(opp.Owner.countryCode), comment.Id);
                    }
                }
            }

            update opp;
        } catch (Exception e) {
            database.rollback(sp);
            throw(e);
        }        
    }

    public static String addCCEmailsToComment(List<String> emails, String commentId) {
        OpportunityAdditionalInfo__c comment = [SELECT Id, Value3__c,Value4__c FROM OpportunityAdditionalInfo__c WHERE Id =: commentId];

        if (String.isBlank(comment.Value3__c)) {
            comment.Value3__c = String.join(emails,';');
        } else {
            for (String mail : emails) {
                if (comment.Value3__c.contains(mail) == false) {
                    comment.Value3__c += ';' + mail;
                }
            }
        }
        
        update comment;

        return comment.Value3__c;
    }

    @AuraEnabled(cacheable=false)
    public static String addCCEmailToComment(String email, String commentId) {
        return addCCEmailsToComment(new List<String> {email}, commentId);
    }

    @AuraEnabled(cacheable=false)
    public static String addCCUserToComment(String userId, String commentId) {
        User usr = [SELECT Id,Email FROM User WHERE Id =: userId];

        return addCCEmailToComment(usr.Email, commentId);
    }

    @AuraEnabled(cacheable=false)
    public static String removeCCEmailToComment(String email, String commentId) {
        OpportunityAdditionalInfo__c comment = [SELECT Id, Value3__c FROM OpportunityAdditionalInfo__c WHERE Id =: commentId];

        List<String> emails = new List<String>();

        for (String mail : comment.Value3__c.split(';')) {
            if (mail != email) {
                emails.add(mail);
            }
        }
        comment.Value3__c = String.join(emails,';');
        update comment;

        return comment.Value3__c;
    }

    @AuraEnabled(cacheable=false)
    public static String removeToEmailToComment(String email, String commentId) {
        OpportunityAdditionalInfo__c comment = [SELECT Id, Value4__c FROM OpportunityAdditionalInfo__c WHERE Id =: commentId];

        comment.Value4__c = null;
        update comment;

        return comment.Value4__c;
    }


    public static List<Opportunity> getKeyOpportunities() {
        List<Opportunity> keyOpps = [select id, name, ownerId,Account.Name,toLabel(StageName),Last_Activity_Date__c, AccountId from Opportunity where LeadSource = 'Porsamarket' and StageName <> 'Closed Won' and StageName <> 'Closed Lost' and StageName <> 'Lost'];
        return keyOpps;
    }

    @AuraEnabled(cacheable=false)
    public static List<OpportunityAdditionalInfo__c> getLastKeyOpportunitiesComments() {
        List<Opportunity> keyOpps = getKeyOpportunities();
        Set<String> oppIds = new Set<String>();

        for (Opportunity opp : keyOpps) {
            oppIds.add(opp.Id);
        }

        List<OpportunityAdditionalInfo__c> infos = [
            SELECT Id, Opportunity__r.Name, Opportunity__r.Id,Opportunity__r.Last_Activity_Date__c, Value3__c,Value4__c,SentAnswer__c,Opportunity__r.Owner.Name,Opportunity__r.Owner.IsActive,Opportunity__r.Owner.Email,Opportunity__r.OwnerId, Opportunity__r.Owner.Default_Sales_Organization__c, Opportunity__r.Owner.Manager.Name, Value__c,Value2__c, WeeklyCompleted__c, CreatedDate,Opportunity__r.Account.Name,Opportunity__r.AccountId
            FROM OpportunityAdditionalInfo__c
            WHERE Opportunity__c IN :oppIds
            AND Infotype__c = 'WEEKLYCOMMENT'
            AND WeeklyCompleted__c != NULL
            ORDER BY Opportunity__c, WeeklyCompleted__c DESC
        ];

        // Map para mantener solo el más reciente por Account
        Map<Id, OpportunityAdditionalInfo__c> mostRecentByOpp = new Map<Id, OpportunityAdditionalInfo__c>();

        for (OpportunityAdditionalInfo__c info : infos) {
            if (!mostRecentByOpp.containsKey(info.Opportunity__c)) {
                mostRecentByOpp.put(info.Opportunity__c, info);
            }
        }

        return mostRecentByOpp.values();
    }

    @AuraEnabled(cacheable=false)
    public static keyOpportunityData getData(String opportunityId) {
        return new KeyOpportunityData(opportunityId);
    }

    public class keyOpportunityData {
        @AuraEnabled
        public Opportunity opportunityData = new Opportunity();

        @AuraEnabled
        public List<OpportunityAdditionalInfo__c> comments = new List<OpportunityAdditionalInfo__c>();

        @AuraEnabled
        public List<OpportunityTeamMember> teamMembers = new List<OpportunityTeamMember>();

        @AuraEnabled
        public List<String> emailCC = new List<String>();

        public keyOpportunityData(){}

        public keyOpportunityData(String opportunityId) {
            this.opportunityData = [SELECT Id, Name, Last_Activity_Date__c,OwnerId,Owner.Name,Activity_Level__c,AccountId,Product_Categories__c,Account.Name FROM Opportunity WHERE Id =: opportunityId];
            this.comments = getComments(opportunityId);
            this.teamMembers = [SELECT Id, UserId, OpportunityId, TeamMemberRole, User.Name, User.Email FROM OpportunityTeamMember WHERE OpportunityId =: opportunityId];
            this.emailCC = KeyAccountManagementController.getEmailCCByUser(this.opportunityData.OwnerId);
        }
    }
}